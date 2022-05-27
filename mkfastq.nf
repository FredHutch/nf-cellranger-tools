#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

// Define a process which takes two inputs
process mkfastq {
    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}", mode: 'copy', overwrite: true

    input:
    // BCL run folder
    path bcl_run_folder
    // Samplesheet
    path samplesheet

    output:
    // Capture any created files as outputs
    path "*"

    script:
    // Run the code defined in templates/mkfastq.sh
    template "mkfastq.sh"
}

workflow {

    // Check that input_type is either samplesheet or csv
    if("${params.input_type}" != "samplesheet"){
        if("${params.input_type}" != "csv"){
            error "Parameter input_type must be 'samplesheet' or 'csv'"
        }
    }

    // Check that the user specified the output parameter
    if("${params.output}" == "false"){
        error "Parameter 'output' must be specified"
    }

    // Check that the user specified the bcl_run_folder parameter
    if("${params.bcl_run_folder}" == "false"){
        error "Parameter 'bcl_run_folder' must be specified"
    }

    // Check that the user specified the bcl_run_folder parameter
    if("${params.samplesheet}" == "false"){
        error "Parameter 'samplesheet' must be specified"
    }

    mkfastq(
        Channel.fromPath(
            "${params.bcl_run_folder}",
            type: 'dir',
            checkIfExists: true
        ),
        Channel.fromPath(
            "${params.samplesheet}",
            checkIfExists: true
        )
    )

}