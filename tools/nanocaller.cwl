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
  dockerPull: genomicslab/lrtools:v0.0.4
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cores + 1)
baseCommand: []
arguments:
- position: 0
  prefix: ''
  shellQuote: false
  valueFrom: |
    $(inputs.wgs_mode ? "NanoCaller_WGS" : "NanoCaller")
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  wgs_mode: { type: 'boolean?', doc: "Run NanoCaller in WGS mode? If true, runs NanoCaller_WGS. Otherwise, run NanoCaller." }
  input_bam: { type: 'File', secondaryFiles: [{ pattern: ".bai", required: true }],  inputBinding: { prefix: "--bam", position: 1 }, doc: "Bam file, should be phased if 'indel' mode is selected" }
  indexed_reference_fasta: { type: 'File', inputBinding: { prefix: "--ref", position: 1 }, secondaryFiles: [{pattern: ".fai", required: true}], doc: "Reference genome file with .fai index" }
  chrom: { type: 'string?', inputBinding: { prefix: "--chrom", position: 1 }, doc: "Chromosome to which calling will be restricted. Required for WXS. If running in WGS mode multiple chromosomes can be provided as a whitespace separated list (e.g. 'chr1 chr11 chr14')." }
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
        symbols: ["both","snps","snps_unphased","indels"]
    inputBinding:
      prefix: "--mode"
      position: 1
    doc: |
      NanoCaller mode to run, options are 'snps', 'snps_unphased', 'indels' and
      'both'. 'snps_unphased' mode quits NanoCaller without using WhatsHap for
      phasing.
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
  cores: { type: 'int?', default: 1, inputBinding: { prefix: "--cpu", position: 1 }, doc: "Number of CPUs to use." }
  ram: { type: 'int?', default: 2, doc: "GC of RAM to use" }
  mincov: { type: 'int?', inputBinding: { prefix: "--mincov", position: 1 }, doc: "Minimum coverage to call a variant." }
  maxcov: { type: 'int?', inputBinding: { prefix: "--maxcov", position: 1 }, doc: "Maximum coverage of reads to use. If sequencing depth at a candidate site exceeds maxcov then reads are downsampled." }

  # Variant Calling Regions Options
  include_bed: { type: 'File?', secondaryFiles: [{pattern: ".tbi", required: true}], inputBinding: { prefix: "--include_bed", position: 1 }, doc: "Only call variants inside the intervals specified in the
bgzipped and tabix indexed BED file. If any other flags are used to specify a region, intersect the region with intervals in the BED file, e.g. if -chom chr1 -start 10000000 -end 20000000 flags are set, call variants inside the intervals specified by the BED file that overlap with chr1:10000000-20000000. Same goes for the case when whole genome variant calling flag is set." }
  exclude_bed: { type: 'File?', secondaryFiles: [{pattern: ".tbi", required: true}], inputBinding: { prefix: "--exclude_bed", position: 1 }, doc: "Path to bgzipped and tabix indexed BED file containing in
tervals to ignore for variant calling. BED files of centromere and telomere regions for the following genomes are included in NanoCaller: hg38, hg19, mm10 and mm39. To use these BED files use the exclude_bed_preset input." }
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
  start: { type: 'int?', inputBinding: { prefix: "--start", position: 1 }, doc: "Genomic position where to begin analysis" }
  end: { type: 'int?', inputBinding: { prefix: "--end", position: 1 }, doc: "Genomic position where to end analysis" }
  wgs_contigs_type:
    type:
      - 'null'
      - type: enum
        name: wgs_contigs_type
        symbols: ["with_chr", "without_chr", "all"]
    inputBinding:
      prefix: "--wgs_contigs_type"
      position: 1
    doc: |
      For WGS mode ONLY: Options are "with_chr", "without_chr" and "all", "with_chr"
      option will assume human genome and run NanoCaller on chr1-22, "without_chr"
      will run on chromosomes 1-22 if the BAM and reference genome files use
      chromosome names without "chr". "all" option will run NanoCaller on each contig
      present in reference genome FASTA file.

  # SNP Calling Options
  snp_model: { type: 'string?', inputBinding: { prefix: "--snp_model", position: 1 }, doc: "NanoCaller SNP model to be used (e.g. ONT-HG002, CCS-HG002, CLR-HG002)" }
  min_allele_freq: { type: 'float?', inputBinding: { prefix: "--min_allele_freq", position: 1 }, doc: "minimum alternative allele frequency" }
  min_nbr_sites: { type: 'int?', inputBinding: { prefix: "--min_nbr_sites", position: 1 }, doc: "minimum number of nbr sites" }
  neighbor_threshold: { type: 'string?', inputBinding: { prefix: "--neighbor_threshold", position: 1 }, doc: "SNP neighboring site thresholds with lower and upper bounds seperated by comma, for Nanopore r
eads '0.4,0.6' is recommended, for PacBio CCS anc CLR reads '0.3,0.7' and '0.3,0.6' are recommended respectively" }
  supplementary: { type: 'boolean?', inputBinding: { prefix: "--supplementary True", position: 1, shellQuote: false }, doc: "Use supplementary reads" }

  # Indel Calling Options
  indel_model: { type: 'string?', inputBinding: { prefix: "--indel_model", position: 1 }, doc: "NanoCaller indel model to be used (e.g. ONT-HG002, CCS-HG002)" }
  ins_threshold: { type: 'float?', inputBinding: { prefix: "--ins_threshold", position: 1 }, doc: "Insertion Threshold" }
  del_threshold: { type: 'float?', inputBinding: { prefix: "--del_threshold", position: 1 }, doc: "Deletion Threshold" }
  win_size: { type: 'int?', inputBinding: { prefix: "--win_size", position: 1 }, doc: "Size of the sliding window in which the number of indels is counted to determine indel candidate site.  Only indels l
onger than 2bp are counted in this window. Larger window size can increase recall, but use a maximum of 50 only" }
  small_win_size: { type: 'int?', inputBinding: { prefix: "--small_win_size", position: 1 }, doc: "Size of the sliding window in which indel frequency is determined for small indels" }
  impute_indel_phase: { type: 'boolean?', inputBinding: { prefix: "--impute_indel_phase True", position: 1, shellQuote: false }, doc: "Infer read phase by rudimentary allele clustering if the no or insuff
icient phasing information is available, can be useful for datasets without SNPs or regions with poor phasing quality." }

  # Output Options
  keep_bam: { type: 'boolean?', inputBinding: { prefix: "--keep_bam True", position: 1, shellQuote: false }, doc: "Keep phased bam files." }
  output_dir: { type: 'string?', inputBinding: { prefix: "--output", position: 1 }, doc: "VCF output path, default is current working directory" }
  output_basename: { type: 'string?', inputBinding: { prefix: "--prefix",  position: 1 }, doc: "String to use as basename for output files" }
  sample_name: { type: 'string?', inputBinding: { prefix: "--sample",  position: 1 }, doc: "VCF file sample name" }

  # Phasing Options
  phase_bam: { type: 'boolean?', inputBinding: { prefix: "--phase_bam True", position: 1, shellQuote: false }, doc: "Phase bam files if snps mode is selected. This will phase bam file without indel callin
g." }
  enable_whatshap: { type: 'boolean?', inputBinding: { prefix: "--enable_whatshap True", position: 1, shellQuote: false }, doc: "Allow WhatsHap to change SNP genotypes when phasing using --distrust-genoty
pes and --include-homozygous flags (this is not the same as regenotyping), considerably increasing the time needed for phasing.  It has a negligible effect on SNP calling accuracy for Nanopore reads, but
may make a small improvement for PacBio reads. By default WhatsHap will only phase SNP calls produced by NanoCaller, but not change their genotypes." }

outputs:
  snps_unphased_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: true}], outputBinding: { glob: "*snps.vcf.gz" }, doc: "Contains unphased SNP calls made by NanoCaller using a deep learn
ing model. NanoCaller modes that produce this file are: snps_unphased, snps and both." }
  snps_phased_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: true}], outputBinding: { glob: "*snps.phased.vcf.gz" }, doc: "Contains SNP calls from PREFIX.snps.vcf.gz that are phase wi
th WhatsHap. By default they have the same genotype as in the PREFIX.snps.vcf.gz file, unless --enable_whatshap flag is set which can allow WhatsHap to change genotypes. NanoCaller modes that produce this
 file are: snps and both." }
  indels_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: true}], outputBinding: { glob: "*.indels.vcf.gz"}, doc: "Contains indel calls made by NanoCaller using multiple sequence alignm
ent. Some of these calls might be indels combined with nearby substitutions or multi-nucleotide substitutions. NanoCaller modes that produce this file are: indels and both." }
  final_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: true}], outputBinding: { glob: "*.final.vcf.gz" }, doc: "Contains SNP calls from PREFIX.snps.phased.vcf.gz and indel calls from
PREFIX.indels.vcf.gz. NanoCaller mode that produce this file is: both." }
  fail_logs: { type: 'File?', outputBinding: { glob: "failed_jobs_combined_logs" } }
  fail_cmds: { type: 'File?', outputBinding: { glob: "failed_jobs_commands" } }
  logs: { type: 'Directory?', outputBinding: { glob: "logs" } }
