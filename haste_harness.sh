#!/bin/sh

set -eu

if [ "$#" -lt 4 ]; then
    printf "usage: haste_harness.sh <output-file> "
    printf "<executor> <benchmark> <inproc_iters> [param]\n"
    exit 1
fi

outf=$1; shift
executor=$1; shift
bmark=$1; shift
inproc_iters=$1; shift

# The parameter argument is optional.
# Pass an "x" if not given. harness.lua will ignore it anyway.
param=${1:-x};

output=$("$executor" ../../awfy/Lua/harness.lua "$bmark" "$inproc_iters" "$param" 2>&1)
s=$?

# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
    echo "$output"
    echo "error: failed to run inner harness"
    exit $s
fi

# Scrape the reading for the entire process execution from the output, check it
# has a "us" (microseconds) suffix, strip it, convert to miliseconds, and write
# it to where haste asked.
usecs=$(echo "$output" | awk -F ': *' '$1 == "Total Runtime" { print $2 }')
echo "$usecs" | grep 'us'
usecs=${usecs%us}
msecs=$(echo "$usecs" / 1000 | bc -l) # -l enables floating point division
printf "PEXEC_WALLCLOCK_MS=%f" "$msecs" > "$outf"
