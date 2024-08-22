#!/usr/bin/python

# Usage: ./centrifuge_SILVA_DB_preparation.py tax_input taxmap_input taxonomy_tree_outname name_table_outname conversion_table_outname
# Prepares files for centrifuge SILVA DB generation


import sys,re,pandas as pd, numpy as np

# Set variable names
tax_slv_file=sys.argv[1]
taxmap_slv_file=sys.argv[2]

# Make nodes_SILVA_SSU_LSU.dmp
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
spacer1=np.repeat("|", len(tax_slv_df1), axis=0)
spacer2=np.repeat("-", len(tax_slv_df1), axis=0)
spacer3=np.repeat("scientific name", len(tax_slv_df1), axis=0)

## Generate the final dataframe
nodes_SILVA_SSU_LSU_df=pd.DataFrame({'tax_id':tax_slv_df1[1], 'spacer1':spacer1, \
'parent_tax_id':parent_id_list, 'spacer2':spacer1, 'rank':tax_slv_df1[2], \
'spacer3':spacer1, 'spacer4':spacer2, 'spacer5':spacer1})

## Write df
nodes_SILVA_SSU_LSU_df.to_csv("nodes_SILVA_SSU_LSU.dmp", sep='\t', na_rep='NA', index=False, \
header=False)


# Make nodes_SILVA_SSU_LSU.dmp

tax_slv_df3=tax_slv_df1.copy() # Make a copy of df1
tax_slv_df3[0]=tax_slv_df3[0].str.replace(r';$', '').str.replace(r'^.*;', '')

## Generate the final dataframe
names_SILVA_SSU_LSU_df=pd.DataFrame({'taxon':tax_slv_df3[1], 'spacer1':spacer1, \
'tax_id':tax_slv_df3[0], 'spacer2':spacer1, 'spacer3':spacer2, 'spacer4':spacer1, \
'spacer5':spacer3, 'spacer6':spacer1})

## Write df
names_SILVA_SSU_LSU_df.to_csv("names_SILVA_SSU_LSU.dmp", sep='\t', na_rep='NA', index=False, \
header=False)


# Make conversion_table
## Generate the final dataframe
conversion_table_df=pd.DataFrame({'accession number':taxmap_slv_df['primaryAccession'], \
'tax_id':taxmap_slv_df['taxid']})

## Write df
conversion_table_df.to_csv(conversion_table_out, sep='\t', na_rep='NA', \
index=False, header=False)
