#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

// Format the multi config CSVs for each sample
process multi_config {
    // Load the appropriate dependencies
    label "python"

    // Copy all output files to the folder specified by the user with --output
    // in a subdirectory named 'config/'
    publishDir "${params.output}/", mode: 'copy', overwrite: true

    input:
    // The samples CSV
    path "samples.csv"
    // The probe barcodes CSV
    path "probe_barcodes.csv"

    output:
    // Capture any created configurations as outputs
    path "configs/*.csv"

    script:
    // Run the code defined in templates/multi_config_flex.py
    template "multi_config_flex.py"
}

// Define the process used to run cellranger multi
process cellranger_flex {
    // Load the appropriate dependencies
    label "cellranger"
    
    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true
    
    input:
    // The run configuration is driven by a multi config CSV
    path "config.csv"
    // Stage the FASTQ folder (by symlink) in the working directory
    path "FASTQ_DIR"
    // Stage the reference transcriptome (by symlink) in the working directory
    path "GEX_REF"
    // Stage the probe set CSV reference file
    path "cellranger_probe_set.csv"

    output:
    // Capture any created files as outputs
    path "*"

    script:
    // Run the code defined in templates/flex.sh
    template "flex.sh"
}

workflow {

    log.info"""
    Parameters:

        output:             ${params.output}
        fastq_dir:          ${params.fastq_dir}
        transcriptome_dir:  ${params.transcriptome_dir}
        samples:            ${params.samples}
        probe_barcodes:     ${params.probe_barcodes}
        include_introns:    ${params.include_introns}
        dryrun:             ${params.dryrun}
        cellranger_version: ${params.cellranger_version}
    """

    // Check that the user specified the output parameter
    if("${params.output}" == "false"){
        error "Parameter 'output' must be specified"
    }
    
    // Check that the user specified the samples parameter
    if("${params.samples}" == "false"){
        error "Parameter 'samples' must be specified"
    }

    // Check that the user specified the probe_barcodes parameter
    if("${params.probe_barcodes}" == "false"){
        error "Parameter 'probe_barcodes' must be specified"
    }

    // Check that the user specified the fastq_dir parameter
    if("${params.fastq_dir}" == "false"){
        error "Parameter 'fastq_dir' must be specified"
    }

    // Check that the user specified the transcriptome_dir parameter
    if("${params.transcriptome_dir}" == "false"){
        error "Parameter 'transcriptome_dir' must be specified"
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

    // Point to the probe set CSV
    probe_set = file(
        "${params.probe_set}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // Point to the samples CSV provided by the user
    samples = file(
        "${params.samples}",
        checkIfExists: true,
        type: "file",
        glob: false
    )

    // Point to the probe barcodes CSV provided by the user
    probe_barcodes = file(
        "${params.probe_barcodes}",
        checkIfExists: true,
        type: "file",
        glob: false
    )

    // Build the multi config CSV for each sample
    multi_config(samples, probe_barcodes)

    // If the user has not set the `dryrun` parameter
    if("${params.dryrun}" == "false"){
        // Analyze each sample independently
        cellranger_flex(
            multi_config.out,
            fastq_dir,
            transcriptome_dir,
            probe_set
        )
    }else{
        // Log the location of all output configs
        multi_config
            .out
            .map { it -> it.name }
            .toSortedList()
            .view {
                """
                Multi config CSVs have been written to:
                "${params.output}/"
                ${it}
                """
            }
    }

}
