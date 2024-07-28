#!/usr/bin/env bash

set -euo pipefail

GIT_REPO="${GIT_REPO:-$(git -C $(dirname ${BASH_SOURCE[0]}) rev-parse --show-toplevel || echo "EMPTY")}"
IMAGE=manjaro_buildiso
TMP_DIR=/tmp/manjaro_buildiso_docker
BUILDISO_TMP_DIR=${HOME}/tmp/buildiso

function log() {
    printf "\n${1}\n"
    printf '%0.s=' $(seq 1 ${#1})
    printf '\n'
}

function main() {
    mkdir -p "${BUILDISO_TMP_DIR}"
    
    docker build --file ${GIT_REPO}/Dockerfile -t "${IMAGE}" ${GIT_REPO}
    
    docker run \
        -it \
        --rm \
        --net=host \
	--privileged \
        -v ${BUILDISO_TMP_DIR}:/var/lib/manjaro-tools/buildiso \
        "${IMAGE}" \
        bash
}

if [[ "${GIT_REPO}" == "EMPTY" ]]; then
    echo "There is no determinable git repository! repo_dir: ${GIT_REPO}"
    log "Downloading repo..."

    BUILDISO_TAR="${TMP_DIR}/manjaro-buildiso-docker.tar.gz"
    if [ ! -f "${BUILDISO_TAR}" ]; then
        mkdir ${TMP_DIR}
        curl -sSL -o ${BUILDISO_TAR} https://github.com/SilverTux/manjaro_buildiso_docker/tarball/main
        pushd ${TMP_DIR}
        tar xvzf ${BUILDISO_TAR}
        popd
    fi

    GIT_REPO=$(realpath ${TMP_DIR}/SilverTux-manjaro_buildiso_docker*)
    log "Downloaded repo: ${GIT_REPO}"
fi

main
