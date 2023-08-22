# Requires BOLDigger results file with sheet containing filtered results

import pandas as pd
import numpy as np

BOLDigger_file = "/Users/christopherhempel/Desktop/RSDE COI water project/apscale/rsde-coi-water-otu_98_apscale/boldigger_OTUs/BOLDResults_rsde-coi-water-otu_98_apscale_OTUs_filtered_part_1.xlsx"
ranks = ["Phylum", "Class", "Order", "Family", "Genus", "Species"]


# Find the lowest non-NaN value in each row
def find_lowest_taxon(row):
    if "No Match" in row.values:
        return None
    return next((row[col] for col in reversed(ranks) if not pd.isna(row[col])), None)


# Find the name of the lowest non-NaN taxonomic column in each row
def find_lowest_rank(row):
    if "No Match" in row.values:
        return None
    return next((col for col in reversed(ranks) if not pd.isna(row[col])), None)


# Read in data
df = pd.read_excel(BOLDigger_file, sheet_name=0)
df_filtered = pd.read_excel(BOLDigger_file, sheet_name=1)

# Fill in empty ESVs
df["You searched for"] = df["You searched for"].ffill()

# Delete species entry that contain sp.
df.loc[df["Species"].str.contains("sp.", case=False, na=False), "Species"] = np.nan
df["Species"] = df["Genus"] + " " + df["Species"]

# Add info for closest species
esv_lowest_tax = []
for esv in df["You searched for"].drop_duplicates():
    # Cut down
    hits = df[df["You searched for"] == esv][["Species", "Similarity"]]
    # Find the first non-NaN index in Species
    first_non_nan_index = hits["Species"].first_valid_index()
    # Exception if none exist
    if first_non_nan_index is None:
        # Add to list
        esv_lowest_tax.append("No species identified")
        continue
    # Get the similarity of the first non-NaN index
    first_non_nan_entry = hits["Species"][first_non_nan_index]
    similarity_max = hits[hits["Species"] == first_non_nan_entry]["Similarity"].max()
    # Get all rows with that similarity (in case multiple different species have the same similarity)
    maxhits = hits[hits["Similarity"] == similarity_max].dropna()
    # If multiple species, cat them together into one string
    lowest_tax = ", ".join(maxhits["Species"].drop_duplicates())
    # Add to list
    esv_lowest_tax.append(lowest_tax)
# Add info
df_filtered["closest_species"] = esv_lowest_tax

# Polish df
df_filtered["Species"] = df_filtered["Genus"] + " " + df_filtered["Species"]
df_filtered["Species"] = df_filtered["Species"].replace("No Match No Match", "No Match")

# Add info for lowest taxon
df_filtered["lowest_taxon"] = df_filtered.apply(
    lambda row: find_lowest_taxon(row), axis=1
)

# Add info for lowest rank
df_filtered["lowest_rank"] = df_filtered.apply(
    lambda row: find_lowest_rank(row), axis=1
)

# Save
outfile = BOLDigger_file.replace(".xlsx", "_with_additional_info.xlsx")
df_filtered.to_excel(outfile, index=False)
