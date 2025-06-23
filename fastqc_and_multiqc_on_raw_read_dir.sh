#!/bin/zsh

# Ensure the directory argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Variables
input_dir="$1"
env_name="multiqc"

# Check if the directory exists
if [ ! -d "$input_dir" ]; then
  echo "Error: Directory '$input_dir' not found."
  exit 1
fi

# Trap function to ensure deactivation and clean-up on exit
function cleanup {
  echo "Cleaning up and deactivating environment..."
  conda deactivate
}
trap cleanup EXIT

# Activate environment
echo "Activating environment '$env_name'..."
eval "$(conda shell.bash hook)"
conda activate "$env_name" || { echo "Failed to activate environment"; exit 1; }

# Run FastQC
echo "Running FastQC on files in '$input_dir'..."
fastqc -t 24 "$input_dir"/*fastq.gz || { echo "FastQC failed"; exit 1; }

# Run MultiQC
echo "Running MultiQC..."
multiqc --interactive . || { echo "MultiQC failed"; exit 1; }

# Clean up FastQC output files
echo "Removing FastQC output files..."
rm "$input_dir"/*fastqc* || { echo "Failed to remove FastQC output files"; exit 1; }

# Clean up MultiQC output directories
echo "Removing MultiQC output..."
rm -r multiqc*/ || { echo "Failed to remove MultiQC output directories"; exit 1; }

echo "All tasks completed successfully."
