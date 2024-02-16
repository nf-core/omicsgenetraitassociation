process POSTPROCESS_PASCAL {

    label 'process_low'

    // container 'jungwooseok/mea:1.0.0'
    conda "${moduleDir}/environment.yml"
    // TODO: requested BioContainer
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-9d836da785124bb367cbe6fbfc00dddd2107a4da:b033d6a4ea3a42a6f5121a82b262800f1219b382-0' :
        'quay.io/biocontainers/mulled-v2-9d836da785124bb367cbe6fbfc00dddd2107a4da:b033d6a4ea3a42a6f5121a82b262800f1219b382-0' }"


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
