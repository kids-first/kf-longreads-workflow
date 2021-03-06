# Kids First Data Resource Center Pacific Biosciences Long Reads Alignment and Variant Calling Workflow

<p align="center">
  <img src="https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png">
</p>

The Kids First Data Resource Center (KFDRC) Pacific Biosciences (PacBio)
Long Reads Alignment and Variant Calling Workflow is a Common Workflow Language
(CWL) implementation of various softwares used to take reads information
generated by PacBio long reads sequencers and generate alignment and variant
information.

## Relevant Softwares and Versions
- [pbmm2](https://github.com/PacificBiosciences/pbmm2#readme): `1.7.0`
- [Sentieon DNAScope HiFi](https://support.sentieon.com/manual/): `202112.01`
- [LongReadSum](https://github.com/WGLab/LongReadSum#readme): [Unversioned commit](https://github.com/WGLab/LongReadSum/commit/125cd78e49bc4a402d289baa687acf35b555d3e5)
- [Sniffles](https://github.com/fritzsedlazeck/Sniffles#readme): `2.0.3`
- [pbsv](https://github.com/PacificBiosciences/pbsv#readme): `2.8.0`

## Input Files
- `input_unaligned_bam`: The primary input of the PacBio Long Reads Workflow is an unaligned BAM and associated index.
- `indexed_reference_fasta`: Any suitable human reference genome. KFDRC uses `Homo_sapiens_assembly38.fasta` from Broad Institute.

## Output Files
- `dnascope_small_variants`: BGZIP and TABIX indexed VCF containing small variant calls made by Sentieon DNAScope HiFi on `pbmm2_aligned_bam`.
- `longreadsum_bam_metrics`: BGZIP TAR containing various metrics collected by LongReadSum from the `pbmm2_aligned_bam`.
- `pbmm2_aligned_bam`: Indexed BAM file containing reads from the `input_unaligned_bam` aligned to the `indexed_reference_fasta`.
- `pbsv_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by pbsv on the `pbmm2_aligned_bam`.
- `sniffles_structural_variants`: BGZIP and TABIX indexed VCF containing structural variant calls made by Sniffles on the `pbmm2_aligned_bam`.

## Generalized Process
1. Align `input_unaligned_bam` to `indexed_reference_fasta` using pbmm2.
1. Generate long reads alignment metrics from the `pbmm2_aligned_bam` using LongReadSum.
1. Generate structural variant calls from the `pbmm2_aligned_bam` using pbsv.
1. Generate structural variant calls from the `pbmm2_aligned_bam` using Sniffles.
1. Generate small variant from the `pbmm2_aligned_bam` using Sentieon DNAScope HiFi.

## Basic Info
- [D3b dockerfiles](https://github.com/d3b-center/bixtools)
- Testing Tools:
    - [Seven Bridges Cavatica Platform](https://cavatica.sbgenomics.com/)
    - [Common Workflow Language reference implementation (cwltool)](https://github.com/common-workflow-language/cwltool/)

## References
- KFDRC AWS s3 bucket: s3://kids-first-seq-data/broad-references/
- Cavatica: https://cavatica.sbgenomics.com/u/kfdrc-harmonization/kf-references/
- Broad Institute Goolge Cloud: https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/
