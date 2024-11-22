#!/bin/bash

# Check if input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input.fastq>"
    exit 1
fi

input_file="$1"
output_file="${input_file%.*}.fasta"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file $input_file does not exist"
    exit 1
fi

# Check if input file is empty
if [ ! -s "$input_file" ]; then
    echo "Error: Input file $input_file is empty"
    exit 1
fi

# Check if output file already exists
if [ -f "$output_file" ]; then
    echo "Warning: Output file $output_file already exists. Overwriting..."
fi

# Convert FASTQ to FASTA
# This works by:
# 1. Taking every 4th line starting from line 1 (sequence identifiers)
# 2. Taking every 4th line starting from line 2 (sequences)
# 3. Replacing '@' with '>' in sequence identifiers
# 4. Combining them together
awk 'NR%4==1{printf ">%s\n", substr($0,2)}
     NR%4==2{print}' "$input_file" > "$output_file"

# Check if conversion was successful
if [ $? -eq 0 ] && [ -s "$output_file" ]; then
    echo "Conversion successful! Output written to $output_file"
    echo "Input FASTQ lines: $(wc -l < "$input_file")"
    echo "Output FASTA lines: $(wc -l < "$output_file")"
else
    echo "Error: Conversion failed"
    rm -f "$output_file"
    exit 1
fi
