#!/bin/bash

usage() {
    echo "Prints the ID and name of all the concepts in a `metadata.xml` file."
    echo "These files are put in the `mds/` folder by the `./update.sh` script."
    echo
    echo "Usage: ./print-contents.sh <metadata-xml-file>"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

mapfile -t ids < <(grep "<conceptId>.*</conceptId>" $1 | grep -Eo '[0-9]*' | sort -g | uniq)
ids_length=${#ids[@]}
for (( i = 0; i < $ids_length; i++ )); do
    id=${ids[$i]}
    names[$i]=$(grep -A50 "<conceptId>$id</conceptId>" $1 | grep -A8 "<conceptNameId>" | grep "<name>" | sed "s/<name>\(.*\)<\/name>/\1/")
done
echo ${#names[@]}
for (( i = 0; i < $ids_length; i++ )); do
    id=${ids[$i]}
    name=${names[$i]}
    echo -e $id '\t' $name
done
