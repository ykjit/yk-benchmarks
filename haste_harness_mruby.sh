#!/bin/sh
# mruby has no require/require_relative, so unlike haste_harness_ruby.sh
# this can't just run harness.rb and let it require_relative the rest.
# Instead it loads the pieces harness.rb would have require_relative'd
# (benchmark.rb - which also stubs require_relative/Process.clock_gettime
# for mruby, som.rb if the benchmark needs it, and the benchmark file
# itself) via mruby's `-r`, then runs harness.rb (a require-free stand-in
# for what harness.rb/run.rb do on CRuby) as the programfile.
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
param=${1:-1};

repo_dir="$(cd "$(dirname "$0")" && pwd)"
runner="$repo_dir/suites/awfy/MRuby/harness.rb"

# Mirrors run.rb's load_benchmark_suite: try the plain downcased name first
# (e.g. DeltaBlue -> deltablue.rb), and only hyphenate camelCase boundaries
# (e.g. NBody -> n-body.rb) if that file doesn't exist.
plain=$(echo "$bmark" | tr '[:upper:]' '[:lower:]')
if [ -f "$plain.rb" ]; then
    file=$plain
else
    file=$(echo "$bmark" | sed -E 's/([a-z])([A-Z])/\1-\2/g' | tr '[:upper:]' '[:lower:]')
fi

set -- "$executor" -r benchmark.rb
case "$file" in
    bounce|cd|havlak|deltablue|storage|json) set -- "$@" -r som.rb ;;
esac
set -- "$@" -r "$file.rb" "$runner" "$bmark" "$inproc_iters" "$param"

set +e
output=$("$@" 2>&1)
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
