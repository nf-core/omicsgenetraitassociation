process MERGE_ORA_AND_SUMMARY {

    label 'process_low'

    // container 'docker://jungwooseok/mea:1.0.0'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.1.5' :
        'quay.io/biocontainers/pandas:1.1.5' }"

    input:
    tuple val(module_id), path(masterSummaryPiece), path(oraSummaryDir), path(goFile)
    tuple val(pipeline), val(trait)

    output:
    path("summary/")                , emit: summary_dir
    path("summary/*")               , emit: summary_files
    tuple val(pipeline), val(trait) , emit: meta
    val(trait)                      , emit: trait
    path("versions.yml")            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template 'mergeORAandSummary.py'
}
