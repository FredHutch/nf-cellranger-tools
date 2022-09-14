#!/bin/bash

set -e

# Parse the sample name from the CSV
CSV="${multi_config}"
SAMPLE="\${CSV%.csv}"

echo "Resolving relative links in ${multi_config}"
resolve_links.py "${multi_config}"
cat "${multi_config}"

echo "Contents of working directory:"
tree -lah

echo
echo "Contents of the feature reference CSV:"
cat feature.csv
echo

cellranger multi \
           --id="\${SAMPLE}" \
           --csv="\${CSV}.resolved.csv" \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()}
