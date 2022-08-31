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
        -resume
    
    # Test WITH the whitelist
    nextflow \
        run \
        ../${TOOL}.nf \
        --output run/${TOOL} \
        --sample_whitelist count.whitelist.txt \
        --fastq_dir data/count/pbmc_1k_v3_fastqs \
        --transcriptome_dir data/ref/refdata-gex-GRCh38-2020-A \
        -resume
    
}

if [ ! -s run/count/pbmc_1k_v3/pbmc_1k_v3/outs/web_summary.html ]; then
    run_cellranger_count
fi

run_cellranger_vdj(){
    TOOL=vdj

    # Test WITHOUT the whitelist
    nextflow \
        run \
        ../${TOOL}.nf \
        --output run/${TOOL} \
        --fastq_dir data/vdj/sc5p_v2_hs_B_1k_multi_5gex_b_fastqs/sc5p_v2_hs_B_1k_b_fastqs \
        --vdj_dir data/ref/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0 \
        -resume
    
    # Test WITH the whitelist
    nextflow \
        run \
        ../${TOOL}.nf \
        --output run/${TOOL} \
        --sample_whitelist vdj.whitelist.txt \
        --fastq_dir data/vdj/sc5p_v2_hs_B_1k_multi_5gex_b_fastqs/sc5p_v2_hs_B_1k_b_fastqs \
        --vdj_dir data/ref/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0 \
        -resume
    
}

if [ ! -s run/vdj/sc5p_v2_hs_B_1k_b/sc5p_v2_hs_B_1k_b/outs/web_summary.html ]; then
    run_cellranger_vdj
fi
