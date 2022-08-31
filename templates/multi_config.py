#!/usr/bin/env python3

import os
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
        for cname in ["sample_id", "cmo_ids", "description"]:
            assert cname in multiplexing.columns.values, f"Column {cname} is required in multiplexing table"

validate_inputs(grouping, multiplexing)