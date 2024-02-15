#!/bin/bash

set -e

echo "slide=${slide}" | tee -a spaceranger_count.log.txt
echo "area=${area}" | tee -a spaceranger_count.log.txt

if [[ "${slide}" == "null" ]] || [[ "${slide}" == "false" ]] || [[ "${area}" == "null" ]] || [[ "${area}" == "false" ]]; then
    echo "Using --unknown-slide" | tee -a spaceranger_count.log.txt
    ARG="--unknown-slide"
else
    ARG="--slide ${slide} --area ${area}"
fi

spaceranger count \
    --id ${sample_name} \
    --transcriptome ref \
    --fastqs fastqs \
    --${params.image_type}=${image} \
    --probe-set=probes.csv \
    --localcores=${task.cpus} \
    --localmem=${task.memory.toGiga()} \
    $ARG \
    --disable-ui \
    2>&1 | tee -a spaceranger_count.log.txt
