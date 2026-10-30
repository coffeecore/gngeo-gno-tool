#!/usr/bin/env python3
"""Validate structural integrity of GnGeo gnodmpv1 files.

This verifies headers, region sizes, sprite block offsets and compressed data.
It does NOT establish that the game is playable on the target device.

Usage: python3 validate-gno.py /path/to/roms
       python3 validate-gno.py game1.gno game2.gno
"""
import argparse
import struct
import sys
import zlib
from pathlib import Path

REGIONS = {0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11}


class InvalidGno(ValueError):
    pass


def read_exact(f, size):
    data = f.read(size)
    if len(data) != size:
        raise InvalidGno(f"truncated at offset {f.tell() - len(data)}")
    return data


def uint32(f):
    return struct.unpack("<I", read_exact(f, 4))[0]


def validate(path):
    size = path.stat().st_size
    with path.open("rb") as f:
        if read_exact(f, 8) != b"gnodmpv1":
            raise InvalidGno("invalid magic")
        romname = read_exact(f, 8).decode("ascii", errors="replace").strip()
        flags = uint32(f)
        count = read_exact(f, 1)[0]
        if not 1 <= count <= 16:
            raise InvalidGno(f"unexpected section count: {count}")

        regions = set()
        for section in range(count):
            unpacked_size, region, kind = struct.unpack("<IBB", read_exact(f, 6))
            if region not in REGIONS or region in regions:
                raise InvalidGno(f"unknown or duplicate region: {region}")
            regions.add(region)
            if unpacked_size == 0:
                raise InvalidGno(f"empty region: {region}")

            if kind == 0:
                if f.tell() + unpacked_size > size:
                    raise InvalidGno(f"truncated region: {region}")
                f.seek(unpacked_size, 1)
            elif kind == 1 and region == 9:
                block_size = uint32(f)
                if block_size < 128 or block_size & (block_size - 1):
                    raise InvalidGno("invalid sprite block size")
                if unpacked_size % block_size:
                    raise InvalidGno("sprite size not divisible by block size")
                nblocks = unpacked_size // block_size
                if nblocks == 0 or nblocks * 4 + 4 > size - f.tell():
                    raise InvalidGno("truncated sprite offset table")
                offsets = struct.unpack(f"<{nblocks}I", read_exact(f, nblocks * 4))
                compressed_total = uint32(f)
                compressed_bytes = 0
                for index, offset in enumerate(offsets):
                    if offset != f.tell():
                        raise InvalidGno(f"invalid sprite offset in block {index}")
                    chunk_size = uint32(f)
                    if not chunk_size or chunk_size > size - f.tell():
                        raise InvalidGno(f"invalid sprite chunk length in block {index}")
                    try:
                        chunk = zlib.decompress(read_exact(f, chunk_size))
                    except zlib.error as exc:
                        raise InvalidGno(f"sprite decompression failed in block {index}: {exc}") from exc
                    if len(chunk) != block_size:
                        raise InvalidGno(f"wrong sprite decompressed size in block {index}")
                    compressed_bytes += chunk_size
                if compressed_bytes != compressed_total:
                    raise InvalidGno("wrong compressed size in sprite header")
            else:
                raise InvalidGno(f"unsupported region type {kind} for region {region}")

        if 8 not in regions:
            raise InvalidGno("missing main CPU region")
        if (9 in regions) != (10 in regions):
            raise InvalidGno("sprite data/usage region mismatch")
        if f.tell() != size:
            raise InvalidGno(f"trailing data: {size - f.tell()} bytes")
    return romname, count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", type=Path, help="GNO files or directories")
    args = parser.parse_args()
    paths = []
    for p in args.paths:
        if p.is_dir():
            paths.extend(sorted(p.glob("*.gno")))
        else:
            paths.append(p)
    if not paths:
        parser.error("no GNO files found")
    passed = failed = 0
    for path in paths:
        try:
            name, count = validate(path)
            print(f"OK   {path.name}  (driver={name}, sections={count})")
            passed += 1
        except (InvalidGno, OSError, struct.error) as exc:
            print(f"FAIL {path.name}  ({exc})")
            failed += 1
    print(f"\nChecked: {passed + failed} | OK: {passed} | Failed: {failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
