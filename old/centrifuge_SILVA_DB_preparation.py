#!/usr/bin/python

# Usage: ./centrifuge_SILVA_DB_preparation.py tax_input taxmap_input taxonomy_tree_outname name_table_outname conversion_table_outname
# Prepares files for centrifuge SILVA DB generation


import sys,re,pandas as pd, numpy as np

# Set variable names
tax_slv_file=sys.argv[1]
taxmap_slv_file=sys.argv[2]
taxonomy_tree_out=sys.argv[3]
name_table_out=sys.argv[4]
conversion_table_out=sys.argv[5]

# Make taxonomy_tree
##Read in file
tax_slv_df1=pd.read_csv(tax_slv_file, sep='\t', header=None)

## Adding a row with root as forst line, othrwise we can't make the conversion
## table as there is no parent ID for domains
tax_slv_df1.loc[-1] = ['root;', '1', 'no rank', 'NaN', 'NaN']  # adding a row
tax_slv_df1.index = tax_slv_df1.index + 1  # shifting index
tax_slv_df1.sort_index(inplace=True)

## Make dictionary with the taxonomy paths and IDs
tax_slv_dic1={}
for index, row in tax_slv_df1.iterrows():
	tax_slv_dic1[row[0]]=row[1]

## Generate parent paths
tax_slv_df2=tax_slv_df1.copy() # Make a copy of df1
for index, row in tax_slv_df2.iterrows(): # And remove the last rank in the paths to generate parent paths for parent IDs
	row[0]=re.sub('[^;]*;$', '', row[0])

## Make list with parent paths
tax_slv_list=[]
for index, row in tax_slv_df2.iterrows():
	tax_slv_list.append(row[0])

## Make a parent ID list by matching parent paths with original IDs in dic1
parent_id_list=[]
for idx, item in enumerate(tax_slv_list):
	if item == '': # If parent path empty = no parent, insert ID 1, which stands for root
		parent_id_list.append('1')
	else:
		if tax_slv_list[idx] in tax_slv_dic1:
			parent_id_list.append(tax_slv_dic1[tax_slv_list[idx]])
		else:
			parent_path_minus_one=re.sub('[^;]*;$', '', tax_slv_list[idx])
			parent_id_list.append(tax_slv_dic1[parent_path_minus_one])


## Columns have to be separated by "\t|\t", which doesn't work as delimiter, so
## we generate a spacer vector made of "|"
spacer=np.repeat("|", len(tax_slv_df1), axis=0)

## Generate the final dataframe
taxonomy_tree_df=pd.DataFrame({'tax_id':tax_slv_df1[1], 'spacer1':spacer, \
'parent_tax_id':parent_id_list, 'spacer2':spacer, 'rank':tax_slv_df1[2]})

## Write df
taxonomy_tree_df.to_csv(taxonomy_tree_out, sep='\t', na_rep='NA', index=False, \
header=False)


# Make name_table
##Read in file
taxmap_slv_df=pd.read_csv(taxmap_slv_file, sep='\t')

## Make some vectors to match the final output format
spacer=np.repeat("|", len(taxmap_slv_df), axis=0)
unique_name=np.repeat("", len(taxmap_slv_df), axis=0)
name_class=np.repeat("scientific name", len(taxmap_slv_df), axis=0)

## Generate the final dataframe
name_table_df=pd.DataFrame({'tax_id':taxmap_slv_df['taxid'], 'spacer1':spacer, \
'name_txt':taxmap_slv_df['organism_name'], 'spacer2':spacer, \
'unique_name':unique_name, 'spacer3':spacer, 'name_class': name_class, \
'spacer4': spacer})

## Write df
name_table_df.to_csv(name_table_out, sep='\t', na_rep='NA', index=False, \
header=False)


# Make conversion_table
## Generate the final dataframe
conversion_table_df=pd.DataFrame({'accession number':taxmap_slv_df['primaryAccession'], \
'tax_id':taxmap_slv_df['taxid']})

## Write df
conversion_table_df.to_csv(conversion_table_out, sep='\t', na_rep='NA', \
index=False, header=False)
