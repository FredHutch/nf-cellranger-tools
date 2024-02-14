#!/bin/bash

set -e

spaceranger count \
    --id ${sample_name} \
    --transcriptome ref \
    --fastqs fastqs \
    --${params.image_type}=${image} \
    --probe-set=probes.csv \
    --localcores=${task.cpus} \
    --localmem=${task.memory.toGiga()} \
    --disable-ui \
    2>&1 | tee spaceranger_count.log.txt
