#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

// Format the multi config CSVs for each sample
process multi_config {
    // Load the appropriate dependencies
    label "python"
    
    input:
    // The sample grouping CSV
    path "samples.csv"
    // The optional multiplexing CSV
    path "multiplexing.csv"

    output:
    // Capture any created configurations as outputs
    path "configs/"

    script:
    // Run the code defined in templates/multi_config.py
    template "multi_config.py"
}

// Define the process used to run cellranger multi
process cellranger_multi {
    // Load the appropriate dependencies
    label "cellranger"
    
    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true
    
    input:
    // The run configuration is driven by a multi config CSV
    path multi_config
    // Stage the FASTQ folder (by symlink) in the working directory
    path "FASTQ_DIR"
    // Stage the reference transcriptome (by symlink) in the working directory
    path "GEX_REF"
    // Stage the reference V(D)J (by symlink) in the working directory
    path "VDJ_REF"

    output:
    // Capture any created files as outputs
    path "outs/"

    script:
    // Run the code defined in templates/multi.sh
    template "multi.sh"
}

workflow {

    log.info"""
    Parameters:

        output:            ${params.output}
        grouping:          ${params.grouping}
        fastq_dir:         ${params.fastq_dir}
        transcriptome_dir: ${params.transcriptome_dir}
        vdj_dir:           ${params.vdj_dir}
        multiplexing:      ${params.multiplexing}
    """

    // Check that the user specified the output parameter
    if("${params.output}" == "false"){
        error "Parameter 'output' must be specified"
    }
    
    // Check that the user specified the grouping parameter
    if("${params.grouping}" == "false"){
        error "Parameter 'grouping' must be specified"
    }

    // Check that the user specified the fastq_dir parameter
    if("${params.fastq_dir}" == "false"){
        error "Parameter 'fastq_dir' must be specified"
    }

    // Check that the user specified the transcriptome_dir parameter
    if("${params.transcriptome_dir}" == "false"){
        error "Parameter 'transcriptome_dir' must be specified"
    }

    // Check that the user specified the vdj_dir parameter
    if("${params.vdj_dir}" == "false"){
        error "Parameter 'vdj_dir' must be specified"
    }

    // Point to the FASTQ directory
    fastq_dir = file(
        "${params.fastq_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // Point to the reference transcriptome
    transcriptome_dir = file(
        "${params.transcriptome_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // Point to the reference vdj
    vdj_dir = file(
        "${params.vdj_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // Point to the grouping CSV provided by the user
    grouping = file(
        "${params.grouping}",
        checkIfExists: true,
        type: "file",
        glob: false
    )

    // Point to the multiplexing CSV (which by default is an empty table in templates/)
    multiplexing = file(
        "${params.multiplexing}",
        checkIfExists: true,
        type: "file",
        glob: false
    )

    // Build the multi config CSV for each sample
    multi_config(grouping, multiplexing)

    // Analyze each sample independently
    cellranger_multi(
        multi_config.out,
        fastq_dir,
        transcriptome_dir,
        vdj_dir
    )
}
