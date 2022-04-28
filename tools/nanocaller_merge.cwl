class: CommandLineTool
cwlVersion: v1.2
id: nanocaller_merge
doc: |
  This tool merges the scattered VCFs generated by Nanocaller running on scattered intervals.

  Generalized psuedocode:
  - bcftools concat --allow-overlaps
  - bcftools sort
  - bgzip
  - tabix index

  For more information, visit https://github.com/WGLab/NanoCaller

requirements:
- class: InlineJavascriptRequirement
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: genomicslab/lrtools:v0.0.4
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cores)

baseCommand: [/bin/bash,-c]

arguments:
- position: 1
  prefix: ''
  shellQuote: true 
  valueFrom: >
    set -eo pipefail

    bcftools concat --allow-overlaps $(inputs.input_vcfs.filter(function(e) { return e !== null }).map(function(e) { return e.path }).join(' ')) | bcftools sort | bgziptabix $(inputs.output_basename).vcf.gz


inputs:
  input_vcfs: { type: 'File[]', secondaryFiles: [{ pattern: ".tbi", required: false }], doc: "Scattered VCFs from Nanocaller." }
  output_basename: { type: 'string?', default: 'merged', doc: "String to use as basename for output filename." }

  cores: { type: 'int?', default: 1, doc: "Number of input/output compression threads to use in addition to main thread [0]." }
  ram: { type: 'int?', default: 1, doc: "RAM (in GB) to use" }
  
outputs:
  merged_vcf: { type: 'File', secondaryFiles: [{pattern: '.tbi', required: true}],  outputBinding: { glob: "*.vcf.gz" }, doc: "Merged VCF file." }
