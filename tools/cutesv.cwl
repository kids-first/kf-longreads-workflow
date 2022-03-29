class: CommandLineTool
cwlVersion: v1.2
id: cutesv
doc: |
  Long read based human genomic structural variation detection with cuteSV.

  Suggestions:
    For PacBio CLR data:
        --max_cluster_bias_INS      100
        --diff_ratio_merging_INS    0.3
        --max_cluster_bias_DEL  200
        --diff_ratio_merging_DEL    0.5
    For PacBio CCS(HIFI) data:
        --max_cluster_bias_INS      1000
        --diff_ratio_merging_INS    0.9
        --max_cluster_bias_DEL  1000
        --diff_ratio_merging_DEL    0.5
    For ONT data:
        --max_cluster_bias_INS      100
        --diff_ratio_merging_INS    0.3
        --max_cluster_bias_DEL  100
        --diff_ratio_merging_DEL    0.3

  For more information, visit https://github.com/tjiangHIT/cuteSV
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: dmiller15/cutesv:1.0.13
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  ramMin: ${ return inputs.ram * 1000 }
  coresMin: $(inputs.cores)
baseCommand: [cuteSV]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  # Required Arguments
  input_bam: { type: 'File', secondaryFiles: [{ pattern: ".bai", required: false}, { pattern: "^.bai", required: false}], inputBinding: { position: 80 }, doc: "Sorted .bam file from NGMLR or Minimap2." }
  reference_fasta: { type: 'File', secondaryFiles: [{ pattern: ".fai", required: true}], inputBinding: { position: 81 }, doc: "The reference genome in fasta format." }
  output_filename: { type: 'string', inputBinding: { position: 82 }, doc: "Output VCF format file." }
  workdir: { type: 'string?', default: '.', inputBinding: { position: 83 }, doc: "Work-directory for distributed jobs" }

  # Optional Arguments
  cores: { type: 'int?', default: 16, inputBinding: { prefix: "--threads", position: 1 }, doc: "Number of threads to use" }
  ram: { type: 'int?', default: 32, doc: "RAM (in GB) to use" }
  batches: { type: 'int?', inputBinding: { prefix: "--batches", position: 1 }, doc: "Batch of genome segmentation interval." }
  sample: { type: 'string?', inputBinding: { prefix: "--sample", position: 1 }, doc: "Sample name/id" }
  retain_workdir: { type: 'boolean?', inputBinding: { prefix: "--retain_work_dir", position: 1 }, doc: "Enable to retain temporary folder and files." }
  report_readid: { type: 'boolean?', inputBinding: { prefix: "--report_readid", position: 1 }, doc: "Enable to report supporting read ids for each SV." }

  # Collection of SV signatures Arguments
  max_split_parts: { type: 'int?', inputBinding: { prefix: "--max_split_parts", position: 1 }, doc: "Maximum number of split segments a read may be aligned before it is ignored. All split segments are considered when using -1. (Recommand -1 when applying assembly-based alignment.)[7]" }
  min_mapq: { type: 'int?', inputBinding: { prefix: "--min_mapq", position: 1 }, doc: "Minimum mapping quality value of alignment to be taken into account.[20]" }
  min_read_len: { type: 'int?', inputBinding: { prefix: "--min_read_len", position: 1 }, doc: "Ignores reads that only report alignments with not longer than bp.[500]" }
  merge_del_threshold: { type: 'int?', inputBinding: { prefix: "--merge_del_threshold", position: 1 }, doc: "Maximum distance of deletion signals to be merged. In our paper, I used -md 500 to process HG002 real human sample data.[0]" }
  merge_ins_threshold: { type: 'int?', inputBinding: { prefix: "--merge_ins_threshold", position: 1 }, doc: "Maximum distance of insertion signals to be merged. In our paper, I used -mi 500 to process HG002 real human sample data.[100]" }

  # Generation of SV clusters Arguments
  min_support: { type: 'int?', inputBinding: { prefix: "--min_support", position: 1 }, doc: "Minimum number of reads that support a SV to be reported.[10]" }
  min_size: { type: 'int?', inputBinding: { prefix: "--min_size", position: 1 }, doc: "Minimum size of SV to be reported.[30]" }
  max_size: { type: 'int?', inputBinding: { prefix: "--max_size", position: 1 }, doc: "Maximum size of SV to be reported. All SVs are reported when using -1. [100000]" }
  min_siglength: { type: 'int?', inputBinding: { prefix: "--min_siglength", position: 1 }, doc: "Minimum length of SV signal to be extracted.[10]" }

  # Computing genotypes Arguments
  genotype: { type: 'boolean?', inputBinding: { prefix: "--genotype", position: 1 }, doc: "Enable to generate genotypes." }
  gt_round: { type: 'int?', inputBinding: { prefix: "--gt_round", position: 1 }, doc: "Maximum round of iteration for alignments searching if perform genotyping.[500]" }

  # Force Calling Arguments
  force_calling_input_vcf: { type: 'File?', inputBinding: { prefix: "-Ivcf", position: 1 }, doc: "Optional given vcf file. Enable to perform force calling." }

  # Advanced Arguments
  max_cluster_bias_INS: { type: 'int?', inputBinding: { prefix: "--max_cluster_bias_INS", position: 1 }, doc: "Maximum distance to cluster read together for insertion.[100]" }
  diff_ratio_merging_INS: { type: 'float?', inputBinding: { prefix: "--diff_ratio_merging_INS", position: 1 }, doc: "Do not merge breakpoints with basepair identity more than [0.3] for insertion." }
  max_cluster_bias_DEL: { type: 'int?', inputBinding: { prefix: "--max_cluster_bias_DEL", position: 1 }, doc: "Maximum distance to cluster read together for deletion.[200]" }
  diff_ratio_merging_DEL: { type: 'float?', inputBinding: { prefix: "--diff_ratio_merging_DEL", position: 1 }, doc: "Do not merge breakpoints with basepair identity more than [0.5] for deletion." }
  max_cluster_bias_INV: { type: 'int?', inputBinding: { prefix: "--max_cluster_bias_INV", position: 1 }, doc: "Maximum distance to cluster read together for inversion.[500]" }
  max_cluster_bias_DUP: { type: 'int?', inputBinding: { prefix: "--max_cluster_bias_DUP", position: 1 }, doc: "Maximum distance to cluster read together for duplication.[500]" }
  max_cluster_bias_TRA: { type: 'int?', inputBinding: { prefix: "--max_cluster_bias_TRA", position: 1 }, doc: "Maximum distance to cluster read together for translocation.[50]" }
  diff_ratio_filtering_TRA: { type: 'float?', inputBinding: { prefix: "--diff_ratio_filtering_TRA", position: 1 }, doc: "Filter breakpoints with basepair identity less than [0.6] for translocation." }

outputs:
  output_vcf: { type: 'File?', outputBinding: { glob: "$(inputs.output_filename)" }, doc: "VCF file contianing SV calls" }
