#!/bin/bash

set -e

# This script should be run from inside the test/ folder in the nf-cellranger-tools directory

# CellRanger count tool
mkdir -p data/count
cd data/count
[ ! -s pbmc_1k_v3_fastqs.tar ] && \
    wget https://cf.10xgenomics.com/samples/cell-exp/3.0.0/pbmc_1k_v3/pbmc_1k_v3_fastqs.tar

[ ! -d pbmc_1k_v3_fastqs/ ] && \
    tar -xvf pbmc_1k_v3_fastqs.tar
cd ../..

# Reference Genome
mkdir -p data/ref
cd data/ref
[ ! -s refdata-gex-GRCh38-2020-A.tar.gz ] && \
    wget https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz && \
    tar -zxvf refdata-gex-GRCh38-2020-A.tar.gz

cd ../..

# CellRanger vdj tool
mkdir -p data/vdj
cd data/vdj
[ ! -s sc5p_v2_hs_B_1k_multi_5gex_b_Multiplex_fastqs.tar ] && \
    curl -LO https://cf.10xgenomics.com/samples/cell-vdj/6.0.0/sc5p_v2_hs_B_1k_multi_5gex_b_Multiplex/sc5p_v2_hs_B_1k_multi_5gex_b_Multiplex_fastqs.tar && \
    tar -xf sc5p_v2_hs_B_1k_multi_5gex_b_Multiplex_fastqs.tar
cd ../..

# V(D)J reference
cd data/ref
[ ! -s refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0.tar.gz ] && \
    curl -O https://cf.10xgenomics.com/supp/cell-vdj/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0.tar.gz && \
    tar -xf refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0.tar.gz
cd ../..

# CellRanger multi tool
mkdir -p data/multi
cd data/multi
[ ! -s sc5p_v2_hs_B_1k_multi_5gex_b_Multiplex_fastqs.tar ] && \
    curl -LO https://cf.10xgenomics.com/samples/cell-vdj/6.0.0/sc5p_v2_hs_B_1k_multi_5gex_b_Multiplex/sc5p_v2_hs_B_1k_multi_5gex_b_Multiplex_fastqs.tar && \
    tar -xf sc5p_v2_hs_B_1k_multi_5gex_b_Multiplex_fastqs.tar
cd ../..