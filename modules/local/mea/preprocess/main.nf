process PREPROCESS_PASCAL {

    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.1.5' :
        'quay.io/biocontainers/pandas:1.1.5' }"

    input:
    path(gene_score_file)
    tuple val(module_id), path(module_file_dir)
    tuple val(pipeline), val(trait), val(gene_col_name), val(pval_col_name)

    output:
    tuple val(module_id), path("pascalInput/GS_*"), path("pascalInput/Module_*"), path("pascalInput/GO_*"), emit: paths
    tuple val(pipeline), val(trait), emit: meta
    path("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template 'preProcessForPascal.py'
}
