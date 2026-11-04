#filter to remove variants that are not present in the proband
#if hom ref or missing in proband, then remove variant

#need to find a way to get the proband sample name to this point

version 1.0

task filterVcfProband {
  input {
    File input_vcf
    String proband_name
    String? output_vcf_name = "proband_filter.vcf"
  }

  Int space_needed_gb = 10 + round(2 * size(input_vcf, "GB"))
  runtime {
    preemptible: 1
    maxRetries: 2
    memory: "4GB"
    docker: "mgibio/bcftools-cwl:1.12"
    disks: "local-disk ~{space_needed_gb} HDD"
  }

  command <<<
      set -euo pipefail

      INPUT_VCF="~{input_vcf}"
      PROBAND_NAME="~{proband_name}"
      OUTPUT_VCF="~{output_vcf_name}"

      # Find the proband's sample index in the VCF
      PROBAND_INDEX=$(
          /opt/bcftools/bin/bcftools query -l "$INPUT_VCF" |
          /usr/bin/awk -v sample="$PROBAND_NAME" '
              $0 == sample { print NR-1; found=1 }
              END { if (!found) exit 1 }
          '
      )

      # Define the expression to filter by, this will only keep 0/1, 1/0, and 1/1 cases for the proband, will not keep 0/0, ./., or 0/.
      FILTER_EXPR="GT[${PROBAND_INDEX}]=\"alt\""

      # Filter variants based on the proband's genotype
      /opt/bcftools/bin/bcftools view \
          -i "$FILTER_EXPR" \
          -Ov \
          -o "$OUTPUT_VCF" \
          "$INPUT_VCF"
  >>>

  output {
    File filtered_vcf = output_vcf_name
  }
}
