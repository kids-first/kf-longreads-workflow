class: CommandLineTool
cwlVersion: v1.2
id: nanocaller_scatter
doc: |
  This tool uses the Nanocaller_WGS interval scattering code and runs
  it as a standalone tool.

  Generalized psuedocode:
  - If the user provides the chromosome argument use that as the base contig list
  - If the user sets a wgs_contigs_type use that as the base contig list (AUTOSOMES ONLY!)
  - If neither of the above, all chromosomes found in the reference fai will be the base contig list
  - If the include_bed is provided, only use the contigs that overlap with the regions in that file
  - For each contig in the contig list, strike those contigs that are not found in both the reference fai and BAM (determined by comparison to idxstats)
  - Finally split those contigs by chromosome x interval_len, putting a bed style format into a unique file

  The output files will be used to split future Nanocaller runs.

  For more information, visit https://github.com/WGLab/NanoCaller

requirements:
- class: InlineJavascriptRequirement
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: genomicslab/lrtools:v0.0.4
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cores)
- class: InitialWorkDirRequirement
  listing:
  - entryname: nanocaller_scatter.py
    writable: false
    entry:
      $include: ../scripts/nanocaller_scatter.py

baseCommand: [python, nanocaller_scatter.py]

inputs:
  # Required Arguments
  input_bam: { type: 'File', secondaryFiles: [{ pattern: ".bai", required: true }],  inputBinding: { prefix: "--bam", position: 1 }, doc: "Bam file, should be phased if 'indel' mode is selected" }
  reference_fai: { type: 'File', inputBinding: { prefix: "--ref_fai", position: 1 }, doc: "Reference genome file .fai index" }

  # Region Arguments
  interval_length: { type: 'int?', inputBinding: { prefix: "--interval_len", position: 1 }, doc: "Length of split intervals. Lower the value to make smaller intervals. Increase the value to make larger intervals." }
  chrom: { type: 'string?', inputBinding: { prefix: "--chrom", position: 1 }, doc: "Chromosome to which calling will be restricted. Required for WXS. If running in WGS mode multiple chromosomes can be provided as a whitespace separated list (e.g. 'chr1 chr11 chr14')." }
  include_bed: { type: 'File?', secondaryFiles: [{pattern: ".tbi", required: true}], inputBinding: { prefix: "--include_bed", position: 1 }, doc: "Only call variants inside the intervals specified in the
bgzipped and tabix indexed BED file. If any other flags are used to specify a region, intersect the region with intervals in the BED file, e.g. if -chom chr1 -start 10000000 -end 20000000 flags are set, c
all variants inside the intervals specified by the BED file that overlap with chr1:10000000-20000000. Same goes for the case when whole genome variant calling flag is set." }
  wgs_contigs_type:
    type:
      - 'null'
      - type: enum
        name: wgs_contigs_type
        symbols: ["with_chr", "without_chr", "all"]
    inputBinding:
      prefix: "--wgs_contigs_type"
      position: 1
    doc: |
      Options are "with_chr", "without_chr" and "all", "with_chr"
      option will assume human genome and run NanoCaller on chr1-22, "without_chr"
      will run on chromosomes 1-22 if the BAM and reference genome files use
      chromosome names without "chr". "all" option will run NanoCaller on each contig
      present in reference genome FASTA file.

  # Output Arguments
  output_dir: { type: 'string?', inputBinding: { prefix: "--output", position: 1 }, doc: "VCF output path, default is current working directory" }

  # Resource Control
  cores: { type: 'int?', default: 1, doc: "Number of input/output compression threads to use in addition to main thread [0]." }
  ram: { type: 'int?', default: 1, doc: "RAM (in GB) to use" }
  
outputs:
  scattered_interval_beds: { type: 'File[]', outputBinding: { glob: "$(inputs.output_dir ? inputs.output_dir+'/*.bed' : '*.bed')" }, doc: "Scattered interval beds." }
