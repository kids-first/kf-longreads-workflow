cwlVersion: v1.2
class: Workflow
id: kfdrc-ont-longreads-workflow
label: Kids First DRC ONT LongReads Workflow
doc: |
  # Kids First Data Resource Center Oxford Nanopore Technologies Long Reads Alignment and Variant Calling Workflow

  <p align="center">
    <img src="https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png">
  </p>

  The Kids First Data Resource Center (KFDRC) Oxford Nanopore Technologies (ONT)
  Long Reads Alignment and Variant Calling Workflow is a Common Workflow Language
  (CWL) implementation of various softwares used to take reads information
  generated by ONT long reads sequencers and generate alignment and variant
  information. This pipeline was made possible thanks to significant software and
  support contributions from both Sentieon and Wang Genomics Lab. For more
  information on our collaborators, check out their websites:
  - Sentieon: https://www.sentieon.com/
  - Wang Genomics Lab: https://wglab.org/

  ## Relevant Softwares and Versions
  - [samtools head](http://www.htslib.org/doc/samtools-head.html): `1.17`
  - [samtools fastq](http://www.htslib.org/doc/samtools-fastq.html): `1.15.1`
  - [Sentieon Minimap2](https://support.sentieon.com/manual/usages/general/?highlight=minimap2#minimap2-binary): `202112.01`
  - [Sentieon util sort](https://support.sentieon.com/manual/usages/general/?highlight=minimap2#util-binary): `202112.01`
  - [Sentieon LongReadSV](https://support.sentieon.com/manual/): `202112.06`
  - [LongReadSum](https://github.com/WGLab/LongReadSum#readme): `1.2.0`
  - [Sniffles](https://github.com/fritzsedlazeck/Sniffles#readme): `2.0.7`
  - [CuteSV](https://github.com/tjiangHIT/cuteSV#readme): `2.0.3`
  - [Nanocaller](https://github.com/WGLab/NanoCaller#readme): `3.2.0`

  ## Input Files
  - `input_unaligned_bam`: The primary input of the ONT Long Reads Workflow is an unaligned BAM and associated index.
  - `indexed_reference_fasta`: Any suitable human reference genome. KFDRC uses `Homo_sapiens_assembly38.fasta` from Broad Institute.

  ## Output Files
  - `cutesv_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by CuteSV on the `minimap2_aligned_bam`.
  - `longreadsum_bam_metrics`: BGZIP TAR containing various metrics collected by LongReadSum from the `minimap2_aligned_bam`.
  - `minimap2_aligned_bam`: Indexed BAM file containing reads from the `input_unaligned_bam` aligned to the `indexed_reference_fasta`.
  - `nanocaller_small_variants`: BGZIP and TABIX indexed VCF containing small variant calls made by Nanocaller on the `minimap2_aligned_bam`.
  - `sniffles_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by Sniffles on the `minimap2_aligned_bam`.
  - `longreadsv_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by Sentieon LongReadSV on the `minimap2_aligned_bam`.

  ## Generalized Process
  1. Read group information (`@RG`) is harvested from the `input_unaligned_bam` header using `samtools head` and `grep`.
  1. If user provides `biospecimen_name` input, that value replaces the `SM` value pulled in the preceeding step.
  1. Align `input_unaligned_bam` to `indexed_reference_fasta` with tohe above `@RG` information using samtools fastq, Sentieon Minimap2, and Sentieon sort.
  1. Generate long reads alignment metrics from the `minimap2_aligned_bam` using LongReadSum.
  1. Generate structural variant calls from the `minimap2_aligned_bam` using CuteSV.
  1. Generate structural variant calls from the `minimap2_aligned_bam` using Sniffles.
  1. Generate structural variant calls from the `minimap2_aligned_bam` using Sentieon LongReadSV.
  1. Estimate mean depth of coverage of chr1 and chrX using samtools.
  1. Generate small variant calls from the `minimap2_aligned_bam` using Nanocaller.

  ## Workflow Trivia
  - Nanocaller runtime is particularly influenced by one of its inputs: `mincov`. This value is something that users should be tuning based on their understanding of the data (particularly quality and coverage). In general as coverage goes up, mincov should also go up to reduce the amount of noise. Even in the absence of user input we should scale this value based on the input BAM; therefore, the workflow will now samtools coverage on chr1 to assess the mean depth of coverage. From there we will set `mincov` to `meandepth / 4` for SNPs and `meandepth / 8` for INDELs. The reason for INDELs being more permissive is the following: The mincov for SNP calling applies to all reads, but for indel calling, it applies to reads from each parental haplotype. So a mincov of 8 for SNP means each position needs to have at least 8 reads to be considered for SNP calling, but for indel calling, it needs 8 from each parental haplotype, so it ends up being 16 reads required at least. Therefore to keep read support parity between SNPs and INDELs, INDELs mincov should be half of SNPs.
  - Input sample sex matters to Nanocaller. Nanocaller in SNP mode and the `phase` flag set will output phased BAM files for all diploid chromosomes in the sample. For male samples this means that phased BAMs are produced for the autosomes (chr1-22); females, however, will have an additional phased BAM for chrX. If the user does not provide the sex of the sample as an input, the workflow will attempt to guess. The workflow will use samtools coverage to calculate the mean depth of coverage for chrX. Using that value as well as the meandepth of coverage calcualted for chr1 (see above), if the chrX/chr1 mean depth ratio is 0.75 or more, the workflow will presume the sample is female and therefore has a diploid X.

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
  indexed_reference_fasta: {type: 'File', secondaryFiles: [{pattern: '.fai', required: true},
      {pattern: '^.dict', required: true}], doc: "Reference fasta and fai index.",
    "sbg:suggestedValue": {class: File, path: 60639014357c3a53540ca7a3, name: Homo_sapiens_assembly38.fasta,
      secondaryFiles: [{class: File, path: 60639016357c3a53540ca7af, name: Homo_sapiens_assembly38.fasta.fai},
        {class: File, path: 60639019357c3a53540ca7e7, name: Homo_sapiens_assembly38.dict}]},
    "sbg:fileTypes": "FASTA, FA"}
  output_basename: {type: 'string', doc: "String to use as basename for all workflow\
      \ outputs."}
  biospecimen_name: {type: 'string?', doc: "String name of the biospecimen. Providing\
      \ this value will override the SM value provided in the @RG line of the input_unaligned_bam\
      \ header."}
  sentieon_license: {type: 'string?', doc: "License server host and port for Sentieon\
      \ tools.", default: "10.5.64.221:8990"}
  minimap2_preset:
    type:
    - name: minimap2_preset
      type: enum
      symbols:
      - map-ont
      - ava-ont
      - splice
    doc: |-
      Select one of the preset options prepared by the tool authors. Selecting one of
      these options will apply multiple options at the same time. Use presets for the
      following cases:
        - map-ont: Oxford Nanopore genomic reads
        - splice: noisy Nanopore Direct RNA-seq
        - ava-ont: Nanopore read overlap
  nanocaller_wgs_contigs:
    type:
    - 'null'
    - type: enum
      name: wgs_contigs
      symbols: ["chr1-22XY", "1-22XY"]
    default: "chr1-22XY"
    doc: |
      Preset list of chromosomes to use for variant calling on human genomes.
      "chr1-22XY" option will assume human reference genome with "chr" prefix present
      in the chromosome notation, and run NanoCaller on chr1 to chr22, chrX and chrY.
      "1-22XY" option will assume no "chr" prefix is present in the chromosome
      notation and run NanoCaller on chromosomes 1-22, X and Y.
  nanocaller_exclude_bed_preset:
    type:
    - 'null'
    - type: enum
      name: exclude_bed_preset
      symbols: ["hg38", "hg19", "mm10", "mm39"]
    default: "hg38"
    doc: |
      BED files of centromere and telomere regions to exclude from variant calling.
      If you wish to use it for your sample, select the appropriate genome.
  nanocaller_regions: {type: 'string[]?', doc: "A space/whitespace separated list\
      \ of regions specified as 'CONTIG_NAME' or 'CONTIG_NAME:START-END'. If you want\
      \ to use 'CONTIG_NAME:START-END' format then specify both start and end coordinates.\
      \ For example: chr3 chr6:28000000-35000000 chr22."}
  nanocaller_include_bed: {type: 'File?', doc: "A BED file specifying regions for\
      \ variant calling."}
  nanocaller_exclude_bed: {type: 'File?', doc: "A BED file specifying regions to exclude\
      \ from variant calling."}
  nanocaller_preset:
    type:
      type: enum
      name: nanocaller_preset
      symbols: ["ont", "ul_ont", "ul_ont_extreme", "ccs", "clr"]
    doc: |
      Apply recommended preset values for SNP and Indel calling parameters, options
      are 'ont', 'ul_ont', 'ul_ont_extreme', 'ccs' and 'clr'. 'ont' works well for
      any type of ONT sequencing datasets. However, use 'ul_ont' if you have several
      ultra-long ONT reads up to 100kbp long, and 'ul_ont_extreme' if you have
      several ultra-long ONT reads up to 300kbp long. For PacBio CCS (HiFi) and CLR
      reads, use 'ccs'and 'clr' respectively. Presets are described in detail here:
      github.com/WGLab/NanoCaller/blob/master/docs/Usage.md#preset-options.
  nanocaller_snp_model: {type: 'string?', doc: "NanoCaller SNP model to be used"}
  nanocaller_neighbor_threshold: {type: 'string?', doc: "SNP neighboring site thresholds\
      \ with lower and upper bounds seperated by comma, for Nanopore reads '0.4,0.6'\
      \ is recommended, for PacBio CCS anc CLR reads '0.3,0.7' and '0.3,0.6' are recommended\
      \ respectively"}
  nanocaller_indel_model: {type: 'string?', doc: "NanoCaller indel model to be used"}
  nanocaller_ins_threshold: {type: 'float?', doc: "Insertion Threshold"}
  nanocaller_del_threshold: {type: 'float?', doc: "Deletion Threshold"}
  nanocaller_win_size: {type: 'int?', doc: "Size of the sliding window in which the\
      \ number of indels is counted to determine indel candidate site.  Only indels\
      \ longer than 2bp are counted in this window. Larger window size can increase\
      \ recall, but use a maximum of 50 only"}
  nanocaller_small_win_size: {type: 'int?', doc: "Size of the sliding window in which\
      \ indel frequency is determined for small indels"}
  nanocaller_mincov: {type: 'int?', doc: "Minimum coverage to call a variant."}
  nanocaller_maxcov: {type: 'int?', doc: "Maximum coverage of reads to use. If sequencing\
      \ depth at a candidate site exceeds maxcov then reads are downsampled."}
  sex:
    type:
    - 'null'
    - type: enum
      name: sex
      symbols: ["female", "male"]
    doc: "Sex of the input sample. Male samples will have inferred haploid X"
  cutesv_genotype: {type: 'boolean?', doc: "Enable to generate genotypes."}
  cutesv_max_cluster_bias_DEL: {type: 'int?', default: 100, doc: "Maximum distance\
      \ to cluster read together for deletion."}
  cutesv_diff_ratio_merging_DEL: {type: 'float?', default: 0.3, doc: "Do not merge\
      \ breakpoints with basepair identity more than the ratio of default for deletion."}
  sniffles_tandem_repeats_input_bed: {type: 'File?', doc: "Sniffles input .bed file\
      \ containing tandem repeat annotations for the input reference genome. Providing\
      \ this file can improve Sniffles call accuracy."}
  sniffles_non_germline: {type: 'boolean?', doc: "Request that Sniffles call non-germline\
      \ SVs (rare, somatic or mosaic SVs)."}
  minimap2_cpu: {type: 'int?', default: 36, doc: "CPU Cores for minimap2 to use."}
  minimap2_ram: {type: 'int?', doc: "RAM (in GB) for minimap2 to use."}
  longreadsum_cpu: {type: 'int?', doc: "CPU Cores for longreadsum to use."}
  cutesv_cpu: {type: 'int?', doc: "CPU Cores for cutesv to use."}
  cutesv_ram: {type: 'int?', doc: "RAM (in GB) for cutesv to use."}
  sniffles_cpu: {type: 'int?', doc: "CPU Cores for sniffles to use."}
  sniffles_ram: {type: 'int?', doc: "RAM (in GB) for sniffles to use."}
  longreadsv_cpu: {type: 'int?', doc: "CPU Cores for Sentieon LongReadSV to use."}
  longreadsv_ram: {type: 'int?', doc: "RAM (in GB) for Sentieon LongReadSV to use."}
outputs:
  minimap2_aligned_bam: {type: 'File', secondaryFiles: [{pattern: '.bai', required: true}],
    outputSource: clt_pickvalue/outfile, doc: "Aligned BAM file from Minimap2."}
  nanocaller_small_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi', required: true}],
    outputSource: nanocaller_merge_final/merged_vcf, doc: "VCF.GZ file and index containing\
      \ NanoCaller-gerated small variant calls."}
  longreadsum_bam_metrics: {type: 'File', outputSource: tar_longreadsum_dir/output,
    doc: "TAR.GZ file containing longreadsum-generated metrics."}
  cutesv_structural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi', required: true}],
    outputSource: bgzip_tabix_index_cutesv_vcf/output, doc: "VCF.GZ file and index\
      \ containing cutesv-generated SV calls."}
  sniffles_structural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi',
        required: true}], outputSource: sniffles/output_vcf, doc: "VCF.GZ file and\
      \ index containing sniffles-generated SV calls."}
  longreadsv_structural_variants: {type: 'File', secondaryFiles: [{pattern: '.tbi',
        required: true}], outputSource: sentieon_longreadsv/output_vcf, doc: "VCF.GZ\
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
  sentieon_longreadsv:
    run: ../tools/sentieon_LongReadSV.cwl
    in:
      sentieon_license: sentieon_license
      reference: indexed_reference_fasta
      input_bam: clt_pickvalue/outfile
      platform:
        valueFrom: "ONT"
      output_file_name:
        source: output_basename
        valueFrom: $(self).longreadsv.vcf.gz
      cpu: longreadsv_cpu
      ram: longreadsv_ram
    out: [output_vcf]
  longreadsum:
    run: ../tools/longreadsum.cwl
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    in:
      input_type:
        valueFrom: "bam"
      input_file: clt_pickvalue/outfile
      output_dir:
        source: output_basename
        valueFrom: $(self).longreadsum
      output_basename:
        source: output_basename
        valueFrom: $(self).longreadsum.
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
  cutesv:
    run: ../tools/cutesv.cwl
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    in:
      input_bam: clt_pickvalue/outfile
      reference_fasta: indexed_reference_fasta
      output_filename:
        source: output_basename
        valueFrom: $(self).cutesv.vcf
      sample:
        source: update_rg_sm/sample_name
        valueFrom: $(self[0])
      max_cluster_bias_DEL: cutesv_max_cluster_bias_DEL
      diff_ratio_merging_DEL: cutesv_diff_ratio_merging_DEL
      genotype: cutesv_genotype
      cpu: cutesv_cpu
      ram: cutesv_ram
    out: [output_vcf]
  bgzip_tabix_index_cutesv_vcf:
    run: ../tools/bgzip_tabix_index.cwl
    in:
      input_vcf: cutesv/output_vcf
      cpu: cutesv_cpu
    out: [output]
  sniffles:
    run: ../tools/sniffles.cwl
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    in:
      input_bam:
        source: clt_pickvalue/outfile
        valueFrom: $([self])
      vcf_output_filename:
        source: output_basename
        valueFrom: $(self).sniffles.vcf.gz
      reference_fasta: indexed_reference_fasta
      tandem_repeats_input_bed: sniffles_tandem_repeats_input_bed
      non_germline: sniffles_non_germline
      sample_id:
        source: update_rg_sm/sample_name
        valueFrom: $(self[0])
      cpu: sniffles_cpu
      ram: sniffles_ram
    out: [output_vcf, output_snf]
  samtools_coverage_1:
    run: ../tools/samtools_coverage.cwl
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    in:
      input_reads:
        source: clt_pickvalue/outfile
        valueFrom: $([self])
      region:
        valueFrom: "chr1"
    out: [output, meandepth]
  samtools_coverage_x:
    run: ../tools/samtools_coverage.cwl
    hints:
    - class: "sbg:AWSInstanceType"
      value: c5.9xlarge
    in:
      input_reads:
        source: clt_pickvalue/outfile
        valueFrom: $([self])
      region:
        valueFrom: "chrX"
    out: [output, meandepth]
  nanocaller_snps:
    run: ../tools/nanocaller.cwl
    in:
      input_bam: clt_pickvalue/outfile
      indexed_reference_fasta: indexed_reference_fasta
      output_basename:
        source: output_basename
        valueFrom: $(self).nanocaller
      sample_name:
        source: update_rg_sm/sample_name
        valueFrom: $(self[0])
      mode:
        valueFrom: "snps"
      phase:
        valueFrom: |
          $(1 == 1)
      wgs_contigs: nanocaller_wgs_contigs
      regions: nanocaller_regions
      include_bed: nanocaller_include_bed
      exclude_bed: nanocaller_exclude_bed
      exclude_bed_preset: nanocaller_exclude_bed_preset
      preset: nanocaller_preset
      snp_model: nanocaller_snp_model
      neighbor_threshold: nanocaller_neighbor_threshold
      mincov:
        source: [nanocaller_mincov, samtools_coverage_1/meandepth]
        valueFrom: |
          $(self[0] != null ? self[0] : Math.ceil(self[1]/4))
      maxcov: nanocaller_maxcov
      haploid_X:
        source: [sex, samtools_coverage_1/meandepth, samtools_coverage_x/meandepth]
        valueFrom: |
          $(self[0] == "male" ? true : self[2]/self[1] < 0.75)
      cpu:
        valueFrom: $(36)
      ram:
        valueFrom: $(36)
    out: [snps_unphased_vcf, snps_phased_vcf, indels_vcf, final_vcf, phased_bams]
  nanocaller_indels_diploid:
    run: ../tools/nanocaller.cwl
    scatter: [input_bam]
    hints:
    - class: sbg:AWSInstanceType
      value: c5.12xlarge
    in:
      input_bam: nanocaller_snps/phased_bams
      indexed_reference_fasta: indexed_reference_fasta
      output_basename:
        source: output_basename
        valueFrom: $(self).nanocaller
      sample_name:
        source: update_rg_sm/sample_name
        valueFrom: $(self[0])
      mode:
        valueFrom: "indels"
      regions:
        valueFrom: |
          $([inputs.input_bam.basename.split('.')[0]])
      include_bed: nanocaller_include_bed
      exclude_bed: nanocaller_exclude_bed
      exclude_bed_preset: nanocaller_exclude_bed_preset
      preset: nanocaller_preset
      indel_model: nanocaller_indel_model
      ins_threshold: nanocaller_ins_threshold
      del_threshold: nanocaller_del_threshold
      win_size: nanocaller_win_size
      small_win_size: nanocaller_small_win_size
      mincov:
        source: [nanocaller_mincov, samtools_coverage_1/meandepth]
        valueFrom: |
          $(self[0] != null ? self[0] / 2 : Math.ceil(self[1]/8))
      maxcov: nanocaller_maxcov
      cpu:
        valueFrom: $(8)
      ram:
        valueFrom: $(8)
    out: [snps_unphased_vcf, snps_phased_vcf, indels_vcf, final_vcf, phased_bams]
  nanocaller_indels_haploid:
    run: ../tools/nanocaller.cwl
    hints:
    - class: sbg:AWSInstanceType
      value: c5.12xlarge
    in:
      input_bam: clt_pickvalue/outfile
      indexed_reference_fasta: indexed_reference_fasta
      output_basename:
        source: output_basename
        valueFrom: $(self).nanocaller
      sample_name:
        source: update_rg_sm/sample_name
        valueFrom: $(self[0])
      mode:
        valueFrom: "indels"
      regions:
        source: [sex, samtools_coverage_1/meandepth, samtools_coverage_x/meandepth]
        valueFrom: |
          $(self[0] == "male" ? ["chrX","chrY"] : self[2]/self[1] < 0.75 ? ["chrX","chrY"] : ["chrY"])
      include_bed: nanocaller_include_bed
      exclude_bed: nanocaller_exclude_bed
      exclude_bed_preset: nanocaller_exclude_bed_preset
      preset: nanocaller_preset
      snp_model: nanocaller_snp_model
      neighbor_threshold: nanocaller_neighbor_threshold
      mincov:
        source: [nanocaller_mincov, samtools_coverage_1/meandepth]
        valueFrom: |
          $(self[0] != null ? self[0] : Math.ceil(self[1]/4))
      maxcov: nanocaller_maxcov
      haploid_X:
        source: [sex, samtools_coverage_1/meandepth, samtools_coverage_x/meandepth]
        valueFrom: |
          $(self[0] == "male" ? true : self[2]/self[1] < 0.75)
      cpu:
        valueFrom: $(8)
      ram:
        valueFrom: $(8)
    out: [snps_unphased_vcf, snps_phased_vcf, indels_vcf, final_vcf, phased_bams]
  nanocaller_merge_indels:
    run: ../tools/nanocaller_merge.cwl
    in:
      input_vcfs:
        source: [nanocaller_indels_diploid/indels_vcf, nanocaller_indels_haploid/indels_vcf]
        valueFrom: |
          $(self[0].concat(self[1]))
      output_basename:
        source: output_basename
        valueFrom: $(self).nanocaller.indels
    out: [merged_vcf]
  nanocaller_merge_final:
    run: ../tools/nanocaller_merge.cwl
    in:
      input_vcfs: [nanocaller_snps/snps_phased_vcf, nanocaller_merge_indels/merged_vcf]
      output_basename:
        source: output_basename
        valueFrom: $(self).nanocaller.final
    out: [merged_vcf]
$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: "sbg:maxNumberOfParallelInstances"
  value: 2
"sbg:license": Apache License 2.0
"sbg:publisher": KFDRC
"sbg:categories":
- ALIGNMENT
- CUTESV
- DNA
- INDEL
- LONG
- LONGREADS
- LONGREADSUM
- METRICS
- MINIMAP2
- NANOCALLER
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
- id: 'https://github.com/kids-first/kf-longreads-workflow/releases/tag/v2.0.0'
  label: github-release
