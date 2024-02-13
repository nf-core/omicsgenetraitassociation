//
// workflow for running MMAP, parsing the output, and formatting it for CMA
//
include { MMAP } from '../../modules/local/mmap/mmap'
include { MMAP_PARSE } from '../../modules/local/mmap/mmap_parse'
include { FORMAT_CMA_INPUT } from '../../modules/local/cma/format_cma_input'

workflow MMAP_SUBWORKFLOW {
    take:
    gene_list_file
    trait
    phenotype_file
    pedigree_file
    covariance_matrix_file

    main:
    ch_versions             = Channel.empty()
    ch_concatenated_mmap    = Channel.empty()
    ch_mmap_genes           = Channel.fromPath(gene_list_file)
        .splitText()
        .map ( gene -> gene.trim() )
    ch_mmap_cma_format      = Channel.empty()

    //
    // MODULE: MMAP
    //
    // TODO: add gene to meta field
    MMAP (
        ch_mmap_genes, trait, phenotype_file.first(), pedigree_file, covariance_matrix_file
    )
    ch_concatenated_mmap = MMAP.out.csv
        .collectFile(name: 'mmap_results.csv', cache:false)
    ch_versions = ch_versions.mix(MMAP.out.versions)

    //
    // MODULE: MMAP PARSE
    //
    // TODO: propagate meta
    MMAP_PARSE (
        ch_concatenated_mmap
    )
    ch_mmap_parsed = MMAP_PARSE.out.mmap_parsed_output
    ch_versions = ch_versions.mix(MMAP_PARSE.out.versions)

    //
    // MODULE: FORMAT_CMA_INPUT
    //
    // TODO: propagate meta
    FORMAT_CMA_INPUT (
        ch_mmap_parsed,
        "MMAP",
        params.mmap_header,
        params.mmap_pval_col,
        params.mmap_beta_col,
        params.mmap_se_genes
    )
    ch_mmap_cma_format = FORMAT_CMA_INPUT.out.csv
    ch_versions = ch_versions.mix(FORMAT_CMA_INPUT.out.versions)


    emit:
    parsed_mmap_output      = ch_mmap_parsed
    cma_format_output       = ch_mmap_cma_format
    versions                = ch_versions
}
