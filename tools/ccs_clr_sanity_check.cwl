cwlVersion: v1.2
class: CommandLineTool
id: ccs_clr_sanity_check
doc: >-
  Various Checks for Discerning CCS from CLR Long Reads BAMs.
requirements:
  - class: DockerRequirement
    dockerPull: 'staphb/samtools:1.18'
  - class: InitialWorkDirRequirement
    listing:
      - entryname: pg_pbmm2_flags.awk
        entry:
          $include: ../scripts/pg_pbmm2_flags.awk
      - entryname: pg_pns.awk
        entry:
          $include: ../scripts/pg_pns.awk
      - entryname: record_quals.awk
        entry:
          $include: ../scripts/record_quals.awk
      - entryname: rg_ds_readtypes.awk
        entry:
          $include: ../scripts/rg_ds_readtypes.awk
      - entryname: sanity_check.sh
        entry: |
          set -eo pipefail

          samtools head $(inputs.input_reads.path) | awk -f pg_pbmm2_flags.awk > PG_PBMM2_FLAGS.STATUS

          samtools head $(inputs.input_reads.path) | awk -f pg_pns.awk > PG_PNS.STATUS

          samtools head $(inputs.input_reads.path) | awk -f rg_ds_readtypes.awk > RG_DS_READTYPES.STATUS

          samtools view $(inputs.cram_reference_fasta != null ? "-T " + inputs.cram_reference_fasta.path + " " : "")$(inputs.input_reads.path) | head -n100 | awk -f record_quals.awk > RECORD_QUALS.STATUS || if [[ $? -eq 141 ]]; then true; else exit $?; fi
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cpu)
    ramMin: $(inputs.ram * 1000)
  - class: ShellCommandRequirement

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: |
      /bin/bash sanity_check.sh

inputs:
  input_reads: { type: 'File', doc: "Long Reads BAM/CRAM/SAM file."}
  cram_reference_fasta: { type: 'File?', secondaryFiles: [{ pattern: '.fai', required: true}], doc: "If input_reads are CRAM, FASTA reference used to create the CRAM." }
  cpu: { type: 'int?', default: 8 }
  ram: { type: 'int?', default: 16 }

outputs:
  pg_pbmm2_flags_status:
    type: string
    outputBinding:
      glob: "PG_PBMM2_FLAGS.STATUS"
      loadContents: true
      outputEval: $(self[0].contents.trim())
  pg_pns_status:
    type: string
    outputBinding:
      glob: "PG_PNS.STATUS"
      loadContents: true
      outputEval: $(self[0].contents.trim())
  rg_ds_readtypes_status:
    type: string
    outputBinding:
      glob: "RG_DS_READTYPES.STATUS"
      loadContents: true
      outputEval: $(self[0].contents.trim())
  record_quals_status:
    type: string
    outputBinding:
      glob: "RECORD_QUALS.STATUS"
      loadContents: true
      outputEval: $(self[0].contents.trim())
