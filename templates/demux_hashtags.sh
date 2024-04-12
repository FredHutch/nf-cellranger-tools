#!/bin/bash

set -e

# Parse the sample name from the CSV
CSV="demux.config.csv"

echo "Resolving relative links in \$CSV"
resolve_links.py "\$CSV"
cat "\$CSV"

echo
echo "Contents of the hashtags CSV:"
cat hashtags.csv
echo

echo "Running cellranger multi" | tee "demultiplexed_samples.log.txt"
cellranger --version 2>&1 | tee -a "demultiplexed_samples.log.txt"
cellranger multi \
            --id="demultiplexed_samples" \
            --csv="\${CSV}.resolved.csv" \
            --localcores=${task.cpus} \
            --localmem=${task.memory.toGiga()} \
    2>&1 | tee -a "demultiplexed_samples.log.txt"

echo "Finished running cellranger multi - " | tee -a "demultiplexed_samples.log.txt"

if [ -d "demultiplexed_samples" ]; then
    if [ -d "demultiplexed_samples/SC_MULTI_CS" ]; then
        echo "Cleaning up demultiplexed_samples/SC_MULTI_CS" | tee -a "demultiplexed_samples.log.txt"
        rm -r "demultiplexed_samples/SC_MULTI_CS"
    fi

    if [ -d "demultiplexed_samples/outs" ]; then
        echo "Cleaning up demultiplexed_samples/outs" | tee -a "demultiplexed_samples.log.txt"
        mv "demultiplexed_samples/outs/"* "demultiplexed_samples/"
        rmdir "demultiplexed_samples/outs"
    fi

    # Move the per-sample BAM files to the top level directory
    for sample in demultiplexed_samples/per_sample_outs/*; do
        BAM=\$sample/count/sample_alignments.bam
        if [ -s "\$BAM" ]; then
            DEST=demultiplexed_samples/\${sample##*/}.bam
            echo Moving BAM file from \$sample/count/sample_alignments.bam to \$DEST | tee -a "demultiplexed_samples.log.txt"
            mv "\$BAM" "\$DEST"
        fi
    done

fi
echo "Completed - demultiplexing samples" | tee -a "demultiplexed_samples.log.txt"
