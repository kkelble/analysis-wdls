version 1.0

import "alignment_exome.wdl" as ae
import "types.wdl"  # !UnusedImport

import "tools/interval_list_expand.wdl" as ile
import "subworkflows/joint_genotype_germline_detect_variants.wdl" as gdv
import "tools/bam_to_cram.wdl" as btc
import "tools/index_cram.wdl" as ic

workflow germlineExome {
  input {
    File reference
    File reference_fai
    File reference_dict
    File reference_alt
    File reference_amb
    File reference_ann
    File reference_bwt
    File reference_pac
    File reference_0123
    Array[SampleData] samples
    TrimmingOptions? trimming
    Array[File] bqsr_known_sites
    Array[File] bqsr_known_sites_tbi
    File bait_intervals
    File target_intervals
    Int target_interval_padding = 100
    Array[LabelledFile] per_base_intervals
    Array[LabelledFile] per_target_intervals
    Array[LabelledFile] summary_intervals
    File omni_vcf
    File omni_vcf_tbi
    String picard_metric_accumulation_level
    Array[String] gvcf_gq_bands
    Array[Array[String]] intervals
    Int? ploidy
    File vep_cache_dir_zip
    String vep_ensembl_assembly
    String vep_ensembl_version
    String vep_ensembl_species
    Array[String]? vep_plugins
    File? synonyms_file
    Boolean? annotate_coding_only
    Int? qc_minimum_mapping_quality
    Int? qc_minimum_base_quality
    Array[VepCustomAnnotation] vep_custom_annotations
    Array[String]? variants_to_table_fields
    Array[String]? variants_to_table_genotype_fields
    Array[String]? vep_to_table_fields
    Float germline_filter_gnomAD_maximum_population_allele_frequency
    String? coding_filter
  }

  scatter (sample in samples) {
    call ae.alignmentExome as alignmentAndQc {
      input:
      reference=reference,
      reference_fai=reference_fai,
      reference_dict=reference_dict,
      reference_alt=reference_alt,
      reference_amb=reference_amb,
      reference_ann=reference_ann,
      reference_bwt=reference_bwt,
      reference_pac=reference_pac,
      reference_0123=reference_0123,
      sequence=sample.sequences,
      final_name=sample.sample_name,
      trimming=trimming,
      bqsr_known_sites=bqsr_known_sites,
      bqsr_known_sites_tbi=bqsr_known_sites_tbi,
      bait_intervals=bait_intervals,
      target_intervals=target_intervals,
      per_base_intervals=per_base_intervals,
      per_target_intervals=per_target_intervals,
      summary_intervals=summary_intervals,
      omni_vcf=omni_vcf,
      omni_vcf_tbi=omni_vcf_tbi,
      picard_metric_accumulation_level=picard_metric_accumulation_level,
      qc_minimum_mapping_quality=qc_minimum_mapping_quality,
      qc_minimum_base_quality=qc_minimum_base_quality
    }
  } #output is bam, bam_bai, and verify_bam_id_metrics

  call ile.intervalListExpand as padTargetIntervals {
    input:
    interval_list=target_intervals,
    roi_padding=target_interval_padding
  }

  #make verify bam id metrics usuable input to detect variants
  scatter (qc in alignmentAndQc.qc_metrics) {
    File verify_bam_id_metric = select_first([qc.verify_bam_id_metrics])
  }

  #call detectVariants with the array of bam files from alignment and qc step
  call gdv.jointGermlineDetectVariants as detectVariants {
    input:
    reference=reference,
    reference_fai=reference_fai,
    reference_dict=reference_dict,
    bams=alignmentAndQc.bam,
    bais=alignmentAndQc.bam_bai,
    gvcf_gq_bands=gvcf_gq_bands,
    intervals=intervals,
    verify_bam_id_metrics=verify_bam_id_metric,
    ploidy=ploidy,
    vep_cache_dir_zip=vep_cache_dir_zip,
    synonyms_file=synonyms_file,
    annotate_coding_only=annotate_coding_only,
    limit_variant_intervals=padTargetIntervals.expanded_interval_list,
    vep_ensembl_assembly=vep_ensembl_assembly,
    vep_ensembl_version=vep_ensembl_version,
    vep_ensembl_species=vep_ensembl_species,
    vep_plugins=vep_plugins,
    vep_to_table_fields=vep_to_table_fields,
    vep_custom_annotations=vep_custom_annotations,
    variants_to_table_fields=variants_to_table_fields,
    variants_to_table_genotype_fields=variants_to_table_genotype_fields,
    germline_filter_gnomAD_maximum_population_allele_frequency=germline_filter_gnomAD_maximum_population_allele_frequency,
    coding_filter=coding_filter
  }

  scatter (bam in alignmentAndQc.bam) {
    call btc.bamToCram {
      input:
      bam=bam,
      reference=reference,
      reference_fai=reference_fai,
      reference_dict=reference_dict
    }
  }

  scatter (cram in bamToCram.cram) {
    call ic.indexCram {
      input: cram=cram
    }
  }

  output {
    Array[File] cram = indexCram.indexed_cram
    Array[File] cram_crai = indexCram.indexed_cram_crai
    Array[File] mark_duplicates_metrics = alignmentAndQc.mark_duplicates_metrics
    Array[QCMetrics] qc_metrics = alignmentAndQc.qc_metrics
    File raw_vcf = detectVariants.raw_vcf
    File raw_vcf_tbi = detectVariants.raw_vcf_tbi
    File final_vcf = detectVariants.final_vcf
    File final_vcf_tbi = detectVariants.final_vcf_tbi
    File filtered_vcf = detectVariants.filtered_vcf
    File filtered_vcf_tbi = detectVariants.filtered_vcf_tbi
    File vep_summary = detectVariants.vep_summary
    File final_tsv = detectVariants.final_tsv
    File filtered_tsv = detectVariants.filtered_tsv
  }
}

