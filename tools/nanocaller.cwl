class: CommandLineTool
cwlVersion: v1.2
id: nanocaller
doc: |
  NanoCaller is a computational method that integrates long reads in deep
  convolutional neural network for the detection of SNPs/indels from long-read
  sequencing data. NanoCaller uses long-range haplotype structure to generate
  predictions for each SNP candidate variant site by considering pileup
  information of other candidate sites sharing reads. Subsequently, it performs
  read phasing, and carries out local realignment of each set of phased reads and
  the set of all reads for each indel candidate variant site to generate indel
  calling, and then creates consensus sequences for indel sequence prediction.

  For more information, visit https://github.com/WGLab/NanoCaller
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: genomicslab/nanocaller:3.2.0
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cpu)
baseCommand: []
arguments:
- position: 0
  prefix: ''
  shellQuote: false
  valueFrom: |
    NanoCaller
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  input_bam: { type: 'File', secondaryFiles: [{ pattern: ".bai", required: false }, { pattern: ".csi", required: false }],  inputBinding: { prefix: "--bam", position: 1 }, doc: "Bam file, should be phased if 'indel' mode is selected" }
  indexed_reference_fasta: { type: 'File', inputBinding: { prefix: "--ref", position: 1 }, secondaryFiles: [{pattern: ".fai", required: true}], doc: "Reference genome file with .fai index" }
  preset:
    type:
      type: enum
      name: preset
      symbols: ["ont","ul_ont","ul_ont_extreme","ccs","clr"]
    inputBinding:
      prefix: "--preset"
      position: 1
    doc: |
      Apply recommended preset values for SNP and Indel calling parameters, options
      are 'ont', 'ul_ont', 'ul_ont_extreme', 'ccs' and 'clr'. 'ont' works well for
      any type of ONT sequencing datasets. However, use 'ul_ont' if you have several
      ultra-long ONT reads up to 100kbp long, and 'ul_ont_extreme' if you have
      several ultra-long ONT reads up to 300kbp long. For PacBio CCS (HiFi) and CLR
      reads, use 'ccs'and 'clr' respectively. Presets are described in detail here:
      github.com/WGLab/NanoCaller/blob/master/docs/Usage.md#preset-options.

  # Configuration Options
  mode:
    type:
      - 'null'
      - type: enum
        name: mode
        symbols: ["all","snps","indels"]
    inputBinding:
      prefix: "--mode"
      position: 1
    doc: |
      NanoCaller mode to run. 'snps' mode quits NanoCaller without using
      WhatsHap for phasing. In this mode, if you want NanoCaller to phase SNPs and
      BAM files, use --phase argument additionally. (default: all)
  sequencing:
    type:
      - 'null'
      - type: enum
        name: sequencing
        symbols: ["ont","ul_ont","ul_ont_extreme","pacbio"]
    inputBinding:
      prefix: "--sequencing"
      position: 1
    doc: |
      Sequencing type, options are 'ont', 'ul_ont', 'ul_ont_extreme', and 'pacbio'.
      'ont' works well for any type of ONT sequencing datasets. However, use 'ul_ont'
      if you have several ultra-long ONT reads up to 100kbp long, and
      'ul_ont_extreme' if you have several ultra-long ONT reads up to 300kbp long.
      For PacBio CCS (HiFi) and CLR reads, use 'pacbio'.
  mincov: { type: 'int?', inputBinding: { prefix: "--mincov", position: 1 }, doc: "Minimum coverage to call a variant." }
  maxcov: { type: 'int?', inputBinding: { prefix: "--maxcov", position: 1 }, doc: "Maximum coverage of reads to use. If sequencing depth at a candidate site exceeds maxcov then reads are downsampled." }
  haploid_genome: { type: 'boolean?', inputBinding: { position: 1, prefix: "--haploid_genome" }, doc: "Assume that all chromosomes in the genome are haploid." }
  haploid_X: { type: 'boolean?', inputBinding: { position: 1, prefix: "--haploid_X" }, doc: "Assume that chrX is haploid. chrY and chrM are assumed to be haploid by default." }

  # Variant Calling Regions Options
  regions: { type: 'string[]?', inputBinding: { position: 1, prefix: "--regions" }, doc: "A space/whitespace separated list of regions specified as 'CONTIG_NAME' or 'CONTIG_NAME:START-END'. If you want to use 'CONTIG_NAME:START-END' format then specify both start and end coordinates. For example: chr3 chr6:28000000-35000000 chr22. (default: None)" }
  include_bed: { type: 'File?', inputBinding: { prefix: "--bed", position: 1 }, doc: "A BED file specifying regions for variant calling." }
  exclude_bed: { type: 'File?', secondaryFiles: [{pattern: ".tbi", required: true}], inputBinding: { prefix: "--exclude_bed", position: 1 }, doc: "Path to bgzipped and tabix indexed BED file containing intervals to ignore for variant calling. BED files of centromere and telomere regions for the following genomes are included in NanoCaller: hg38, hg19, mm10 and mm39. To use these BED files use the exclude_bed_preset input." }
  exclude_bed_preset:
    type:
      - 'null'
      - type: enum
        name: exclude_bed_preset
        symbols: ["hg38", "hg19", "mm10", "mm39"]
    inputBinding:
      prefix: "--exclude_bed"
      position: 1
    doc: |
      BED files of centromere and telomere regions to exclude from variant calling.
      If you wish to use it for your sample, select the appropriate genome.
  wgs_contigs:
    type:
      - 'null'
      - type: enum
        name: wgs_contigs
        symbols: ["chr1-22XY", "1-22XY"]
    inputBinding:
      prefix: "--wgs_contigs"
      position: 1
    doc: |
      Preset list of chromosomes to use for variant calling on human genomes.
      "chr1-22XY" option will assume human reference genome with "chr" prefix present
      in the chromosome notation, and run NanoCaller on chr1 to chr22, chrX and chrY.
      "1-22XY" option will assume no "chr" prefix is present in the chromosome
      notation and run NanoCaller on chromosomes 1-22, X and Y.

  # SNP Calling Options
  snp_model: { type: 'string?', inputBinding: { prefix: "--snp_model", position: 1 }, doc: "NanoCaller SNP model to be used (e.g. ONT-HG002, CCS-HG002, CLR-HG002)" }
  min_allele_freq: { type: 'float?', inputBinding: { prefix: "--min_allele_freq", position: 1 }, doc: "minimum alternative allele frequency" }
  min_nbr_sites: { type: 'int?', inputBinding: { prefix: "--min_nbr_sites", position: 1 }, doc: "minimum number of nbr sites" }
  neighbor_threshold: { type: 'string?', inputBinding: { prefix: "--neighbor_threshold", position: 1 }, doc: "SNP neighboring site thresholds with lower and upper bounds seperated by comma, for Nanopore reads '0.4,0.6' is recommended, for PacBio CCS anc CLR reads '0.3,0.7' and '0.3,0.6' are recommended respectively" }
  supplementary: { type: 'boolean?', inputBinding: { prefix: "--supplementary", position: 1, shellQuote: false }, doc: "Use supplementary reads" }

  # Indel Calling Options
  indel_model: { type: 'string?', inputBinding: { prefix: "--indel_model", position: 1 }, doc: "NanoCaller indel model to be used (e.g. ONT-HG002, CCS-HG002)" }
  ins_threshold: { type: 'float?', inputBinding: { prefix: "--ins_threshold", position: 1 }, doc: "Insertion Threshold" }
  del_threshold: { type: 'float?', inputBinding: { prefix: "--del_threshold", position: 1 }, doc: "Deletion Threshold" }
  win_size: { type: 'int?', inputBinding: { prefix: "--win_size", position: 1 }, doc: "Size of the sliding window in which the number of indels is counted to determine indel candidate site.  Only indels longer than 2bp are counted in this window. Larger window size can increase recall, but use a maximum of 50 only" }
  small_win_size: { type: 'int?', inputBinding: { prefix: "--small_win_size", position: 1 }, doc: "Size of the sliding window in which indel frequency is determined for small indels" }
  impute_indel_phase: { type: 'boolean?', inputBinding: { prefix: "--impute_indel_phase", position: 1, shellQuote: false }, doc: "Infer read phase by rudimentary allele clustering if the no or insufficient phasing information is available, can be useful for datasets without SNPs or regions with poor phasing quality." }

  # Output Options
  output_basename: { type: 'string?', default: "variant_calls", inputBinding: { prefix: "--prefix",  position: 1 }, doc: "String to use as basename for output files" }
  sample_name: { type: 'string?', inputBinding: { prefix: "--sample",  position: 1 }, doc: "VCF file sample name" }

  # Phasing Options
  phase: { type: 'boolean?', inputBinding: { position: 1, prefix: "--phase" }, doc: "Phase SNPs and BAM files if snps mode is selected. (default: False)" }
  enable_whatshap: { type: 'boolean?', inputBinding: { prefix: "--enable_whatshap", position: 1, shellQuote: false }, doc: "Allow WhatsHap to change SNP genotypes when phasing using --distrust-genotypes and --include-homozygous flags (this is not the same as regenotyping), considerably increasing the time needed for phasing.  It has a negligible effect on SNP calling accuracy for Nanopore reads, but may make a small improvement for PacBio reads. By default WhatsHap will only phase SNP calls produced by NanoCaller, but not change their genotypes." }

  cpu: { type: 'int?', default: 8, inputBinding: { prefix: "--cpu", position: 1 }, doc: "Number of CPUs to use." }
  ram: { type: 'int?', default: 16, doc: "GC of RAM to use" }
outputs:
  snps_unphased_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: true}], outputBinding: { glob: "*snps.vcf.gz" }, doc: "Contains unphased SNP calls made by NanoCaller using a deep learning model. NanoCaller modes that produce this file are: snps_unphased, snps and both." }
  snps_phased_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: true}], outputBinding: { glob: "*snps.phased.vcf.gz" }, doc: "Contains SNP calls from PREFIX.snps.vcf.gz that are phase with WhatsHap. By default they have the same genotype as in the PREFIX.snps.vcf.gz file, unless --enable_whatshap flag is set which can allow WhatsHap to change genotypes. NanoCaller modes that produce this
 file are: snps and both." }
  indels_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: true}], outputBinding: { glob: "*.indels.vcf.gz"}, doc: "Contains indel calls made by NanoCaller using multiple sequence alignment. Some of these calls might be indels combined with nearby substitutions or multi-nucleotide substitutions. NanoCaller modes that produce this file are: indels and both." }
  final_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: true}], outputBinding: { glob: "$(inputs.output_basename).vcf.gz" }, doc: "Contains SNP calls from PREFIX.snps.phased.vcf.gz and indel calls from PREFIX.indels.vcf.gz. NanoCaller mode that produce this file is: all." }
  phased_bams: { type: 'File[]?', secondaryFiles: [{ pattern: ".csi", required: true}], outputBinding: { glob: "intermediate_phase_files/*.phased.bam" }, doc: "Phased bam files made when setting the --phase flag or running in mode: all" }
