process TABIX_BGZIP {
    tag "$meta.id"
    label 'process_single'

    conda (params.enable_conda ? 'bioconda::tabix=1.11' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tabix:1.11--hdfd78af_0' :
        'quay.io/biocontainers/tabix:1.11--hdfd78af_0' }"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("${prefix}*"), emit: output
    tuple val(meta), path("*gzi")      , emit: gzi, optional: true
    path  "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    in_bgzip = input.toString().endsWith(".gz")
    command1 = in_bgzip ? '-d' : '-c'
    command2 = in_bgzip ? ''   : " > ${prefix}.${input.getExtension()}.gz"
    // Name the index according to $prefix, unless a name has been requested
    if ((args.matches("(^| )-i\\b") || args.matches("(^| )--index(\$| )")) && !args.matches("(^| )-I\\b") && !args.matches("(^| )--index-name\\b")) {
        args = args + " -I ${prefix}.${input.getExtension()}.gz.gzi"
    }
    """
    bgzip $command1 $args -@${task.cpus} $input $command2

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tabix: \$(echo \$(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """
}
