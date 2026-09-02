#!/usr/bin/env bash
#
# Runs the geometry tests in tools/tests against a mock of the slicer API.
#
# These check placement arithmetic only -- wall thickness around a cavity, lid
# clearance, whether both readings of an ambigram are concentric. They cannot
# check that a plugin does the right thing in PrusaSlicer, because `api`,
# `VolumeType` and the preset system exist only inside it. Treat a green run as
# "the maths is what I intended", not as "this prints correctly".

set -euo pipefail

LUA=${LUA:-lua}
status=0

for test in tools/tests/*_test.lua; do
    echo "== $(basename "$test")"
    if "$LUA" "$test"; then
        :
    else
        status=1
    fi
done

exit $status
