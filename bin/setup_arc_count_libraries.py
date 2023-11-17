#!/usr/bin/env python3

from typing import List
import pandas as pd
from pathlib import Path


def parse_samples(folder, library_type):
    for file in Path(folder).glob(".fastq.gz"):
        sample = parse_sample(file.name)
        yield dict(
            fastqs=folder,
            library_type=library_type,
            sample=sample
        )


def parse_sample(file_name):
    file_name = remove_end(file_name, "_001.fastq.gz")
    file_name = remove_end_options(file_name, ['1', '2', '3'])
    file_name = remove_end_options(file_name, ["_R", "_I"])
    file_name = rsplit(file_name, "_L0")
    file_name = rsplit(file_name, "_S")
    return file_name


def rsplit(file_name: str, substr: str) -> str:
    assert substr in file_name, f'Expected {file_name} to contain with {substr}'
    return file_name.rsplit(substr, 1)[0]


def remove_end(file_name: str, ending: str) -> str:
    assert file_name.endswith(ending), f'Expected {file_name} to end with {ending}'
    return file_name[:-len(ending)]


def remove_end_options(file_name: str, endings: List[str]) -> str:
    for ending in endings:
        if file_name.endswith(ending):
            return file_name[:-len(ending)]
    msg = f'Expected {file_name} to end with one of {", ".join(endings)}'
    assert False, msg


(
    pd.DataFrame([
        row
        for folder, library_type in [
            ("GEX_FASTQS", "Gene Expression"),
            ("ATAC_FASTQS", "Chromatin Accessibility")
        ]
        for row in parse_samples(folder, library_type)
    ])
    .to_csv("libraries.csv", index=False)
)
