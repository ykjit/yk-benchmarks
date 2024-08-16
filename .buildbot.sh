#!/bin/sh

set -eu

# Build everything
. ./common.sh
setup

# Do a "quick" rebench run as a smoke-test.
~/.local/bin/rebench --quick --no-denoise -c rebench.conf
