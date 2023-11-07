#!/bin/bash

set -e

# Format the optional flags
FLAGS=""
if [[ "${params.filter_dual_index}" != "false" ]]; then
    FLAGS="\${FLAGS} --filter-dual-index"
fi
if [[ "${params.filter_single_index}" != "false" ]]; then
    FLAGS="\${FLAGS} --filter-single-index"
fi
if [[ "${params.lanes}" != "false" ]]; then
    FLAGS="\${FLAGS} --lanes ${params.lanes}"
fi
if [[ "${params.use_bases_mask}" != "false" ]]; then
    FLAGS="\${FLAGS} --use-bases-mask ${params.use_bases_mask}"
fi
if [[ "${params.delete_undetermined}" != "false" ]]; then
    FLAGS="\${FLAGS} --delete-undetermined"
fi
if [[ "${params.project}" != "false" ]]; then
    FLAGS="\${FLAGS} --project ${params.project}"
fi

# Run CellRanger mkfastq
${params.software} \
    mkfastq \
    --run "${bcl_run_folder}" \
    --${params.input_type} "${samplesheet}" \
    --barcode-mismatches ${params.barcode_mismatches} \
    "\${FLAGS}" \
    --localcores ${task.cpus} \
    --localmem ${task.memory.toGiga()} \
    2>&1 | tee log.txt

for sample in *; do
    if [ -d "\${sample}" ]; then
        if [ -d "\${sample}/MAKE_FASTQS_CS" ]; then
            rm -r "\${sample}/MAKE_FASTQS_CS"
        fi

        if [ -d "\${sample}/outs" ]; then
            mv "\${sample}/outs/"* "\${sample}/"
            rmdir "\${sample}/outs"
        fi
    fi
done