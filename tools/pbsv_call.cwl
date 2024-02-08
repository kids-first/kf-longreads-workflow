class: CommandLineTool
cwlVersion: v1.2
id: pbsv
doc: |
  Call structural variants from SV signatures and assign genotypes (SVSIG to VCF).

  pbsv is a suite of tools to call and analyze structural variants in diploid
  genomes from PacBio single molecule real-time sequencing (SMRT) reads. The
  tools power the Structural Variant Calling analysis workflow in PacBio's SMRT
  Link GUI.

  pbsv calls insertions, deletions, inversions, duplications, and translocations.
  Both single-sample calling and joint (multi-sample) calling are provided. pbsv
  is most effective for:
    insertions 20 bp to 10 kb
    deletions 20 bp to 100 kb
    inversions 200 bp to 10 kb
    duplications 20 bp to 10 kb
    translocations between different chromosomes or further than 100kb apart on a single chromosome

  For more information, visit https://github.com/PacificBiosciences/pbsv
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: 684194535433.dkr.ecr.us-east-1.amazonaws.com/d3b-healthomics:pbsv-2.9.0--h9ee0642_0
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cpu)
baseCommand: [pbsv, call]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  # Required Arguments
  reference_fasta: { type: 'File', secondaryFiles: [{ pattern: ".fai", required: true}], inputBinding: { position: 80 }, doc: "The reference genome in fasta format." }
  input_svsig: { type: 'File', inputBinding: { position: 81 }, doc: "SV signatures from one or more samples from pbsv discover." }
  output_filename: { type: 'string', inputBinding: { position: 81 }, doc: "Output Variant call format (VCF) filename" }

  # Basic Arguments
  region: { type: 'string?', inputBinding: { prefix: "--region", position: 1 }, doc: "Limit discovery to this reference region: CHR|CHR:START-END." }
  hifi_preset: { type: 'boolean?', inputBinding: { prefix: "--hifi", position: 1 }, doc: "Use options optimized for HiFi/CCS reads: -y 97" }
  # Variant Arguments
  sv_types: { type: 'string?', inputBinding: { prefix: "--types", position: 1 }, doc: "Which SV types will be called: 'DEL', 'INS', 'INV', 'DUP', 'BND'. Can be one or more ('DEL', 'DEL,INS,BND', etc.)" }
  min_sv_length: { type: 'string?', inputBinding: { prefix: "--min-sv-length", position: 1 }, doc: "Ignore variants with length < N bp (e.g. '100', '10K', '3M')." }
  max_ins_length: { type: 'string?', inputBinding: { prefix: "--max-ins-length", position: 1 }, doc: "Ignore insertions with length > N bp (e.g. '100', '10K', '3M')." }
  max_dup_length: { type: 'string?', inputBinding: { prefix: "--max-dup-length", position: 1 }, doc: "Ignore duplications with length > N bp (e.g. '100', '10K', '3M')." }

  # SV Signature Cluster Arguments
  cluster_max_length_perc_diff: { type: 'int?', inputBinding: { prefix: "--cluster-max-length-perc-diff", position: 1 }, doc: "Do not cluster signatures with difference in length > P%." }
  cluster_max_ref_pos_diff: { type: 'string?', inputBinding: { prefix: "--cluster-max-ref-pos-diff", position: 1 }, doc: "Do not cluster signatures > N bp (e.g. '100', '10K', '3M') apart in reference." }
  cluster_min_basepair_perc_id: { type: 'int?', inputBinding: { prefix: "--cluster-min-basepair-perc-id", position: 1 }, doc: "Do not cluster signatures with basepair identity < P%." }

  # Consensus Arguments
  max_consensus_coverage: { type: 'int?', inputBinding: { prefix: "--max-consensus-coverage", position: 1 }, doc: "Limit to N reads for variant consensus." }
  poa_scores: { type: 'string?', inputBinding: { prefix: "--poa-scores", position: 1 }, doc: "Score POA alignment with triplet match,mismatch,gap (e.g. '1,-2,-2')" }
  min_realign_length: { type: 'string?', inputBinding: { prefix: "--min-realign-length", position: 1 }, doc: "Consider segments with > N length (e.g. '100', '10K', '3M') for re-alignment." }

  # Call Arguments
  call_min_reads_all_samples: { type: 'int?', inputBinding: { prefix: "--call-min-reads-all-samples", position: 1 }, doc: "Ignore calls supported by < N reads total across samples." }
  call_min_reads_one_sample: { type: 'int?', inputBinding: { prefix: "--call-min-reads-one-sample", position: 1 }, doc: "Ignore calls supported by < N reads in every sample." }
  call_min_reads_per_strand_all_samples: { type: 'int?', inputBinding: { prefix: "--call-min-reads-per-strand-all-samples", position: 1 }, doc: "Ignore calls supported by < N reads per strand total across samples" }
  call_min_bnd_reads_all_samples: { type: 'int?', inputBinding: { prefix: "--call-min-bnd-reads-all-samples", position: 1 }, doc: "Ignore BND calls supported by < N reads total across samples" }
  call_min_read_perc_one_sample: { type: 'int?', inputBinding: { prefix: "--call-min-read-perc-one-sample", position: 1 }, doc: "Ignore calls supported by < P% of reads in every sample." }
  preserve_non_acgt: { type: 'boolean?', inputBinding: { prefix: "--preserve-non-acgt", position: 1 }, doc: "Preserve non-ACGT in REF allele instead of replacing with N." }

  # Genotyping Arguments
  gt_min_reads: { type: 'int?', inputBinding: { prefix: "--gt-min-reads", position: 1 }, doc: "Minimum supporting reads to assign a sample a non-reference genotype." }

  # Annotation Arguments
  annotations: { type: 'File?', inputBinding: { prefix: "--annotations", position: 1 }, doc: "Annotate variants by comparing with sequences in fasta. Default annotations are ALU, L1, SVA." }
  annotation_min_perc_sim: { type: 'int?', inputBinding: { prefix: "--annotation-min-perc-sim", position: 1 }, doc: "Annotate variant if sequence similarity > P%." }

  # Variant Filtering Arguments
  min_N_in_gap: { type: 'string?', inputBinding: { prefix: "--min-N-in-gap", position: 1 }, doc: "Consider >= N consecutive 'N' bp (e.g. '100', '10K', '3M') as a reference gap." }
  filter_near_reference_gap: { type: 'string?', inputBinding: { prefix: "--filter-near-reference-gap", position: 1 }, doc: "Flag variants < N bp (e.g. '100', '10K', '3M') from a gap as 'NearReferenceGap'." }
  filter_near_contig_end: { type: 'string?', inputBinding: { prefix: "--filter-near-contig-end", position: 1 }, doc: "Flag variants < N bp (e.g. '100', '10K', '3M') from a contig end as 'NearContigEnd'." }
  # Control
  cpu: { type: 'int?', default: 16, inputBinding: { prefix: "--num-threads", position: 1 }, doc: "Number of threads to use, 0 means autodetection." }
  ram: { type: 'int?', default: 32, doc: "RAM (in GB) to use" }
  log_level:
    type:
      - 'null'
      - type: enum
        name: log_level
        symbols: ["TRACE","DEBUG","INFO","WARN","FATAL"]
    inputBinding:
      prefix: "--log-level"
      position: 1
    doc: |
      Set log level.
  log_file: { type: 'string?', inputBinding: { prefix: "--log-file", position: 1 }, doc: "Log to a file, instead of stderr." }

outputs:
  output_vcf: { type: 'File', outputBinding: { glob: $(inputs.output_filename) }, doc: "Output SV VCF" }
  output_log_file: { type: 'File?', outputBinding: { glob: $(inputs.log_file) }, doc: "Log output, if explicitly declared" }
