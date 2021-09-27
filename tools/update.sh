#!/usr/bin/env bash

usage() {
    echo "Unzips all the MDS files in configuration/pih/concepts/ to the mds/ folder."
    echo
    echo "Usage: ./update.sh"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

mkdir -p mds
cd mds/
rm *.xml*
unzip -B '../../configuration/pih/concepts/*.zip'
cd ..
