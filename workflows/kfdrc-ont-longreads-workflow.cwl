cwlVersion: v1.2
class: Workflow
id: kfdrc-ont-longreads-workflow
label: Kids First DRC ONT LongReads Workflow
doc: |
  # Kids First Data Resource Center ONT LongReads Workflows

  ![data service logo](https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png)

requirements:
- class: InlineJavascriptRequirement
- class: MultipleInputFeatureRequirement
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
- class: SubworkflowFeatureRequirement

inputs:
  input_unaligned_bam: { type: 'File', secondaryFiles: [{ pattern: '.bai', required: true }], doc: "" }
  indexed_reference_fasta: { type: 'File', secondaryFiles: [{ pattern: '.fai', required: true }], doc: "" }
  output_basename: { type: 'string', doc: "String to use as basename for all workflow outputs." }
  biospecimen_name: { type: 'string?', doc: "String name of the biospecimen. Providing this value will override the SM value provided in the @RG line of the input_unaligned_bam header." }
  sentieon_license: { type: 'string', doc: "License server host and port for Sentieon tools." }

  # Minimap2 Alignment Options
  minimap2_preset:
    type:
    - name: minimap2_preset
      type: enum
      symbols:
      - map-pb
      - map-ont
      - asm5
      - asm10
      - asm20
      - ava-pb
      - ava-ont
      - splice
      - splice:hq
      - sr
      - map-hifi
    doc: |-
      Select one of the preset options prepared by the tool authors. Selecting one of
      these options will apply multiple options at the same time.

  # NanoCaller WGS Options
  nanocaller_preset:
    type:
      type: enum
      name: nanocaller_preset
      symbols: ["ont","ul_ont","ul_ont_extreme","ccs","clr"]
    doc: |
      Apply recommended preset values for SNP and Indel calling parameters, options
      are 'ont', 'ul_ont', 'ul_ont_extreme', 'ccs' and 'clr'. 'ont' works well for
      any type of ONT sequencing datasets. However, use 'ul_ont' if you have several
      ultra-long ONT reads up to 100kbp long, and 'ul_ont_extreme' if you have
      several ultra-long ONT reads up to 300kbp long. For PacBio CCS (HiFi) and CLR
      reads, use 'ccs'and 'clr' respectively. Presets are described in detail here:
      github.com/WGLab/NanoCaller/blob/master/docs/Usage.md#preset-options.
  nanocaller_snp_model: { type: 'string?', doc: "NanoCaller SNP model to be used" }
  nanocaller_neighbor_threshold: { type: 'string?', doc: "SNP neighboring site thresholds with lower and upper bounds seperated by comma, for Nanopore reads '0.4,0.6' is recommended, for PacBio CCS anc CLR reads '0.3,0.7' and '0.3,0.6' are recommended respectively" }
  nanocaller_indel_model: { type: 'string?', doc: "NanoCaller indel model to be used" }
  nanocaller_ins_threshold: { type: 'float?', doc: "Insertion Threshold" }
  nanocaller_del_threshold: { type: 'float?', doc: "Deletion Threshold" }
  nanocaller_win_size: { type: 'int?', doc: "Size of the sliding window in which the number of indels is counted to determine indel candidate site.  Only indels longer than 2bp are counted in this window. Larger window size can increase recall, but use a maximum of 50 only" }
  nanocaller_small_win_size: { type: 'int?', doc: "Size of the sliding window in which indel frequency is determined for small indels" }

  # CuteSV SV Calling Options
  cutesv_max_cluster_bias_DEL: { type: 'int?', default: 100, doc: "Maximum distance to cluster read together for deletion." }
  cutesv_diff_ratio_merging_DEL: { type: 'float?', default: 0.3,  doc: "Do not merge breakpoints with basepair identity more than the ratio of default for deletion." }

  # Resource Control
  minimap2_cores: { type: 'int?', doc: "CPU Cores for minimap2 to use." }
  minimap2_ram: { type: 'int?', doc: "RAM (in GB) for minimap2 to use." }
  nanocaller_cores: { type: 'int?', doc: "CPU Cores for nanocaller to use." }
  nanocaller_ram: { type: 'int?', doc: "RAM (in GB) for nanocaller to use." }
  longreadsum_cores: { type: 'int?', doc: "CPU Cores for longreadsum to use." }
  cutesv_cores: { type: 'int?', doc: "CPU Cores for cutesv to use." }
  cutesv_ram: { type: 'int?', doc: "RAM (in GB) for cutesv to use." }
  sniffles_cores: { type: 'int?', doc: "CPU Cores for sniffles to use." }
  sniffles_ram: { type: 'int?', doc: "RAM (in GB) for sniffles to use." }

outputs:
  minimap2_aligned_bam: { type: 'File', secondaryFiles: [{ pattern: '.bai', required: true }], outputSource: minimap2/out_alignments, doc: "Aligned BAM file from Minimap2." }
  nanocaller_small_variants: { type: 'File', secondaryFiles: [{ pattern: '.tbi', required: true }], outputSource: nanocaller_wgs/final_vcf, doc: "VCF.GZ file and index containing NanoCaller-gerated small variant calls." }
  longreadsum_bam_metrics: { type: 'File', outputSource: tar_longreadsum_dir/output, doc: "TAR.GZ file containing longreadsum-generated metrics." }
  cutesv_structural_variants: { type: 'File', secondaryFiles: [{ pattern: '.tbi', required: true }], outputSource: bgzip_tabix_index_cutesv_vcf/output, doc: "VCF.GZ file and index containing cutesv-generated SV calls." }
  sniffles_structural_variants: { type: 'File', secondaryFiles: [{ pattern: '.tbi', required: true }], outputSource: sniffles/output_vcf, doc: "VCF.GZ file and index containing sniffles-generated SV calls." }

steps:
  samtools_head_rg:
    run: ../tools/samtools_head.cwl
    in:
      input_bam: input_unaligned_bam 
      line_filter:
        valueFrom: "@RG"
    out: [header_file]

  update_rg_sm:
    run: ../tools/expression_preparerg.cwl
    in:
      rg: samtools_head_rg/header_file
      sample: biospecimen_name 
    out: [rg_str]
 
  minimap2:
    run: ../tools/sentieon_minimap2_bam_input.cwl
    in:
      in_reads:
        source: input_unaligned_bam 
        valueFrom: $([self])
      reference: indexed_reference_fasta
      input_type:
        valueFrom: 'uBAM'
      output_basename:
        source: output_basename
        valueFrom: $(self).minimap2
      sentieon_license: sentieon_license
      preset_option: minimap2_preset
      read_group_line: update_rg_sm/rg_str
      cpu_per_job: minimap2_cores
      mem_per_job: minimap2_ram
    out: [out_alignments]

  nanocaller_wgs:
    run: ../tools/nanocaller.cwl
    in:
      wgs_mode:
        valueFrom: $(1 == 1)
      input_bam: minimap2/out_alignments
      indexed_reference_fasta: indexed_reference_fasta
      output_basename:
        source: output_basename
        valueFrom: $(self).nanocaller
      preset: nanocaller_preset
      snp_model: nanocaller_snp_model
      neighbor_threshold: nanocaller_neighbor_threshold
      indel_model: nanocaller_indel_model
      ins_threshold: nanocaller_ins_threshold
      del_threshold: nanocaller_del_threshold
      win_size: nanocaller_win_size
      small_win_size: nanocaller_small_win_size
      cores: nanocaller_cores
      ram: nanocaller_ram
    out: [snps_unphased_vcf, snps_phased_vcf, indels_vcf, final_vcf, fail_logs, fail_cmds, logs]

  longreadsum:
    run: ../tools/longreadsum.cwl
    in:
      input_type:
        valueFrom: "bam"
      input_file: minimap2/out_alignments
      output_dir:
        source: output_basename
        valueFrom: $(self).longreadsum
      output_basename:
        source: output_basename
        valueFrom: $(self).longreadsum.
      cores: longreadsum_cores
    out: [outputs]

  tar_longreadsum_dir:
    run: ../tools/tar.cwl
    in:
      output_filename:
        source: output_basename
        valueFrom: $(self).longreadsum.tar.gz
      input_dir: longreadsum/outputs
    out: [output]

  cutesv:
    run: ../tools/cutesv.cwl
    in:
      input_bam: minimap2/out_alignments
      reference_fasta: indexed_reference_fasta
      output_filename:
        source: output_basename
        valueFrom: $(self).cutesv.vcf
      max_cluster_bias_DEL: cutesv_max_cluster_bias_DEL
      diff_ratio_merging_DEL: cutesv_diff_ratio_merging_DEL
      cores: cutesv_cores
      ram: cutesv_ram
    out: [output_vcf]

  bgzip_tabix_index_cutesv_vcf:
    run: ../tools/bgzip_tabix_index.cwl
    in:
      input_vcf: cutesv/output_vcf
      cores: cutesv_cores
    out: [output]

  sniffles:
    run: ../tools/sniffles.cwl
    in:
      input_bam:
        source: minimap2/out_alignments
        valueFrom: $([self])
      vcf_output_filename:
        source: output_basename
        valueFrom: $(self).sniffles.vcf.gz
      reference_fasta: indexed_reference_fasta
      cores: sniffles_cores
      ram: sniffles_ram
    out: [output_vcf, output_snf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: "sbg:maxNumberOfParallelInstances"
  value: 2
"sbg:license": Apache License 2.0
"sbg:publisher": KFDRC
"sbg:categories":
- ALIGNMENT
- DNA
- WGS
- WXS
"sbg:links":
- id: ''
  label: github-release
