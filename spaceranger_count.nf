#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

params.image_type = "cytaimage"

process count {
    // Load the appropriate dependencies
    label "spaceranger"

    publishDir "${params.output}", mode: 'copy', overwrite: true, pattern: "${sample_name}*"

    input:
    tuple val(sample_name), path("fastqs/"), path(image), val(slide), val(area)
    path "ref/"
    path "probes.csv"

    output:
    path "*"

    script:
    template "spaceranger_count.sh"
}

workflow {

    // Group any number of FASTQ pairs by their sample
    Channel
        .fromPath(params.fastq_manifest, checkIfExists: true)
        .splitCsv(header: true, sep: ",")
        .flatMap {
            r -> [
                [r["sample"], file(r["fastq_1"], checkIfExists: true)],
                [r["sample"], file(r["fastq_2"], checkIfExists: true)]
            ]
        }
        .groupTuple()
        .ifEmpty { error "No FASTQ manifest lines found" }
        .view()
        .set { fastq_ch }

    // Get the list of images, also keyed by sample
    Channel
        .fromPath(params.image_manifest, checkIfExists: true)
        .splitCsv(header: true, sep: ",")
        .map  {
            r -> [
                r["sample"],
                file(r["file"], checkIfExists: true),
                r["slide"],
                r["area"]
            ]
        }
        .ifEmpty { error "No image manifest lines found" }
        .view()
        .set { image_ch }

    // Join the channels
    fastq_ch
        .join(image_ch)
        .ifEmpty { error "No overlap found between FASTQ and image manifests" }
        .view()
        .set { comb_ch }

    // Reference genome
    ref = file(params.ref, checkIfExists: true, type: 'dir')

    // Probes
    probes = file(params.probes, checkIfExists: true)

    count(
        comb_ch,
        ref,
        probes
    )
}