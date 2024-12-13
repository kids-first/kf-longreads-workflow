cwlVersion: v1.2
class: CommandLineTool
label: sentieon_minimap2
doc: |-
  The Sentieon **minimap2** binary performs alignment of PacBio or Oxford
  Nanopore genomic reads data and will behave the same way as the tool described
  in [https://github.com/lh3/minimap2](https://github.com/lh3/minimap2)
  (2.22-r1101). This App outputs the sorted BAM.

  ### Inputs:
  - ``Reference``: Location of the reference FASTA file (Required)
  - ``Input reads``: Files containing reads (Required)

requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  coresMin: $(inputs.cpu_per_job)
  ramMin: $(inputs.mem_per_job * 1000)
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/hdchen/sentieon:202308.03
- class: EnvVarRequirement
  envDef:
  - envName: SENTIEON_LICENSE
    envValue: $(inputs.sentieon_license)

baseCommand: []

arguments:
- prefix: ''
  position: 1
  valueFrom: |
    $(inputs.input_type == 'uBAM' ? 'samtools fastq ' + inputs.in_reads.map(function(e) {return e.path}).join(' ') + ' | ' : '') 
  shellQuote: false
- prefix: ''
  position: 100
  valueFrom: 'sentieon minimap2'
  shellQuote: false
- prefix: ''
  position: 102
  valueFrom: |
    $(inputs.output_type == 'BAM' ? '-a': '')
  shellQuote: false
- prefix: ''
  position: 102
  valueFrom: $("-t $(nproc)")
  shellQuote: false
- prefix: ''
  position: 199
  valueFrom: |
    $(inputs.input_type == 'uBAM' ? '-' : inputs.in_reads.map(function(e) {return e.path}).join(' '))
  shellQuote: false
- prefix: ''
  position: 201
  valueFrom: |
    $(inputs.output_type == 'BAM' ? ' | sentieon util sort -i - --sam2bam ' : '')
  shellQuote: false
- prefix: -o
  position: 299
  valueFrom: |-
    ${
        // generate output file name
        var out_name = ""
        var ext = "" 
        if (inputs.output_basename)
        {
            out_name = inputs.output_basename
        }
        else
        {
            var reads = [].concat(inputs.in_reads)
            if ((reads[0].metadata) && (reads[0].metadata['sample_id']))
            {
                out_name = reads[0].metadata['sample_id']
            }
            else
            {
                out_name = reads[0].nameroot
            }
        } 
        ext = (inputs.output_type == 'BAM' ? '.bam' : '.paf')
        return out_name + ext
    }
  shellQuote: false

inputs:
  # Required Arguments
  sentieon_license: { type: 'string', doc: "License server host and port." }
  reference: { type: 'File', inputBinding: { position: 198, shellQuote: false }, doc: "Reference file or minimap reference index. Beware that indexing options are fixed in the index file. When an index file is provided as the target sequences, options -H, -k, -w, -I will be effectively overridden by the options stored in the index file.", "sbg:fileTypes": "FA, MMI, FASTA" }
  in_reads: { type: 'File[]', doc: "File or files containing reads.", "sbg:fileTypes": "FQ, FASTQ, FQ.GZ, FASTQ.GZ, BAM" }

  # Common Arguments
  output_basename: { type: 'string?', doc: "Desired output file name (without an extension). If not filled, output file is named based on sample ID metadata, if that is not present, output name is generated based on input read names." }
  input_type:
    type:
    - 'null'
    - name: input_type
      type: enum
      symbols:
      - uBAM
      - FASTQ/A
    default: 'FASTQ/A'
    doc: |
      If input is FASTQ/FASTQ, minimap2 will be run directly on inputs. If the input
      is uBAM, the files will first be processed by samtools fastq before being fed
      into minimap2.
  output_type:
    type:
    - 'null'
    - name: output_type
      type: enum
      symbols:
      - BAM
      - PAF
    default: BAM
    doc: |
      Output alignments in BAM or in PAF format. Setting this parameter to BAM,
      prefix '-a' is added to the command line and the output will be sorted.
  preset_option:
    type:
    - 'null'
    - name: preset_options
      type: enum
      symbols:
      - map-pb
      - map-ont
      - asm5
      - asm10
      - asm20
      - ava-pb
      - ava-ont
      - splice
      - splice:hq
      - sr
      - map-hifi
    inputBinding:
      prefix: -x
      position: 111
      shellQuote: false
    doc: |-
      Select one of the preset options prepared by the tool authors. Selecting one of
      these options will apply multiple options at the same time. It should be
      applied before other options because options applied later will overwrite the
      values set.
  read_group_line: { type: 'string', inputBinding: { position: 112, prefix: "-R", shellQuote: true }, doc: "SAM read group line in a format like '@RG\tID:foo\tSM:bar\tPL:PacBio'" }

  # Alignment Arguments
  matching_score: { type: 'int?', inputBinding: { position: 112, prefix: "-A" }, doc: "Matching score" }
  mismatch_penalty: { type: 'int?', inputBinding: { position: 112, prefix: "-B" }, doc: "Mismatch penalty" }
  gap_open_penalty: { type: 'int[]?', inputBinding: { position: 112, prefix: "-O", itemSeparator: ",", shellQuote: false }, doc: "Gap open penalty [default: 4,24]. If INT2 is not specified, it is set to INT1." }
  gap_extension_penalty: { type: 'int[]?', inputBinding: { position: 112, prefix: "-E", itemSeparator: ",", shellQuote: false }, doc: "Gap extension penalty [default: 2,1]. A gap of length k costs min{O1+k*E1,O2+k*E2}. In the splice mode, the second gap penalties are not used." }
  zdrop: { type: 'int[]?', inputBinding: { position: 112, prefix: "-z", itemSeparator: ",", shellQuote: false }, doc: "Truncate an alignment if the running alignment score drops too quickly along the diagonal of the DP matrix (diagonal X-drop, or Z-drop) [400,200]." }
  min_dp_score: { type: 'int?', inputBinding: { position: 112, prefix: "-s" }, doc: "Minimal peak DP alignment score to output [default: 40]. The peak score is computed from the final CIGAR. It is the score of the max scoring segment in the alignment and may be different from the total alignment score." }

  # Input/Output Arguments
  write_cigar: { type: 'boolean?', inputBinding: { position: 112, prefix: "-L" }, doc: "Write CIGAR with >65535 operators at the CG tag. Older tools are unable to convert alignments with >65535 CIGAR ops to BAM. This option makes minimap2 SAM compatible with older tools. Newer tools recognizes this tag and reconstruct the real CIGAR in memory." }
  copy_comments: { type: 'boolean?', inputBinding: { position: 112, prefix: "-y" }, doc: "Copy input FASTA/Q comments." }
  create_cigar: { type: 'boolean?', inputBinding: { position: 112, prefix: "-c" }, doc: "Generate CIGAR. In PAF, the CIGAR is written to the 'cg' custom tag." }
  ouput_cs_tag:
    type:
    - 'null'
    - name: ouput_cs_tag
      type: enum
      symbols:
      - short
      - long
    inputBinding:
      prefix: -cs=
      position: 112
      separate: false
    doc: |-
      Output the cs tag. STR can be either short or long. If no STR is given, short is assumed. [default: none]
  md_tag: { type: 'boolean?', inputBinding: { position: 112, prefix: "--MD" }, doc: "Output the MD tag (see the SAM spec)." }
  eqx: { type: 'boolean?', inputBinding: { position: 112, prefix: "--eqx" }, doc: "Output =/X CIGAR operators for sequence match/mismatch." }
  soft_clipping: { type: 'boolean?', inputBinding: { position: 112, prefix: "-Y" }, doc: "In SAM output, use soft clipping for supplementary alignments." }
  minibatch_size: { type: 'string?', inputBinding: { position: 112, prefix: "-K" }, doc: "Number of bases loaded into memory to process in a mini-batch [500M]." }
  additional_inputs: { type: 'string?', inputBinding: { position: 197, shellQuote: false }, doc: "Optional input for additional arguments." }
  cpu_per_job: { type: 'int?', default: 36, doc: "CPU per job" }
  mem_per_job: { type: 'int?', default: 36, doc: "Memory per job[GB]" }

outputs:
  out_alignments: { type: 'File', secondaryFiles: [{ pattern: '.bai', required: false }], outputBinding: { glob: '{*.paf,*.bam}' }, doc: "Output alignment file in PAF or BAM format." }

$namespaces:
  sbg: https://sevenbridges.com
