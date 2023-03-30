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
  information.

  ## Relevant Softwares and Versions
  - [pbmm2](https://github.com/PacificBiosciences/pbmm2#readme): `1.7.0`
  - [Sentieon DNAScope HiFi](https://support.sentieon.com/manual/): `202112.01`
  - [LongReadSum](https://github.com/WGLab/LongReadSum#readme): [Unversioned commit](https://github.com/WGLab/LongReadSum/commit/125cd78e49bc4a402d289baa687acf35b555d3e5)
  - [Sniffles](https://github.com/fritzsedlazeck/Sniffles#readme): `2.0.3`
  - [pbsv](https://github.com/PacificBiosciences/pbsv#readme): `2.8.0`

  ## Input Files
  - `input_unaligned_bam`: The primary input of the PacBio Long Reads Workflow is an unaligned BAM and associated index.
  - `indexed_reference_fasta`: Any suitable human reference genome. KFDRC uses `Homo_sapiens_assembly38.fasta` from Broad Institute.

  ## Output Files
  - `dnascope_small_variants`: BGZIP and TABIX indexed VCF containing small variant calls made by Sentieon DNAScope HiFi on `pbmm2_aligned_bam`.
  - `longreadsum_bam_metrics`: BGZIP TAR containing various metrics collected by LongReadSum from the `pbmm2_aligned_bam`.
  - `pbmm2_aligned_bam`: Indexed BAM file containing reads from the `input_unaligned_bam` aligned to the `indexed_reference_fasta`.
  - `pbsv_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by pbsv on the `pbmm2_aligned_bam`.
  - `sniffles_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by Sniffles on the `pbmm2_aligned_bam`.

  ## Generalized Process
  1. Align `input_unaligned_bam` to `indexed_reference_fasta` using pbmm2.
  1. Generate long reads alignment metrics from the `pbmm2_aligned_bam` using LongReadSum.
  1. Generate structural variant calls from the `pbmm2_aligned_bam` using pbsv.
  1. Generate structural variant calls from the `pbmm2_aligned_bam` using Sniffles.
  1. Generate small variant from the `pbmm2_aligned_bam` using Sentieon DNAScope HiFi.

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
  input_unaligned_bam: {type: 'File', secondaryFiles: [{pattern: '.bai', required: true}],
    doc: "Unaligned BAM file and index containing long reads generated by an ONT sequencer.",
    "sbg:fileTypes": "BAM"}
  indexed_reference_fasta: {type: 'File', secondaryFiles: [{pattern: '.fai', required: true}],
    doc: "Reference fasta and fai index.", "sbg:suggestedValue": {class: File, path: 60639014357c3a53540ca7a3,
      name: Homo_sapiens_assembly38.fasta, secondaryFiles: [{class: File, path: 60639016357c3a53540ca7af,
          name: Homo_sapiens_assembly38.fasta.fai}]}, "sbg:fileTypes": "FASTA, FA"}
  output_basename: {type: 'string', doc: "String to use as basename for all workflow\
      \ outputs."}
  biospecimen_name: {type: 'string?', doc: "String name of the biospecimen. Providing\
      \ this value will override the SM value provided in the input_unaligned_bam."}
  sentieon_license: {type: 'string?', doc: "License server host and port for Sentieon\
      \ tools.", default: "10.5.64.221:8990"}
  pbmm2_preset:
    type:
    - 'null'
    - type: enum
      name: preset
      symbols: ["SUBREAD", "CCS", "HIFI", "ISOSEQ", "UNROLLED"]
    doc: |
      Set alignment mode. See below for preset parameter details.
      Alignment modes of --preset:
          SUBREAD     : -k 19 -w 10    -o 5 -O 56 -e 4 -E 1 -A 2 -B 5 -z 400 -Z 50  -r 2000   -L 0.5 -g 5000
          CCS or HiFi : -k 19 -w 10 -u -o 5 -O 56 -e 4 -E 1 -A 2 -B 5 -z 400 -Z 50  -r 2000   -L 0.5 -g 5000
          ISOSEQ      : -k 15 -w 5  -u -o 2 -O 32 -e 1 -E 0 -A 1 -B 2 -z 200 -Z 100 -r 200000 -L 0.5 -g 2000 -C 5 -G 200000
          UNROLLED    : -k 15 -w 15    -o 2 -O 32 -e 1 -E 0 -A 1 -B 2 -z 200 -Z 100 -r 2000   -L 0.5 -g 10000
  pbsv_hifi_preset: {type: 'boolean?', doc: "Use options optimized for HiFi/CCS reads:\
      \ -y 97"}

  # Resource Control
  pbmm2_cores: {type: 'int?', doc: "CPU Cores for pbmm2 to use."}
  pbmm2_ram: {type: 'int?', doc: "RAM (in GB) for pbmm2 to use."}
  longreadsum_cores: {type: 'int?', doc: "CPU Cores for longreadsum to use."}
  dnascope_cores: {type: 'int?', doc: "CPU Cores for dnascope to use."}
  dnascope_ram: {type: 'int?', doc: "RAM (in GB) for dnascope to use."}
  pbsv_cores: {type: 'int?', doc: "CPU Cores for pbsv to use."}
  pbsv_ram: {type: 'int?', doc: "RAM (in GB) for pbsv to use."}
  sniffles_cores: {type: 'int?', doc: "CPU Cores for sniffles to use."}
  sniffles_ram: {type: 'int?', doc: "RAM (in GB) for sniffles to use."}
  longreadsv_cores: {type: 'int?', doc: "CPU Cores for Sentieon LongReadSV to use." }
  longreadsv_ram: {type: 'int?', doc: "RAM (in GB) for Sentieon LongReadSV to use." }

outputs:
  pbmm2_aligned_bam: {type: 'File', secondaryFiles: [{pattern: '.bai', required: true}],
    outputSource: pbmm2_align/output_bam, doc: "BAM file and index generated by pbmm2"}
  longreadsum_bam_metrics: {type: 'File', outputSource: tar_longreadsum_dir/output,
    doc: "TAR.GZ file containing longreadsum-generated metrics."}
  dnascope_small_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi', required: true}],
    outputSource: dnascope/output_vcf, doc: "VCF.GZ file and index containing DNAscope-generated\
      \ small variant calls."}
  pbsv_strucutural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi', required: true}],
    outputSource: bgzip_tabix_index_pbsv_vcf/output, doc: "VCF.GZ file and index containing\
      \ pbsv-generated SV calls."}
  sniffles_structural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi',
        required: true}], outputSource: sniffles/output_vcf, doc: "VCF.GZ file and\
      \ index containing sniffles-generated SV calls."}
  longreadsv_structural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi', required: true}], outputSource: sentieon_longreadsv/output_vcf, doc: "VCF.GZ file and index containing Sentieon LongReadSV-generated SV calls."}

steps:
  pbmm2_align:
    run: ../tools/pbmm2_align.cwl
    in:
      reference: indexed_reference_fasta
      input_reads: input_unaligned_bam
      output_filename:
        source: output_basename
        valueFrom: $(self).pbmm2.bam
      sort:
        valueFrom: $(1 == 1)
      preset: pbmm2_preset
      sample_name: biospecimen_name
      cores: pbmm2_cores
      ram: pbmm2_ram
    out: [output_bam]

  longreadsum:
    run: ../tools/longreadsum.cwl
    in:
      input_type:
        valueFrom: "bam"
      input_file: pbmm2_align/output_bam
      output_dir: output_basename
      output_basename: output_basename
      cores: longreadsum_cores
    out: [outputs]

  tar_longreadsum_dir:
    run: ../tools/tar.cwl
    in:
      output_filename:
        source: output_basename
        valueFrom: $(self).tar.gz
      input_dir: longreadsum/outputs
    out: [output]

  dnascope:
    run: ../tools/sentieon_DNAscope_LongRead.cwl
    in:
      sentieon_license: sentieon_license
      reference: indexed_reference_fasta
      input_bam: pbmm2_align/output_bam
      output_file_name:
        source: output_basename
        valueFrom: $(self).dnascope.vcf.gz
      cpu_per_job: dnascope_cores
      mem_per_job: dnascope_ram
    out: [output_vcf]

  pbsv_discover:
    run: ../tools/pbsv_discover.cwl
    in:
      input_bam: pbmm2_align/output_bam
      output_filename:
        source: output_basename
        valueFrom: $(self).pbsv.svsig.gz
      hifi_preset: pbsv_hifi_preset
      cores: pbsv_cores
      ram: pbsv_ram
    out: [output_svsig]

  pbsv_call:
    run: ../tools/pbsv_call.cwl
    in:
      reference_fasta: indexed_reference_fasta
      input_svsig: pbsv_discover/output_svsig
      output_filename:
        source: output_basename
        valueFrom: $(self).pbsv.vcf
      hifi_preset: pbsv_hifi_preset
      cores: pbsv_cores
      ram: pbsv_ram
    out: [output_vcf]

  bgzip_tabix_index_pbsv_vcf:
    run: ../tools/bgzip_tabix_index.cwl
    in:
      input_vcf: pbsv_call/output_vcf
      cores: pbsv_cores
    out: [output]

  sniffles:
    run: ../tools/sniffles.cwl
    in:
      input_bam:
        source: pbmm2_align/output_bam
        valueFrom: $([self])
      vcf_output_filename:
        source: output_basename
        valueFrom: $(self).sniffles.vcf.gz
      reference_fasta: indexed_reference_fasta
      cores: sniffles_cores
      ram: sniffles_ram
    out: [output_vcf, output_snf]

  sentieon_longreadsv:
    run: ../tools/sentieon_LongReadSV.cwl
    in:
      sentieon_license: sentieon_license
      reference: indexed_reference_fasta
      input_bam: pbmm2_align/output_bam
      platform:
        valueFrom: "PacBioHiFi"
      output_file_name:
        source: output_basename
        valueFrom: $(self).longreadsv.vcf.gz
      cpu: longreadsv_cores
      ram: longreadsv_ram
    out: [output_vcf]

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
- id: 'https://github.com/kids-first/kf-longreads-workflow/releases/tag/v1.0.0'
  label: github-release
