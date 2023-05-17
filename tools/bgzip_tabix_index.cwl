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
    coresMin: $(inputs.cpu)
    ramMin: $(inputs.ram * 1000)
  - class: ShellCommandRequirement

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      bgzip -@ $(inputs.cpu) $(inputs.input_vcf.basename)
  - position: 2
    shellQuote: false
    valueFrom: >-
      && tabix -p vcf $(inputs.input_vcf.basename).gz

inputs:
  input_vcf: { type: 'File', doc: "Position sorted input vcf file"}
  cpu: { type: 'int?', default: 8 }
  ram: { type: 'int?', default: 16 }

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.input_vcf.basename).gz
    secondaryFiles: [{ pattern: '.tbi', required: true }]
