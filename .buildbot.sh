#!/bin/sh

set -eu

# Build everything
. ./common.sh
setup

# Do a "quick" rebench run as a smoke-test.
#
# We can't use --quick here due to:
# https://github.com/xdefago/stats-ci/issues/3
#
# Workaround: collect 2 samples per benchmark.
sed -e 's/invocations: [0-9]\+/invocations: 2/g' \
   -e 's/iterations: [0-9]\+/iterations: 1/g' \
   rebench.conf > rebench_ci.conf
~/.local/bin/rebench --no-denoise -c rebench_ci.conf

# Do some minimal checks on the reporter.
cd reporter
cargo fmt
cargo build

RES_DIR=results
RES_SUBDIR=${RES_DIR}/$(date +%Y%m)
mkdir -p ${RES_SUBDIR}
mv ../benchmark.data ${RES_SUBDIR}/$(date +%Y%m%d_%H%M%S).data
cargo run results html
ls html/index.html # checks the file exists
