version 1.0

task mergeGVCF {
  input {
    Array[File] gvcfs
    Array[File] gvcf_tbis
    String merged_vcf_basename = "merged"
  }

  Int space_needed_gb = 10 + round(2*(size(gvcfs, "GB") + size(gvcf_tbis, "GB")))
  runtime {
    preemptible: 1
    maxRetries: 2
    docker: "mgibio/bcftools-cwl:1.12"
    memory: "4GB"
    disks: "local-disk ~{space_needed_gb} HDD"
  }

  String output_file = merged_vcf_basename + ".g.vcf.gz"
  command <<<
    /opt/bcftools/bin/bcftools concat --allow-overlaps --remove-duplicates --output-type z -o ~{output_file} ~{sep=" " gvcfs}
  
    /opt/bcftools/bin/bcftools index --tbi ~{output_file}
  >>>

  output {
    File merged_gvcf = output_file
    File merged_gvcf_tbi = output_file + ".tbi"
  }
}
