#!/bin/bash

set -e

spaceranger mkref \
    --genome="${params.genome_name}" \
    --fasta="${fasta}" \
    --genes="${genes}" \
    --nthreads=${task.cpus} \
    --memgb=${task.memory.toGiga()} \
    --localcores=${task.cpus} \
    --localmem=${task.memory.toGiga()} \
    --disable-ui \
    2>&1 | tee spaceranger_mkref.log.txt
