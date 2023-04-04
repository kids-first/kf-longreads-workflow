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
  dockerPull: pgc-images.sbgenomics.com/danmiller/longreadsum:1.0.1
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  coresMin: $(inputs.cores)
baseCommand: []
arguments:
- position: 0
  prefix: ''
  shellQuote: false
  valueFrom: |
    LongReadSum
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
      symbols: ["bam","f5","fa","fq"]
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

  # Common Options
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
  cores: { type: 'int?', inputBinding: { prefix: "--thread", position: 2 }, doc: "The number of threads used by this task" }
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

outputs:
  outputs: { type: 'Directory', outputBinding: { glob: "$(inputs.output_dir ? inputs.output_dir : 'output_LongReadSum')" }, doc: "Just grab everything I guess" }
