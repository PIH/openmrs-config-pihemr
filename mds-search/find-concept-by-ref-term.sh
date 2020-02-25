#!/bin/bash

usage() {
    echo "Finds the package that a given reference term is found in."
    echo "Ignores the reference term source."
    echo
    echo "Looks through the .xml files that ./update.sh puts in this directory."
    echo "If there are no .xml files in this directory, run ./update.sh."
    echo
    echo "Usage: ./find-concept-by-ref-term.sh <ref_term>"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

grep -l "<code>$1</code>" * | sed 's/metadata.xml/header.xml/' | xargs grep "<name>"

