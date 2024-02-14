#!/usr/bin/env nextflow

// Enable DSL 2 syntax
nextflow.enable.dsl = 2

process merge {
    publishDir "${params.output}", mode: 'copy', overwrite: true, pattern: "probes.csv"
    label "python"

    input:
    path "input.fasta"
    path "input.gtf"
    path "input.csv"
    path "custom/"

    output:
    tuple path("merged.fasta"), path("merged.gtf"), emit: seqs
    path "probes.csv", emit: probes

    """#!/bin/bash
set -e
spaceranger_merge.py
"""

}

process mkref {
    // Load the appropriate dependencies
    label "spaceranger"

    publishDir "${params.output}", mode: 'copy', overwrite: true

    input:
    tuple path(fasta), path(genes)

    output:
    path "*"

    script:
    template "spaceranger_mkref.sh"
}

workflow {
    fasta = file(params.fasta, checkIfExists: true)
    genes = file(params.genes, checkIfExists: true)
    probes = file(params.probes, checkIfExists: true)
    Channel
        .fromPath(
            "${params.custom}".split(",").toList(),
            checkIfExists: true
        )
        .toSortedList()
        .set { custom }

    merge(fasta, genes, probes, custom)
    mkref(merge.out.seqs)

}