#!/usr/bin/env bash
#
# Simulates the plugin scan PrusaSlicer performs at startup.
#
# PluginBundle::load_plugins() runs every .lua file in a bare Lua engine to read
# its `info` table. That engine has neither `api` nor the slicer's custom
# `require` -- those exist only when a plugin is executed. A file that touches
# either at load time therefore aborts, and the plugin silently never appears in
# the menu.
#
# This check reproduces that pass: each file is loaded in a fresh interpreter
# with nothing provided. Loading must succeed; a file that defines `info` is
# reported as a plugin, one that does not is treated as a shared module.

set -euo pipefail

LUA=${LUA:-lua}
status=0
plugins_found=0

for bundle in plugins/*/; do
    bundle_id=$(basename "$bundle")
    echo "$bundle_id"

    if [ ! -f "$bundle/manifest.json" ]; then
        echo "  ERROR: no manifest.json — the slicer will not treat this as a bundle"
        status=1
        continue
    fi

    for file in "$bundle"*.lua; do
        name=$(basename "$file")
        output=$("$LUA" -e "
            local ok, err = pcall(dofile, [[$file]])
            if not ok then
                print('FAIL\t' .. tostring(err))
            elseif type(info) == 'table' and info.id then
                print('PLUGIN\t' .. tostring(info.menu))
            else
                print('MODULE\t')
            end
        " 2>&1) || {
            echo "  $name: FAIL (interpreter error)"
            echo "$output" | sed 's/^/    /'
            status=1
            continue
        }

        kind=${output%%$'\t'*}
        detail=${output#*$'\t'}

        case "$kind" in
            PLUGIN)
                echo "  $name: plugin, menu '$detail'"
                plugins_found=$((plugins_found + 1))
                ;;
            MODULE)
                echo "  $name: shared module"
                ;;
            FAIL)
                echo "  $name: FAILS THE SCAN — this plugin would not appear in the menu"
                echo "    $detail"
                echo "    Modules must be required inside execute(), not at file level."
                status=1
                ;;
        esac
    done
done

if [ "$plugins_found" -eq 0 ]; then
    echo "ERROR: no plugins found in any bundle"
    status=1
fi

exit $status
