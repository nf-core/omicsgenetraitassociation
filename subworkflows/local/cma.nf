//
// test CMA 
//

include { CMA } from '../../modules/local/cma/cma'

workflow CMA_SUBWORKFLOW {
    take:
    input_files     
    trait
    category

    main:

    ch_versions = Channel.empty()
    ch_pval = Channel.empty()
    ch_tetrachor = Channel.empty()

    // CMA
    CMA (
      input_files,
      trait,
      category
    )

    ch_pval = CMA.out.pval
    ch_tetrachor = CMA.out.tetrachor
    ch_versions = ch_versions.mix(CMA.out.versions)

    

    emit:
    pval = ch_pval
    tetrachor = ch_tetrachor
    versions = ch_versions 
}