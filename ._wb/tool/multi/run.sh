#!/bin/bash

set -euo pipefail

date
echo
echo "Running workflow from ${PWD}"
echo

# Run the workflow
echo Starting workflow
nextflow \
    run \
    "${TOOL_REPO}/multi.nf" \
    -params-file ._wb/tool/params.json \
    -resume \
    -process.cpus "${TASK_CPUS}" \
    -process.memory "${TASK_MEM}"

# If temporary files were not placed in a separate location
if [ -d work ]; then
    # Delete the temporary files created during execution
    echo Removing temporary files
    rm -r work
fi


echo
date
echo Done
