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

run_cellranger_vdj(){
    TOOL=vdj

    nextflow \
        run \
        ../${TOOL}.nf \
        --output run/${TOOL} \
        --samplesheet samplesheet.csv \
        --sample_header Sample \
        --fastq_dir data/vdj/sc5p_v2_hs_B_1k_multi_5gex_b_fastqs/sc5p_v2_hs_B_1k_b_fastqs \
        --vdj_dir data/ref/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0 \
        -resume
    
}

run_cellranger_vdj