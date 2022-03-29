class: CommandLineTool
cwlVersion: v1.2
id: sniffles
doc: |
  A fast structural variant caller for long-read sequencing, Sniffles2 accurately
  detect SVs on germline, somatic and population-level for PacBio and Oxford
  Nanopore read data.

  Usage example A - Call SVs for a single sample:
     sniffles --input sorted_indexed_alignments.bam --vcf output.vcf

     ... OR, with CRAM input and bgzipped+tabix indexed VCF output:
       sniffles --input sample.cram --vcf output.vcf.gz

     ... OR, producing only a SNF file with SV candidates for later multi-sample calling:
       sniffles --input sample1.bam --snf sample1.snf

     ... OR, simultaneously producing a single-sample VCF and SNF file for later multi-sample calling:
       sniffles --input sample1.bam --vcf sample1.vcf.gz --snf sample1.snf

     ... OR, with additional options to specify tandem repeat annotations (for improved call accuracy), reference (for DEL sequences) and non-germline mode for detecting rare SVs:
       sniffles --input sample1.bam --vcf sample1.vcf.gz --tandem-repeats tandem_repeats.bed --reference genome.fa --non-germline

  Usage example B - Multi-sample calling:
     Step 1. Create .snf for each sample: sniffles --input sample1.bam --snf sample1.snf
     Step 2. Combined calling: sniffles --input sample1.snf sample2.snf ... sampleN.snf --vcf multisample.vcf

     ... OR, using a .tsv file containing a list of .snf files, and custom sample ids in an optional second column (one sample per line):
     Step 2. Combined calling: sniffles --input snf_files_list.tsv --vcf multisample.vcf

  Usage example C - Determine genotypes for a set of known SVs (force calling):
     sniffles --input sample.bam --genotype-vcf input_known_svs.vcf --vcf output_genotypes.vcf

  For more information, visit https://github.com/fritzsedlazeck/Sniffles
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: dmiller15/sniffles:2.0.3
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  ramMin: ${ return inputs.ram * 1000 }
  coresMin: $(inputs.cores)
baseCommand: [sniffles]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  # Common Arguments
  input_bam: { type: 'File[]', secondaryFiles: [{ pattern: ".bai", required: false}, { pattern: "^.bai", required: false}, { pattern: ".crai", required: false}, { pattern: "^.crai", required: false}], inputBinding: { prefix: "--input", position: 1 }, doc: "For single-sample calling: A coordinate-sorted and indexed .bam/.cram (BAM/CRAM format) file containing aligned reads. - OR - For multi-sample calling: Multiple .snf files (generated before by running Sniffles2 for individual samples with --snf) (default: None)" }
  vcf_output_filename: { type: 'string?', inputBinding: { prefix: "--vcf", position: 1 }, doc: "VCF output filename to write the called and refined SVs to. If the given filename ends with .gz, the VCF file will be automatically bgzipped and a .tbi index built for it. (default: None)" }
  snf_output_filename: { type: 'string?', inputBinding: { prefix: "--snf", position: 1 }, doc: "Sniffles2 file (.snf) output filename to store candidates for later multi-sample calling (default: None)" }
  reference_fasta: { type: 'File?', secondaryFiles: [{ pattern: ".fai", required: true}], inputBinding: { prefix: "--reference", position: 1 }, doc: "Reference sequence the reads were aligned against. To enable output of deletion SV sequences, this parameter must be set. (default: None)." }
  tandem_repeats_input_bed: { type: 'File?', inputBinding: { prefix: "--tandem-repeats", position: 1 }, doc: "Input .bed file containing tandem repeat annotations for the reference genome. (default: None)" }
  non_germline: { type: 'boolean?', inputBinding: { prefix: "--non-germline", position: 1 }, doc: "Call non-germline SVs (rare, somatic or mosaic SVs)" }
  phase: { type: 'boolean?', inputBinding: { prefix: "--phase", position: 1 }, doc: "Determine phase for SV calls (requires the input alignments to be phased)" }
  cores: { type: 'int?', default: 4, inputBinding: { prefix: "--threads", position: 1 }, doc: "Number of threads to use" }
  ram: { type: 'int?', default: 8, doc: "RAM (in GB) to use" }

  # SV Filtering Arguments
  minsupport: { type: 'string?', inputBinding: { prefix: "--minsupport", position: 1 }, doc: "Minimum number of supporting reads for a SV to be reported (default: automatically choose based on coverage)" }
  minsupport_auto_mult: { type: 'string?', inputBinding: { prefix: "--minsupport-auto-mult", position: 1 }, doc: "Coverage based minimum support multiplier for germline/non-germline modes (only for auto minsupport). Example input '0.1/0.025'" }
  minsvlen: { type: 'int?', inputBinding: { prefix: "--minsvlen", position: 1 }, doc: "Minimum SV length (in bp)" }
  minsvlen_screen_ratio: { type: 'float?', inputBinding: { prefix: "--minsvlen-screen-ratio", position: 1 }, doc: "Minimum length for SV candidates (as fraction of --minsvlen)" }
  mapq: { type: 'int?', inputBinding: { prefix: "--mapq", position: 1 }, doc: "Alignments with mapping quality lower than this value will be ignored" }
  no_qc: { type: 'boolean?', inputBinding: { prefix: "--no-qc", position: 1 }, doc: "Output all SV candidates, disregarding quality control steps." }
  qc_stdev:
    type:
      - 'null'
      - type: enum
        name: reverse_sequence
        symbols: ["True","False"]
    inputBinding:
      prefix: "--qc-stdev"
      position: 1
    doc: |
      Apply filtering based on SV start position and length standard deviation
  qc_stdev_abs_max: { type: 'int?', inputBinding: { prefix: "--qc-stdev-abs-max", position: 1 }, doc: "Maximum standard deviation for SV length and size (in bp)" }
  qc_strand:
    type:
      - 'null'
      - type: enum
        name: reverse_sequence
        symbols: ["True","False"]
    inputBinding:
      prefix: "--qc-strand"
      position: 1
    doc: |
      Apply filtering based on strand support of SV calls
  qc_coverage: { type: 'int?', inputBinding: { prefix: "--qc-coverage", position: 1 }, doc: "Minimum surrounding region coverage of SV calls." }
  long_ins_length: { type: 'int?', inputBinding: { prefix: "--long-del-length", position: 1 }, doc: "Deletion SVs longer than this value are subjected to central coverage drop-based filtering (Not applicable for --non-germline)" }
  long_del_coverage: { type: 'float?', inputBinding: { prefix: "--long-del-coverage", position: 1 }, doc: "Long deletions with central coverage (in relation to upstream/downstream coverage) higher than this value will be filtered (Not applicable for --non-germline)" }
  long_dup_length: { type: 'int?', inputBinding: { prefix: "--long-dup-length", position: 1 }, doc: "Duplication SVs longer than this value are subjected to central coverage increase-based filtering (Not applicable for --non-germline)" }
  long_dup_coverage: { type: 'float?', inputBinding: { prefix: "--long-dup-coverage", position: 1 }, doc: "Long duplications with central coverage (in relation to upstream/downstream coverage) lower than this value will be filtered (Not applicable for --non-germline)" }
  max_splits_kb: { type: 'float?', inputBinding: { prefix: "--max-splits-kb", position: 1 }, doc: "Additional number of splits per kilobase read sequence allowed before reads are ignored" }
  max_splits_base: { type: 'int?', inputBinding: { prefix: "--max-splits-base", position: 1 }, doc: "Base number of splits allowed before reads are ignored (in addition to --max-splits-kb)" }
  min_alignment_length: { type: 'int?', inputBinding: { prefix: "--min-alignment-length", position: 1 }, doc: "Reads with alignments shorter than this length (in bp) will be ignored" }
  phase_conflict_threshold: { type: 'float?', inputBinding: { prefix: "--phase-conflict-threshold", position: 1 }, doc: "Maximum fraction of conflicting reads permitted for SV phase information to be labelled as PASS (only for --phase)" }
  detect_large_ins:
    type:
      - 'null'
      - type: enum
        name: reverse_sequence
        symbols: ["True","False"]
    inputBinding:
      prefix: "--detect-large-ins"
      position: 1
    doc: |
      Infer insertions that are longer than most reads and therefore are spanned by
      few alignments only.

  # SV Clustering Arguments
  cluster_binsize: { type: 'int?', inputBinding: { prefix: "--cluster-binsize", position: 1 }, doc: "Initial screening bin size in bp (default: 100)" }
  cluster_r: { type: 'float?', inputBinding: { prefix: "--cluster-r", position: 1 }, doc: "Multiplier for SV start position standard deviation criterion in cluster merging" }
  cluster_repeat_h: { type: 'float?', inputBinding: { prefix: "--cluster-repeat-h", position: 1 }, doc: "Multiplier for mean SV length criterion for tandem repeat cluster merging" }
  cluster_repeat_h_max: { type: 'int?', inputBinding: { prefix: "--cluster-repeat-h-max", position: 1 }, doc: "Max. merging distance based on SV length criterion for tandem repeat cluster merging" }
  cluster_merge_pos: { type: 'int?', inputBinding: { prefix: "--cluster-merge-pos", position: 1 }, doc: "Max. merging distance for insertions and deletions on the same read and cluster in non-repeat regions" }
  cluster_merge_len: { type: 'float?', inputBinding: { prefix: "--cluster-merge-len", position: 1 }, doc: "Max. size difference for merging SVs as fraction of SV length" }
  cluster_merge_bnd: { type: 'int?', inputBinding: { prefix: "--cluster-merge-bnd", position: 1 }, doc: "Max. merging distance for breakend SV candidates." }

  # SV Genotyping Arguments
  genotype_ploidy: { type: 'int?', inputBinding: { prefix: "--genotype-ploidy", position: 1 }, doc: "Sample ploidy (currently fixed at value 2)" }
  genotype_error: { type: 'float?', inputBinding: { prefix: "--genotype-error", position: 1 }, doc: "Estimated false positve rate for leads (relating to total coverage)" }
  sample_id: { type: 'string?', inputBinding: { prefix: "--sample-id", position: 1 }, doc: "Custom ID for this sample, used for later multi-sample calling (stored in .snf)" }
  genotype_vcf: { type: 'File?', inputBinding: { prefix: "--genotype-vcf", position: 1 }, doc: "Determine the genotypes for all SVs in the given input .vcf file (forced calling). Re-genotyped .vcf will be written to the output file specified with --vcf." }

  # Multi-Sample Calling / Combine Arguments
  combine_high_confidence: { type: 'float?', inputBinding: { prefix: "--combine-high-confidence", position: 1 }, doc: "Minimum fraction of samples in which a SV needs to have individually passed QC for it to be reported in combined output (a value of zero will report all SVs that pass QC in at least one of the input samples)" }
  combine_low_confidence: { type: 'float?', inputBinding: { prefix: "--combine-low-confidence", position: 1 }, doc: "Minimum fraction of samples in which a SV needs to be present (failed QC) for it to be reported in combined output" }
  combine_low_confidence_abs: { type: 'int?', inputBinding: { prefix: "--combine-low-confidence-abs", position: 1 }, doc: "Minimum absolute number of samples in which a SV needs to be present (failed QC) for it to be reported in combined output" }
  combine_null_min_coverage: { type: 'int?', inputBinding: { prefix: "--combine-null-min-coverage", position: 1 }, doc: "Minimum coverage for a sample genotype to be reported as 0/0 (sample genotypes with coverage below this threshold at the SV location will be output as ./.)" }
  combine_match: { type: 'int?', inputBinding: { prefix: "--combine-match", position: 1 }, doc: "Multiplier for maximum deviation of multiple SV's start/end position for them to be combined across samples.  Given by max_dev=M*sqrt(min(SV_length_a,SV_length_b)), where M is this parameter." }
  combine_match_max: { type: 'int?', inputBinding: { prefix: "--combine-match-max", position: 1 }, doc: "Upper limit for the maximum deviation computed for --combine-match, in bp." }
  combine_consensus: { type: 'boolean?', inputBinding: { prefix: "--combine-consensus", position: 1 }, doc: "Output the consensus genotype of all samples" }
  combine_separate_intra: { type: 'boolean?', inputBinding: { prefix: "--combine-separate-intra", position: 1 }, doc: "Disable combination of SVs within the same sample" }
  combine_output_filtered: { type: 'boolean?', inputBinding: { prefix: "--combine-output-filtered", position: 1 }, doc: "Include low-confidence / putative non-germline SVs in multi-calling" }

  # SV Postprocessing, QC and Output Arguments
  output_rnames: { type: 'boolean?', inputBinding: { prefix: "--output-rnames", position: 1 }, doc: "Output names of all supporting reads for each SV in the RNAMEs info field" }
  no_consensus: { type: 'boolean?', inputBinding: { prefix: "--no-consensus", position: 1 }, doc: "Disable consensus sequence generation for insertion SV calls (may improve performance)" }
  no_sort: { type: 'boolean?', inputBinding: { prefix: "--no-sort", position: 1 }, doc: "Do not sort output VCF by genomic coordinates (may slightly improve performance)" }
  no_progress: { type: 'boolean?', inputBinding: { prefix: "--no-progress", position: 1 }, doc: "Disable progress display" }
  quiet: { type: 'boolean?', inputBinding: { prefix: "--quiet", position: 1 }, doc: "Disable all logging, except errors" }
  max_del_seq_len: { type: 'int?', inputBinding: { prefix: "--max-del-seq-len", position: 1 }, doc: "Maximum deletion sequence length to be output. Deletion SVs longer than this value will be written to the output as symbolic SVs." }
  symbolic: { type: 'boolean?', inputBinding: { prefix: "--symbolic", position: 1 }, doc: "Output all SVs as symbolic, including insertions and deletions, instead of reporting nucleotide sequences." }

outputs:
  output_vcf: { type: 'File?', secondaryFiles: [{ pattern: ".tbi", required: false}],  outputBinding: { glob: $(inputs.vcf_output_filename) }, doc: "VCF file contianing called and refined SVs" }
  output_snf: { type: 'File?', outputBinding: { glob: $(inputs.snf_output_filename) }, doc: "Sniffles2 file (.snf) containing candidates for later multi-sample calling" }
