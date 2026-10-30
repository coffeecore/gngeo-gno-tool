# ROM Set → GNO Compatibility — Trimui Model S

> Status as of October 30, 2026. This inventory is based on 46 failures from the initial conversion, ZIP contents (sizes and CRCs), and changes applied to the converter. **The 39 additional candidate conversions have not yet been run.**

## Goal and validation levels

Generate the GNO files in a single batch, validate their structure before copying them to the Trimui Model S, and verify playability over time. The compatibility changes are host-converter-specific; they do not alter ROM definitions used by the on-device GnGeo emulator.

**Status definitions:**

- **Created**: A GNO was produced during a manual driver-alias test, and its `gnodmpv1` signature was checked. Full structural validation and on-device testing have not been performed.
- **Candidate**: Conversion support has been added, but a successful end-to-end conversion has not yet been demonstrated.
- **Excluded**: No confirmed GnGeo conversion path is available.
- **Structure OK**: Reserved for GNO files that pass `scripts/validate-gno.py` after the full batch conversion.
- **Console OK**: Reserved for games actually tested and confirmed to work on the handheld.

## Summary before the full reconversion

| Category | Count |
|---|---:|
| Driver aliases already converted manually | 5 |
| Alternative drivers / CRC variants awaiting validation | 13 |
| ROM layout fixes awaiting validation | 10 |
| 15 host-only definitions plus `sengoku3` awaiting validation | 16 |
| Currently excluded cases | 2 |
| **Total initial failures** | **46** |

## Compatibility matrix: 46 ROM sets

| Original ZIP | Planned handling | Status | Notes |
|---|---|---|---|
| `androdun.zip` | ROM layout / region adjustment | Candidate | — |
| `bstars.zip` | Alternative driver CRC | Candidate | — |
| `cnbe.zip` | New host-only definition | Candidate | — |
| `columnsn.zip` | New host-only definition | Candidate | — |
| `crswd2bl.zip` | New host-only definition | Candidate | — |
| `fatfury2.zip` | ROM layout / region adjustment | Candidate | P/V/C layout adapted in the host converter |
| `ffeast.zip` | New host-only definition | Candidate | — |
| `fightfev.zip` | Alternative driver CRC | Candidate | — |
| `flipshot.zip` | ROM layout / region adjustment | Candidate | — |
| `froman2b.zip` | New host-only definition | Candidate | — |
| `gowcaizr.zip` | Alternative driver CRC | Candidate | — |
| `gururin.zip` | Alternative driver CRC | Candidate | — |
| `ironclad.zip` | New host-only definition | Candidate | Host definition built from the ZIP manifest; playability unknown |
| `irrmaze.zip` | ROM layout / region adjustment | Candidate | Game-specific BIOS and controls; functional verification recommended |
| `janshin.zip` | Alternative driver CRC | Candidate | — |
| `kof99.zip` | Driver alias to `kof99a` | Candidate | Fixed-layer BIOS ROM may need to be loaded from `neogeo.zip` |
| `lasthope.zip` | New host-only definition | Candidate | — |
| `legendos.zip` | Alternative driver CRC | Candidate | — |
| `ltorb.zip` | New host-only definition | Candidate | — |
| `maglord.zip` | Driver alias to `maglordh` | Created | — |
| `mahretsu.zip` | Alternative driver CRC | Candidate | — |
| `miexchng.zip` | ROM layout / region adjustment | Candidate | — |
| `moshougi.zip` | Driver alias to `mosyougi` | Created | — |
| `neocup98.zip` | Alternative driver CRC | Candidate | — |
| `neomrdo.zip` | ROM layout / region adjustment | Candidate | — |
| `neonopon.zip` | New host-only definition | Candidate | — |
| `neopong.zip` | New host-only definition | Candidate | Host definition built from the ZIP manifest; playability unknown |
| `neothund.zip` | New host-only definition | Candidate | — |
| `ngem2k.zip` | New host-only definition | Candidate | — |
| `ngtetris.zip` | New host-only definition | Candidate | — |
| `pgoal.zip` | ROM layout / region adjustment | Candidate | — |
| `pnyaa.zip` | Alternative driver CRC | Candidate | — |
| `poknight.zip` | New host-only definition | Candidate | — |
| `powerins.zip` | Unsupported | Excluded | Not a Neo Geo ROM set supported by this converter |
| `pulstar.zip` | Alternative driver CRC | Candidate | — |
| `puzzldpr.zip` | ROM layout / region adjustment | Candidate | Depends on the parent ZIP `puzzledp.zip`; verify parent ROM and BIOS availability |
| `sbp.zip` | Unsupported | Excluded | Keep the ZIP or use another emulator until reliable support is available |
| `sdodgeb.zip` | ROM layout / region adjustment | Candidate | — |
| `sengoku3.zip` | 512 KiB M1 variant | Candidate | Conversion candidate; verify audio and decryption on the handheld |
| `shocktro.zip` | Driver alias to `shocktra` | Created | — |
| `socbrawl.zip` | Driver alias to `socbrawla` | Created | — |
| `strhoop.zip` | ROM layout / region adjustment | Candidate | — |
| `totc.zip` | New host-only definition | Candidate | — |
| `twsoc96.zip` | Driver alias to `tws96` | Created | — |
| `vliner.zip` | Alternative driver CRC | Candidate | — |
| `wh2j.zip` | Driver alias to `wh2jh` | Candidate | Clone driver `wh2jh`; parent dependency and data still need verification |

## Code changes

- `gngeo-steward-fu/trimui-model-s`: Host-only aliases and variants (`tools/gno_dump.c`), additional host-only definitions (`tools/gno-extra-romdefs.inc`), strict ZIP selection/loading, checked GNO serialization, and `Makefile.host` options.
- `gngeo-gno-tool/master`: Temporary GNO output and atomic replacement only after a successful conversion in `docker/entrypoint.sh`; external validation using `scripts/validate-gno.py`.
- **Important:** A ROM definition generated from file sizes and CRCs does not establish that the emulator supports the game's memory layout, decryption routines, or special hardware.

## Preparing the Docker rebuild

The `gngeo-gno-tool` Dockerfile clones the `trimui-model-s` branch of `coffeecore/gngeo-steward-fu`. **Running `make gno-image` includes local GnGeo changes only after those changes are available on the remote branch**, unless the Docker build configuration is changed to use local sources. The atomic-output change and validation script must also be present in the local `gngeo-gno-tool` checkout used for the build.

Before the full conversion, run `git diff --check`, compile the host binary, and rebuild the Docker image from the intended source revision. A GNO file's existence does not prove that the game is playable.

## Full batch reconversion (run once after build verification)

Run these commands from the `gngeo-gno-tool` repository:

```bash
ROM_DIR="/absolute/path/to/roms"
make gno-image
set -o pipefail
make gno-dir ROM_DIR="$ROM_DIR" FORCE=1 2>&1 | tee "$HOME/gno-reconversion.log"
python3 scripts/validate-gno.py "$ROM_DIR" | tee "$HOME/gno-validation.log"
```

The validator checks the `gnodmpv1` format, section sizes, sprite-block offsets, decompression, and the end of the file. It cannot confirm playability on the Trimui Model S.

### After the conversion

- Keep the original `.zip` archives; do not create duplicate ZIPs under driver-alias names.
- Review remaining failures in `.gno-failures/` and the conversion log summary.
- Transfer only GNO files that pass structural validation.
- Test games on the handheld over time and update their verified status accordingly.

## Known limitations

- `powerins` is not a Neo Geo game supported by this converter.
- `sbp` requires special support that has not been confirmed.
- `sengoku3`: The different M1 format does not guarantee working audio; decryption must be checked in practice.
- Split ROM sets may require parent ZIP archives (notably `puzzldpr`).
- Homebrew games, prototypes, and bootlegs may produce structurally valid GNO files without being playable in standalone GnGeo.

## To update after the single batch reconversion

Record the total ZIP files scanned, GNO files generated, failed conversions, and structurally invalid GNO files. For each game, replace **Candidate** with **Structure OK** or **Failed (reason)** as appropriate. Assign **Console OK** only after the game has actually been tested on the handheld.
