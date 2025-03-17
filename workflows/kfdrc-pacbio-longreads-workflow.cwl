cwlVersion: v1.2
class: Workflow
id: kfdrc-pacbio-longreads-workflow
label: Kids First DRC PacBio LongReads Workflow
doc: |
  # Kids First Data Resource Center Pacific Biosciences Long Reads Alignment and Variant Calling Workflow

  <p align="center">
    <img src="https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png">
  </p>

  The Kids First Data Resource Center (KFDRC) Pacific Biosciences (PacBio)
  Long Reads Alignment and Variant Calling Workflow is a Common Workflow Language
  (CWL) implementation of various softwares used to take reads information
  generated by PacBio long reads sequencers and generate alignment and variant
  information. This pipeline was made possible thanks to significant software and
  support contributions from both Sentieon and Wang Genomics Lab. For more
  information on our collaborators, check out their websites:
  - Sentieon: https://www.sentieon.com/
  - Wang Genomics Lab: https://wglab.org/

  ## Relevant Softwares and Versions
  - [samtools head](http://www.htslib.org/doc/samtools-head.html): `1.17`
  - [samtools fastq](http://www.htslib.org/doc/samtools-fastq.html): `1.15.1`
  - [Sentieon Minimap2](https://support.sentieon.com/manual/usages/general/?highlight=minimap2#minimap2-binary): `202308.03`
  - [Sentieon util sort](https://support.sentieon.com/manual/usages/general/?highlight=minimap2#util-binary): `202308.03`
  - [Sentieon DNAScope HiFi](https://support.sentieon.com/manual/): `202308.03`
  - [Sentieon LongReadSV](https://support.sentieon.com/manual/): `202308.03`
  - [LongReadSum](https://github.com/WGLab/LongReadSum#readme): `1.2.0`
  - [Sniffles](https://github.com/fritzsedlazeck/Sniffles#readme): `2.0.7`
  - [pbsv](https://github.com/PacificBiosciences/pbsv#readme): `2.9.0`

  ## Input Files
  - `input_unaligned_bam`: The primary input of the PacBio Long Reads Workflow is an unaligned BAM and associated index.
  - `indexed_reference_fasta`: Any suitable human reference genome. KFDRC uses `Homo_sapiens_assembly38.fasta` from Broad Institute.

  ## Output Files
  - `dnascope_small_variants`: BGZIP and TABIX indexed VCF containing small variant calls made by Sentieon DNAScope HiFi on `minimap2_aligned_bam`.
  - `longreadsum_bam_metrics`: BGZIP TAR containing various metrics collected by LongReadSum from the `minimap2_aligned_bam`.
  - `minimap2_aligned_bam`: Indexed BAM file containing reads from the `input_unaligned_bam` aligned to the `indexed_reference_fasta`.
  - `pbsv_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by pbsv on the `minimap2_aligned_bam`.
  - `sniffles_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by Sniffles on the `minimap2_aligned_bam`.
  - `longreadsv_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by Sentieon LongReadSV on the `minimap2_aligned_bam`.

  ## Generalized Process
  1. Read group information (`@RG`) is harvested from the `input_unaligned_bam` header using `samtools head` and `grep`.
  1. If user provides `biospecimen_name` input, that value replaces the `SM` value pulled in the preceeding step.
  1. Align `input_unaligned_bam` to `indexed_reference_fasta` with tohe above `@RG` information using samtools fastq, Sentieon Minimap2, and Sentieon sort.
  1. Generate long reads alignment metrics from the `minimap2_aligned_bam` using LongReadSum.
  1. Generate structural variant calls from the `minimap2_aligned_bam` using pbsv.
  1. Generate structural variant calls from the `minimap2_aligned_bam` using Sniffles.
  1. Generate structural variant calls from the `minimap2_aligned_bam` using Sentieon LongReadSV.
  1. If the reads are not CLR, Generate small variant from the `minimap2_aligned_bam` using Sentieon DNAScope HiFi.

  ## Basic Info
  - [D3b dockerfiles](https://github.com/d3b-center/bixtools)
  - Testing Tools:
      - [Seven Bridges Cavatica Platform](https://cavatica.sbgenomics.com/)
      - [Common Workflow Language reference implementation (cwltool)](https://github.com/common-workflow-language/cwltool/)

  ## References
  - KFDRC AWS s3 bucket: s3://kids-first-seq-data/broad-references/
  - Cavatica: https://cavatica.sbgenomics.com/u/kfdrc-harmonization/kf-references/
  - Broad Institute Goolge Cloud: https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/
requirements:
- class: InlineJavascriptRequirement
- class: MultipleInputFeatureRequirement
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
- class: SubworkflowFeatureRequirement
inputs:
  input_unaligned_bam: {type: 'File', secondaryFiles: [{pattern: '.bai', required: false}],
    doc: "Unaligned BAM file and index containing long reads generated by an ONT sequencer.",
    "sbg:fileTypes": "BAM"}
  indexed_reference_fasta: {type: 'File', secondaryFiles: [{pattern: '.fai', required: true},
      {pattern: '^.dict', required: true}], doc: "Reference fasta and fai index.",
    "sbg:suggestedValue": {class: File, path: 60639014357c3a53540ca7a3, name: Homo_sapiens_assembly38.fasta,
      secondaryFiles: [{class: File, path: 60639016357c3a53540ca7af, name: Homo_sapiens_assembly38.fasta.fai},
        {class: File, path: 60639019357c3a53540ca7e7, name: Homo_sapiens_assembly38.dict}]},
    "sbg:fileTypes": "FASTA, FA"}
  output_basename: {type: 'string', doc: "String to use as basename for all workflow\
      \ outputs."}
  biospecimen_name: {type: 'string?', doc: "String name of the biospecimen. Providing\
      \ this value will override the SM value provided in the input_unaligned_bam."}
  sentieon_license: {type: 'string?', doc: "License server host and port for Sentieon\
      \ tools.", default: "10.5.64.221:8990"}
  sentieon_dnascope_model: { type: 'File', doc: "Sentieon DNAscope model bundle." }
  minimap2_preset:
    type:
    - name: minimap2_preset
      type: enum
      symbols:
      - map-pb
      - asm20
      - ava-pb
      - splice:hq
      - map-hifi
    doc: |-
      Select one of the preset options prepared by the tool authors. Selecting one of
      these options will apply multiple options at the same time. Use presets for the
      following cases:
        - map-pb: PacBio CLR genomic reads
        - map-hifi: PacBio HiFi/CCS genomic reads (v2.19 or later)
        - asm20: PacBio HiFi/CCS genomic reads (v2.18 or earlier)
        - ava-pb: PacBio read overlap
        - splice:hq: Final PacBio Iso-seq or traditional cDNA
  minimap2_cpu: {type: 'int?', default: 36, doc: "CPU Cores for minimap2 to use."}
  minimap2_ram: {type: 'int?', doc: "RAM (in GB) for minimap2 to use."}
  longreadsum_cpu: {type: 'int?', doc: "CPU Cores for longreadsum to use."}
  dnascope_cpu: {type: 'int?', doc: "CPU Cores for dnascope to use."}
  dnascope_ram: {type: 'int?', doc: "RAM (in GB) for dnascope to use."}
  pbsv_cpu: {type: 'int?', doc: "CPU Cores for pbsv to use."}
  pbsv_ram: {type: 'int?', doc: "RAM (in GB) for pbsv to use."}
  sniffles_cpu: {type: 'int?', doc: "CPU Cores for sniffles to use."}
  sniffles_ram: {type: 'int?', doc: "RAM (in GB) for sniffles to use."}
outputs:
  minimap2_aligned_bam: {type: 'File', secondaryFiles: [{pattern: '.bai', required: true}],
    outputSource: clt_pickvalue/outfile, doc: "Aligned BAM file from Minimap2."}
  longreadsum_bam_metrics: {type: 'File', outputSource: tar_longreadsum_dir/output,
    doc: "TAR.GZ file containing longreadsum-generated metrics."}
  dnascope_small_variants: {type: 'File?', secondaryFiles: [{pattern: '.tbi', required: true}],
    outputSource: dnascope/small_variants, doc: "VCF.GZ file and index containing DNAscope-generated\
      \ small variant calls."}
  pbsv_strucutural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi', required: true}],
    outputSource: bgzip_tabix_index_pbsv_vcf/output, doc: "VCF.GZ file and index containing\
      \ pbsv-generated SV calls."}
  sniffles_structural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi',
        required: true}], outputSource: sniffles/output_vcf, doc: "VCF.GZ file and\
      \ index containing sniffles-generated SV calls."}
  longreadsv_structural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi',
        required: true}], outputSource: dnascope/structural_variants, doc: "VCF.GZ\
      \ file and index containing Sentieon LongReadSV-generated SV calls."}
steps:
  samtools_split:
    run: ../tools/samtools_split.cwl
    in:
      input_reads: input_unaligned_bam
      cpu: minimap2_cpu
    out: [output]
  samtools_head_rg:
    run: ../tools/samtools_head.cwl
    scatter: [input_bam]
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    in:
      input_bam: samtools_split/output
      line_filter:
        valueFrom: "^@RG"
    out: [header_file]
  update_rg_sm:
    run: ../tools/clt_preparerg.cwl
    scatter: [rg]
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    in:
      rg: samtools_head_rg/header_file
      sample: biospecimen_name
    out: [rg_str, sample_name]
  minimap2:
    run: ../tools/sentieon_minimap2.cwl
    scatter: [in_reads, read_group_line]
    scatterMethod: dotproduct
    in:
      in_reads:
        source: samtools_split/output
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
      soft_clipping:
        valueFrom: |
          $(1 == 1)
      cpu_per_job: minimap2_cpu
      mem_per_job: minimap2_ram
    out: [out_alignments]
  sentieon_readwriter_merge_sort:
    run: ../tools/sentieon_ReadWriter.cwl
    when: $(inputs.input_bam.length > 1)
    in:
      input_bam: minimap2/out_alignments
      reference: indexed_reference_fasta
      sentieon_license: sentieon_license
      output_file_name:
        source: output_basename
        valueFrom: $(self).minimap2.bam
      cpu_per_job: minimap2_cpu
    out: [output_reads]
  clt_pickvalue:
    run: ../tools/clt_pickvalue.cwl
    in:
      infile:
        source: [sentieon_readwriter_merge_sort/output_reads, minimap2/out_alignments]
        valueFrom: |
          $(self[0] == null ? self[1][0] : self[0])
      cpu: minimap2_cpu
    out: [outfile]
  longreadsum:
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    run: ../tools/longreadsum.cwl
    in:
      input_type:
        valueFrom: "bam"
      input_file: clt_pickvalue/outfile
      output_dir: output_basename
      output_basename: output_basename
      log:
        valueFrom: "test.log"
      log_level:
        valueFrom: "2"
      cpu: longreadsum_cpu
    out: [outputs]
  tar_longreadsum_dir:
    run: ../tools/tar.cwl
    in:
      output_filename:
        source: output_basename
        valueFrom: $(self).longreadsum.tar.gz
      input_dir: longreadsum/outputs
    out: [output]
  dnascope:
    run: ../tools/sentieon_DNAscope_LongRead_CLI.cwl
    in:
      sentieon_license: sentieon_license
      reference: indexed_reference_fasta
      input_bam: 
        source: [clt_pickvalue/outfile]
        linkMerge: merge_flattened
      model_bundle: sentieon_dnascope_model
      tech:
        valueFrom: "HiFi"
      output_vcf:
        source: output_basename
        valueFrom: $(self).dnascope.vcf.gz
      skip-mosdepth:
        default: true
      skip-small-variants:
        source: minimap2_preset
        valueFrom: $(self != "map-hifi")
      skip-svs:
        source: minimap2_preset
        valueFrom: $(self != "map-hifi")
      cpu_per_job: dnascope_cpu
      mem_per_job: dnascope_ram
    out: [small_variants, structural_variants]
  pbsv_discover:
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    run: ../tools/pbsv_discover.cwl
    in:
      input_bam: clt_pickvalue/outfile
      output_filename:
        source: output_basename
        valueFrom: $(self).pbsv.svsig.gz
      hifi_preset:
        source: minimap2_preset
        valueFrom: |
          $(self == "map-hifi")
      cpu: pbsv_cpu
      ram: pbsv_ram
    out: [output_svsig]
  pbsv_call:
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    run: ../tools/pbsv_call.cwl
    in:
      reference_fasta: indexed_reference_fasta
      input_svsig: pbsv_discover/output_svsig
      output_filename:
        source: output_basename
        valueFrom: $(self).pbsv.vcf
      hifi_preset:
        source: minimap2_preset
        valueFrom: |
          $(self == "map-hifi")
      cpu: pbsv_cpu
      ram: pbsv_ram
    out: [output_vcf]
  bgzip_tabix_index_pbsv_vcf:
    run: ../tools/bgzip_tabix_index.cwl
    in:
      input_vcf: pbsv_call/output_vcf
      cpu: pbsv_cpu
    out: [output]
  sniffles:
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    run: ../tools/sniffles.cwl
    in:
      input_bam:
        source: clt_pickvalue/outfile
        valueFrom: $([self])
      vcf_output_filename:
        source: output_basename
        valueFrom: $(self).sniffles.vcf.gz
      reference_fasta: indexed_reference_fasta
      sample_id:
        source: update_rg_sm/sample_name
        valueFrom: $(self[0])
      cpu: sniffles_cpu
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
- INDEL
- LONG
- LONGREADS
- LONGREADSUM
- METRICS
- NANOCALLER
- PACBIO
- PACIFIC
- PBMM2
- PBSV
- SENTIEON
- SNIFFLES
- SNP
- SOMATIC
- STRUCTURAL
- SV
- VARIANT
- WGS
- WXS
"sbg:links":
- id: 'https://github.com/kids-first/kf-longreads-workflow/releases/tag/v2.1.0'
  label: github-release
