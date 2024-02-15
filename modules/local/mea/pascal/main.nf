process RUN_PASCAL {

    label 'process_low'

    container 'jungwooseok/mea_pascal:1.1'

    input:
    tuple val(module_id), path(geneScoreFile), path(moduleFile), path(goFile)
    tuple val(pipeline), val(trait)

    output:
    tuple val(module_id), path("pascalOutput/*"), path(geneScoreFile), path(goFile), emit: paths
    tuple val(pipeline), val(trait), emit: meta
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template 'runPascal.py'
}
