#!/bin/sh

set -eu

pipx install rebench

# Do a "quick" run as a smoke-test.
~/.local/bin/rebench --quick --no-denoise -c rebench.conf
