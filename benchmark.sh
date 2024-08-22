#!/bin/sh
#
# Run a benchmarking session inside a docker container and file away the
# results file.

set -eu

usage() {
    echo "usage: run.sh <results-dir>"
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

if [ $1 = "-h" -o $1 = "--help" ]; then
    usage
    exit 0
fi

RES_DIR=$1; shift

# Read the system clock now.
#
# We use this reading to generate all paths that contain date/time elements.
TIMESTAMP=$(date +%s) # seconds since EPOCH.

# Create a place for the results file to live if necessary.
#
# We are going to put results files in YYYY-MM sub-directories so that we don't
# get one huge directory of results files.
RES_SUBDIR="${RES_DIR}/$(date -j -f %s ${TIMESTAMP} +%Y%m)"
mkdir -p ${RES_SUBDIR}

# Run benchmarks inside docker.
YMDHMS=$(date -j -f %s ${TIMESTAMP} +%Y%m%d_%H%M%S)
IMAGE_TAG="bm-${YMDHMS}"
CONT_NAME=$(pwgen -s 16 1)
BM_UID=$(id -u)
docker build --build-arg BM_UID=${BM_UID} -t ${IMAGE_TAG} --file Dockerfile-benchmarking .
docker run --cap-add CAP_PERFMON -u ${BM_UID} --name ${CONT_NAME} ${IMAGE_TAG}

# Stash extra info file.
docker container cp ${CONT_NAME}:/bm/extra.toml \
    ${RES_SUBDIR}/${YMDHMS}-extra.toml

# File away the results file in the output directory.
docker container cp ${CONT_NAME}:/bm/benchmark.data \
    ${RES_SUBDIR}/${YMDHMS}.data

# Remove the container.
docker container rm ${CONT_NAME}
