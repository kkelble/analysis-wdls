version 1.0

task gatkGenotypeGVCFs {
    input {
        File reference
        File reference_fai
        File reference_dict
        File joint_gvcf
        File joint_gvcf_tbi
        String output_file_name = "joint_genotype.vcf.gz"
    }

    Float reference_size = size([reference, reference_fai, reference_dict], "GB")
    Float gvcf_size = size([joint_gvcf, joint_gvcf_tbi], "GB")
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
        /gatk/gatk --java-options -Xmx16g GenotypeGVCFs \
        -R ~{reference} \
        -V ~{joint_gvcf} \
        -O ~{output_file_name}
    >>>

    output {
        File genotype_vcf = output_file_name
        File genotype_vcf_tbi = output_file_name + ".tbi"
    }
}