#!/bin/bash

set -e

run_cellranger_count(){
    TOOL=count

    # Test WITHOUT the whitelist
    nextflow \
        run \
        ../${TOOL}.nf \
        --output run/${TOOL} \
        --fastq_dir data/count/pbmc_1k_v3_fastqs \
        --transcriptome_dir data/ref/refdata-gex-GRCh38-2020-A \
        -resume \
        $1
    
    # Test WITH the whitelist
    nextflow \
        run \
        ../${TOOL}.nf \
        --output run/${TOOL} \
        --sample_whitelist count.whitelist.txt \
        --fastq_dir data/count/pbmc_1k_v3_fastqs \
        --transcriptome_dir data/ref/refdata-gex-GRCh38-2020-A \
        -resume \
        $1
    
}

run_cellranger_count $1
