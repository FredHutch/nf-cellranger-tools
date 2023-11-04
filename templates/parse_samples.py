#!/usr/bin/env python3

import os

# The list of files should be found in a file named 'files.txt'
assert os.path.exists('files.txt'), "Could not file 'files.txt'"

# Read in the list of files
with open('files.txt', 'r') as handle:
    files = [
        line.rstrip('\\n')
        for line in handle
    ]

# Log the list of files
print(f"Read in a list of {len(files):,} files:")
print("\\n".join(files))
print("")

# Filter to those which end with ".fastq.gz"
files = [f for f in files if f.endswith(".fastq.gz")]
print(f"Number ending with .fastq.gz: {len(files):,}")


# Filter to those which match the pattern "*_S*_L**_R{1,2}_001.fastq.gz",
# returning the sample name at the start of the string if it does match
def matches_filter(fp):
    fp = right_replace(fp, ".fastq.gz")
    if fp is None:
        return

    fp = right_replace(fp, "_001")
    if fp is None:
        return

    fp = right_replace(fp, ("_R1", "_R2"), l=3)
    if fp is None:
        return

    if len(fp.split("_")) < 3:
        return

    fields = fp.rsplit("_", 2)
    assert len(fields) == 3, fields

    if fields[1][0] != "S":
        return

    if fields[2][0] != "L":
        return

    return fields[0]


def right_replace(fp, s, l=None):
    if not fp.endswith(s):
        return
    else:
        if l is None:
            l = len(s)
        return fp[:-l]

samples = list(map(matches_filter, files))
samples = [f for f in samples if f is not None]
print(f"Number matching pattern expected for Illumina output: {len(samples):,}")

# Get the unique list
samples = list(set(samples))
print(f"Number of unique sample names: {len(samples):,}")
print("\\n".join(samples))
print("")

# Write out to a file
with open("samples.txt", "w") as handle:
    handle.write("\\n".join(samples))
