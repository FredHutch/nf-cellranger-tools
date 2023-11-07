#!/bin/bash

set -euo pipefail

# The output path has been passed in as an argument
OUTPUT_PATH="${1}/count/barcode_metadata.csv"

# Write out the header
echo "Barcode,sample_id" > "${OUTPUT_PATH}"

# Iterate over each line in the list of inputs
IFS=","
# Keep track of the row index
ix=0
cat aggr.csv | while read sample_id molecule_h5; do
    # Skip the header
    if [[ "${molecule_h5}" == "molecule_h5" ]]; then continue; fi
    echo "Reading the set of barcodes for ${sample_id} from ${molecule_h5}"

    # Add to the line index
    let "ix=$ix + 1"

    # Write out the list of barcodes
    $(find / -name h5dump) -N /barcodes "${molecule_h5}" | \
        grep 000 | \
        sed 's/.* //' | \
        sed 's/\\.*//' | \
        tr -d '"' | \
        while read barcode; do
            echo "${barcode}-${ix},${sample_id}"
        done >> "${OUTPUT_PATH}"
done
