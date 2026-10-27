version 1.0

import "../tools/cnvkit_batch.wdl" as cb
import "../tools/cnvkit_vcf_export.wdl" as cve
import "../tools/cnvkit_heatmap.wdl" as chm

workflow cnvkitSingleSample {
  input {
    File reference
    File reference_fai
    File sample_bam
    File sample_bam_bai
    String method  # enum ["hybrid" "amplicon" "wgs"]
    Boolean? diagram
    Boolean? scatter_plot
    Boolean heatmap
    Boolean? drop_low_coverage
    Boolean? male_reference
    File? reference_cnn
    String cnvkit_vcf_name = "cnvkit.vcf"
    String? segment_filter  # enum ["ampdel" "ci" "cn" "sem"]
  }

  call cb.cnvkitBatch as cnvkitMain {
    input:
    sample_bam=sample_bam,
    sample_bam_bai=sample_bam_bai,
    method=method,
    diagram=diagram,
    scatter_plot=scatter_plot,
    drop_low_coverage=drop_low_coverage,
    male_reference=male_reference,
    reference_fasta=reference,
    reference_cnn=reference_cnn
  }

  call cve.cnvkitVcfExport as cnsToVcf {
    input:
    segment_filter=segment_filter,
    cns_file=cnvkitMain.sample_segmented_ratios,
    male_reference=male_reference,
    cnr_file=cnvkitMain.sample_bin_level_ratios,
    output_name=cnvkit_vcf_name
  }

  if (heatmap) {
    call chm.cnvkitHeatmap as cnvkitHeatmap {
      input:
      cns_file=cnvkitMain.sample_segmented_ratios
    }
  }

  output {
    File? cn_diagram = cnvkitMain.cn_diagram
    File? cn_scatter_plot = cnvkitMain.cn_scatter_plot
    File? cn_heatmap = cnvkitHeatmap.cn_heatmap
    File sample_antitarget_coverage = cnvkitMain.sample_antitarget_coverage
    File sample_target_coverage = cnvkitMain.sample_target_coverage
    File sample_bin_level_ratios = cnvkitMain.sample_bin_level_ratios
    File sample_segmented_ratios = cnvkitMain.sample_segmented_ratios
    File cnvkit_vcf = cnsToVcf.cnvkit_vcf
  }
}
