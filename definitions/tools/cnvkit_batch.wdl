version 1.0

task cnvkitBatch {
  input {
    File sample_bam
    File sample_bam_bai
    File? bait_intervals
    File? access
    File? normal_bam
    File? normal_bam_bai
    File? reference_fasta  # fasta or CNN must exist
    File? reference_cnn    # fasta or CNN must exist
    String method = "hybrid"  # enum [hybrid, amplicon, wgs]
    Boolean diagram = false
    Boolean scatter_plot = false
    Boolean drop_low_coverage = false
    Boolean male_reference = false
    Int? target_average_size
  }


  Int size_needed_gb = 10 + round(size([sample_bam, bait_intervals, access, normal_bam, reference_fasta, reference_cnn], "GB") * 2)
  runtime {
    preemptible: 1
    maxRetries: 2
    memory: "8GB"
    cpu: 1
    # We use a forked cnvkit so we can get access to root privileges
    # which let us write files at /cromwell_root/
    docker: "mgibio/cnvkit:0.9.9"
    disks: "local-disk ~{size_needed_gb} HDD"
  }

  command <<<
    # touch each bai to ensure they have a timestamp after the bam
    # Avoids a reindex which has thrown exceptions
    # this is why we need root privileges
    touch ~{sample_bam_bai}
    touch ~{normal_bam_bai}

    if ~{defined(normal_bam)}; then
      REF="--normal ~{normal_bam} --fasta ~{reference_fasta}"
    else
      REF="--reference ~{reference_cnn}"
    fi
    /usr/bin/python3 /usr/local/bin/cnvkit.py batch \
    ~{sample_bam} $REF \
    ~{if defined(bait_intervals) then "--targets ~{bait_intervals}" else ""} \
    ~{if defined(access) then "--access ~{access}" else ""} \
    --method ~{method} \
    ~{if diagram then "--diagram" else ""} \
    ~{if scatter_plot then "--scatter" else ""} \
    ~{if drop_low_coverage then "--drop-low-coverage" else ""} \
    ~{if male_reference then "--male-reference" else ""} \
    ~{if defined(target_average_size) then "--target-avg-size ~{target_average_size}" else ""}
  >>>

  String intervals_base = basename(if defined(bait_intervals) then "~{bait_intervals}" else "", ".interval_list")
  String normal_base = basename(if defined(normal_bam) then "~{normal_bam}" else "", ".bam")
  output {
    File? intervals_antitarget = intervals_base + ".antitarget.bed"
    File? intervals_target = intervals_base + ".target.bed"
    File? normal_antitarget_coverage = normal_base + ".antitargetcoverage.cnn"
    File? normal_target_coverage = normal_base + ".targetcoverage.cnn"
    File? reference_coverage = "reference.cnn"
    File? cn_diagram = basename(sample_bam, ".bam") + "-diagram.pdf"
    File? cn_scatter_plot = basename(sample_bam, ".bam") + "-scatter.png"
    File sample_antitarget_coverage = basename(sample_bam, ".bam") + ".antitargetcoverage.cnn"
    File sample_target_coverage = basename(sample_bam, ".bam") + ".targetcoverage.cnn"
    File sample_bin_level_ratios = basename(sample_bam, ".bam") + ".cnr"
    File sample_segmented_ratios = basename(sample_bam, ".bam") + ".cns"
  }
}


workflow wf {
  input {
    File sample_bam
    File sample_bam_bai
    File? bait_intervals
    File? access
    File? normal_bam
    File? normal_bam_bai
    File? reference_fasta  # fasta or CNN must exist
    File? reference_cnn    # fasta or CNN must exist
    String method = "hybrid"  # enum [hybrid, amplicon, wgs]
    Boolean diagram = false
    Boolean scatter_plot = false
    Boolean drop_low_coverage = false
    Boolean male_reference = false
    Int? target_average_size
  }

  call cnvkitBatch {
    input:
    sample_bam=sample_bam,
    sample_bam_bai=sample_bam_bai,
    bait_intervals=bait_intervals,
    access=access,
    normal_bam=normal_bam,
    normal_bam_bai=normal_bam_bai,
    reference_fasta=reference_fasta,
    reference_cnn=reference_cnn,
    method=method,
    diagram=diagram,
    scatter_plot=scatter_plot,
    drop_low_coverage=drop_low_coverage,
    male_reference=male_reference,
    target_average_size=target_average_size
  }
}
