#!/usr/bin/env python3

import os
import pandas as pd

"""
Set up the multi config CSVs needed to run the cellranger multi tool.
Customized for FLEX fixed RNA samples, this will include:
    - The transcriptome GEX reference
    - The probe set CSV
    - The sample-barcode mapping used for probe barcodes
"""


def read_and_log(fp, allowed_cols=None):

    df = pd.read_csv(fp)
    print(f"Read in {df.shape[0]:,} rows from {fp}")
    print(df)
    print("----")

    if allowed_cols is not None:
        for cname in df.columns.values:
            msg = f"Column name is not allowed: {cname} (must be one of {', '.join(allowed_cols)})" # noqa
            assert cname in allowed_cols, msg

    return df


class Config:

    def __init__(self):

        # The multi config CSV will be built as a list, and
        # then concatenated and written out as a text file
        self.config = []

    def add_section(self, header, content):
        self.config.extend([f"[{header}]", content])

    def write(self):

        # Make a single block of text
        config_str = "\\n".join(self.config)
        print(config_str)
        print("---")

        with open("configs/config.csv", "w") as handle:
            handle.write(config_str)

    def add_references(self):
        # Path to references is hardcoded in the cellranger process
        self.add_section(
            "gene-expression",
            "\n".join([
                "reference,GEX_REF",
                "probe-set,cellranger_probe_set.csv",
                "include-introns,${params.include_introns}"
            ])
        )

    def add_samples(self, sample_list):
        self.add_section(
            "libraries",
            "\n".join([
                "fastq_id,fastqs,feature_types"
            ] + [
                f"{sample_name},FASTQ_DIR,Gene Expression"
                for sample_name in sample_list
            ])
        )

    def add_probe_barcodes(self, probe_barcodes: pd.DataFrame):
        self.add_section(
            "samples",
            probe_barcodes.reindex(
                columns=[
                    "sample_id",
                    "probe_barcode_ids"
                ]
            ).to_csv(
                index=None
            )
        )


def build_config(
    samples: pd.DataFrame,
    probe_barcodes: pd.DataFrame
) -> None:

    # Set up a config file
    config = Config()

    # Add the sample names
    config.add_samples(samples["sample"].tolist())

    # Add the probe barcodes
    config.add_probe_barcodes(probe_barcodes)

    # Add the references
    config.add_references()

    # Write out
    config.write()


# Read in the probe_barcodes CSV
probe_barcodes = read_and_log(
    "probe_barcodes.csv",
    allowed_cols=["sample_id", "probe_barcode_ids"]
)

# Read in the samples CSV
samples = read_and_log(
    "samples.csv",
    allowed_cols=["sample"]
)

# Create the output folder
os.mkdir("configs")

# The probe barcodes cannot be empty
assert probe_barcodes.shape[0] > 0, "Must specify probe barcodes"

# Build a config file
build_config(samples, probe_barcodes)
