#!/usr/bin/env python3
# Read in a file from $1, resolve the full path of all lines
# starting with "reference,", and write out to ${1}.resolved.csv

import os
import sys

fp_in = sys.argv[1]
print(f"Reading in from {fp_in}")

fp_out = f"{fp_in}.resolved.csv"
print(f"Writing out to {fp_out}")


def resolve(line, targets=[
    "FASTQ_DIR",
    "GEX_REF",
    "VDJ_REF",
    "feature.csv",
    "cellranger_probe_set.csv"
]):

    for target in targets:

        if target in line:

            resolved_target = os.path.abspath(target)
            print(f"Resolving {target} -> {resolved_target}")
            return line.replace(target, resolved_target)

    return line


with open(fp_in, "r") as handle_in, open(fp_out, "w") as handle_out:

    for line in handle_in:

        handle_out.write(
            resolve(
                line
            )
        )
