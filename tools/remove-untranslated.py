#!/usr/bin/env python3

import argparse
import re
from pathlib import Path

DIR = Path("../configuration/messageproperties")

def main(lang):
    en_strings = properties_to_dict(read_file("en"))
    t_strings = properties_to_dict(read_file(lang))
    translated = {k: t_strings[k] for k in t_strings if en_strings[k] != t_strings[k]}
    pairs = sorted(translated.items(), key=lambda t: t[0])

    outfile_path = DIR / ("./messages_" + lang + ".properties")
    with open(outfile_path, "w") as outfile:
        for k, v in pairs:
            outfile.write(k + "=" + v + "\n")

    print("Written to " + str(outfile_path))


def read_file(lang):
    infile_path = DIR / ("./messages_" + lang + ".properties")
    text = open(infile_path).read()
    text = re.sub(r"\s*\\\n\s*", " ", text)
    lines = text.split("\n")
    lines = [l.strip() for l in lines if l.strip() and not l.strip().startswith("#")]
    return lines


def properties_to_dict(lines):
    return {
        s.split("=")[0].strip(): (
            s.split("=")[1].strip() if len(s.split("=")) > 1 else ""
        )
        for s in lines
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Remove translation strings if they match the English string. Overwrites existing file."
    )
    parser.add_argument("language", help="e.g. 'es' for messages_es.properties")
    args = parser.parse_args()
    main(args.language)
