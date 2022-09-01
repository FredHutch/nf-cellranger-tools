#!/bin/bash

set -e

# Parse the sample name from the CSV
CSV="${multi_config}"
SAMPLE="\${CSV%.csv}"

cellranger multi \
           --id=\$SAMPLE \
           --csv=\$CSV \
           --noui \
           --localcores=${task.cpus} \
           --localmem=${task.memory.toGiga()}
