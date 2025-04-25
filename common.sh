# Common shared functionality.

# Build/install everything required for benchmarking.
#
# The python bits are installed inside a virtual env in a directory
# `$(PWD)/venv`.
setup() {
    # Install Rust
    export CARGO_HOME="$(pwd)/.cargo"
    export RUSTUP_HOME="$(pwd)/.rustup"
    export RUSTUP_INIT_SKIP_PATH_CHECK="yes"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
    sh rustup.sh --default-host x86_64-unknown-linux-gnu \
       --default-toolchain nightly \
       --no-modify-path \
       --profile default \
       -y
    export PATH=${PWD}/.cargo/bin/:${PATH}

    # Set up yk.
    git clone --recurse-submodules https://github.com/ykjit/yk
    cd yk
    cargo build --release -p ykcapi -vv
    export PATH=$(pwd)/bin:${PATH}
    cd ..

    # Build yklua with JIT support.
    git clone https://github.com/ykjit/yklua
    cd yklua
    patch -p0 < $1/clua_gettime
    YK_BUILD_TYPE=release make -j $(nproc)
    mv src/lua src/yklua
    cd ..

    # Build plain old Lua as a baseline.
    LUA_V=5.4.6
    curl https://lua.org/ftp/lua-${LUA_V}.tar.gz -o lua-${LUA_V}.tar.gz
    tar zxvf lua-${LUA_V}.tar.gz
    mv lua-${LUA_V} lua
    cd lua
    patch -p0 < $1/clua_gettime
    make -j $(nproc)
    cd ..

    python3 -m venv venv
    ./venv/bin/pip install rebench
    ./venv/bin/pip install toml-cli
}
