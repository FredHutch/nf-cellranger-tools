#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

// Define the process used to run cellranger-arc count
process cellranger_arc_count {
    // Load the appropriate dependencies
    label "cellranger"

    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true

    input:
    // Run the process once per sample
    // Stage input reads in the GEX_FASTQS and ATAC_FASTQS folders
    tuple val(sample), path("GEX_FASTQS/"), path("ATAC_FASTQS/")
    // Stage the reference in the working directory
    path "REF"

    output:
    // Capture any created files in the output directory
    path "*"

    script:
    // Run the code defined in templates/count.sh
    template "arc_count.sh"
}

workflow {

    log.info"""
    Parameters:

        output:             ${params.output}
        samplesheet:        ${params.samplesheet}
        reference_dir:      ${params.reference_dir}
        cellranger_version: ${params.cellranger_version}
    """

    // Check that the user specified the output parameter
    if("${params.output}" == "false"){
        error "Parameter 'output' must be specified"
    }

    // Check that the user specified the samplesheet parameter
    if("${params.samplesheet}" == "false"){
        error "Parameter 'samplesheet' must be specified"
    }

    // Check that the user specified the reference_dir parameter
    if("${params.reference_dir}" == "false"){
        error "Parameter 'reference_dir' must be specified"
    }

    // Point to the reference directory
    ref_dir = file(
        "${params.reference_dir}",
        checkIfExists: true,
        type: "dir",
        glob: false
    )

    // Parse the set of files provided by the user from a samplesheet
    Channel
        .fromPath(
            "${params.samplesheet}",
            checkIfExists: true
        )
        .splitCsv(header: true)
        .map { it -> [
            [
                it.sample,
                it.fastq_type,
                file(it.fastq_1, checkIfExists: true)
            ],
            [
                it.sample,
                it.fastq_type,
                file(it.fastq_2, checkIfExists: true)
            ]
        ]}
        .groupTuple(by:[0, 1], sort: true)
        .branch {
            gex: it[1] == "gex"
            atac: it[1] == "atac"
        }
        .set { long_ch }

        
    long_ch.gex
        .map { it -> [it[0], it[2]] }
        .join(
            long_ch.atac
                .map { it -> [it[0], it[2]] }
        )
        .set { wide_ch }

    wide_ch.view()

    // Analyze each sample independently
    cellranger_arc_count(wide_ch, ref_dir)
}
