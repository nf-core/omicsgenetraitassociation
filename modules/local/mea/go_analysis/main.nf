process GO_ANALYSIS {

    label 'process_low'

    container 'jungwooseok/webgestalt:1.0.3'
    // TODO: requested BioContainers

    input:
    tuple val(module_id), path(masterSummarySlice), path(sigModuleDir), path(goFile)
    tuple val(pipeline), val(trait)

    output:
    tuple val(module_id), path(masterSummarySlice), path("GO_summaries/${trait}/"), path(goFile), emit: paths
    tuple val(pipeline), val(trait), emit: meta
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template 'ORA_cmd.R'
}
