#!/bin/sh
#
# This script is run inside docker to collect benchmark results.

set -eu

# Build everything
. ./common.sh
setup

# Collect some extra info and put in a TOML file alongside the results file.
EXTRA_TOML=extra.toml
TOML_BIN=~/.local/bin/toml
touch ${EXTRA_TOML}
${TOML_BIN} add_section --toml-path ${EXTRA_TOML} versions
${TOML_BIN} set --toml-path ${EXTRA_TOML} versions.yk-benchmarks "$(git rev-parse HEAD)"
${TOML_BIN} set --toml-path ${EXTRA_TOML} versions.yk "$(cd yk && git rev-parse HEAD)"
${TOML_BIN} set --toml-path ${EXTRA_TOML} versions.ykllvm "$(cd yk/ykllvm && git rev-parse HEAD)"
${TOML_BIN} set --toml-path ${EXTRA_TOML} versions.yklua "$(cd yklua && git rev-parse HEAD)"

# Run benchmarks.
~/.local/bin/rebench --no-denoise -c rebench.conf
