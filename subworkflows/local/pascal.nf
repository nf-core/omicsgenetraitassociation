//
// workflow for running PASCAL and formatting the output for CMA
//
include { PASCAL } from '../../modules/local/pascal'
include { FORMAT_CMA_INPUT } from '../../modules/local/cma/format_cma_input'

workflow PASCAL_SUBWORKFLOW {
    take:
    gwas_file
    gene_annotation
    ref_panel

    main:
    ch_versions             = Channel.empty()
    ch_pascal_out           = Channel.empty()

    PASCAL (
      gwas_file, gene_annotation, ref_panel
    )
    ch_pascal_out = PASCAL.out.tsv
    ch_versions = ch_versions.mix(PASCAL.out.versions)

    FORMAT_CMA_INPUT (
      ch_pascal_out,
      "PASCAL",
      params.pascal_header,
      params.pascal_pval_col,
      [],
      []
    )
    ch_pascal_cma_format = FORMAT_CMA_INPUT.out.csv
    ch_versions = ch_versions.mix(FORMAT_CMA_INPUT.out.versions)

    emit:
    pascal_output         = ch_pascal_out
    cma_format_output     = ch_pascal_cma_format
    versions              = ch_versions
}