#!/usr/bin/env python3

import os
from tokenize import group
import pandas as pd

"""Set up the multi config CSVs needed to run the cellranger multi tool."""

def read_and_log(fp, allowed_cols=None):

    df = pd.read_csv(fp)
    print(f"Read in {df.shape[0]:,} rows from {fp}")
    print(df)
    print("----")

    if allowed_cols is not None:
        for cname in df.columns.values:
            assert cname in allowed_cols, f"Column name is not allowed: {cname} (must be one of {', '.join(allowed_cols)})"

    return df

def validate_inputs(grouping, multiplexing):

    # The `sample` column in `grouping` is mutually exclusive with `multiplexing`
    if 'sample' in grouping.columns.values:
        msg = "Cannot use 'sample' column if multiplexing with CMOs"
        assert multiplexing.shape[0] == 0, msg
    else:
        msg = "Must use 'sample' column if not multiplexing with CMOs"
        assert multiplexing.shape[0] > 0, msg

    # Both `library` and `feature_types` must be present in grouping
    for cname in ['library', 'feature_types']:
        assert cname in grouping.columns.values, f"Grouping table must have a '{cname}' column"

    # The values in `feature_types` are controlled
    valid_feature_types = [
        "Gene Expression",
        "VDJ",
        "VDJ-T",
        "VDJ-B",
        "Antibody Capture",
        "CRISPR Guide Capture",
        "Multiplexing Capture"
    ]
    invalid_feature_types = [
        feature_type
        for feature_type in grouping["feature_types"].values
        if feature_type not in valid_feature_types
    ]

    assert len(invalid_feature_types) == 0, f"Invalid: {', '.join(invalid_feature_types)}"

    # multiplexing must have all three columns
    if multiplexing.shape[0] > 0:
        for cname in ["sample_id", "cmo_ids"]:
            assert cname in multiplexing.columns.values, f"Column {cname} is required in multiplexing table"


class Config:

    def __init__(self, sample_name, grouping):

        # The multi config CSV will be built as a list, and
        # then concatenated and written out as a text file
        self.config = []

        # Add the sample name to the object
        self.sample_name = sample_name

        # Add the sample table to the object
        self.grouping = grouping
        
        # Add the references
        self.add_references()

        # Add the libraries
        self.add_libraries()

    def add_references(self):
        """
        Parse the sample table and add the appropriate references
        based on what feature types may be present
        """

        # GEX
        if "Gene Expression" in self.grouping["feature_types"].values:
            self.add_gex_ref()

        # V(D)J
        if self.grouping["feature_types"].isin(["VDJ", "VDJ-T", "VDJ-B"]).any():
            self.add_vdj_ref()

        # Antibody / CRISPR
        if self.grouping["feature_types"].isin(["Antibody Capture", "CRISPR Guide Capture"]).any():
            self.add_feature_ref()

    def add_section(self, header, content):
        self.config.append("\\n".join(["", header, content, ""]))

    def write(self):

        # Make a single block of text
        config_str = "\\n".join(self.config)
        print(config_str)
        print("---")

        with open(f"configs/{self.sample_name}.csv", "w") as handle:
            handle.write(config_str)

    def add_gex_ref(self):
        self.add_section("[gene-expression]", "reference,GEX_REF")

    def add_vdj_ref(self):
        self.add_section("[vdj]", "reference,VDJ_REF")

    def add_feature_ref(self):
        self.add_section("[feature]", "reference,feature.csv")

    def add_libraries(self):
        libraries = self.grouping.assign(
            fastqs="FASTQ_DIR"
        ).rename(
            columns=dict(
                library="fastq_id"
            )
        ).reindex(
            columns=[
                "fastq_id",
                "fastqs",
                "feature_types"
            ]
        ).to_csv(index=None)

        self.add_section("[libraries]", libraries)

    def add_multiplexing(self, multiplexing):
        """Add multiplexing information using CMOs."""

        samples = multiplexing.reindex(
            columns=[
                "sample_id",
                "cmo_ids"
            ]
        ).to_csv(index=None)

        self.add_section("[samples]", samples)


def build_sample_configs(grouping):

    # Build an independent sample configuration sheet for each sample
    for sample, sample_grouping in grouping.groupby("sample"):

        print("---")
        print(f"Processing {sample}")
        print("---")
        print(sample_grouping)
        print("---")

        # Start building the config for this sample
        # Initialization will take care of setting up the appropriate references
        # as well as the libraries
        config = Config(sample, sample_grouping)

        # Write out
        config.write()


def build_cmo_config(grouping, multiplexing):

    print("---")
    print("Building a config using CMOs")
    print(grouping)
    print(multiplexing)

    # Start building the config for this sample
    # Initialization will take care of setting up the appropriate references
    # and the libraries
    config = Config("multi", grouping)

    # Add the CMO multiplexing information
    config.add_multiplexing(multiplexing)

    # Write out
    config.write()

# Read in the grouping CSV
grouping = read_and_log(
    "grouping.csv",
    allowed_cols=["library", "sample", "feature_types"]
)

# Read in the multiplexing CSV
multiplexing = read_and_log(
    "multiplexing.csv",
    allowed_cols=["sample_id", "cmo_ids", "description"]
)

# Create the output folder
os.mkdir("configs")

validate_inputs(grouping, multiplexing)

# If multiplexing was used
if multiplexing.shape[0] > 0:

    # Build >=1 configs without CMOs
    build_sample_configs(grouping)

else:

    # Build a single config with CMOs
    build_cmo_config(grouping, multiplexing)
