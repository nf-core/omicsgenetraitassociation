process PASCAL {
    label 'process_medium'

    container 'docker://jungwooseok/pascal:1.0.3'

    publishDir "results/pascal", mode:'copy', saveAs: { filename  -> filename.endsWith(".csv") ? "PASCAL.csv" : filename}

    input:
    path gwas_file
    path gene_annotation
    val ref_panel
    val output_file
    val manhattan_plot_file

    output:
    path("${output_file}"), emit: tsv
    path("${manhattan_plot_file}"), emit: manhattan
    path("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    """
    python3 ${moduleDir}/bin/pascal.py \\
      --gwas_file $gwas_file \\
      --gene_annotation $gene_annotation \\
      --ref_panel $ref_panel \\
      --manhattan_plot_file $manhattan_plot_file \\
      --output_file $output_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version)
        pascal: \$(python3 -c "import PascalX; print (PascalX.__version__)")
    END_VERSIONS
    """
}
