class: CommandLineTool
cwlVersion: v1.2
id: pbmm2_index
doc: |
  Indexing is optional, but recommended if you use the same reference with the
  same --preset multiple times.

  Notes:
  - If you use an index file, you can't override parameters -k, -w, nor -u in
    pbmm2 align!
  - Minimap2 parameter -H (homopolymer-compressed k-mer) is always on for SUBREAD
    and UNROLLED presets and can be disabled with -u.
  - You can also use existing minimap2 .mmi files in pbmm2 align.

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
baseCommand: [pbmm2, index]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  # Required Arguments
  reference_fasta: { type: 'File', secondaryFiles: [{ pattern: ".fai", required: true}], inputBinding: { position: 80 }, doc: "The reference genome in fasta format." }
  output_filename: { type: 'string', inputBinding: { position: 81 }, doc: "Output Reference Index" }

  # Parameter Set
  preset:
    type:
      - 'null'
      - type: enum
        name: preset
        symbols: ["SUBREAD","CCS","ISOSEQ","UNROLLED"]
    inputBinding:
      prefix: "--preset"
      position: 1
    doc: |
      Set alignment mode.
      Alignment modes of --preset:
        SUBREAD     : -k 19 -w 10
        CCS or HiFi : -k 19 -w 10 -u
        ISOSEQ      : -k 15 -w 5  -u
        UNROLLED    : -k 15 -w 15

  # Parameter Override
  align_kmer: { type: 'int?', inputBinding: { prefix: "-k", position: 1 }, doc: "k-mer size (no larger than 28)." }
  align_minimizer_window_size: { type: 'int?', inputBinding: { prefix: "-w", position: 1 }, doc: "Minimizer window size." }
  align_disable_hpc: { type: 'boolean?', inputBinding: { prefix: "--no-kmer-compression", position: 1 }, doc: "Disable homopolymer-compressed k-mer (compression is active for SUBREAD & UNROLLED presets)." }

  # Control
  cpu: { type: 'int?', default: 16, inputBinding: { prefix: "--num-threads", position: 1 }, doc: "Number of threads to use" }
  ram: { type: 'int?', default: 32, doc: "RAM (in GB) to use" }
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
  output_mmi: { type: 'File', outputBinding: { glob: $(inputs.output_filename) }, doc: "Minimap2 reference index" }
  output_log_file: { type: 'File?', outputBinding: { glob: $(inputs.log_file) }, doc: "Log output, if explicitly declared" }
