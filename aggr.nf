#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

// Define the process used to run cellranger aggr
process cellranger_aggr {
    // Load the appropriate dependencies
    label "cellranger"
    
    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true
    
    input:
    // Stage one or more folders with all of the inputs
    path "*"

    output:
    // Capture any created files as outputs
    path "*"

    script:
    // Run the code defined in templates/aggr.sh
    template "aggr.sh"
}

workflow {

    log.info"""
    Parameters:

        input:              ${params.input}
        output:             ${params.output}
        aggr_name:          ${params.aggr_name}
        cellranger_version: ${params.cellranger_version}
    """

    // Check that the user specified the input parameter
    if("${params.input}" == "false"){
        error "Parameter 'input' must be specified"
    }
    
    // Check that the user specified the output parameter
    if("${params.output}" == "false"){
        error "Parameter 'output' must be specified"
    }

    // Point to the input directory (or directories)
    Channel
        .fromPath(
            "${params.input}".split(",").toList(),
            checkIfExists: true,
            type: "dir"
        )
        .set { input_ch }

    // Analyze each sample independently
    cellranger_aggr(input_ch)

}
