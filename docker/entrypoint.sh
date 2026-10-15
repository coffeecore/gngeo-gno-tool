#!/bin/bash

set -euo pipefail

DUMPER="/usr/local/bin/gngeo-gno-dump"
FORCE="${FORCE:-0}"

usage()
{
    echo "Usage:"
    echo "  gno-convert single /roms/game.zip"
    echo "  gno-convert dir /roms"
}

convert_rom()
{
    local rom="$1"
    local rom_dir
    local base
    local output
    local log_dir
    local log
    local tmp_log

    rom_dir="$(dirname "$rom")"
    base="$(basename "$rom")"

    if [[ "${base,,}" == "neogeo.zip" ]]; then
        return 2
    fi

    output="${rom%.*}.gno"

    if [[ -f "$output" && "$FORCE" != "1" ]]; then
        echo "Skipping existing: $output"
        return 2
    fi

    echo
    echo "Converting: $base"

    log_dir="$rom_dir/.gno-failures"
    mkdir -p "$log_dir"

    log="$log_dir/${base%.zip}.log"
    tmp_log="${log}.tmp"

    if "$DUMPER" "$rom" >"$tmp_log" 2>&1; then
        cat "$tmp_log"
        rm -f "$tmp_log" "$log"
        return 0
    fi

    cat "$tmp_log"
    mv "$tmp_log" "$log"

    echo "ERROR: failed to convert: $base" >&2
    return 1
}

if [[ $# -lt 2 ]]; then
    usage
    exit 1
fi

case "$1" in
    single)
        convert_rom "$2"
        ;;

    dir)
        ROM_DIR="$2"

        [[ -d "$ROM_DIR" ]] || {
            echo "ERROR: directory not found: $ROM_DIR" >&2
            exit 1
        }

        [[ -f "$ROM_DIR/neogeo.zip" ]] || {
            echo "ERROR: neogeo.zip not found in: $ROM_DIR" >&2
            exit 1
        }

        shopt -s nullglob nocaseglob

        converted=0
        skipped=0
        failed=0
        failed_roms=()

        for rom in "$ROM_DIR"/*.zip; do
            if convert_rom "$rom"; then
                converted=$((converted + 1))
            else
                status=$?

                if [[ "$status" -eq 2 ]]; then
                    skipped=$((skipped + 1))
                else
                    failed=$((failed + 1))
                    failed_roms+=("$(basename "$rom")")
                fi
            fi
        done

        echo
        echo "Conversion complete:"
        echo "  Converted: $converted"
        echo "  Skipped:   $skipped"
        echo "  Failed:    $failed"

        if [[ "$failed" -gt 0 ]]; then
            echo
            echo "Failed ROMs:"

            for rom in "${failed_roms[@]}"; do
                echo "  $rom"
            done

            exit 1
        fi
        ;;

    *)
        usage
        exit 1
        ;;
esac
