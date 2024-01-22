process FORMAT_CMA_INPUT {

    label 'process_medium'

    conda "${moduleDir}/environment.yml"

    input:
    path input_file
    val name // renames output file to <name>.csv e.g. PASCAL.csv, MMAP.csv, STAAR.csv
    val header // 0 or 1 depending on whether input file has header
    val pval_col
    val beta_col
    val se_col

    output:
    path "${name}.csv", emit: csv
    path("versions.yml"), emit: versions.yml

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    python3 ${moduleDir}/bin/format_cma_input.py \\
        --input_file ${input_file} \\
        --name ${name} \\
        --header ${header} \\
        --pval_col ${pval_col} \\
        --beta_col ${beta_col} \\
        --se_col ${se_col}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version)
        pandas: \$(python3 -c "import pandas; print (pandas.__version__)")
    END_VERSIONS
    """
}
