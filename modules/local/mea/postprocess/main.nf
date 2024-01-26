process POSTPROCESS_PASCAL {

    label 'process_low'

    container 'docker://jungwooseok/mea:1.0.0'
    // TODO: requested BioContainer 

    input:
    tuple val(module_id), path(pascalOutputFile), path(geneScoreFilePascalInput), path(goFile)
    tuple val(pipeline), val(trait)
    val numTests
    val alpha

    output:
    tuple val(module_id), path("masterSummaryPiece/master_summary_slice_*"), path("significantModules/"), path(goFile), emit: paths
    tuple val(pipeline), val(trait), emit: meta
    path("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template 'processPascalOutput.py'
}