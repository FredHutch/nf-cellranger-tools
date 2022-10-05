#!/bin/bash

set -e

cellranger vdj \
           --id=$sample \
           --reference=REF/ \
           --fastqs=FASTQ_DIR/ \
           --sample=$sample \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()}

if [ -d "${sample}" ]; then
    if [ -d "${sample}/SC_VDJ_ASSEMBLER_CS" ]; then
        rm -r "${sample}/SC_VDJ_ASSEMBLER_CS"
    fi

    if [ -d "${sample}/outs" ]; then
        mv "${sample}/outs/*" "${sample}/"
        rmdir "${sample}/outs"
    fi

    mkdir -p summary
    if [ -s "${sample}/web_summary.html" ]; then
        cp "${sample}/web_summary.html" "summary/${sample}.html"
    fi
fi