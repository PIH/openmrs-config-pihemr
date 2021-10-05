#!/bin/bash

usage() {
    echo "Searches MDS packages for a concept by ID."
    echo "Looks through the XML files that `./update.sh` puts in `mds/`"
    echo "If there are no XML files in that directory, run `./update.sh`."
    echo
    echo "Usage: ./find-concept.sh <concept_id>"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

grep -l "<conceptId>$1</conceptId>" mds/* | sed 's/metadata.xml/header.xml/' | xargs grep "<name>"
grep "<conceptId>$1</conceptId>" mds/*
grep -A50 "<conceptId>$1</conceptId>" mds/* | grep -m 1 -A8 "<conceptNameId>" | grep "<name>"
