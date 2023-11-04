// Logic to get the list of samples from a list of files
process parse_samples {
    // Load the appropriate dependencies
    label "python"

    input:
    path "files.txt"

    output:
    path "samples.txt"

    script:
    template "parse_samples.py"
}

// Function to list the files in a folder
def list_files(folder_path){
    return Channel
        .fromPath(
            "${folder_path}/*"
        )
        .map { it -> "${it.name}" }
        .collectFile(name: 'files.txt', newLine: true)
}

workflow sample_list {

    // If the user supplied a sample whitelist
    if("${params.sample_whitelist}" != "false"){
    
        // Get the file with the list of samples
        Channel
            .of(
                file(
                    "${params.sample_whitelist}",
                    checkIfExists: true
                )
            )
            .set { sample_manifest }
    
    } else {

        // Make a file listing all samples with data in the `fastq_dir`
        parse_samples(
            list_files(
                "${params.fastq_dir}"
            )
        )
        parse_samples
            .out
            .set { sample_manifest }

    }

    // Split up the file listing all samples
    sample_manifest
        .splitCsv(
            header: false
        )
        .unique()
        .flatten()
        .set { sample_ch }

    emit:
    sample_ch
}

workflow parse_samplesheet {
    // Parse the set of files provided by the user from a samplesheet
    Channel
        .fromPath(
            "${params.samplesheet}",
            checkIfExists: true
        )
        .splitCsv(header: true)
        .map { it -> [
            it.sample,
            file(it.fastq_1, checkIfExists: true),
            file(it.fastq_2, checkIfExists: true)
        ]}
        .groupTuple()
        .set { output_ch }

    emit:
    output_ch
    
}