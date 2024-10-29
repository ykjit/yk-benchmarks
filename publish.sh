#!/bin/sh
#
# Generate report and publish to gh-pages.

set -eu

GIT_REPO=git@github.com:ykjit/yk-benchmarks

usage() {
    echo "publish.sh <results-dir>"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

RES_DIR=$1
OUT_DIR=$(mktemp -d)

cd reporter
cargo build --release
cd ..

./reporter/target/release/reporter ${RES_DIR} ${OUT_DIR}

cd ${OUT_DIR}
git init
git config user.email "noreply@soft-dev.org"
git config user.name "yk-benchmarks"
git add .
git commit -m "Deploy gh-pages"
git push -f ${GIT_REPO} HEAD:gh-pages
