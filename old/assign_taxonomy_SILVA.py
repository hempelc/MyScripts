#!/usr/bin/python

# Usage: ./assign_taxonomy_SILVA.py SILVA_blast_file SILVA_taxonomy_file output_file_name

# Assigns taxonomy to SILVA blast searches by merging two files (SILVA blast file and SILVA taxonomy file) on columns that exist in both files (should be staxids)

# SILVA taxonomy file can be found under /hdd1/databases/SILVA_database_mar_2020/taxonomy/files_to_make_NCBI_staxids/taxmap_slv_ssu_ref_nr_138.txt


import pandas as pd, sys

df1_name=sys.argv[1]
df2_name=sys.argv[2]
output_name=sys.argv[3]

df1 = pd.read_csv(df1_name, sep='\t', index_col=False, names=['qseqid', 'sseqid', 'pident', 'length', 'mismatch', 'gapopen', 'qstart', 'qend', 'sstart', 'send', 'evalue', 'bitscore', 'taxid'])
df2 = pd.read_csv(df2_name, sep='\t')
df3 = pd.merge(df1, df2, how='inner')
df4 = df3.drop(columns=['primaryAccession', 'start', 'stop'])
df4.to_csv(output_name, sep='\t', na_rep='NA', index=False)
