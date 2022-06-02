#!/bin/bash

set -e

cellranger count \
           --id=$sample \
           --transcriptome=REF/ \
           --fastqs=FASTQ_DIR/ \
           --sample=$sample \
           --expect-cells ${params.expect_cells} \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()}
