class: CommandLineTool
cwlVersion: v1.2
id: samtools_fastq
doc: |-
  Converts a BAM or CRAM into either FASTQ or FASTA format depending on the
  command invoked. The files will be automatically compressed if the file names
  have a .gz or .bgzf extension.
  
  If the input contains read-pairs which are to be interleaved or written to
  separate files in the same order, then the input should be first collated by
  name. Use samtools collate or samtools sort -n to ensure this.
  
  For each different QNAME, the input records are categorised according to the
  state of the READ1 and READ2 flag bits. The three categories used are: 1 : Only
  READ1 is set.  2 : Only READ2 is set.  0 : Either both READ1 and READ2 are set;
  or neither is set.
  
  The exact meaning of these categories depends on the sequencing technology
  used. It is expected that ordinary single and paired-end sequencing reads will
  be in categories 1 and 2 (in the case of paired-end reads, one read of the pair
  will be in category 1, the other in category 2). Category 0 is essentially a
  “catch-all” for reads that do not fit into a simple paired-end sequencing
  model.
  
  For each category only one sequence will be written for a given QNAME. If more
  than one record is available for a given QNAME and category, the first in input
  file order that has quality values will be used. If none of the candidate
  records has quality values, then the first in input file order will be used
  instead.
  
  Sequences will be written to standard output unless one of the -1, -2, -o, or
  -0 options is used, in which case sequences for that category will be written
  to the specified file. The same filename may be specified with multiple
  options, in which case the sequences will be multiplexed in order of
  occurrence.
  
  If a singleton file is specified using the -s option then only paired sequences
  will be output for categories 1 and 2; paired meaning that for a given QNAME
  there are sequences for both category 1 and 2. If there is a sequence for only
  one of categories 1 or 2 then it will be diverted into the specified singletons
  file. This can be used to prepare fastq files for programs that cannot handle a
  mixture of paired and singleton reads.
  
  The -s option only affects category 1 and 2 records. The output for category 0
  will be the same irrespective of the use of this option. 
requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'dmiller15/samtools:1.15'
baseCommand: [samtools, fastq]
arguments:
  - position: 99
    shellQuote: false
    valueFrom: >
      1>&2 

inputs:
  input_bam: { type: 'File', secondaryFiles: [{ pattern: '.bai', required: false }, { pattern: '^.bai', required: false }, { pattern: '.crai', required: false }, { pattern: '^.crai', required: false }], inputBinding: { position: 2 }, doc: "SAM/BAM/CRAM file" }

  # FASTQ Routing
  output_filename_singleton: { type: 'string?', inputBinding: { position: 1, prefix: "-s" }, doc: "Write singleton reads to FILE." }
  output_filename_read1: { type: 'string?', inputBinding: { position: 1, prefix: "-1" }, doc: "Write reads with the READ1 FLAG set (and READ2 not set) to FILE instead of outputting them. If the -s option is used, only paired reads will be written to this file." }
  output_filename_read2: { type: 'string?', inputBinding: { position: 1, prefix: "-2" }, doc: "Write reads with the READ2 FLAG set (and READ1 not set) to FILE instead of outputting them. If the -s option is used, only paired reads will be written to this file." }
  output_filename_read12: { type: 'string?', inputBinding: { position: 1, prefix: "-o" }, doc: "Write reads with either READ1 FLAG or READ2 flag set to FILE instead of outputting them to stdout. This is equivalent to -1 FILE -2 FILE." }
  output_filename_read0: { type: 'string?', inputBinding: { position: 1, prefix: "-0" }, doc: "Write reads where the READ1 and READ2 FLAG bits set are either both set or both unset to FILE instead of outputting them." }
  output_filename_read1_index: { type: 'string?', inputBinding: { position: 1, prefix: "--i1" }, doc: "write first index reads to FILE" }
  output_filename_read2_index: { type: 'string?', inputBinding: { position: 1, prefix: "--i2" }, doc: "write second index reads to FILE" }

  # Output Arguments 
  no_suffix: { type: 'boolean?', inputBinding: { position: 1, prefix: "-n" }, doc: "By default, either '/1' or '/2' is added to the end of read names where the corresponding READ1 or READ2 FLAG bit is set. Using -n causes read names to be left as they are." }
  always_suffix: { type: 'boolean?', inputBinding: { position: 1, prefix: "-N" }, doc: "Always add either '/1' or '/2' to the end of read names even when put into different files." }
  use_quality: { type: 'boolean?', inputBinding: { position: 1, prefix: "-O" }, doc: "Use quality values from OQ tags in preference to standard quality string if available." }
  copy_tags: { type: 'boolean?', inputBinding: { position: 1, prefix: "-t" }, doc: "Copy RG, BC and QT tags to the FASTQ header line, if they exist." }
  taglist: { type: 'string?', inputBinding: { position: 1, prefix: "-T" }, doc: "Specify a comma-separated list of tags to copy to the FASTQ header line, if they exist." }
  flag_include_any: { type: 'string[]?', inputBinding: { position: 1, prefix: "-f" }, doc: "Only output alignments with all bits set in INT present in the FLAG field. INT can be specified in hex by beginning with '0x' (i.e. /^0x[0-9A-F]+/) or in octal by beginning with '0' (i.e. /^0[0-7]+/) [0]." }
  flag_exclude_any: { type: 'string[]?', inputBinding: { position: 1, prefix: "-F" }, doc: "Do not output alignments with any bits set in INT present in the FLAG field. INT can be specified in hex by beginning with '0x' (i.e. /^0x[0-9A-F]+/) or in octal by beginning with '0' (i.e. /^0[0-7]+/) [0x900]. This defaults to 0x900 representing filtering of secondary and supplementary alignments." }
  flag_exclude_all: { type: 'string[]?', inputBinding: { position: 1, prefix: "-G" }, doc: "Only EXCLUDE reads with all of the bits set in INT present in the FLAG field. INT can be specified in hex by beginning with '0x' (i.e. /^0x[0-9A-F]+/) or in octal by beginning with '0' (i.e. /^0[0-7]+/) [0]." }
  add_casava: { type: 'boolean?', inputBinding: { position: 1, prefix: "-i" }, doc: "add Illumina Casava 1.8 format entry to header (eg 1:N:0:ATCACG)" }
  compression_level: { type: 'int?', inputBinding: { position: 1, prefix: "-c" }, doc: "set compression level when writing gz or bgzf fastq files." }
  barcode_tag: { type: 'string?', inputBinding: { position: 1, prefix: "--barcode-tag" }, doc: "Changes the auxiliary tag used for barcode sequence. Defaults to BC." }
  quality_tag: { type: 'string?', inputBinding: { position: 1, prefix: "--quality-tag" }, doc: "Changes the auxiliary tag used for barcode quality. Defaults to QT." }
  index_format: { type: 'string?', inputBinding: { position: 1, prefix: "--index-format" }, doc: "string to describe how to parse the barcode and quality tags. For example: i14i8 the first 14 characters are index 1, the next 8 characters are index 2; n8i14 ignore the first 8 characters, and use the next 14 characters for index 1; If the tag contains a separator, then the numeric part can be replaced with '*' to mean 'read until the separator or end of tag', for example: n*i* ignore the left part of the tag until the separator, then use the second part" }

  cores: { type: 'int?', default: 16, inputBinding: { position: 1, prefix: "--threads" }, doc: "Number of input/output compression threads to use in addition to main thread [0]." }

outputs:
  output: 
    type: File
    secondaryFiles: [{ pattern: '.tbi', required: false }]
    outputBinding:
      glob: '{*.fq,*.fq.gz,*.fastq,*fastq.gz}' 

$namespaces:
  sbg: https://sevenbridges.com
