#!/bin/bash

set -e

# Parse the sample name from the CSV
CSV="${multi_config}"
SAMPLE="\${CSV%.csv}"

echo "Resolving relative links in ${multi_config}"
resolve_links.py "${multi_config}"
cat "${multi_config}"

echo
echo "Contents of the feature reference CSV:"
cat feature.csv
echo

cellranger multi \
           --id="\${SAMPLE}" \
           --csv="\${CSV}.resolved.csv" \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()}

if [ -d "$sample" ]; then
    if [ -d "$sample/SC_MULTI_CS" ]; then
        rm -r "$sample/SC_MULTI_CS"
    fi

    if [ -d "$sample/outs" ]; then
        mv "$sample/outs/*" "$sample/"
        rmdir "$sample/outs"
    fi

    mkdir -p summary
    if [ -s "$sample/per_sample_outs/$sample/web_summary.html" ]; then
        cp "$sample/per_sample_outs/$sample/web_summary.html" "summary/$sample.html"
    fi
fi