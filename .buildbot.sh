#!/bin/sh

set -eu

# Build everything
. ./common.sh
setup $(pwd)/patches

# Setup some extra benchmarks
sh setup.sh lua/src/lua

# Do a "quick" rebench run as a smoke-test.
#
# We can't use --quick here due to:
# https://github.com/xdefago/stats-ci/issues/3
#
# Workaround: collect 2 samples per benchmark.
sed -e 's/invocations: [0-9]\+/invocations: 2/g' \
   -e 's/iterations: [0-9]\+/iterations: 1/g' \
   rebench.conf > rebench_ci.conf
venv/bin/rebench --no-denoise -c rebench_ci.conf

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
cd ..

# Check the haste config file works.
git clone https://github.com/ykjit/haste
cd haste
cargo build --release
cd ..
mv haste.toml haste.toml.orig
sed -e 's/proc_execs = [0-9]\+/proc_execs = 1/g' \
   -e 's/inproc_iters = [0-9]\+/inproc_iters = 1/g' \
   haste.toml.orig > haste.toml
./haste/target/release/haste b
