version 1.0

task cnvkitHeatmap {
  input {
    File cns_file
  }

  Int space_needed_gb = 10 + round(2*size([cns_file], "GB"))
  runtime {
    preemptible: 1
    maxRetries: 2
    memory: "4GB"
    docker: "mgibio/cnvkit:0.9.9"
    disks: "local-disk ~{space_needed_gb} HDD"
  }

  command <<<
    name="~{basename(cns_file, ".cns")}-heatmap.pdf"
    /usr/bin/python3 /usr/local/bin/cnvkit.py heatmap \
    ~{cns_file} \
    -o "$name"
  >>>

  output {
    File cn_heatmap = basename(cns_file, ".cns") + "-heatmap.pdf"
  }
}
