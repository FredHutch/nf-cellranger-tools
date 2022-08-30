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