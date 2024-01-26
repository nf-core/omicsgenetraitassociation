/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowOmicsgenetraitassociation.initialise(params, log)

// /*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     CONFIG FILES
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// */

// ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
// ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
// ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
// ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULES: local modules
//
include { PASCAL }                      from '../modules/local/pascal'
include { MMAP }                        from '../modules/local/mmap/mmap'    
include { MMAP_PARSE }                  from '../modules/local/mmap/mmap_parse'
include { PREPROCESS_PASCAL }           from '../modules/local/mea/preprocess'
include { RUN_PASCAL }                  from '../modules/local/mea/pascal'
include { POSTPROCESS_PASCAL }          from '../modules/local/mea/postprocess'
include { GO_ANALYSIS }                 from '../modules/local/mea/go_analysis'
include { MERGE_ORA_AND_SUMMARY }       from '../modules/local/mea/merge_ora_and_summary'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
// include { INPUT_CHECK }                 from '../subworkflows/local/input_check'
include { PASCAL_SUBWORKFLOW }          from '../subworkflows/local/pascal' 
include { MMAP_SUBWORKFLOW }            from '../subworkflows/local/mmap'
include { CMA_SUBWORKFLOW }             from '../subworkflows/local/cma'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
// include { FASTQC                      } from '../modules/nf-core/fastqc/main'
// include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
// include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
// def multiqc_report = []

workflow OMICSGENETRAITASSOCIATION {

    ch_versions = Channel.empty()
    ch_mea_preprocess_input = Channel.empty()

    //
    // Validate and parse samplesheet
    //
    // TODO: deal with additional sources
    Channel.fromSamplesheet("input")
        .multiMap{ sample, trait, pascal, twas, additional_sources ->
            def num_additional_sources = 0
            if (additional_sources) {
                num_additional_sources = additional_sources.countLines()
            }
            def meta = ["id": sample, "trait": trait]
            pascal: [meta, pascal]
            twas: [meta, twas]
            num_additional_sources: [meta, num_additional_sources]
        }
        .set { ch_input }
    // ch_input.pascal.view()
    // ch_input.twas.view()
    // ch_input.num_additional_sources.view()


    //
    // MODULE: PASCAL
    //
    PASCAL_SUBWORKFLOW (
      ch_input.pascal,
      params.pascal_gene_annotation,
      params.pascal_ref_panel
    )
    ch_pascal_output = PASCAL_SUBWORKFLOW.out.pascal_output
    ch_pascal_cma_format = PASCAL_SUBWORKFLOW.out.cma_format_output
    ch_versions = ch_versions.mix(PASCAL_SUBWORKFLOW.out.versions)

    // ch_pascal_output.view()

    //
    // SUBWORKFLOW: MMAP_SUBWORKFLOW
    //
    MMAP_SUBWORKFLOW (
      params.mmap_gene_list,
      params.trait,
      ch_input.twas,
      params.mmap_pedigree_file,
      params.mmap_cov_matrix_file
    )
    ch_mmap_parsed = MMAP_SUBWORKFLOW.out.parsed_mmap_output
    ch_mmap_cma_format = MMAP_SUBWORKFLOW.out.cma_format_output
    ch_versions = ch_versions.mix(MMAP_SUBWORKFLOW.out.versions)

    //
    // MODULE: run CMA
    //

    // ch_pascal_cma_format.view()
    // ch_mmap_cma_format.view()

    ch_cma_input_files = ch_pascal_cma_format
      .mix(ch_mmap_cma_format)
      .toList()

    CMA_SUBWORKFLOW (
      ch_cma_input_files,
      params.trait,
      []
    )
    ch_pval = CMA_SUBWORKFLOW.out.pval
      .collect()
    ch_versions = ch_versions.mix(CMA_SUBWORKFLOW.out.versions)

    //
    // MODULE: PREPROCESSFORPASCAL 
    //
    ch_mea_preprocess_input = ch_pval
      .multiMap{ pval ->
        gene_score_file: pval
        meta: tuple ( params.pipeline, params.trait, params.gene_col_name, params.pval_col_name)
      }

    ch_module_files = Channel.fromPath("${params.module_file_dir}/*.txt")
      .map { module_file ->
        tuple ( module_file.baseName, module_file)
      }

    ch_preprocess_input = ch_mea_preprocess_input.gene_score_file
      .combine(ch_module_files)
      .combine(ch_mea_preprocess_input.meta)
      .multiMap { gene_score_file, module_id, module_file_dir, pipeline, trait, gene_col_name, pval_col_name ->
        gene_score_file: gene_score_file
        module_file: tuple (module_id, module_file_dir)
        meta: tuple (pipeline, trait, gene_col_name, pval_col_name)
      }

    PREPROCESS_PASCAL (
        ch_preprocess_input
    )
    ch_mea_paths = PREPROCESS_PASCAL.out.paths
    ch_mea_meta = PREPROCESS_PASCAL.out.meta
    ch_versions = ch_versions.mix(PREPROCESS_PASCAL.out.versions)

    //
    // MODULE: MEA PASCAL
    //
    RUN_PASCAL (
      ch_mea_paths,
      ch_mea_meta
    )

    ch_pascal_paths = RUN_PASCAL.out.paths
    ch_pascal_meta = RUN_PASCAL.out.meta
    ch_versions = ch_versions.mix(RUN_PASCAL.out.versions)

    //
    // MODULE: POSTPROCESS_PASCAL
    //
    POSTPROCESS_PASCAL (
      ch_pascal_paths,
      ch_pascal_meta,
      params.numtests,
      params.alpha
    )
    ch_postprocess_paths = POSTPROCESS_PASCAL.out.paths
    ch_postprocess_meta = POSTPROCESS_PASCAL.out.meta
    ch_versions = ch_versions.mix(POSTPROCESS_PASCAL.out.versions)

    //
    // MODULE: GO analysis
    //
    GO_ANALYSIS (
      ch_postprocess_paths,
      ch_postprocess_meta
    )
    ch_go_paths = GO_ANALYSIS.out.paths
    ch_go_meta = GO_ANALYSIS.out.meta
    ch_versions = ch_versions.mix(GO_ANALYSIS.out.versions)

    //
    // MODULE: MERGE_ORA_AND_SUMMARY
    // TODO: each run of MERGE_ORA_AND_SUMMARY overwrites contents of summary_dir. should not happen
    //
    MERGE_ORA_AND_SUMMARY (
      ch_go_paths,
      ch_go_meta
    )
    ch_merge_summary_dir = MERGE_ORA_AND_SUMMARY.out.summary_dir
    ch_merge_summary_files = MERGE_ORA_AND_SUMMARY.out.summary_files
    ch_merge_meta = MERGE_ORA_AND_SUMMARY.out.meta
    ch_merge_trait = MERGE_ORA_AND_SUMMARY.out.trait

    // ch_merge_summary_files.collect().view()

    // concatenate summary slices and write to master_summary_<trait>.csv
    ch_master_summary = ch_merge_summary_files
      .collectFile(name: "master_summary_${params.trait}.csv", 
        cache: false,
        keepHeader: true,
        skip: 1,
        storeDir: "${params.outdir}/mea/"
      )
      // .view()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
