#!/bin/bash

set -e

# Set up the libraries CSV file, assuming that the inputs are in
# two different folders
echo "Setting up libraries.csv"
setup_arc_count_libraries.py
cat libraries.csv

echo "Resolving relative links in libraries.csv"
resolve_links.py libraries.csv
mv libraries.csv.resolved.csv libraries.resolved.csv
cat libraries.resolved.csv

cellranger-arc --version 2>&1 | tee -a "${sample_name}.log.txt"
cellranger-arc count \
           --id="${sample_name}" \
           --reference="\$PWD/REF" \
           --libraries=libraries.resolved.csv \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()} \
    2>&1 | tee -a "${sample_name}.log.txt"

rm -r GEX_FASTQS
rm -r ATAC_FASTQS
