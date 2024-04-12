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

    return df


def validate_inputs(grouping, multiplexing):

    # Both `fastq_id` and `feature_types` must be present in grouping
    for cname in ['fastq_id', 'feature_types']:
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

    # At a minimum, Gene Expression and Multiplexing Capture must be present
    for cname in ["Gene Expression", "Multiplexing Capture"]:
        msg = f"Column {cname} is required in grouping table"
        assert cname in grouping["feature_types"].values, msg

    # multiplexing must have two required columns
    if multiplexing.shape[0] > 0:
        for cname in ["sample_id", "cmo_ids"]:
            assert cname in multiplexing.columns.values, f"Column {cname} is required in multiplexing table"


class Config:

    config: list

    def __init__(self, grouping):

        # The multi config CSV will be built as a list, and
        # then concatenated and written out as a text file
        self.config = []

        # Add the table describing which types of data are present
        # from which sequencing libraries
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
        self.config.extend([f"[{header}]", content])

    def write(self, fp):

        # Make a single block of text
        config_str = "\\n".join(self.config)
        print(config_str)
        print("---")

        with open(fp, "w") as handle:
            handle.write(config_str)

    def add_gex_ref(self):
        self.add_section("gene-expression", "reference,GEX_REF")
        if "Multiplexing Capture" in self.grouping["feature_types"].values:
            self.config.append("cmo-set,hashtags.csv")

        self.config.append("include-introns,${params.include_introns}")
        if int("${params.cellranger_version}"[0]) > 7:
            self.config.append("create-bam,true")

    def add_vdj_ref(self):
        self.add_section("vdj", "reference,VDJ_REF")

    def add_feature_ref(self):
        self.add_section("feature", "reference,feature.csv")

    def add_libraries(self):
        libraries = self.grouping.to_csv(index=None)

        self.add_section("libraries", libraries)

    def add_multiplexing(self, multiplexing):
        """Add multiplexing information using CMOs."""

        samples = multiplexing.reindex(
            columns=[
                "sample_id",
                "cmo_ids"
            ]
        ).to_csv(index=None)

        self.add_section("samples", samples)


def build_sample_configs(
    grouping: pd.DataFrame,
    multiplexing: pd.DataFrame,
    has_feature_reference: bool
):

    # Make a config to drive the dumultiplexing of hashtags
    # This only uses gene expression and multiplexing capture FASTQs
    config = Config(
        (
            grouping
            .loc[
                grouping["feature_types"].isin(["Gene Expression", "Multiplexing Capture"])
            ]
            # Always list the gene expression library first
            .sort_values(by="feature_types")
        )
    )
    # Add the multiplexing to this config
    config.add_multiplexing(multiplexing)

    # Write out
    config.write("demux.config.csv")

    # Make a config which can be used in the step after demultiplexing

    # If the user provided a feature reference, use the "Multiplexing Capture" data
    # as Antibody Capture
    if has_feature_reference:
        grouping = grouping.replace({
            "feature_types": {
                "Multiplexing Capture": "Antibody Capture"
            }
        })

    # If there is any data beyond the gene expression and multiplexing capture
    if (
        grouping
        .query("feature_types != 'Gene Expression'")
        .query("feature_types != 'Multiplexing Capture'")
        .shape[0] > 0
    ):
        # Change the name of the GEX library to bamtofastq
        grouping = grouping.query("feature_types != 'Gene Expression'")
        grouping = pd.concat([
            grouping,
            pd.DataFrame([{
                "fastq_id": "bamtofastq",
                "fastqs": "DEMUX_DIR",
                "feature_types": "Gene Expression"
            }])
        ])

        # Set up that config file
        config = Config(grouping)

        # Write out to a different file
        config.write("post_demux.config.csv")


def check_for_null(fp):
    """Return True if the file contains more than just the string 'null'."""
    with open(fp, "r") as handle:
        return "null" not in handle.read(4)


# Read in the grouping CSV
grouping = read_and_log(
    "grouping.csv",
    allowed_cols=["sample", "grouping", "feature_types"]
)

# Reformat the grouping table
grouping = (
    grouping
    .assign(fastqs="FASTQ_DIR")
    .rename(columns=dict(sample="fastq_id"))
    .reindex(columns=["fastq_id", "fastqs", "feature_types"])
)

# Read in the multiplexing CSV
multiplexing = read_and_log(
    "multiplexing.csv",
    allowed_cols=["sample_id", "cmo_ids", "description"]
)

# Set up a boolean flag indicating whether the user
# provided a feature_reference.csv which has > 0 lines
has_feature_reference = pd.read_csv("feature_reference.csv").shape[0] > 0

validate_inputs(grouping, multiplexing)

# Build config file(s)
build_sample_configs(grouping, multiplexing, has_feature_reference)
