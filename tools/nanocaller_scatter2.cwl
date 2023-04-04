class: CommandLineTool
cwlVersion: v1.2
id: nanocaller_scatter
doc: |
  This tool uses the Nanocaller_WGS interval scattering code and runs
  it as a standalone tool.

  Generalized psuedocode:
  - If the user sets a primary_contigs_only use only the primary contigs 
  - If the user provides region strings, use those
  - If the user provides the bed, only use the contigs that overlap with the regions in that file
  - For each contig in the contig list, strike those contigs that are not found in both the reference fai and BAM (determined by comparison to idxstats)
  - Finally split those contigs by chromosome x interval_len, putting a bed style format into a unique file

  The output files will be used to split future Nanocaller runs.

  For more information, visit https://github.com/WGLab/NanoCaller

requirements:
- class: InlineJavascriptRequirement
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: quay.io/biocontainers/pysam:0.20.0--py39h9abd093_0
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cores)
- class: InitialWorkDirRequirement
  listing:
  - entryname: nanocaller_scatter.py
    writable: false
    entry:
      $include: ../scripts/nanocaller_scatter2.py

baseCommand: [python, nanocaller_scatter.py]

inputs:
  # Required Arguments
  input_bam: { type: 'File', secondaryFiles: [{ pattern: ".bai", required: true }],  inputBinding: { prefix: "--bam", position: 1 }, doc: "Bam file, should be phased if 'indel' mode is selected" }

  # Region Arguments
  primary_contigs_only: { type: 'boolean?', inputBinding: { position: 2, prefix: "--primary_contigs_only" }, doc: "Only analyze the primary contigs. Recommended for WGS." }
  regions: { type: 'string[]?', inputBinding: { position: 2, prefix: "--regions" }, doc: "A space/whitespace separated list of regions specified as 'CONTIG_NAME' or 'CONTIG_NAME:START-END'. If you want to use 'CONTIG_NAME:START-END' format then specify both start and end coordinates. For example: chr3 chr6:28000000-35000000 chr22." }
  bed: { type: 'File?', inputBinding: { position: 2, prefix: "--bed" }, doc: "A BED file specifying regions for variant calling." }
  interval_length: { type: 'int?', inputBinding: { prefix: "--interval_len", position: 1 }, doc: "Length of split intervals. Lower the value to make smaller intervals. Increase the value to make larger intervals." }

  # Resource Control
  cores: { type: 'int?', default: 1, doc: "Number of input/output compression threads to use in addition to main thread [0]." }
  ram: { type: 'int?', default: 1, doc: "RAM (in GB) to use" }
  
outputs:
  scattered_interval_beds: { type: 'File[]', secondaryFiles: [{pattern: '.tbi', required: true}],  outputBinding: { glob: "*.bed" }, doc: "Scattered interval beds." }
