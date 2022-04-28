#!/usr/bin/env python3

import argparse
import datetime
import os
import pysam
import sys
from subprocess import PIPE, Popen


def run_cmd(cmd, verbose=False, output=False,error=False):
    stream=Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
    stdout, stderr = stream.communicate()

    stdout=stdout.decode('utf-8')
    stderr=stderr.decode('utf-8')

    if stderr:
        print(stderr, flush=True)

    if verbose:
        print(stdout, flush=True)


    if output:
        return stdout
    if error:
        return stderr


if __name__ == '__main__':

    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    requiredNamed = parser.add_argument_group('Required Arguments')
    region_group=parser.add_argument_group("Variant Calling Regions")
    out_group=parser.add_argument_group("Output Options")

    #region
    region_group.add_argument("-interval_len", "--interval_len", help='Length of split intervals. Lower the value to make smaller intervals. Increase the value to make larger intervals.', type=int, default=10000000)
    region_group.add_argument("-chrom",  "--chrom", nargs='*',  help='A space/whitespace separated list of contigs, e.g. chr3 chr6 chr22.')
    region_group.add_argument("-include_bed",  "--include_bed",  help="Only call variants inside the intervals specified in the bgzipped and tabix indexed BED file. If any other flags are used to specify a region, intersect the region with intervals in the BED file, e.g. if -chom chr1 -start 10000000 -end 20000000 flags are set, call variants inside the intervals specified by the BED file that overlap with chr1:10000000-20000000. Same goes for the case when whole genome variant calling flag is set.", type=str, default=None)
    region_group.add_argument('-wgs_contigs_type','--wgs_contigs_type', \
                        help="""Options are "with_chr", "without_chr" and "all",\
                        "with_chr" option will assume \
                        human genome and run NanoCaller on chr1-22, "without_chr" will \
                        run on chromosomes 1-22 if the BAM and reference genome files \
                        use chromosome names without "chr". "all" option will run \
                        NanoCaller on each contig present in reference genome FASTA file.""", \
                        type=str, default='all')

    #required
    requiredNamed.add_argument("-bam",  "--bam",  help="Bam file, should be phased if 'indel' mode is selected", required=True)
    requiredNamed.add_argument("-ref_fai",  "--ref_fai",  help="Reference genome file .fai index", required=True)

    #output options
    out_group.add_argument("-o",  "--output", help="Output directory, default is current working directory", type=str, default='.')

    args = parser.parse_args()

    if args.chrom:
        chrom_list= args.chrom

    else:
        if args.wgs_contigs_type=='with_chr':
            chrom_list=['chr%d' %d for d in range(1,23)]

        elif args.wgs_contigs_type == 'without_chr':
            chrom_list=['%d' %d for d in range(1,23)]

        elif args.wgs_contigs_type == 'all':
            chrom_list=[]

            try:
                with open(args.ref_fai,'r') as file:
                    for line in file:
                        chrom_list.append(line.split('\t')[0])

            except FileNotFoundError:
                print('%s: index file .fai required for reference genome file.\n' %str(datetime.datetime.now()), flush=True)
                sys.exit(2)

    if args.include_bed:
        stream=run_cmd('zcat %s|cut -f 1|uniq' %args.include_bed, output=True)
        bed_chroms=stream.split()

        chrom_list=[chrom for chrom in chrom_list if chrom in bed_chroms]

    chrom_lengths={}
    with open(args.ref_fai,'r') as file:
        for line in file:
            chrom_lengths[line.split('\t')[0]]=int(line.split('\t')[1])

    bam_chrom_list=out=run_cmd('samtools idxstats %s|cut -f 1' %args.bam, output=True).split('\n')

    for chrom in chrom_list:
        try:
            chr_end=chrom_lengths[chrom]

        except KeyError:
            print('Contig %s not found in reference. Ignoring it.' %chrom,flush=True)
            continue

        if chrom not in bam_chrom_list:
            print('Contig %s not found in BAM file. Ignoring it.' %chrom,flush=True)
            continue

        for mbase in range(1,chr_end,args.interval_len):
            output_name='%s_%d_%d_scatter_interval.bed' %(chrom, mbase, min(chr_end,mbase+args.interval_len-1))
            out_path=os.path.join(args.output, output_name)
            with open(out_path,'w') as f:
                f.write('%s\t%d\t%d' %(chrom, mbase, min(chr_end,mbase+args.interval_len-1)))
            pysam.tabix_compress(out_path, out_path+'.gz')
            pysam.tabix_index(out_path+'.gz', preset='bed')
