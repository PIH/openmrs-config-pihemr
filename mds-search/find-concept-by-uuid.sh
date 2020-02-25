#!/bin/bash

usage() {
    echo "Searches MDS packages for a concept by UUID."
    echo "Looks through the .xml files that ./update.sh puts in this directory."
    echo "If there are no .xml files in this directory, run ./update.sh."
    echo
    echo "Usage: ./find-concept-by-uuid.sh <concept_id>"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

grep -l "uuid=\"$1\"" header.xml* | xargs grep "<name>"
grep -A1 "uuid=\"$1\"" header.xml* | grep -h "<id>"
grep -A100 "uuid=\"$1\"" metadata.xml* | grep -m 1 -C5 "<locale.*en</locale>" | grep "<name>"
