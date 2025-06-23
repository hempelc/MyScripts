#!/usr/bin/env python3

# Script to concatenate 2 fastq OR fastq.gz files (such as Undetermined reads and Undetermined index)
# The fastq lines from file 2 will be added to the end of the fastq lines from file 1

import sys
import gzip

def merge_fastq(file1, file2, output_file):
    # Open the input files (handle gzip files)
    if file1.endswith('.gz'):
        f1 = gzip.open(file1, 'rt')
    else:
        f1 = open(file1, 'r')

    if file2.endswith('.gz'):
        f2 = gzip.open(file2, 'rt')
    else:
        f2 = open(file2, 'r')

    # Open the output file (write in text mode)
    if output_file.endswith('.gz'):
        out = gzip.open(output_file, 'wt')
    else:
        out = open(output_file, 'w')

    while True:
        # Read 4 lines from each file
        try:
            # File 1
            header1 = next(f1).strip()
            sequence1 = next(f1).strip()
            plus1 = next(f1).strip()
            quality1 = next(f1).strip()

            # File 2
            header2 = next(f2).strip()
            sequence2 = next(f2).strip()
            plus2 = next(f2).strip()
            quality2 = next(f2).strip()
        except StopIteration:
            break

        # Combine sequences and quality scores
        combined_sequence = sequence1 + sequence2
        combined_quality = quality1 + quality2

        # Write to output file
        out.write(f"{header1}\n")
        out.write(f"{combined_sequence}\n")
        out.write(f"{plus1}\n")
        out.write(f"{combined_quality}\n")

    # Close all files
    f1.close()
    f2.close()
    out.close()

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python merge_fastq.py <input_file1> <input_file2> <output_file>")
        sys.exit(1)

    input_file1 = sys.argv[1]
    input_file2 = sys.argv[2]
    output_file = sys.argv[3]

    merge_fastq(input_file1, input_file2, output_file)
