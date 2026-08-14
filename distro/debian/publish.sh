#!/bin/bash

# This script expects a file named .pihemr-debian-env in the users home directory, which contains the credentials for the debian repository
# DEBIAN_REPO_USER=user
# DEBIAN_REPO_PASSWORD='password'

usage () {
    echo -e "Usage: publish.sh [stable|unstable]\n"
    echo -e "Publishes the debian package in the project build directory to the PIH EMR Debian repo under the stable or unstable distribution"
}

if [[ $# -eq 0 || ($1 != 'stable' && $1 != 'unstable') ]]; then
    echo -e "Please provide the name of the distribution to deploy to [stable or unstable] as a command line argument"
    usage
    exit 1
fi

DEBIAN_REPO_BASE_URL="https://openmrs.jfrog.io/artifactory/deb-pih/pool"
DEBIAN_REPO_DISTRIBUTION=$1

DEBIAN_FILENAME="$(ls *.deb)"

# insert distro name into filename when posting it the repo
DEBIAN_FILENAME_WITH_DISTRO="${DEBIAN_FILENAME/-1_all/-1_"$1"_all}"

curl -u${DEBIAN_REPO_USER}:${DEBIAN_REPO_PASSWORD} -X PUT "${DEBIAN_REPO_BASE_URL}/${DEBIAN_FILENAME_WITH_DISTRO};deb.distribution=${DEBIAN_REPO_DISTRIBUTION};deb.component=main;deb.architecture=amd64" -T ${DEBIAN_FILENAME}