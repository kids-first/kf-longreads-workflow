class: CommandLineTool
cwlVersion: v1.2
id: guppy_basecaller
doc: |
  Guppy is a data processing toolkit that contains the Oxford Nanopore
  Technologies production basecalling algorithms and several bioinformatic post-
  processing features. It is run from the command line in Windows, Mac OS, and on
  multiple Linux platforms. Guppy is also integrated with our sequencing
  instrument software, MinKNOW, and a subset of Guppy features are available via
  the MinKNOW UI. A selection of configuration files allows basecalling of DNA
  and RNA libraries made with Oxford Nanopore Technologies current sequencing
  kits, in a range of flow cells.

  The Guppy software contains many configurable parameters that can be used to
  specify exactly how the data analysis is performed. Adjusting some of these
  parameters requires a deep knowledge of nanopore data, and as such, Guppy is
  aimed at more advanced users. For those who are new to sequencing or have
  limited knowledge of sequencing data analysis, we recommend using the options
  presented in the MinKNOW software UI for basecalling.

  For more information, visit https://community.nanoporetech.com/
requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement
- class: LoadListingRequirement
- class: DockerRequirement
  dockerPull: genomicpariscentre/guppy-gpu:6.0.1
- class: ResourceRequirement
  ramMin: |
    $((inputs.num_callers * inputs.cpu_threads_per_caller + 4) * 1000)
  coresMin: |
    $(inputs.num_callers * inputs.cpu_threads_per_caller)
baseCommand: [guppy_basecaller]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2

inputs:
  # Required Params
  input_path: { type: 'Directory', loadListing: 'deep_listing',  inputBinding: { prefix: "--input_path", position: 1 }, doc: "Full or relative path to the directory where the raw read files are located. The folder can be absolute (e.g. /data/my_reads) or a relative path to the current working directory (e.g. ../my_reads)" }
  save_path: { type: 'string?', default: "guppy_outputs", inputBinding: { prefix: "--save_path", position: 1 }, doc: "Full or relative path to the directory where the basecall results will be saved. The f
older can be absolute or a relative path to the current working directory. This folder will be created if it does not exist using the path you provide. (e.g. if it is a relative path, it will be relative
to the current working directory)" }
  flowcell: { type: 'string?', inputBinding: { prefix: "--flowcell", position: 1 }, doc: "The name of the flow cell used for sequencing (e.g. FLO-MIN106)." }
  kit: { type: 'string?', inputBinding: { prefix: "--kit", position: 1 }, doc: "The name of the kit used for sequencing (e.g. SQK-LSK109)." }
  config_builtin: { type: 'string?', inputBinding: { prefix: "--config", position: 1 }, doc: "Name of the builtin config file to use. Must correspond to one of the standard configuration files provided by the package. To see the supported flow cells and kits, run Guppy with the --print_workflows option." }
  config_custom: { type: 'File?', inputBinding: { prefix: "--config", position: 1 }, doc: "Custom config file. To see the supported flow cells and kits, run Guppy with the --print_workflows option." }

  # Optional Data Feature Params
  disable_qscore_filtering: { type: 'boolean?', inputBinding: { prefix: "--disable_qscore_filtering", position: 2 }, doc: "Disable filtering of reads into PASS/FAIL folders based on min qscore." }
  min_qscore: { type: 'float?', inputBinding: { prefix: "--min_qscore", position: 2 }, doc: "The minimum q-score a read must attain to pass qscore filtering. The default value for this varies by configuration: for faster models it is 7.0, roughly corresponding to an accuracy of 85%, and is higher for more accurate models. This should have a minimal impact on output." }
  calib_detect: { type: 'boolean?', inputBinding: { prefix: "--calib_detect", position: 2 }, doc: "Flag to enable calibration strand detection and filtering. If enabled, any reads which align to the calibration strand reference will be filtered into a separate output folder to simplify downstream processing. Off by default." }
  align_ref: { type: 'File?', inputBinding: { prefix: "--align_ref", position: 2 }, doc: "Optional reference genome file name. If an align_ref is provided, Guppy will perform alignment against the reference for called strands, using the minimap2 library. See the Alignment section for more information on alignment in Guppy." }
  reverse_sequence:
    type:
      - 'null'
      - type: enum
        name: reverse_sequence
        symbols: ["TRUE","FALSE"]
    inputBinding:
      prefix: "--reverse_sequence"
      position: 2
    doc: |
      Reverse the called sequence (used for RNA sequencing, as RNA strands
      translocate through the pore in the 3’ to 5’ direction). The default value is
      FALSE for DNA sequencing and TRUE for RNA sequencing.
  u_substitution:
    type:
      - 'null'
      - type: enum
        name: u_substitution
        symbols: ["TRUE","FALSE"]
    inputBinding:
      prefix: "--u_substitution"
      position: 2
    doc: |
      Substitute 'U' for 'T' in the called sequence (for RNA sequencing). The default
      value is FALSE for DNA sequencing and TRUE for RNA sequencing.
  do_read_splitting: { type: 'boolean?', inputBinding: { prefix: "--do_read_splitting", position: 2 }, doc: "Split potentially concatenated input reads into separate outputs, based on the score obtained f
rom mid-strand adapter detection. See --min_score_read_splitting. If enabled, reads which exceed this threshold will be split into two." }
  max_read_split_depth: { type: 'int?', inputBinding: { prefix: "--max_read_split_depth", position: 2 }, doc: "Limit the number of times a read will be passed into the read splitter. e.g. --max_read_split
_depth 2 would permit the read to be split, and then each resulting read to be split a second time, resulting in up to four reads. The default value is 2." }
  min_score_read_splitting: { type: 'int?', inputBinding: { prefix: "--min_score_read_splitting", position: 2 }, doc: "The minimum score a read must generate from mid-strand adapter detection for the read
 to be considered a concatamer and to be split into two reads for subsequent processing and output." }

  # Expert Data Feature Params
  calib_reference: { type: 'File?', inputBinding: { prefix: "--calib_reference", position: 2 }, doc: "Provide a FASTA file to override the reference calibration strand." }
  calib_min_sequence_length: { type: 'int?', inputBinding: { prefix: "--calib_min_sequence_length", position: 2 }, doc: "Minimum sequence length for reads to be considered candidate calibration strands."
}
  calib_max_sequence_length: { type: 'int?', inputBinding: { prefix: "--calib_max_sequence_length", position: 2 }, doc: "Maximum sequence length for reads to be considered candidate calibration strands."
}
  calib_min_coverage: { type: 'float?', inputBinding: { prefix: "--calib_min_coverage", position: 2 }, doc: "Minimum reference coverage of candidate strand required for a read to pass calibration strand d
etection." }
  trim_threshold: { type: 'float?', inputBinding: { prefix: "--trim_threshold", position: 2 }, doc: "Threshold above which data will be trimmed (in standard deviations of current level distribution)." }
  trim_min_events: { type: 'int?', inputBinding: { prefix: "--trim_min_events", position: 2 }, doc: "Adapter trimmer minimum stride intervals after stall that must be seen." }
  max_search_len: { type: 'int?', inputBinding: { prefix: "--max_search_len", position: 2 }, doc: "Maximum number of samples from the beginning of the read to search through for the stall." }
  override_scaling: { type: 'boolean?', inputBinding: { prefix: "--override_scaling", position: 2 }, doc: "Flag to manually provide scaling parameters rather than estimating them from each read. See the -
-scaling_med and --scaling_mad options." }
  scaling_med: { type: 'float?', inputBinding: { prefix: "--scaling_med", position: 2 }, doc: "Median current value to use for manual scaling." }
  scaling_mad: { type: 'float?', inputBinding: { prefix: "--scaling_mad", position: 2 }, doc: "Median absolute deviation to use for manual scaling." }
  trim_strategy:
    type:
      - 'null'
      - type: enum
        name: trim_strategy
        symbols: ["dna","rna","none"]
    inputBinding:
      prefix: "--trim_strategy"
      position: 2
      Trimming strategy to apply to the raw signal before basecalling (must be one of
      dna, rna or none). The adapter looks different in the signal depending on
      whether DNA or RNA is being basecalled, so the two cases require a different
      adapter trimming algorithm. This should be set automatically by the config
      file, and usually it is not required to set this at the command line.
  dmean_win_size: { type: 'int?', inputBinding: { prefix: "--dmean_win_size", position: 2 }, doc: "Window size for coarse stall event detection. This parameter, –-dmean_threshold and –-jump_threshold are
used to override how the RNA adapter trimming code operates. Generally, users should not need to change these unless they are familiar with how RNA adapter trimming works." }
  dmean_threshold: { type: 'float?', inputBinding: { prefix: "--dmean_threshold", position: 2 }, doc: "Threshold for coarse stall event detection." }
  jump_threshold: { type: 'float?', inputBinding: { prefix: "--jump_threshold", position: 2 }, doc: "Threshold level for RNA stall detection." }
  disable_events: { type: 'boolean?', inputBinding: { prefix: "--disable_events", position: 2 }, doc: "Flag to disable the transmission of event tables when receiving reads back from the basecall server.
If the event tables are not required for downstream processing (e.g. for 1D2) then it is more efficient to disable them." }
  pt_scaling: { type: 'boolean?', inputBinding: { prefix: "--pt_scaling", position: 2 }, doc: "Flag to enable polyT/adapter max detection for read scaling. This will be used in preference to read median/m
edian absolute deviation to perform read scaling if the poly-T to non-sequence adapter current level change can be detected." }
  pt_median_offset: { type: 'float?', inputBinding: { prefix: "--pt_median_offset", position: 2 }, doc: "Set polyT median offset for setting read scaling median (default 2.5)" }
  adapter_pt_range_scale: { type: 'float?', inputBinding: { prefix: "--adapter_pt_range_scale", position: 2 }, doc: "Set polyT/adapter range scale for setting read scaling median absolute deviation (defau
lt 5.2)" }
  pt_required_adapter_drop: { type: 'float?', inputBinding: { prefix: "--pt_required_adapter_drop", position: 2 }, doc: "Set minimum required current drop from adapter max to polyT detection. (default 30.
0)" }
  pt_minimum_read_start_index: { type: 'int?', inputBinding: { prefix: "--pt_minimum_read_start_index", position: 2 }, doc: "Set minimum index for read start sample required to attempt polyT scaling. (def
ault 30)" }
  noisiest_section_scaling_max_size: { type: 'int?', inputBinding: { prefix: "--noisiest_section_scaling_max_size", position: 2 }, doc: "Set the maximum size of a read (in samples) for which noisiest-sect
ion signal scaling is performed. For short reads, greater accuracy can be achieved by only using the noisiest section of the signal to calculate the signal median and median absolute deviation. These valu
es are then used when scaling the read signal. Defaults to 0." }
  read_id_list: { type: 'File?', inputBinding: { prefix: "--read_id_list", position: 2 }, doc: "text file containing a whitelist of read IDs (one per line, no whitespace). If this option is specified, Gup
py will only basecall reads from the input which have read IDs that are in the read whitelist." }
  barcoding_config_file: { type: 'File?', inputBinding: { prefix: "--barcoding_config_file", position: 2 }, doc: "File from which to load the barcoding configuration, allowing users to override all barcod
ing parameters without specifying them at the command line. Defaults to 'configuration.cfg'." }


  # Optional Input/Output Params
  quiet: { type: 'boolean?', inputBinding: { prefix: "--quiet", position: 2 }, doc: "This option prevents the Guppy basecaller from outputting anything to stdout. Stdout is short for 'standard output' and
 is the default location to which a running program sends its output. For a command line executable, stdout will typically be sent to the terminal window from which the program was run." }
  verbose_logs: { type: 'boolean?', inputBinding: { prefix: "--verbose_logs", position: 2 }, doc: "Flag to enable verbose logging (outputting a verbose log file, in addition to the standard log files, whi
ch contains detailed information about the application). Off by default." }
  records_per_fastq: { type: 'int?', inputBinding: { prefix: "--records_per_fastq", position: 2 }, doc: "The number of reads to put in a single FASTQ file (see output format below). Set this to zero to ou
tput all reads into one file (per run id, per caller). The default value is 4000." }
  compress_fastq: { type: 'boolean?', inputBinding: { prefix: "--compress_fastq", position: 2 }, doc: "Flag to enable gzip compression of output FASTQ files; this reduces file size to about 50% of the ori
ginal." }
  recursive: { type: 'boolean?', inputBinding: { prefix: "--recursive", position: 2 }, doc: "Flag to require searching through all subfolders contained in the --input_path value, and basecall any .fast5 f
iles found in them." }
  fast5_out: { type: 'boolean?', inputBinding: { prefix: "--fast5_out", position: 2 }, doc: "Flag to enable outupt of .fast5 files containing original raw reads, event data from basecall and basecall resu
lt sequence. Off by default." }
  bam_out: { type: 'boolean?', inputBinding: { prefix: "--bam_out", position: 2 }, doc: "Flag to enable output of .bam files containing basecall result sequence. If a modified base model was used, the mod
ified base locations and probabilities will be emitted. If alignment was performed, the results will also be emitted. Off by default." }
  index: { type: 'boolean?', inputBinding: { prefix: "--index", position: 2 }, doc: "Flag to enable the generation of the .bai index file for .bam file output. Requires --bam_out. Off by default." }
  bam_methylation_threshold: { type: 'float?', inputBinding: { prefix: "--bam_methylation_threshold", position: 2 }, doc: "The value below which a predicted methylation probability will not be emitted into a BAM file, expressed as a percentage. Default is 5.0(%)." }
  data_path: { type: 'Directory?', inputBinding: { prefix: "--data_path", position: 2 }, doc: "Option to explicitly specify the path to use for loading any data files the application requires (for example, if you have created your own model files or config files)." }
  input_file_list: { type: 'File?', inputBinding: { prefix: "--input_file_list", position: 2 }, doc: "Optional file containing list of input .fast5 files to process from the input_path." }
  nested_output_folder: { type: 'boolean?', inputBinding: { prefix: "--nested_output_folder", position: 2 }, doc: "Optional flag, which if set will cause FASTQ files to be output to a nested folder structure similar to that used by MinKNOW." }
  progress_stats_frequency: { type: 'int?', inputBinding: { prefix: "--progress_stats_frequency", position: 2 }, doc: "Frequency in seconds in which to report progress statistics, if supplied will replace the default progress display." }
  max_queued_reads: { type: 'int?', inputBinding: { prefix: "--max_queued_reads", position: 2 }, doc: "Maximum number of reads 'in flight', defaults to 2000. Helps to limit the amount of memory used in the case where basecalling cannnot keep up with the speed reads are loaded." }


  # Optional Optimization Basic
  num_callers: { type: 'int?', default: 1, inputBinding: { prefix: "--num_callers", position: 2 }, doc: "Number of parallel basecallers to create. A thread will be spawned for each basecaller to use. Increasing this number will allow Guppy to make better use of multi-core CPU systems, but may impact overall system performance." }
  chunks_per_caller: { type: 'int?', inputBinding: { prefix: "--chunks_per_caller", position: 2 }, doc: "A soft limit on the number of chunks in each basecaller's chunk queue. When a read is sent to the basecaller, it is broken up into 'chunks' of signal, and each chunk is basecalled in isolation. Once all the chunks for a read have been basecalled, they are combined to produce a full basecall. --chunks_per_caller sets a limit on how many chunks will be collected before they are dispatched for basecalling. On GPU platforms this is an important parameter to obtain good performance, as it directly influences how much computation can be done in parallel by a single basecaller." }
  device: { type: 'string?', inputBinding: { prefix: "--device", position: 2 }, doc: "Specify a GPU device to use in order to accelerate basecalling. If this option is not selected, Guppy will default to CPU usage. You can specify one or more devices as well as optionally limiting the amount of GPU memory used (to leave space for other tasks to run on GPUs). GPUs are counted from zero, and the memory limit can be specified as percentage of total GPU memory or as size in bytes." }


  # Expert Optimization Params
  model_file: { type: 'File?', inputBinding: { prefix: "--model_file", position: 2 }, doc: "A path to a JSON RNN model file to use instead of the model specified in the configuration file." }
  chunk_size: { type: 'int?', inputBinding: { prefix: "--chunk_size", position: 2 }, doc: "Set the size of the chunks of data which are sent to the basecaller for analysis. Chunk size is specified in signal blocks, so the total chunk size in samples will be chunk_size * event_stride." }
  overlap: { type: 'int?', inputBinding: { prefix: "--overlap", position: 2 }, doc: "The overlap between adjacent chunks, specified in signal blocks. An overlap is required for chunks to be stitched back into a continuous read." }
  chunks_per_runner: { type: 'int?', inputBinding: { prefix: "--chunks_per_runner", position: 2 }, doc: "The maximum number of chunks which can be submitted to a single neural network runner before it starts computation. Increasing this figure will increase GPU basecalling performance when it is enabled." }
  gpu_runners_per_device: { type: 'int?', inputBinding: { prefix: "--gpu_runners_per_device", position: 2 }, doc: "The number of neural network runners to create per CUDA device. Increasing this number may improve performance on GPUs with a large number of compute cores, but will increase GPU memory use. This option only affects GPU calling." }
  cpu_threads_per_caller: { type: 'int?', default: 1, inputBinding: { prefix: "--cpu_threads_per_caller", position: 2 }, doc: "The number of CPU threads to create for each caller to use. Increasing this number may improve performance on CPUs with a large number of cores, but will increase system load. This option only affects CPU calling." }
  stay_penalty: { type: 'float?', inputBinding: { prefix: "--stay_penalty", position: 2 }, doc: "Scaling factor to apply to stay probability calculation during transducer decode." }
  qscore_offset: { type: 'float?', inputBinding: { prefix: "--qscore_offset", position: 2 }, doc: "Override the q-score offset to apply when calibrating output q-scores for the read. There is an offset and scale (see --qscore_scale) that are applied to the output base probabilities in the FASTQ for a basecall, to make the q-scores as close as possible to the Phred quality scores. Once a basecall model has been trained, these scores are calculated and added to the config files." }
  qscore_scale: { type: 'float?', inputBinding: { prefix: "--qscore_scale", position: 2 }, doc: "Override the q-score scale to apply when calibrating output q-scores for the read." }
  builtin_scripts:
    type:
      - 'null'
      - type: enum
        name: builtin_scripts
        symbols: ["TRUE","FALSE"]
    inputBinding:
      prefix: "--builtin_scripts"
      position: 2
    doc: |
      Set this flag to false to disable built-in GPU kernels, allowing custom kernels to be used (see --kernel_path).
  kernel_path: { type: 'File?', inputBinding: { prefix: "--kernel_path", position: 2 }, doc: "Path to GPU kernel files location (only needed if builtin_scripts is false)." }
  read_batch_size: { type: 'int?', inputBinding: { prefix: "--read_batch_size", position: 2 }, doc: "The maximum batch size, in reads, for grouping input files. This controls the granularity at which resume can operate." }

  # Catchall for additional ARGS (there are a lot more)
  additional_args: { type: 'string[]?', inputBinding: { position: 3, shellQuote: false }, doc: "Any additional Guppy args that the user wishes to set, add them here as they would appear in the command line (e.g. '--align_type auto', '--num_barcoding_buffers 8', etc.)." }

outputs:
  output_directory: { type: 'Directory', outputBinding: { glob: $(inputs.save_path) }, doc: "Directory containing Guppy outputs" }
