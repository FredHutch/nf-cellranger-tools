# nf-cellranger-tools
Collection of Nextflow tools for using CellRanger

## Tools

### mkfastq

Docs: [Generating FASTQs with cellranger mkfastq](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/mkfastq)

#### Parameters

  - `bcl_run_folder`: Folder containing the Illumina sequencer's base call files
  - `samplesheet`: Sample sheet defining data structure, either a Illumina Experiment Manager sample sheet or a simple three-column CSV
  - `output`: Path for output files
  - `input_type`: Define the format of the sample sheet input, either "samplesheet" or "csv" (default: "samplesheet")
  - `filter_dual_index`: Optional. Only demultiplex samples identified by i7/i5 dual-indices (e.g., SI-TT-A6), ignoring single-index samples. Single-index samples will not be demultiplexed
  - `filter_single_index`: Optional. Only demultiplex samples identified by an i7-only sample index, ignoring dual-indexed samples. Dual-indexed samples will not be demultiplexed
  - `lanes`: Comma-delimited series of lanes to demultiplex (e.g. 1,3). Use this if you have a sample sheet for an entire flow cell but only want to generate a few lanes for further 10x Genomics analysis. (optional)
  - `use_bases_mask` Same meaning as for bcl2fastq. Use to clip extra bases off a read if you ran extra cycles for QC.
  - `delete_undetermined` Delete the Undetermined FASTQs generated by bcl2fastq. Useful if you are demultiplexing a small number of samples from a large flow cell.
  - `barcode_mismatches` Same meaning as for bcl2fastq. Use this option to change the number of allowed mismatches per index adapter (0, 1, 2). Default: 1.
  - `project` Custom project name, to override the sample sheet or to use in conjunction with the --csv argument.

### count

Docs: [Single-Library Analysis with cellranger count](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/count)

#### Parameters

  - `output`: Path for output files
  - `samplesheet`: Sample sheet with a column containing the sample name (does not need to be unique)
  - `sample_header`: Header for the column in the sample sheet which contains the sample name
  - `fastq_dir`: Directory containing all FASTQ files
  - `transcriptome_dir`: Directory containing transcriptome reference files (see below)
  - `expect_cells`: Expected number of cells per sample (default: 10000)

#### References

The default transcriptome reference in the workflow is:

- `/shared/biodata/reference/10x/refdata-gex-GRCh38-2020-A`

### VDJ

Docs: [Analysis of V(D)J data](https://support.10xgenomics.com/single-cell-vdj/software/pipelines/latest/tutorial/tutorial-vdj)

#### Parameters

  - `output`: Path for output files
  - `samplesheet`: Sample sheet with a column containing the sample name (does not need to be unique)
  - `sample_header`: Header for the column in the sample sheet which contains the sample name
  - `fastq_dir`: Directory containing all FASTQ files
  - `vdj_dir`: Directory containing VDJ reference files (see below)

#### References

The default VDJ reference in the workflow is:

- `/shared/biodata/reference/10x/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0`

## Resource Allocation

The amount of CPUs and memory available to each task can be customized with the parameters `-process.cpus` (default: 16) and `-process.memory` (default: `64.GB`)
