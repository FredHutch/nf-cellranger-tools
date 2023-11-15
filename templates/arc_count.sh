#!/bin/bash

set -e

# Set up the libraries CSV file, assuming that the inputs are in
# two different folders
echo """fastqs,sample,library_type
GEX_FASTQS,${sample_name},Gene Expression
ATAC_FASTQS,${sample_name},Chromatin Accessibility""" \
> libraries.csv

echo "Resolving relative links in libraries.csv"
resolve_links.py libraries.csv
cat libraries.resolved.csv

cellranger-arc count \
           --id="${sample_name}" \
           --reference="\$PWD/REF" \
           --libraries=libraries.resolved.csv \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()} \
    2>&1 | tee "${sample_name}.log.txt"
