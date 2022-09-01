#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

// Import the process used to identify samples from the FASTQ files in a folder
include { sample_list } from './modules/general'

// Define the process used to run cellranger vdj
process cellranger_vdj {
    // Load the appropriate dependencies
    label "cellranger"

    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true

    input:
    // Run the process once per sample
    val sample
    // Stage the FASTQ folder (by symlink) in the working directory
    path "FASTQ_DIR"
    // Stage the reference transcriptome (by symlink) in the working directory
    path "REF"

    output:
    // Capture any created files in the output directory
    path "*"

    script:
    // Run the code defined in templates/vdj.sh
    template "vdj.sh"
}

workflow {

    // Check that the user specified the output parameter
    if("${params.output}" == "false"){
        error "Parameter 'output' must be specified"
    }

    // Check that the user specified the fastq_dir parameter
    if("${params.fastq_dir}" == "false"){
        error "Parameter 'fastq_dir' must be specified"
    }

    // Check that the user specified the vdj_dir parameter
    if("${params.vdj_dir}" == "false"){
        error "Parameter 'vdj_dir' must be specified"
    }

    // Get the sample list either from the sample_whitelist or the fastq_dir
    sample_list()

    // Point to the FASTQ directory
    fastq_dir = file(
        "${params.fastq_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // Point to the reference vdj
    ref_dir = file(
        "${params.vdj_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // If the user set the `dryrun` parameter
    if("${params.dryrun}" != "false"){
        // Analyze each sample independently
        cellranger_vdj(sample_list.out, fastq_dir, ref_dir)
    }else{
        // Log the samples which have been detected
        sample_list.out
            .view {
                "Sample: ${it}"
            }
    }

}
