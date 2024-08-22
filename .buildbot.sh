#!/bin/sh

set -eu

# Build everything
. ./common.sh
setup

# Do a "quick" rebench run as a smoke-test.
~/.local/bin/rebench --quick --no-denoise -c rebench.conf

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
