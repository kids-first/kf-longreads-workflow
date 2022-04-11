class: CommandLineTool
cwlVersion: v1.2
id: samtools_import
doc: |-
  Reads one or more FASTQ files and converts them to unmapped SAM, BAM or CRAM.
  The input files may be automatically decompressed if they have a .gz extension.
  
  The simplest usage in the absence of any other command line options is to
  provide one or two input files.
  
  If a single file is given, it will be interpreted as a single-ended sequencing
  format unless the read names end with /1 and /2 in which case they will be
  labelled as PAIRED with READ1 or READ2 BAM flags set. If a pair of filenames
  are given they will be read from alternately to produce an interleaved output
  file, also setting PAIRED and READ1 / READ2 flags.
  
  The filenames may be explicitly labelled using -1 and -2 for READ1 and READ2
  data files, -s for an interleaved paired file (or one half of a paired-end
  run), -0 for unpaired data and explicit index files specified with --i1 and
  --i2. These correspond to typical output produced by Illumina bcl2fastq and
  match the output from samtools fastq. The index files will set both the BC
  barcode code and it's associated QT quality tag.
  
  The Illumina CASAVA identifiers may also be processed when the -i option is
  given. This tag will be processed for READ1 / READ2, whether or not the read
  failed processing (QCFAIL flag), and the barcode sequence which will be added
  to the BC tag. This can be an alternative to explicitly specifying the index
  files, although note that doing so will not fill out the barcode quality tag. 
requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/d3b-bixu/samtools:1.15.1'
baseCommand: [samtools, import]
arguments:
  - position: 99
    shellQuote: false
    valueFrom: >
      1>&2 
inputs:
  paired_interleaved_fastq:
    type:
      - 'null'
      - type: array
        items: File
        inputBinding:
          prefix: "-s" 
    inputBinding:
      position: 2
    doc: |
      Import paired interleaved data from FILE(s).
  single_end_fastq:
    type:
      - 'null'
      - type: array
        items: File
        inputBinding:
          prefix: "-0"
    inputBinding:
      position: 2
    doc: |
      Import single-ended (unpaired) data from FILE(s).
  paired_fastq_1: { type: 'File?', inputBinding: { position: 2, prefix: "-1" }, doc: "Import paired data from a pair of FILEs. The BAM flag PAIRED will be set, but not PROPER_PAIR as it has not been aligned. READ1 and READ2 will be stored in their original, unmapped, orientation." }
  paired_fastq_2: { type: 'File?', inputBinding: { position: 2, prefix: "-2" }, doc: "Import paired data from a pair of FILEs. The BAM flag PAIRED will be set, but not PROPER_PAIR as it has not been aligned. READ1 and READ2 will be stored in their original, unmapped, orientation." }
  paired_fastq_1_index: { type: 'File?', inputBinding: { position: 2, prefix: "--i1" }, doc: "Specifies index barcodes associated with the -1 and -2 files. These will be appended to READ1 and READ2 records in the barcode (BC) and quality (QT) tags." }
  paired_fastq_2_index: { type: 'File?', inputBinding: { position: 2, prefix: "--i2" }, doc: "Specifies index barcodes associated with the -1 and -2 files. These will be appended to READ1 and READ2 records in the barcode (BC) and quality (QT) tags." }
  process_casava: { type: 'boolean?', inputBinding: { position: 1, prefix: "-i" }, doc: "Specifies that the Illumina CASAVA identifiers should be processed. This may set the READ1, READ2 and QCFAIL flags and add a barcode tag." }
  use_name_2: { type: 'boolean?', inputBinding: { position: 1, prefix: "--name2" }, doc: "Assume the read names are encoded in the SRA and ENA formats where the first word is an automatically generated name with the second field being the original name. This option extracts that second field instead." }
  barcode_tag: { type: 'string?', inputBinding: { position: 1, prefix: "--barcode-tag" }, doc: "Changes the auxiliary tag used for barcode sequence. Defaults to BC." }
  quality_tag: { type: 'string?', inputBinding: { position: 1, prefix: "--quality-tag" }, doc: "Changes the auxiliary tag used for barcode quality. Defaults to QT." }
  output_filename: { type: 'string?', inputBinding: { position: 1, prefix: "-o" }, doc: "Output to FILE. By default output will be written to stdout." }
  order: { type: 'string?', inputBinding: { position: 1, prefix: "--order" }, doc: "When outputting a SAM record, also output an integer tag containing the Nth record number. This may be useful if the data is to be sorted or collated in some manner and we wish this to be reversible. In this case the tag may be used with samtools sort -t TAG to regenerate the original input order." }
  rg_line:
    type:
      - 'null'
      - type: array
        items: string
        inputBinding:
          prefix: "--rg-line"
    inputBinding:
      position: 1
    doc: |
      A complete @RG header line may be specified, with or without the initial "@RG"
      component. If specified this will also use the ID field from RG_line in each
      SAM records RG auxiliary tag. If specified multiple times this appends to the
      RG line, automatically adding tabs between invocations (for example, -r ID:xyz
      -r PL:ILLUMINA becomes @RG\tID:xyz\tPL:ILLUMINA)
  rg_id: { type: 'string?', inputBinding: { position: 1, prefix: "--rg" }, doc: "This is a shorter form of the option above, equivalent to --rg-line ID:RG_ID. If both are specified then this option is ignored." }
  uncompressed_output: { type: 'boolean?', inputBinding: { position: 1, prefix: "-u" }, doc: "Output BAM or CRAM as uncompressed data." }
  taglist: { type: 'string?', inputBinding: { position: 1, prefix: "-T" }, doc: "This looks for any SAM-format auxiliary tags in the comment field of a fastq read name. These must match the <alpha-num><alpha-num>:<type>:<data> pattern as specified in the SAM specification. TAGLIST can be blank or * to indicate all tags should be copied to the output, otherwise it is a comma-separated list of tag types to include with all others being discarded." }

outputs:
  output: 
    type: File
    secondaryFiles: [{ pattern: '.bai', required: false }, { pattern: '.crai', required: false }]
    outputBinding:
      glob: $(inputs.output_filename) 

$namespaces:
  sbg: https://sevenbridges.com
