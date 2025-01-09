#!/bin/sh
#
# Run a benchmarking session inside a temporary directory and file away the
# results file.

set -eu

usage() {
    echo "usage: run.sh <results-dir>"
}

# Determine how to format time on current platform and take a reading of the
# system clock now.
#
# We use this reading to generate all paths that contain date/time elements.
case $(uname | tr '[:upper:]' '[:lower:]') in
    linux)
        FMT_EPOCH="date -d"
        TIMESTAMP=@$(date +%s) # linux requires an @
        ;;
    openbsd)
        FMT_EPOCH="date -r"
        TIMESTAMP=$(date +%s)
        ;;
    *)
        echo "unsupported OS"
        exit 1
        ;;
esac

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

if [ $1 = "-h" -o $1 = "--help" ]; then
    usage
    exit 0
fi

RES_DIR=$1; shift

# Create a place for the results file to live if necessary.
#
# We are going to put results files in YYYY-MM sub-directories so that we don't
# get one huge directory of results files.
RES_SUBDIR="${RES_DIR}/$(${FMT_EPOCH} ${TIMESTAMP} +%Y%m)"
mkdir -p ${RES_SUBDIR}

# Set up a fresh time-stamped directory.
YMDHMS=$(${FMT_EPOCH} ${TIMESTAMP} +%Y%m%d_%H%M%S)
RUN_DIR="${PWD}/runs/${YMDHMS}"
mkdir -p ${RUN_DIR}
cleanup() {
    rm -rf ${RUN_DIR}
}
trap 'cleanup' EXIT

. ./common.sh
cd ${RUN_DIR}
setup
ln -s ../../rebench.conf .
ln -s ../../suites .

# Collect some extra info and put in a TOML file alongside the results file.
EXTRA_TOML=extra.toml
TOML_BIN=venv/bin/toml
touch ${EXTRA_TOML}
${TOML_BIN} add_section --toml-path ${EXTRA_TOML} versions
${TOML_BIN} set --toml-path ${EXTRA_TOML} versions.yk-benchmarks "$(git rev-parse HEAD)"
${TOML_BIN} set --toml-path ${EXTRA_TOML} versions.yk "$(cd yk && git rev-parse HEAD)"
${TOML_BIN} set --toml-path ${EXTRA_TOML} versions.ykllvm "$(cd yk/ykllvm && git rev-parse HEAD)"
${TOML_BIN} set --toml-path ${EXTRA_TOML} versions.yklua "$(cd yklua && git rev-parse HEAD)"

# Run benchmarks.
venv/bin/rebench -q --no-denoise -c rebench.conf

# File away the results file (and extra info file) in the output directory.
cp ${EXTRA_TOML} ../../${RES_SUBDIR}/${YMDHMS}-extra.toml
cp benchmark.data ../../${RES_SUBDIR}/${YMDHMS}.data
