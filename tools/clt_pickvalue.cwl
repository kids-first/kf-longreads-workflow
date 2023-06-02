cwlVersion: v1.2
class: CommandLineTool
id: clt_pickvalue
doc: |
  Given a file return that file. Used to simplify some pickvalue scenarios.
requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cpu)
    ramMin: $(inputs.ram * 1000)
baseCommand: [echo, done]
inputs:
  infile: { type: 'File' }
  cpu: { type: 'int?', default: 8, doc: "CPUs to allocate to this task." }
  ram: { type: 'int?', default: 16, doc: "RAM (in GB) to allocate to this task." }
outputs:
  outfile:
    type: File
    outputBinding:
      outputEval: |
        $(inputs.infile)
