cwlVersion: v1.2
class: CommandLineTool
id: tar
requirements:
  - class: InlineJavascriptRequirement
  - class: LoadListingRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cores)
  - class: InitialWorkDirRequirement
    listing: $(inputs.input_dir)
baseCommand: [tar, czf]
inputs:
  output_filename:
    type: string
    inputBinding:
      position: 1
  input_dir:
    type: Directory
    loadListing: deep_listing
    inputBinding:
      position: 2
      valueFrom: $(self.basename)
  # Control
  cores: { type: 'int?', default: 16, doc: "Number of threads to use." }
outputs:
  output: 
    type: File
    outputBinding:
      glob: $(inputs.output_filename)
