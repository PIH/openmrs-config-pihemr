#!/bin/bash

usage() {
    echo "Finds the MDS package header file by name. Can be partially specified."
    echo "Looks through the XML files that `./update.sh` puts in `mds/`"
    echo "If there are no XML files in that directory, run `./update.sh`."
    echo
    echo "Usage: ./find-package-by-name.sh <package_name>"
    echo
    echo "  e.g. ./find-package-by-name.sh allergies"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

grep -i "<name>.*$1.*</name>" mds/header.xml*
