#!/bin/bash

set -e

ls -lah
ls -lah *

echo "Resolving relative links in config.csv"
resolve_links.py config.csv

echo "CellRanger Configuration"
cat config.csv.resolved.csv

echo "Starting CellRanger"

# If running v8 or higher, add the --create-bam=true flag
if [[ "${params.cellranger_version}" =~ ^8.* ]]; then
    BAM_FLAG="--create-bam=true"
else
    BAM_FLAG=""
fi

cellranger multi \
            --id="output" \
            --csv="config.csv.resolved.csv" \
            --localcores=${task.cpus} \
            --localmem=${task.memory.toGiga() - 2} \
            \${BAM_FLAG} \
    2>&1 | tee log.txt

if [ -d "output" ]; then
    if [ -d "output/SC_MULTI_CS" ]; then
        rm -r "output/SC_MULTI_CS"
    fi

    if [ -d "output/outs" ]; then
        mv "output/outs/"* "output/"
        rmdir "output/outs"
    fi

    mkdir -p summary
    if [ -s "output/per_sample_outs/output/web_summary.html" ]; then
        cp "output/per_sample_outs/output/web_summary.html" "summary/output.html"
    fi
fi

# Clean up the version of the config with local paths
rm config.csv.resolved.csv

echo DONE
