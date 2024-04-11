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
    // The sample grouping CSV (indicating which FASTQ files contain which data)
    path "grouping.csv"
    // The multiplexing CSV (which hashtags were used for each sample)
    path "multiplexing.csv"
    // The optional feature barcode CSV (indicating whether additional
    // feature barcode analysis should be run after demultiplexing)
    path "feature_reference.csv"

    output:
    // Get the config used for demultiplexing
    path "demux.config.csv", emit: demux
    path "post_demux.config.csv", optional: true, emit: post_demux

    script:
    // Run the code defined in templates/multi_config.py
    template "multi_config_hashtagging.py"
}

// Define the process used to run cellranger multi
process demux_hashtags {
    // Load the appropriate dependencies
    label "cellranger"
    
    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true
    
    input:
    // The run configuration for demultiplexing is driven by a multi config CSV
    path "demux.config.csv"
    // Stage the FASTQ folder (by symlink) in the working directory
    path "FASTQ_DIR"
    // Stage the reference transcriptome (by symlink) in the working directory
    path "GEX_REF"
    // The hashtags CSV
    path "hashtags.csv"

    output:
    // Capture any created files as outputs
    path "*", emit: all
    // Capture the per-sample BAM files
    path "demultiplexed_samples/*.bam", emit: bam, optional: true

    script:
    // Run the code defined in templates/demux_hashtags.sh
    template "demux_hashtags.sh"
}

// Convert the BAM file for each sample into FASTQs
process bam_to_fastq {
    // Load the appropriate dependencies
    label "cellranger"
    
    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true
    
    input:
    // The run configuration for demultiplexing is driven by a multi config CSV
    tuple val(sample_name), path(BAM)

    output:
    // Capture any created files as outputs
    tuple val(sample_name), path("${sample_name}/"), emit: fastqs
    path "*.log", emit: log

    """#!/bin/bash
    set -e
    bamtofastq --version | tee -a bamtofastq.${sample_name}.log
    bamtofastq \
        --reads-per-fastq=2200000000 \
        ${BAM} \
        ${sample_name} \
    2>&1 | tee -a bamtofastq.${sample_name}.log

    # Since the GEX reads are listed first in the demux step
    # (note that we explicitly set this in the config)
    # as a result, the GEX reads will be the first FASTQ folder
    # We will drop the other reads and keep only the GEX reads
    mv ${sample_name}/demultiplexed_samples_0*/* ${sample_name}/
    rmdir ${sample_name}/demultiplexed_samples_0*
    rm -r ${sample_name}/demultiplexed_samples_1*
    """
}


// Optionally run cellranger multi on the demuxed reads
process post_demux_multi {
    // Load the appropriate dependencies
    label "cellranger"
    
    // Copy all output files to the folder specified by the user with --output
    publishDir "${params.output}/", mode: 'copy', overwrite: true
    
    input:
    // The run configuration for demultiplexing is driven by a multi config CSV
    path "post_demux.config.csv"
    // The FASTQ files for each sample
    tuple val(sample_name), path("DEMUX_DIR")
    // Stage the FASTQ folder (by symlink) in the working directory
    path "FASTQ_DIR"
    // Stage the reference transcriptome (by symlink) in the working directory
    path "GEX_REF"
    // Stage the reference V(D)J (by symlink) in the working directory
    path "VDJ_REF"
    // The feature reference CSV
    path "feature.csv"

    output:
    // Capture any created files as outputs
    path "*", emit: all

    script:
    // Run the code defined in templates/demux_hashtags.sh
    template "post_demux_multi.sh"
}

workflow {

    log.info"""
    Parameters:

        output:             ${params.output}
        grouping:           ${params.grouping}
        include_introns:    ${params.include_introns}
        fastq_dir:          ${params.fastq_dir}
        transcriptome_dir:  ${params.transcriptome_dir}
        vdj_dir:            ${params.vdj_dir}
        multiplexing:       ${params.multiplexing}
        feature_csv:        ${params.feature_csv}
        probes_csv:         ${params.probes_csv}
        dryrun:             ${params.dryrun}
        cellranger_version: ${params.cellranger_version}
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

    // Check that the user specified the feature_csv parameter
    if("${params.feature_csv}" == "false"){
        error "Parameter 'feature_csv' must be specified"
    }

    // Check that the user specified the probes_csv parameter
    if("${params.probes_csv}" == "false"){
        error "Parameter 'probes_csv' must be specified"
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
    // Indicates which samples were processed with which hashtag
    multiplexing = file(
        "${params.multiplexing}",
        checkIfExists: true,
        type: "file",
        glob: false
    )

    // Point to the feature reference CSV (which by default is an empty table in templates/)
    feature_csv = file(
        "${params.feature_csv}",
        checkIfExists: true,
        type: "file",
        glob: false
    )

    // Point to the hashtag CSV which describes the hashtagging library
    hashtag_csv = file(
        "${params.hashtag_csv}",
        checkIfExists: true,
        type: "file",
        glob: false
    )

    // Build the multi config CSV for each sample
    multi_config(grouping, multiplexing, feature_csv)

    // If the user has not set the `dryrun` parameter
    if("${params.dryrun}" == "false"){
        // Split up each sample
        demux_hashtags(
            multi_config.out.demux,
            fastq_dir,
            transcriptome_dir,
            hashtag_csv
        )
        // Convert the BAM files to FASTQ
        bam_to_fastq(
            demux_hashtags.out.bam
                .flatten()
                .map {
                    it -> [
                        it.name.replace(".bam", ""),
                        it
                    ]
                }
        )

        // If there is data beyond the GEX, run cellranger multi
        // on the reads from each individual sample
        post_demux_multi(
            multi_config.out.post_demux,
            bam_to_fastq.out.fastqs,
            fastq_dir,
            transcriptome_dir,
            vdj_dir,
            feature_csv
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
                "${params.output}/configs/"
                ${it}
                """
            }
    }

}
