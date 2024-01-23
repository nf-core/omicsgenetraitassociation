process PASCAL {
    label 'process_medium'

    container 'docker://jungwooseok/pascal:1.0.3'

    // publishDir "results/pascal", mode:'copy', saveAs: { filename  -> filename.endsWith(".csv") ? "PASCAL.csv" : filename}

    input:
    path gwas_file
    path gene_annotation
    path ref_panel

    output:
    path("pascal_out.tsv")        , emit: tsv
    path("manhattan_plot.png")    , emit: manhattan
    path("versions.yml")          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def ref_panel_name = ref_panel.getSimpleName() // get filename without ext

    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)

    // extract tarball (nextflow does not support s3 glob)
    """
    tar -xzvf ${ref_panel}

    python3 ${moduleDir}/bin/pascal.py \\
      --gwas_file $gwas_file \\
      --gene_annotation $gene_annotation \\
      --ref_panel $ref_panel_name \\
      --manhattan_plot_file manhattan_plot.png \\
      --output_file pascal_out.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version)
        pascal: \$(python3 -c "import PascalX; print (PascalX.__version__)")
    END_VERSIONS
    """
}
