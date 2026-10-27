version 1.0

task gatkCombineGVCFs {
    input {
        File reference
        File reference_fai
        File reference_dict
        Array[File] gvcfs
        Array[File] gvcf_tbis
        String output_file_name = "joint.g.vcf.gz"
    }

    Float reference_size = size([reference, reference_fai, reference_dict], "GB")
    Float gvcf_size = size(flatten([gvcfs, gvcf_tbis]), "GB")
    Int space_needed_gb = 10 + round(reference_size + gvcf_size)
    runtime {
        preemptible: 1
        maxRetries: 2
        memory: "18GB"
        docker: "broadinstitute/gatk:4.1.8.1"
        disks: "local-disk ~{space_needed_gb} HDD"
    }

    command <<<
        # do the task itself
        /gatk/gatk --java-options -Xmx16g CombineGVCFs \
        -R ~{reference} \
        --variant ~{sep=" --variant " gvcfs} \
        -O ~{output_file_name} \
        --create-output-variant-index true
    >>>

    output {
        File joint_gvcf = output_file_name
        File joint_gvcf_tbi = output_file_name + ".tbi"
    }
}