#!/bin/sh

set -eu

# Install Rust
export RUSTUP_INIT_SKIP_PATH_CHECK="yes"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
sh rustup.sh --default-host x86_64-unknown-linux-gnu \
    --default-toolchain nightly \
    --no-modify-path \
    --profile default \
    -y
export PATH=~/.cargo/bin/:${PATH}

# Set up yk.
git clone --recurse-submodules https://github.com/ykjit/yk
cd yk
cargo build --release -p ykcapi -vv
export PATH=$(pwd)/bin:${PATH}
cd ..

# Build yklua with JIT support.
git clone https://github.com/ykjit/yklua
cd yklua
YK_BUILD_TYPE=release make -j $(nproc)
mv src/lua src/yklua

# Build yklua without JIT support. This will be the baseline.
make clean
make -j $(nproc)
cd ..

# Do a "quick" rebench run as a smoke-test.
pipx install rebench
~/.local/bin/rebench --quick --no-denoise -c rebench.conf
