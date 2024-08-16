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

# Create a place for the results file to live if necessary.
#
# We are going to put results files in YYYY-MM sub-directories so that we don't
# get one huge directory of results files.
RES_SUBDIR="${RES_DIR}/$(date +%Y%m)"
mkdir -p ${RES_SUBDIR}

# Run benchmarks inside docker.
IMAGE_TAG="bm-$(date +%Y%m%d_%H%M%S)"
CONT_NAME=$(pwgen -s 16 1)
BM_UID=$(id -u)
docker build --build-arg BM_UID=${BM_UID} -t ${IMAGE_TAG} --file Dockerfile-benchmarking .
docker run --cap-add CAP_PERFMON -u ${BM_UID} --name ${CONT_NAME} ${IMAGE_TAG}

# File away the results file in the output directory.
RES_DEST="${RES_SUBDIR}/$(date +%Y%m%d_%H%M%S).data"
docker container cp ${CONT_NAME}:/bm/benchmark.data ${RES_DEST}

# Remove the container.
docker container rm ${CONT_NAME}
