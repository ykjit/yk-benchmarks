#!/bin/sh

set -eu

if [ "$#" -lt 4 ]; then
    printf "usage: $0 <output-file> "
    printf "<executor> <benchmark> <inproc_iters> [param]\n"
    exit 1
fi

outf=$1; shift
executor=$1; shift
bmark=$1; shift
inproc_iters=$1; shift

# The parameter argument is optional.
param=${1:-x}

# Classpath: SOM_LIB (the SOM implementation's Smalltalk core library, set by
# the user) plus the awfy SOM benchmark dir and each of its subdirs.
SOM_DIR=../../awfy/SOM
SUBDIRS="$SOM_DIR:$SOM_DIR/Core:$SOM_DIR/CD:$SOM_DIR/DeltaBlue:$SOM_DIR/Havlak:$SOM_DIR/Json:$SOM_DIR/NBody:$SOM_DIR/Richards"
if [ -n "${SOM_LIB:-}" ]; then
    CP="$SOM_LIB:$SUBDIRS"
else
    CP="$SUBDIRS"
fi

set +e
output=$("$executor" -cp "$CP" Harness "$bmark" "$inproc_iters" "$param" 2>&1)
s=$?
set -e

# shellcheck disable=SC2181
if [ $s -ne 0 ]; then
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
