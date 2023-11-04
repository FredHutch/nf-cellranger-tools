#!/usr/bin/env python3

from pathlib import Path
import pandas as pd


def main():
    # Find all of the input files
    inputs = [
        str(p.absolute())
        for p in Path(".").rglob("*molecule_info.h5")
    ]

    # If there is only one input, stop any further action
    assert len(inputs) > 1, "Only one input found -- halting"

    # Count up the number of times that each folder name is found
    folder_counts = pd.Series([
        folder
        for fp in inputs
        for folder in fp.split("/")
        if len(folder) > 0
    ]).value_counts()

    # Assign the name for each input using the first unique folder name
    names = [
        assign_name(i, folder_counts)
        for i in inputs
    ]

    # Make a samplesheet
    samplesheet = pd.DataFrame(dict(
        sample_id=names,
        molecule_h5=inputs
    ))

    # Write out to aggr.csv
    (
        samplesheet
        .reindex(columns=["sample_id", "molecule_h5"])
        .to_csv("aggr.csv", index=None)
    )


def assign_name(fp: str, folder_counts: pd.Series):
    folders = [n for n in fp.split("/") if len(n) > 0]
    counts = [folder_counts[n] for n in folders]
    for n in folders:
        if folder_counts[n] == min(counts):
            return n


if __name__ == "__main__":
    main()
