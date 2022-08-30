#!/bin/bash

set -e

run_cellranger_count(){
    TOOL=count

    nextflow \
        run \
        ../${TOOL}.nf \
        --output run/${TOOL} \
        --samplesheet samplesheet.csv \
        --sample_header Sample \
        --fastq_dir data/count/pbmc_1k_v3_fastqs \
        --transcriptome_dir data/ref/refdata-gex-GRCh38-2020-A \
        -resume
    
}

run_cellranger_count