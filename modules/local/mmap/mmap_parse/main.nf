process MMAP_PARSE {

    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-344874846f44224e5f0b7b741eacdddffe895d1e:d3fff24ee1297b4c3bcef48354c2a30f0c82007a-0' :
        'quay.io/biocontainers/mulled-v2-344874846f44224e5f0b7b741eacdddffe895d1e:d3fff24ee1297b4c3bcef48354c2a30f0c82007a-0' }"

    input:
    path output_MMAP

    output:
    path "parsed_output_*"        , emit: mmap_parsed_output
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    python3 ${moduleDir}/bin/parse_MMAP_output.py \\
        --output_MMAP ${output_MMAP}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version)
        numpy: \$(python3 -c "import numpy; print(numpy.__version__)")
        pandas: \$(python3 -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
