#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

// Import the process used to identify samples from the FASTQ files in a folder
include { sample_list; parse_samplesheet } from './modules/general'

// Define the process used to run cellranger count
process cellranger_count {
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
    // Run the code defined in templates/count.sh
    template "count.sh"
}

// Define the process used to run cellranger count from the samplesheet inputs
process cellranger_count_samplesheet {
    // Load the appropriate dependencies
    label "cellranger"

    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true

    input:
    // Run the process once per sample
    tuple val(sample), path("FASTQ_DIR/${sample}_S1_L00*_R1_001.fastq.gz"), path("FASTQ_DIR/${sample}_S1_L00*_R2_001.fastq.gz")
    // Stage the reference transcriptome (by symlink) in the working directory
    path "REF"

    output:
    // Capture any created files in the output directory
    path "*"

    script:
    // Run the code defined in templates/count.sh
    template "count.sh"
}

workflow {

    log.info"""
    Parameters:

        output:             ${params.output}
        fastq_dir:          ${params.fastq_dir}
        samplesheet:        ${params.samplesheet}
        transcriptome_dir:  ${params.transcriptome_dir}
        include_introns:    ${params.include_introns}
        dryrun:             ${params.dryrun}
        cellranger_version: ${params.cellranger_version}
    """

    // Check that the user specified the output parameter
    if("${params.output}" == "false"){
        error "Parameter 'output' must be specified"
    }

    // Check that the user specified the fastq_dir parameter
    if("${params.fastq_dir}" == "false" && "${params.samplesheet}" == "false"){
        error "Either 'fastq_dir' or 'samplesheet' must be specified"
    }

    // Check that the user specified the fastq_dir parameter
    if("${params.fastq_dir}" != "false" && "${params.samplesheet}" != "false"){
        error "Either 'fastq_dir' or 'samplesheet' must be specified, but not both."
    }

    // Check that the user specified the transcriptome_dir parameter
    if("${params.transcriptome_dir}" == "false"){
        error "Parameter 'transcriptome_dir' must be specified"
    }

    // Point to the reference transcriptome
    ref_dir = file(
        "${params.transcriptome_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    if("${params.fastq_dir}" != "false"){
        // If the user provided a folder of files to process (or the fastq_dir)

        // Get the sample list either from the sample_whitelist or the fastq_dir
        sample_list()

        // Point to the FASTQ directory
        fastq_dir = file(
            "${params.fastq_dir}",
            checkIfExists: true,
            type: "dir",
            glob: false
        )

        // If the user has not set the `dryrun` parameter
        if("${params.dryrun}" == "false"){
            // Analyze each sample independently
            cellranger_count(sample_list.out, fastq_dir, ref_dir)
        }else{
            // Log the samples which have been detected
            sample_list.out
                .view {
                    "Sample: ${it}"
                }
        }
    } else {
        // If the user provided a samplesheet
        parse_samplesheet()

        parse_samplesheet.out.view()

        // Analyze each sample independently
        cellranger_count_samplesheet(parse_samplesheet.out, ref_dir)

    }
}
