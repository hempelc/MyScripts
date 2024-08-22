#!/bin/bash

# Run kraken2
kraken2 --db /hdd1/databases/kraken2_SILVA_DB/ --threads 16 scaffolds.fasta \
> kraken_SILVA.txt
# Now we're gonna edit the output so that is has the same format as CREST output,
# since we already have a script to deal with SILVA CREST output
  # Extract the taxids column of the standard kraken output
  cut -f3 kraken_SILVA.txt > kraken_taxids.txt
  # Access the SILVA taxonomy file and generate a file containing one column for
  # each SILVA taxid and one column for the respective SILVA taxonomy path:
  tail -n +2 /hdd1/databases/SILVA_database_mar_2020/taxonomy/files_to_make_NCBI_staxids/taxmap_slv_ssu_ref_nr_138.txt \
  | cut -f 4,6 | sort -u > SILVA_paths_and_taxids.txt
  # Kraken2 spits out the taxid 0 when no hit is found, but 0 doesn't exist in
  # the SILVA taxonomy, so manually add taxid 0 with path “No hits” to the SILVA
  # path file:
  echo -e "No hits;\t0" > tmp && cat SILVA_paths_and_taxids.txt >> tmp \
  && mv tmp SILVA_paths_and_taxids.txt
  # Merge your kraken taxids with the SILVA path file to assign a SILVA taxonomy
  # path to every kraken hit
  mergeFilesOnColumn.pl SILVA_paths_and_taxids.txt kraken_taxids.txt 2 1 > merged.txt
  cut -f -2 merged.txt | sed 's/;\t/\t/g' > merged_edit.txt # Edit the output
  # Extract the sequence names from the kraken output and generate a final file
  # with sequence name, taxid, and SILVA path
  cut -f 3 kraken_SILVA.txt > names.txt
  paste names.txt merged_edit.txt | awk 'BEGIN {FS="\t"; OFS="\t"} {print $1, $3, $2}' \
  > kraken_SILVA_formatted.txt
# This file has now the same format as the output of CREST and can be translated
# into NCBI taxonomy the same way as CREST output

assign_NCBI_staxids_to_CREST_v4.py /hdd1/databases/SILVA_database_mar_2020/taxonomy/files_to_make_NCBI_staxids/NCBI_staxids_scientific.txt \
/hdd1/databases/SILVA_database_mar_2020/taxonomy/files_to_make_NCBI_staxids/NCBI_staxids_non_scientific.txt \
kraken_SILVA_formatted.txt kraken_SILVA_formatted_with_NCBI_taxids.txt
sed -i '1d' kraken_SILVA_formatted_with_NCBI_taxids.txt # Remove header
mergeFilesOnColumn.pl kraken_SILVA_formatted_with_NCBI_taxids.txt \
kraken_SILVA_formatted.txt 1 1 > merged_final.txt # Merge SILVA output with taxids
cut -f3 merged_final.txt > NCBItaxids.txt # Extract taxids
assign_taxonomy_NCBI_staxids.sh -b NCBItaxids.txt -c 1 -e ~/.etetoolkit/taxa.sqlite
sed -i '1d' NCBItaxids_with_taxonomy.txt # Remove header
cut -f2 kraken_SILVA.txt > contig_names.txt # Get contig names from original kraken2 output
paste contig_names.txt NCBItaxids_with_taxonomy.txt \
> contigs_with_NCBItaxids_and_taxonomy.txt # Add contig names to taxonomy file
echo -e "contig\tstaxid\tlowest_rank\tlowest_hit\tsuperkingdom\tkingdom\tphylum\tsubphylum\tclass\tsubclass\torder\tsuborder\tinfraorder\tfamily\tgenus" \
> kraken_SILVA_final.txt && cat contigs_with_NCBItaxids_and_taxonomy.txt \
>> kraken_SILVA_final.txt # Add header

# Sort files
mkdir intermediate_files
mv kraken_SILVA.txt kraken_taxids.txt SILVA_paths_and_taxids.txt merged* \
names.txt kraken_SILVA_formatted* NCBItaxids* contig* intermediate_files/
