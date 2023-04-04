#!/usr/bin/env python3

import argparse
import datetime
import os
import pysam
import sys

def get_regions_list(inbam, primary_contigs_only, regions, bed):
    """Construct the list of regions that will be analyzed.
    Args:
        inbam: BAM file containing reads information and header with SQ lines
        primary_contigs_only: Boolean denoting whether to only return the primary contigs (properly chr-formatted)
        regions: List of strings denoting chromosomes or chromosomes:start-end positions
        bed: BED file containing tab separated region information chrom\tstart\tend
    Return:
        regions_list: List of tuples containing (chrom, start, end) genetic information 
    """
    regions_list=[]
    if primary_contigs_only:
        sam_file=pysam.Samfile(inbam)

        prefix = 'chr' if sam_file.references[0].startswith('chr') else ''

        for contig in list(range(1,23)) + ['X','Y']:
            contig=f'{prefix}{contig}'
            if sam_file.is_valid_reference_name(contig):
                regions_list.append((contig, 1, sam_file.get_reference_length(contig)))

    elif regions:
        sam_file=pysam.Samfile(inbam)
        for r in regions:
            r2=r.split(':')
            if len(r2)==1:
                r2=r2[0]
                if sam_file.is_valid_reference_name(r2):
                    regions_list.append((r2, 1, sam_file.get_reference_length(r2)))
                else:
                    print('\n%s: Contig %s not present in the BAM file.'  %(str(datetime.datetime.now()), r2), flush=True)

            elif len(r2)==2:
                cord=r2[1].split('-')
                if len(cord)==2:
                    regions_list.append((r2[0], int(cord[0]), int(cord[1])))
                else:
                    print('\n%s: Invalid region %s.'  %(str(datetime.datetime.now()), r), flush=True)

            else:
                print('\n%s: Invalid region %s.'  %(str(datetime.datetime.now()), r), flush=True)

    elif bed:
        sam_file=pysam.Samfile(inbam)
        with open(bed, 'r') as bed_file:
            for line in bed_file:
                line=line.rstrip('\n').split()
                if sam_file.is_valid_reference_name(line[0]):
                    regions_list.append((line[0], int(line[1]), int(line[2])))
                else:
                    print('\n%s: Contig %s not present in the BAM file.'  %(str(datetime.datetime.now()), line[0]), flush=True)

    else:
        sam_file=pysam.Samfile(inbam)
        regions_list=[(r, 1, sam_file.get_reference_length(r)) for r in sam_file.references]

    if len(regions_list)==0:
        print('\n%s: No valid regions found.'  %str(datetime.datetime.now()), flush=True)
        sys.exit(2)

    return regions_list

def chunk_regions(regions_list, interval_len=50000000):
    """Given a list of regions, chunk those regions into files containing interval_len bases.
    Args:
        regions_list: List of tuples containing (chrom, start, end) genetic information
        interval_len: int denoting the maximum number of bases that should be in each file
    Return:
        None
    """
    bucket = []
    scatter_count = 0
    while regions_list != []:
        bucket, regions_list, scatter_count = fill_bucket(bucket, regions_list, interval_len, scatter_count)

def fill_bucket(bucket, regions_list, interval_len, scatter_count):
    """Constructs buckets containing genetic regions and prints them when they are full or no regions remain
    Args:
        bucket: List of tuples containing (chrom, start, end) genetic information
        regions_list: tuple containing (chrom, start, end) genetic information
        interval_len: int denoting the maximum number of bases that should be in each file
        scatter_count: int tracking the number of files created
    Return:
        bucket: The list of tuples with cumulative length less than the interval_len 
        regions_list:  
        scatter_count: If the region fits the bucket, return the same count; otherwise add 1
    """
    chrom, start, end = regions_list[0]
    # Room in the bucket is the interval_len minus the sum of the region lengths in the bucket
    headroom = interval_len - sum([e-s for c,s,e in bucket])
    # If the first region fits in the bucket, move it from the list to the bucket 
    if ((end - start) < headroom):
        bucket.append(regions_list.pop(0))
        # Print all that remains once you have depleted the regions_list
        if regions_list == []:
            bucket, scatter_count = print_bucket(bucket, scatter_count)
    # Otherwise break apart the region and fill the bucket
    else:
        bucket_fill = start + headroom - 1
        bucket.append((chrom, start, bucket_fill))
        # Print the full bucket
        bucket, scatter_count = print_bucket(bucket, scatter_count)
        # Replace the first region in the list with whatever was not put in to the bucket
        regions_list[0] = (chrom, bucket_fill + 1, end)
    return bucket, regions_list, scatter_count

def print_bucket(bucket, scatter_count):
    """Given a bucket, print its contents to a file named by scatter count; return an empty bucket and an iterated count
    Args:
        bucket: List of tuples containing (chrom, start, end) genetic information
        scatter_count: int tracking the number of files created
    Retrun:
        bucket: List of tuples containing (chrom, start, end) genetic information, always empty on return
        scatter_count: int tracking the number of files created
    """
    with open(f"{scatter_count:03d}_intervals.bed", 'w') as out:
        for region in bucket:
            print("{}\t{}\t{}".format(*region), file=out)
    bucket = []
    scatter_count += 1
    return bucket, scatter_count

def parse_args():
    """Function to parse the command line input
    Args:
        None
    Return:
        Namespace: returns the args as a standard Namespace object
    """
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("--bam", help="Bam file", required=True)
    parser.add_argument("--interval_len", help="Length of split intervals. Lower the value to make smaller intervals. Increase the value to make larger intervals.", type=int, default=50000000)
    parser.add_argument("--regions", nargs='*', help='A space/whitespace separated list of regions specified as "CONTIG_NAME" or "CONTIG_NAME:START-END". If you want to use "CONTIG_NAME:START-END" format then specify both start and end coordinates. For example: chr3 chr6:28000000-35000000 chr22.')
    parser.add_argument("--bed", help="A BED file specifying regions for variant calling.", type=str, default=None)
    parser.add_argument("--primary_contigs_only", help="Only analyze the primary contigs. Recommended for WGS.", default=False, action='store_true')

    args = parser.parse_args()

    return args

def main():
    args = parse_args()
    regions_list = get_regions_list(args.bam, args.primary_contigs_only, args.regions, args.bed)
    chunk_regions(regions_list, args.interval_len)

if __name__ == '__main__':
    main()
