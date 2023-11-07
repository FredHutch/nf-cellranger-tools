#!/bin/bash

set -e

# The user can specify the version of CellRanger which is run
VERSION="${params.cellranger_version}"
echo "Using CellRanger Version \$VERSION"

# For older versions of CellRanger, the --include-introns flag should be
# entirely omitted to set it as false. Only use the flag if it should be
# set to true, or if the version is >=7.0.0
if [ "${params.include_introns}" == "true" ] || [ \${VERSION:0:1}  == "7" ]; then
    FLAG="--include-introns=${params.include_introns}"
else
    FLAG=""
fi

cellranger count \
           --id=${sample} \
           --transcriptome=REF/ \
           --fastqs=FASTQ_DIR/ \
           --sample=${sample} \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()} \
           \$FLAG \
    2>&1 | tee ${sample}.log.txt

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