#!/bin/bash

set -e

run_cellranger_multi(){
    TOOL=multi

    # Test
    nextflow \
        run \
        ../${TOOL}.nf \
        --output run/${TOOL} \
        --grouping multi.grouping.csv \
        --fastq_dir data/multi/fastqs \
        --transcriptome_dir data/ref/refdata-gex-GRCh38-2020-A \
        --vdj_dir data/ref/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0 \
        -resume \
        $1
    
}

run_cellranger_multi $1
