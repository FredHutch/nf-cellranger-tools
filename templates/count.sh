#!/bin/bash

set -e

cellranger count \
           --id=${sample} \
           --transcriptome=REF/ \
           --fastqs=FASTQ_DIR/ \
           --sample=${sample} \
           --include-introns=${params.include_introns} \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()}

if [ -d "${sample}" ]; then
    if [ -d "${sample}/SC_RNA_COUNTER_CS" ]; then
        rm -r "${sample}/SC_RNA_COUNTER_CS"
    fi

    if [ -d "${sample}/outs" ]; then
        mv "${sample}/outs/"* "${sample}/"
        rmdir "${sample}/outs"
    fi

    mkdir -p summary
    if [ -s "${sample}/web_summary.html" ]; then
        cp "${sample}/web_summary.html" "summary/${sample}.html"
    fi
fi