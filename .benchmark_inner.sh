#!/bin/sh
#
# This script is run inside docker to collect benchmark results.

set -eu

# Build everything
. ./common.sh
setup

# Run benchmarks.
~/.local/bin/rebench --no-denoise -c rebench.conf
