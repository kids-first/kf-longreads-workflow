cwlVersion: v1.2
class: CommandLineTool
id: sentieon_LongReadSV
doc: |-
  Sentieon SV calling for PacBio HiFi and Oxford Nanopore long reads.
  
  ### Inputs:
  #### Required
  - ``Reference``: Location of the reference FASTA file.
  - ``Input BAM``: Location of the BAM/CRAM input file.
  - ``Platform``: PacBio HiFi or Oxford Nanopore

requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  coresMin: $(inputs.cpu) 
  ramMin: $(inputs.ram * 1000) 
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/hdchen/sentieon:202112.06
- class: EnvVarRequirement
  envDef:
  - envName: SENTIEON_LICENSE
    envValue: $(inputs.sentieon_license)
baseCommand:
- sentieon
- driver
arguments:
- prefix: '--algo'
  position: 10
  valueFrom: LongReadSV
  shellQuote: false
inputs:
  sentieon_license:
    type: 'string'
    doc: License server host and port
  reference:
    type: 'File'
    secondaryFiles:
    - pattern: .fai
      required: true
    - pattern: ^.dict
      required: true
    inputBinding:
      prefix: -r
      position: 0
      shellQuote: false
    doc: Reference fasta with associated fai index
    sbg:fileTypes: FA, FASTA
  input_bam:
    type: 'File'
    secondaryFiles:
    - pattern: ^.bai
      required: false
    - pattern: ^.crai
      required: false
    - pattern: .bai
      required: false
    - pattern: .crai
      required: false
    inputBinding:
      prefix: -i
      position: 1
      shellQuote: false
    doc: Input BAM file
    sbg:fileTypes: BAM, CRAM
  platform:
    type:
    - 'null'
    - name: platform
      type: enum
      symbols:
      - PacBioHiFi
      - ONT
    default: PacBioHiFi
    inputBinding:
      prefix: --model
      position: 11
      shellQuote: true
      valueFrom: |-
        ${
            if (self === "PacBioHiFi") {
                return "/opt/dnascope_models/SentieonLongReadSVHiFiBeta0.1.model";
            }
            else if (self === "ONT") {
                return "/opt/dnascope_models/SentieonLongReadSVONTBeta0.1.model";
            }
            return ""
         }
    doc: |-
      PacBio HiFi or Oxford Nanopore (ONT)
    sbg:toolDefaultValue: PacBioHiFi
  min_sv_size:
    type: 'int?'
    inputBinding:
      prefix: --min_sv_size
      shellQuote: true
      position: 12
    doc:  minimum SV size in basepairs to output
    sbg:toolDefaultValue: 40
  min_map_qual:
    type: 'int?'
    inputBinding:
      prefix: --min_map_qual
      shellQuote: true
      position: 12
    doc:  minimum read mapping quality
    sbg:toolDefaultValue: 20
  output_file_name:
    type: 'string'
    inputBinding:
      position: 100
      shellQuote: true
    doc: The output VCF file name. Must end with ".vcf.gz".
  cpu:
    type: 'int?'
    default: 32
    doc: CPUs to allocate to this task
  ram:
    type: 'int?'
    default: 32
    doc: GB of RAM to allocate to this task 
outputs:
  output_vcf:
    type: 'File'
    secondaryFiles:
    - pattern: .tbi
      required: true
    outputBinding:
      glob: '*.vcf.gz'
    sbg:fileTypes: VCF.GZ

$namespaces:
  sbg: https://sevenbridges.com
