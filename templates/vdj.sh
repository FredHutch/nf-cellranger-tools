#!/bin/bash

set -e

cellranger vdj \
           --id=$sample \
           --reference=REF/ \
           --fastqs=FASTQ_DIR/ \
           --sample=$sample \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()}
