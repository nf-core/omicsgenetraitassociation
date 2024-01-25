process MMAP {

    label 'process_low'

    container 'docker://jungwooseok/mmap:1.0.2'

    input:
    val gene
    val trait
    tuple val(meta), path(phenotype_file)
    path pedigree_file
    path covariance_matrix_file

    output:
    // TODO: propagate meta
    path "*.poly.cov.csv"         , emit: csv
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def VERSION = '2022_11_06_21_46' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    #!/bin/bash

    mmap=/app/mmap.2022_01_04_14_13.intel
    covariates=" $gene "

    \$mmap \\
      --ped "${pedigree_file}" \\
      --trait ${trait} \\
      --covariates \$covariates \\
      --phenotype_filename "${phenotype_file}" \\
      --read_binary_covariance_file "${covariance_matrix_file}" \\
      --single_pedigree \\
      --file_suffix "kinship_${gene}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mmap: $VERSION
    END_VERSIONS
    """
}
