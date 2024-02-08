class: CommandLineTool
cwlVersion: v1.2
id: pbmm2_align
doc: |
  pbmm2 is a SMRT C++ wrapper for minimap2's C API. Its purpose is to support
  native PacBio in- and output, provide sets of recommended parameters, generate
  sorted output on-the-fly, and postprocess alignments. Sorted output can be used
  directly for polishing using GenomicConsensus, if BAM has been used as input to
  pbmm2. Benchmarks show that pbmm2 outperforms BLASR in sequence identity,
  number of mapped bases, and especially runtime. pbmm2 is the official
  replacement for BLASR.

  For more information, visit https://github.com/PacificBiosciences/pbmm2
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: 684194535433.dkr.ecr.us-east-1.amazonaws.com/d3b-healthomics:pbmm2-1.10.0--h9ee0642_0
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cpu)
baseCommand: [pbmm2, align]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  # Required Arguments
  reference: { type: 'File', secondaryFiles: [{ pattern: ".fai", required: false}], inputBinding: { position: 80 }, doc: "Reference FASTA, ReferenceSet XML, or Reference Index." }
  input_reads: { type: 'File', secondaryFiles: [{ pattern: ".bai", required: false }, { pattern: "^.bai", required: false }], inputBinding: { position: 81 }, doc: "Input BAM, DataSet XML, FASTA, or FASTQ" }
  output_filename: { type: 'string', inputBinding: { position: 82 }, doc: "Output BAM Filename" }

  # Basic Parameters
  chunk_size: { type: 'int?', inputBinding: { prefix: "--chunk-size", position: 1 }, doc: "Process N records per chunk." }

  # Sorting Parameters
  sort: { type: 'boolean?', inputBinding: { prefix: "--sort", position: 1 }, doc: "Generate sorted BAM file." }
  sort_memory: { type: 'string?', inputBinding: { prefix: "--sort-memory", position: 1 }, doc: "Memory per thread for sorting. Input must be formated as <value><unit> (e.g. 1G, 500M, 100K) [768M]" }
  sort_threads: { type: 'int?', inputBinding: { prefix: "--sort-threads", position: 1 }, doc: "Number of threads used for sorting; 0 means 25% of -j/--num-threads, maximum 8." }

  # Preset Options
  preset:
    type:
      - 'null'
      - type: enum
        name: preset
        symbols: ["SUBREAD","CCS","HIFI","ISOSEQ","UNROLLED"]
    inputBinding:
      prefix: "--preset"
      position: 1
    doc: |
      Set alignment mode. See below for preset parameter details.
      Alignment modes of --preset:
          SUBREAD     : -k 19 -w 10    -o 5 -O 56 -e 4 -E 1 -A 2 -B 5 -z 400 -Z 50  -r 2000   -L 0.5 -g 5000
          CCS or HiFi : -k 19 -w 10 -u -o 5 -O 56 -e 4 -E 1 -A 2 -B 5 -z 400 -Z 50  -r 2000   -L 0.5 -g 5000
          ISOSEQ      : -k 15 -w 5  -u -o 2 -O 32 -e 1 -E 0 -A 1 -B 2 -z 200 -Z 100 -r 200000 -L 0.5 -g 2000 -C 5 -G 200000
          UNROLLED    : -k 15 -w 15    -o 2 -O 32 -e 1 -E 0 -A 1 -B 2 -z 200 -Z 100 -r 2000   -L 0.5 -g 10000

  # General Parameter Override
  align_kmer: { type: 'int?', inputBinding: { prefix: "-k", position: 1 }, doc: "k-mer size (no larger than 28)." }
  align_minimizer_window_size: { type: 'int?', inputBinding: { prefix: "-w", position: 1 }, doc: "Minimizer window size." }
  align_disable_hpc: { type: 'boolean?', inputBinding: { prefix: "--no-kmer-compression", position: 1 }, doc: "Disable homopolymer-compressed k-mer (compression is active for SUBREAD & UNROLLED presets)." }
  match_score: { type: 'int?', inputBinding: { prefix: "-A", position: 1 }, doc: "Matching score." }
  mismatch_penalty: { type: 'int?', inputBinding: { prefix: "-B", position: 1 }, doc: "Mismatch penalty." }
  z_drop: { type: 'int?', inputBinding: { prefix: "-z", position: 1 }, doc: "Z-drop score." }
  z_drop_inv: { type: 'int?', inputBinding: { prefix: "-Z", position: 1 }, doc: "Z-drop inversion score." }
  bandwidth: { type: 'int?', inputBinding: { prefix: "-r", position: 1 }, doc: "Bandwidth used in chaining and DP-based alignment." }
  max_gap: { type: 'int?', inputBinding: { prefix: "-g", position: 1 }, doc: "Stop chain enlongation if there are no minimizers in N bp." }

  # Gap Parameter Override
  gap_open_1: { type: 'int?', inputBinding: { prefix: "--gap-open-1", position: 1 }, doc: "Gap open penalty 1. (a k-long gap costs min{o+k*e,O+k*E})" }
  gap_open_2: { type: 'int?', inputBinding: { prefix: "--gap-open-2", position: 1 }, doc: "Gap open penalty 2. (a k-long gap costs min{o+k*e,O+k*E})" }
  gap_extend_1: { type: 'int?', inputBinding: { prefix: "--gap-extend-1", position: 1 }, doc: "Gap extension penalty 1. (a k-long gap costs min{o+k*e,O+k*E})" }
  gap_extend_2: { type: 'int?', inputBinding: { prefix: "--gap-extend-2", position: 1 }, doc: "Gap extension penalty 2. (a k-long gap costs min{o+k*e,O+k*E})" }
  lj_min_ratio: { type: 'float?', inputBinding: { prefix: "--lj-min-ratio", position: 1 }, doc: "Long join flank ratio. (a k-long gap costs min{o+k*e,O+k*E})" }

  # IsoSeq Parameter Override
  max_intron_length: { type: 'int?', inputBinding: { prefix: "-G", position: 1 }, doc: "Max intron length (changes -r)." }
  non_canon: { type: 'int?', inputBinding: { prefix: "-C", position: 1 }, doc: "Cost for a non-canonical GT-AG splicing (effective in ISOSEQ preset)." }
  no_splice_flank: { type: 'boolean?', inputBinding: { prefix: "--no-splice-flank", position: 1 }, doc: "Do not prefer splice flanks GT-AG (effective in ISOSEQ preset)." }

  # Read Group Arguments
  sample_name: { type: 'string?', inputBinding: { prefix: "--sample", position: 1 }, doc: "Sample name for all read groups. Defaults, in order of precedence: SM field in input read group, biosample name, well sample name, 'UnnamedSample'." }
  rg: { type: 'string?', inputBinding: { prefix: "--rg", position: 1 }, doc: "Read group header line such as '@RG\tID:xyz\tSM:abc'. Only for FASTA/Q inputs." }

  # Identity Filter Arguments
  min_perc_identity_gap_comp: { type: 'float?', inputBinding: { prefix: "--min-gap-comp-id-perc", position: 1 }, doc: "Minimum gap-compressed sequence identity in percent." }

  # Output Arguments
  min_alignment_length: { type: 'int?', inputBinding: { prefix: "--min-length", position: 1 }, doc: "Minimum mapped read length in basepairs." }
  max_num_alns: { type: 'int?', inputBinding: { prefix: "--best-n", position: 1 }, doc: "Output at maximum N alignments for each read, 0 means no maximum." }
  strip: { type: 'boolean?', inputBinding: { prefix: "--strip", position: 1 }, doc: "Remove all kinetic and extra QV tags. Output cannot be polished." }
  split_by_sample: { type: 'boolean?', inputBinding: { prefix: "--split-by-sample", position: 1 }, doc: "One output BAM per sample." }
  output_unmapped: { type: 'boolean?', inputBinding: { prefix: "--unmapped", position: 1 }, doc: "Include unmapped records in output." }
  output_bam_index:
    type:
      - 'null'
      - type: enum
        name: output_bam_index
        symbols: ["BAI","NONE","CSI"]
    inputBinding:
      prefix: "--bam-index"
      position: 1
    doc: |
      Generate index for sorted BAM output.
  short_sa_cigar: { type: 'boolean?', inputBinding: { prefix: "--short-sa-cigar", position: 1 }, doc: "Populate SA tag with short cigar representation." }

  # Input Manipulation Arguments (mutually exclusive)
  median_filter: { type: 'boolean?', inputBinding: { prefix: "--median-filter", position: 1 }, doc: "Pick one read per ZMW of median length." }
  zmw: { type: 'boolean?', inputBinding: { prefix: "--zmw", position: 1 }, doc: "Process ZMW Reads, subreadset.xml input required (activates UNROLLED preset)." }
  hq_region: { type: 'boolean?', inputBinding: { prefix: "--hqregion", position: 1 }, doc: "Process HQ region of each ZMW, subreadset.xml input required (activates UNROLLED preset)." }

  # Sequence Manipulation Arguments
  collapse_homopolymers: { type: 'boolean?', inputBinding: { prefix: "--collapse-homopolymers", position: 1 }, doc: "Collapse homopolymers in reads and reference." }

  # Control
  cpu: { type: 'int?', default: 36, inputBinding: { prefix: "--num-threads", position: 1 }, doc: "Number of threads to use" }
  ram: { type: 'int?', default: 36, doc: "RAM (in GB) to use" }
  log_level:
    type:
      - 'null'
      - type: enum
        name: log_level
        symbols: ["TRACE","DEBUG","INFO","WARN","FATAL"]
    inputBinding:
      prefix: "--log-level"
      position: 1
    doc: |
      Set log level.
  log_file: { type: 'string?', inputBinding: { prefix: "--log-file", position: 1 }, doc: "Log to a file, instead of stderr." }

outputs:
  output_bam: { type: 'File', secondaryFiles: [{ pattern: ".bai", required: false }, { pattern: "^.bai", required: false }], outputBinding: { glob: $(inputs.output_filename) }, doc: "pbmm2 Aligned BAM" }
  output_log_file: { type: 'File?', outputBinding: { glob: $(inputs.log_file) }, doc: "Log output, if explicitly declared" }
