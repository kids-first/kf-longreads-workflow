cwlVersion: v1.2
class: CommandLineTool
id: bgzip_tabix_index
doc: >-
  BGZIP and TABIX Index an input file
requirements:
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/d3b-bixu/samtools:1.15.1'
  - class: InitialWorkDirRequirement
    listing: $(inputs.input_vcf)
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cores)
  - class: ShellCommandRequirement

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      bgzip -@ $(inputs.cores) $(inputs.input_vcf.basename)
  - position: 2
    shellQuote: false
    valueFrom: >-
      && tabix -p vcf $(inputs.input_vcf.basename).gz

inputs:
  input_vcf: { type: 'File', doc: "Position sorted input vcf file"}
  cores: { type: 'int?', default: 16 }

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.input_vcf.basename).gz
    secondaryFiles: [{ pattern: '.tbi', required: true }]
