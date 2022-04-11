class: CommandLineTool
cwlVersion: v1.2
id: pbsv_discover
doc: |
  Discover signatures of structural variation (BAM to SVSIG).

  pbsv is a suite of tools to call and analyze structural variants in diploid
  genomes from PacBio single molecule real-time sequencing (SMRT) reads. The
  tools power the Structural Variant Calling analysis workflow in PacBio's SMRT
  Link GUI.

  pbsv calls insertions, deletions, inversions, duplications, and translocations.
  Both single-sample calling and joint (multi-sample) calling are provided. pbsv
  is most effective for:
    insertions 20 bp to 10 kb
    deletions 20 bp to 100 kb
    inversions 200 bp to 10 kb
    duplications 20 bp to 10 kb
    translocations between different chromosomes or further than 100kb apart on a single chromosome

  For more information, visit https://github.com/PacificBiosciences/pbsv
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: quay.io/biocontainers/pbsv:2.8.0--h9ee0642_0
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cores)
baseCommand: [pbsv, discover]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  # Required Arguments
  input_bam: { type: 'File', secondaryFiles: [{ pattern: ".bai", required: false}, { pattern: "^.bai", required: false}], inputBinding: { position: 80 }, doc: "Coordinate-sorted aligned reads in which to identify SV signatures." }
  output_filename: { type: 'string', inputBinding: { position: 81 }, doc: "Structural variant signatures output filename." }

  # Basic Arguments
  hifi_preset: { type: 'boolean?', inputBinding: { prefix: "--hifi", position: 1 }, doc: "Use options optimized for HiFi/CCS reads: -y 97" }

  # Sample Arguments
  override_sample_name: { type: 'string?', inputBinding: { prefix: "--sample", position: 1 }, doc: "Sample name to use for SV calls. Overrides sample name tag from BAM read group." }

  # Alignment Filter Arguments
  min_mapq: { type: 'int?', inputBinding: { prefix: "--min-mapq", position: 1 }, doc: "Ignore alignments with mapping quality < N." }
  min_ref_span: { type: 'string?', inputBinding: { prefix: "--min-ref-span", position: 1 }, doc: "Ignore alignments with reference length < N bp (e.g. '100', '10K', '3M')." }
  min_gap_comp_id_perc: { type: 'float?', inputBinding: { prefix: "--min-gap-comp-id-perc", position: 1 }, doc: "Ignore alignments with gap-compressed sequence identity < N%." }

  # Downsample Arguments
  downsample_window_length: { type: 'string?', inputBinding: { prefix: "--downsample-window-length", position: 1 }, doc: "Window in which to limit coverage, in basepairs (e.g. '100', '10K', '3M')." }
  downsample_max_alignments: { type: 'int?', inputBinding: { prefix: "--downsample-max-alignments", position: 1 }, doc: "Consider up to N alignments in a window; 0 means disabled." }

  # Discovery Arguments
  region: { type: 'string?', inputBinding: { prefix: "--region", position: 1 }, doc: "Limit discovery to this reference region: CHR|CHR:START-END." }
  min_svsig_length: { type: 'string?', inputBinding: { prefix: "--min-svsig-length", position: 1 }, doc: "Ignore SV signatures with length < N bp (e.g. '100', '10K', '3M')." }
  tandem_repeats: { type: 'File?', inputBinding: { prefix: "--tandem-repeats", position: 1 }, doc: "Tandem repeat intervals for indel clustering." }
  max_skip_split: { type: 'string?', inputBinding: { prefix: "--max-skip-split", position: 1 }, doc: "Ignore alignment pairs separated by > N bp (e.g. '100', '10K', '3M') of a read or reference." }

  # Control
  cores: { type: 'int?', default: 16, doc: "Number of threads to use" }
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
  output_svsig: { type: 'File', outputBinding: { glob: $(inputs.output_filename) }, doc: "Structural variant signatures output" }
  output_log_file: { type: 'File?', outputBinding: { glob: $(inputs.log_file) }, doc: "Log output, if explicitly declared" }
