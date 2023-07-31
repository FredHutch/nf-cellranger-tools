#!/bin/bash

set -e

tree -lah

echo "CellRanger Configuration"
cat config.csv

echo "Starting CellRanger"

cellranger multi \
           --id="output" \
           --csv="config.csv" \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()}

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