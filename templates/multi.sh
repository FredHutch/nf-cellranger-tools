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

# If running v8 or higher, add the --create-bam=true flag
if [[ "${cellranger_version}" =~ ^8.* ]]; then
    BAM_FLAG="--create-bam=true"
else
    BAM_FLAG=""
fi

echo "Running cellranger multi" | tee "\${SAMPLE}.log.txt"
cellranger multi \
            --id="\${SAMPLE}" \
            --csv="\${CSV}.resolved.csv" \
            --localcores=${task.cpus} \
            --localmem=${task.memory.toGiga()} \
            \${BAM_FLAG} \
    2>&1 | tee "\${SAMPLE}.log.txt"

echo "Finished running cellranger multi - " | tee "\${SAMPLE}.log.txt"

if [ -d "\$SAMPLE" ]; then
    if [ -d "\$SAMPLE/SC_MULTI_CS" ]; then
        echo "Cleaning up \$SAMPLE/SC_MULTI_CS" | tee "\${SAMPLE}.log.txt"
        rm -r "\$SAMPLE/SC_MULTI_CS"
    fi

    if [ -d "\$SAMPLE/outs" ]; then
        echo "Cleaning up \$SAMPLE/outs" | tee "\${SAMPLE}.log.txt"
        mv "\$SAMPLE/outs/"* "\$SAMPLE/"
        rmdir "\$SAMPLE/outs"
    fi

    mkdir -p summary
    if [ -s "\$SAMPLE/per_sample_outs/\$SAMPLE/web_summary.html" ]; then
        cp "\$SAMPLE/per_sample_outs/\$SAMPLE/web_summary.html" "summary/\$SAMPLE.html"
    fi
fi
echo "Completed - \$SAMPLE" | tee "\${SAMPLE}.log.txt"
