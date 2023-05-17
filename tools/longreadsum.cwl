class: CommandLineTool
cwlVersion: v1.2
id: longreadsum
doc: |
  LongReadSum
  statistics of long-read sequencing datasets
  See: github.com/WGLab/LongReadSum
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: genomicslab/longreadsum:v1.2.0
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  coresMin: $(inputs.cpu)
  ramMin: $(inputs.ram * 1000)
baseCommand: []
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  input_type:
    type:
      type: enum
      name: input_type
      symbols: ["bam","f5","f5s","fa","fq","seqtxt"]
    inputBinding:
      prefix: ""
      position: 1
    doc: |
      Specify the type of the input file(s).
  input_file: { type: 'File?', inputBinding: { prefix: "--input", position: 2 }, doc: "The input file for the analysis" }
  input_files: { type: 'File[]?', inputBinding: { prefix: "--inputs", position: 2, itemSeparator: ",", shellQuote: false }, doc: "The input files for the analysis." }
  input_pattern: { type: 'string?', inputBinding: { prefix: "--inputPattern", position: 2 }, doc: "The pattern of input files with *. The format is \"patter*n\" where \" is required." }
  downsample_percentage: { type: 'float?', inputBinding: { prefix: "--downsample_percentage", position: 2 }, doc: "The percentage of downsampling for quick run. Default: 1.0 without downsampling." }

  # FQ Options
  udqual: { type: 'int?', inputBinding: { prefix: "--udqual", position: 2 }, doc: "User defined quality offset for bases in fq." }

  # SEQTXT Options
  seq:
    type:
      - 'null'
      - type: enum
        name: seq
        symbols: ["0","1"]
    inputBinding:
      prefix: "--seq"
      position: 2
    doc: "sequencing_summary.txt only? 0 no, 1 yes."
  sum_type:
    type:
      - 'null'
      - type: enum
        name: sum_type
        symbols: ["1","2","3"]
    inputBinding:
      prefix: "--sum_type"
      position: 2
    doc: "Different fields in sequencing_summary.txt."

  # Common Options
  fontsize: { type: 'int?', inputBinding: { position: 2, prefix: "--fontsize" }, doc: "Font size for plots." }
  markersize: { type: 'int?', inputBinding: { position: 2, prefix: "--markersize" }, doc: "Marker size for plots." }
  readCount: { type: 'int[]?', inputBinding: { position: 2, prefix: "--readCount" }, doc: "Set the number of reads to randomly sample from the file." }
  log: { type: 'string?', inputBinding: { prefix: "--log", position: 2 }, doc: "Name for log file" }
  log_level:
    type:
      - 'null'
      - type: enum
        name: log_level
        symbols: ["0","1","2","3","4","5","6"]
    inputBinding:
      prefix: "--log_level"
      position: 2
    doc: "Level for logging: ALL(0) < DEBUG(1) < INFO(2) < WARN(3) < ERROR(4) < FATAL(5) < OFF(6)."
  output_dir: { type: 'string?', inputBinding: { prefix: "--outputfolder", position: 2 }, doc: "Name for output directory." }
  output_basename: { type: 'string?', inputBinding: { prefix: "--outprefix", position: 2 }, doc: "String to use as basename for output(s)." }
  seed: { type: 'int?', inputBinding: { prefix: "--seed", position: 2 }, doc: "The number for random seed." }
  detail:
    type:
      - 'null'
      - type: enum
        name: detail
        symbols: ["0","1"]
    inputBinding:
      prefix: "--detail"
      position: 2
    doc: "Will output detail in files?"
  cpu: { type: 'int?', default: 16, inputBinding: { prefix: "--thread", position: 2 }, doc: "The number of threads used by this task" }
  ram: { type: 'int?', default: 16, doc: "GB of ram to allocate to this task" }

outputs:
  outputs: { type: 'Directory', outputBinding: { glob: "$(inputs.output_dir ? inputs.output_dir : 'output_LongReadSum')" }, doc: "Just grab everything I guess" }
  log_file: { type: 'File?', outputBinding: { glob: "$(inputs.log)" }, doc: "Log file." }
