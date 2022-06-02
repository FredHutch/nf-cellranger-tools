#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

// Define the process used to run cellranger count
process cellranger_count {
    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/${sample}/", mode: 'copy', overwrite: true

    input:
    // Run the process once per sample
    val sample
    // Stage the FASTQ folder (by symlink) in the working directory
    path "FASTQ_DIR/"
    // Stage the reference transcriptome (by symlink) in the working directory
    path "REF/"

    output:
    // Capture any created files as outputs
    path "*"

    script:
    // Run the code defined in templates/count.sh
    template "count.sh"
}

workflow {

    // Check that the user specified the samplesheet parameter
    if("${params.samplesheet}" == "false"){
        error "Parameter 'samplesheet' must be specified"
    }
    
    // Check that the user specified the output parameter
    if("${params.output}" == "false"){
        error "Parameter 'output' must be specified"
    }

    // Check that the user specified the sample_header parameter
    if("${params.sample_header}" == "false"){
        error "Parameter 'sample_header' must be specified"
    }

    // Check that the user specified the fastq_dir parameter
    if("${params.fastq_dir}" == "false"){
        error "Parameter 'fastq_dir' must be specified"
    }

    // Get the list of samples from the appropriate column of the samplesheet
    Channel
        .of(
            file(
                "${params.samplesheet}",
                checkIfExists: true
            )
        )
        .splitCsv(
            header: true
        )
        .map {
            row -> row["${params.sample_header}"]
        }
        .unique()
        .set { sample_ch }

    // Point to the FASTQ directory
    fastq_dir = file(
        "${params.fastq_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // Point to the reference transcriptome
    ref_dir = file(
        "${params.transcriptome_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // Analyze each sample independently
    cellranger_count(sample_ch, fastq_dir, ref_dir)
}
