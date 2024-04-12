#!/bin/bash

set -e

# The user can specify the version of CellRanger which is run
VERSION="${params.cellranger_version}"
echo "Using CellRanger Version \$VERSION"

# Format a CSV with all of the inputs
make_aggr_samplesheet.py

echo "Inputs for cellranger aggr:"
cat aggr.csv

cellranger --version 2>&1 | tee -a ${params.aggr_name}.log.txt
cellranger aggr \
    --id=${params.aggr_name} \
    --csv=aggr.csv \
    --localcores=${task.cpus} \
    --localmem=${task.memory.toGiga()} \
    2>&1 | tee -a ${params.aggr_name}.log.txt

if [ -d "${params.aggr_name}" ]; then
    if [ -d "${params.aggr_name}/SC_RNA_COUNTER_CS" ]; then
        rm -r "${params.aggr_name}/SC_RNA_COUNTER_CS"
    fi

    if [ -d "${params.aggr_name}/outs" ]; then
        mv "${params.aggr_name}/outs/"* "${params.aggr_name}/"
        rmdir "${params.aggr_name}/outs"
    fi

    mkdir -p summary
    if [ -s "${params.aggr_name}/web_summary.html" ]; then
        cp "${params.aggr_name}/web_summary.html" "summary/${params.aggr_name}.html"
    fi
fi

echo "Annotating the dataset for each barcode"
annotate_barcode_source.sh ${params.aggr_name}
