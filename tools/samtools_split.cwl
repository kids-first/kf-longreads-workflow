class: CommandLineTool
cwlVersion: v1.2
id: samtools_split
doc: |-
  splits a file by read group
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: '684194535433.dkr.ecr.us-east-1.amazonaws.com/d3b-healthomics:samtools-1.17'
  - class: ResourceRequirement
    coresMin: $(inputs.cpu)
    ramMin: $(inputs.ram * 1000)
baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >
      if [ `samtools head $(inputs.input_reads.path) | grep -c ^@RG` = 1 ]; then >&2 echo "only one read group"; exit 0; fi
  - position: 10
    shellQuote: false
    prefix: "&&"
    valueFrom: >
      >&2 samtools split
inputs:
  input_reads: { type: 'File', secondaryFiles: [{ pattern: '.bai', required: false }, { pattern: '^.bai', required: false }, { pattern: '.crai', required: false }, { pattern: '^.crai', required: false }], inputBinding: { position: 19 }, doc: "BAM/CRAM/SAM files to split." }

  output_filename: { type: 'int?', inputBinding: { position: 12, prefix: "-f" }, doc: "output filename format string ['%*_%#.%.']. Format string expansions: '%% is %, %* is basename, %# is @RG index, %! is @RG ID, %. is filename extension for output format" }
  untagged_output_filename: { type: 'string?', inputBinding: { position: 12, prefix: "-u" }, doc: "put reads with no RG tag or an unrecognised RG tag in this filename" }
  header_file: { type: 'File?', inputBinding: { position: 12, prefix: "-h" }, doc: "file containing override header information" }
  verbose: { type: 'int?', inputBinding: { position: 12, prefix: "-v" }, doc: "verbose output" }
  no_pg: { type: 'int?', inputBinding: { position: 12, prefix: "--no-PG" }, doc: "do not add a PG line" }

  # Generic File Options
  input_fmt_option: { type: 'int?', inputBinding: { position: 12, prefix: "--input-fmt-option" }, doc: "Specify a single input file format option in the form of OPTION or OPTION=VALUE" }
  output_fmt: { type: 'int?', inputBinding: { position: 12, prefix: "--output-fmt" }, doc: "Specify output format (SAM, BAM, CRAM)" }
  output_fmt_option: { type: 'int?', inputBinding: { position: 12, prefix: "--output-fmt-option" }, doc: "Specify a single output file format option in the form of OPTION or OPTION=VALUE" }
  reference: { type: 'File?', inputBinding: { position: 12, prefix: "--reference" }, doc: "Reference sequence FASTA FILE [null]" }
  threads: { type: 'int?', inputBinding: { position: 12, prefix: "--threads" }, doc: "Number of additional threads to use [0]" }
  write_index: { type: 'int?', inputBinding: { position: 12, prefix: "--write-index" }, doc: "Automatically index the output files [off]" }
  verbosity: { type: 'int?', inputBinding: { position: 12, prefix: "--verbosity" }, doc: "Set level of verbosity" }

  cpu: { type: 'int?', default: 4, inputBinding: { position: 12, prefix: "--threads" }, doc: "CPUs to allocate to this task." }
  ram: { type: 'int?', default: 16, doc: "RAM (in GB) to allocate to this task." }
outputs:
  output:
    type: File[]
    outputBinding:
      glob: "*.*am"
      outputEval: |
        $(self.length == 0 ? [inputs.input_reads] : self)
  untagged_reads:
    type: File?
    outputBinding:
      glob: $(inputs.untagged_output_filename)

$namespaces:
  sbg: https://sevenbridges.com
