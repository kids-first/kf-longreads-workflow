cwlVersion: v1.2
class: CommandLineTool
id: picard_fastqtosam
doc: |-
  Convert FASTQ to SAM/BAM
requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: ResourceRequirement
    ramMin: $(inputs.max_memory * 1000)
  - class: DockerRequirement
    dockerPull: 'broadinstitute/gatk:4.2.5.0'
baseCommand: []
arguments:
  - position: 0
    prefix: ''
    shellQuote: false
    valueFrom: |
      gatk --java-options "-Xmx${return Math.floor(inputs.max_memory*1000/1.074-1)}m" FastqToSam
  - position: 99
    prefix: ''
    shellQuote: false
    valueFrom: |
      1>&2

inputs:
  fastq_1: { type: 'File', inputBinding: { prefix: "--FASTQ", position: 1 }, doc: "Input fastq file (optionally gzipped) for single end data, or first read in paired end data." }
  fastq_2: { type: 'File?', inputBinding: { prefix: "--FASTQ2", position: 1 }, doc: "Input fastq file (optionally gzipped) for the second read of paired end data." }
  output_filename: { type: 'string', inputBinding: { prefix: "--OUTPUT", position: 1 }, doc: "Output SAM/BAM file." }
  sample_name: { type: 'string', inputBinding: { prefix: "--SAMPLE_NAME", position: 1 }, doc: "Sample name to insert into the read group header" }

  # Header Arguments
  comment: { type: 'string?', inputBinding: { prefix: "--COMMENT", position: 1 }, doc: "Comment(s) to include in the merged output file's header." }
  description: { type: 'string?', inputBinding: { prefix: "--DESCRIPTION", position: 1 }, doc: "Inserted into the read group header" }
  library_name: { type: 'string?', inputBinding: { prefix: "--LIBRARY_NAME", position: 1 }, doc: "The library name to place into the LB attribute in the read group header" }
  platform: { type: 'string?', inputBinding: { prefix: "--PLATFORM", position: 1 }, doc: "The platform type (e.g. ILLUMINA, SOLID) to insert into the read group header" }
  platform_model: { type: 'string?', inputBinding: { prefix: "--PLATFORM_MODEL", position: 1 }, doc: "Platform model to insert into the group header (free-form text providing further details of the platform/technology used)" }
  platform_unit: { type: 'string?', inputBinding: { prefix: "--PLATFORM_UNIT", position: 1 }, doc: "The platform unit (often run_barcode.lane) to insert into the read group header" }
  predicted_insert_size: { type: 'int?', inputBinding: { prefix: "--PREDICTED_INSERT_SIZE", position: 1 }, doc: "Predicted median insert size, to insert into the read group header" }
  program_group: { type: 'string?', inputBinding: { prefix: "--PROGRAM_GROUP", position: 1 }, doc: "Program group to insert into the read group header." }
  read_group_name: { type: 'string?', inputBinding: { prefix: "--READ_GROUP_NAME", position: 1 }, doc: "Read group name" }
  run_date: { type: 'string?', inputBinding: { prefix: "--RUN_DATE", position: 1 }, doc: "Date the run was produced, to insert into the read group header" }
  sequencing_center: { type: 'string?', inputBinding: { prefix: "--SEQUENCING_CENTER", position: 1 }, doc: "The sequencing center from which the data originated" }
  
  # Input Handling/Filtering Arguments
  ignore_empty: { type: 'boolean?', inputBinding: { prefix: "--ALLOW_AND_IGNORE_EMPTY_LINES", position: 1 }, doc: "Allow (and ignore) empty lines" }
  max_q: { type: 'int?', inputBinding: { prefix: "--MAX_Q", position: 1 }, doc: "Maximum quality allowed in the input fastq. An exception will be thrown if a quality is greater than this value." }
  min_q: { type: 'int?', inputBinding: { prefix: "--MIN_Q", position: 1 }, doc: "Minimum quality allowed in the input fastq. An exception will be thrown if a quality is less than this value." }
  quality_format:
    type:
      - 'null'
      - type: enum
        name: quality_format 
        symbols: ["Solexa","Illumina","Standard"]
    inputBinding:
      prefix: "--QUALITY_FORMAT"
      position: 1
    doc: |
      A value describing how the quality values are encoded in the input FASTQ file.
      Either Solexa (phred scaling + 66), Illumina (phred scaling + 64) or Standard
      (phred scaling + 33). If this value is not specified, the quality format will
      be detected automatically.
  use_sequential_fastqs: { type: 'boolean?', inputBinding: { prefix: "--USE_SEQUENTIAL_FASTQS", position: 1 }, doc: "Use sequential fastq files with the suffix _###.fastq or _###.fastq.gz.The files should be named: _001., _002., ..., _XYZ. The base files should be: _001. An example would be: RUNNAME_S8_L005_R1_001.fastq RUNNAME_S8_L005_R1_002.fastq RUNNAME_S8_L005_R1_003.fastq RUNNAME_S8_L005_R1_004.fastq RUNNAME_S8_L005_R1_001.fastq should be provided as FASTQ." }

  # Output Handling Arguments
  sort_order:
    type:
      - 'null'
      - type: enum
        name: sort_order 
        symbols: ["unsorted", "queryname", "coordinate", "duplicate", "unknown"]
    inputBinding:
      prefix: "--SORT_ORDER"
      position: 1
    doc: |
      The sort order for the output sam/bam file.
  create_index: { type: 'boolean?', inputBinding: { prefix: "--CREATE_INDEX", position: 1 }, doc: "Whether to create an index when writing VCF or coordinate sorted BAM output." }

  # Control
  max_memory: { type: 'int?', default: 16, doc: "GB of memory to use for this task." }

outputs:
  output: { type: 'File', secondaryFiles: [{ pattern: '.bai', required: false }, { pattern: '^.bai', required: false }], outputBinding: { glob: $(inputs.output_filename) } }
