class: CommandLineTool
cwlVersion: v1.2
id: samtools_coverage
doc: |-
  produces a histogram or table of coverage per chromosome
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: '684194535433.dkr.ecr.us-east-1.amazonaws.com/d3b-healthomics:samtools-1.17'
  - class: ResourceRequirement
    coresMin: $(inputs.cpu)
    ramMin: $(inputs.ram * 1000)
baseCommand: [samtools, coverage]
inputs:
  # Input options:
  input_reads: { type: 'File[]', secondaryFiles: [{ pattern: '.bai', required: false }, { pattern: '^.bai', required: false }, { pattern: '.crai', required: false }, { pattern: '^.crai', required: false }], inputBinding: { position: 9 }, doc: "BAM/CRAM/SAM files to evaluate." }
  min_read_len: { type: 'int?', inputBinding: { position: 2, prefix: "--min-read-len" }, doc: "ignore reads shorter than INT bp [0]" }
  min_mq: { type: 'int?', inputBinding: { position: 2, prefix: "--min-MQ" }, doc: "mapping quality threshold [0]" }
  min_bq: { type: 'int?', inputBinding: { position: 2, prefix: "--min-BQ" }, doc: "base quality threshold [0]" }
  rf: { type: 'string?', inputBinding: { position: 2, prefix: "--rf" }, doc: "required flags: skip reads with mask bits unset []" }
  ff: { type: 'string?', inputBinding: { position: 2, prefix: "--ff" }, doc: "filter flags: skip reads with mask bits set [UNMAP,SECONDARY,QCFAIL,DUP]" }
  depth: { type: 'int?', inputBinding: { position: 2, prefix: "--depth" }, doc: "maximum allowed coverage depth [1000000]. If 0, depth is set to the maximum integer value, effectively removing any depth limit." }

  # Output options
  histogram: { type: 'boolean?', inputBinding: { position: 2, prefix: "--histogram" }, doc: "show histogram instead of tabular output" }
  ascii: { type: 'boolean?', inputBinding: { position: 2, prefix: "--ascii" }, doc: "show only ASCII characters in histogram" }
  output_filename: { type: 'string?', default: "coverage.txt", inputBinding: { position: 2, prefix: "--output" }, doc: "write output to FILE [stdout]" }
  no_header: { type: 'boolean?', inputBinding: { position: 2, prefix: "--no-header" }, doc: "don't print a header in tabular mode" }
  n_bins: { type: 'int?', inputBinding: { position: 2, prefix: "--n-bins" }, doc: "number of bins in histogram [terminal width - 40]" }
  region: { type: 'string?', inputBinding: { position: 2, prefix: "--region" }, doc: "show specified region. Format: chr:start-end." }
  
  # Generic options:
  input_fmt_option: { type: 'string?', inputBinding: { position: 2, prefix: "--input-fmt-option" }, doc: "Specify a single input file format option in the form of OPTION or OPTION=VALUE" }
  reference: { type: 'File?', inputBinding: { position: 2, prefix: "--reference" }, doc: "Reference sequence FASTA FILE [null]" }

  cpu: { type: 'int?', default: 4, doc: "CPUs to allocate to this task." }
  ram: { type: 'int?', default: 16, doc: "RAM (in GB) to allocate to this task." }
outputs:
  output: 
    type: File
    outputBinding:
      glob: $(inputs.output_filename) 
  meandepth:
    type: float?
    outputBinding:
      glob: $(inputs.output_filename)
      loadContents: true
      outputEval: |
        ${
          var lines = self[0].contents.trim().split("\n");
          var header = [];
          while (lines.length > 0) {
            if (lines[0].search(/^#/) != -1) {
              header = lines.shift().split("\t");
              break;
            }
            lines.shift();
          }
          var meandepths = [];
          while (lines.length > 0) {
            var mdp = lines.shift().split("\t")[header.indexOf("meandepth")];
            meandepths.push(mdp);
          }
          var nonzero = meandepths.filter(function(e) { return e > 0 }).sort(function(a, b) { return a - b });
          if (nonzero.length == 0) {
            return 0;
          }
          var mid = Math.floor(nonzero.length / 2);
          if (nonzero.length % 2) {
            return nonzero[mid];
          }
          return (nonzero[mid - 1] + nonzero[mid]) / 2;
        }

$namespaces:
  sbg: https://sevenbridges.com
