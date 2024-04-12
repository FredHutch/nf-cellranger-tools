#!/bin/bash

set -e

echo "Resolving relative links in post_demux.config.csv"
resolve_links.py "post_demux.config.csv"
cat "post_demux.config.csv"

echo
echo "Contents of the feature reference CSV:"
cat feature.csv
echo

echo "Running cellranger multi" | tee "${sample_name}.log.txt"
cellranger --version 2>&1 | tee -a "${sample_name}.log.txt"
cellranger multi \
            --id="${sample_name}" \
            --csv="post_demux.config.csv.resolved.csv" \
            --localcores=${task.cpus} \
            --localmem=${task.memory.toGiga()} \
    2>&1 | tee -a "${sample_name}.log.txt"

echo "Finished running cellranger multi - " | tee -a "${sample_name}.log.txt"

if [ -d "${sample_name}" ]; then
    if [ -d "${sample_name}/SC_MULTI_CS" ]; then
        echo "Cleaning up ${sample_name}/SC_MULTI_CS" | tee -a "${sample_name}.log.txt"
        rm -r "${sample_name}/SC_MULTI_CS"
    fi

    if [ -d "${sample_name}/outs" ]; then
        echo "Cleaning up ${sample_name}/outs" | tee -a "${sample_name}.log.txt"
        mv "${sample_name}/outs/"* "${sample_name}/"
        rmdir "${sample_name}/outs"
    fi

    mkdir -p summary
    if [ -s "${sample_name}/per_sample_outs/${sample_name}/web_summary.html" ]; then
        cp "${sample_name}/per_sample_outs/${sample_name}/web_summary.html" "summary/${sample_name}.html"
    fi
fi
echo "Completed - ${sample_name}" | tee -a "${sample_name}.log.txt"
