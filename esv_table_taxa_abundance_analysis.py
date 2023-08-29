"""
Generates read number bar graphs for taxa in ESV tables.

By Chris Hempel (christopher.hempel@kaust.edu.sa) on Jun 27 2023
"""

import pandas as pd
import plotly.express as px

# Options
file = "/Users/christopherhempel/Desktop/RSDE COI water project/apscale/rsde-coi-water-otu_97_apscale/rsde-coi-water-otu_97_apscale_OTU_table_with_BOLDigger_coil_filtered.xlsx"
# Is the file from Boldigger?
boldigger = True
# Gibve tha dataset a name for plotting title
dataset = "RSDE-COI-water"
# Specify string shared by all sample names to extract read abudnances
sample_abbrev = "RSDE"
graph_width = 1200
# Max number of taxa in plot so that names are readable
num_taxa_barplots = 50


# Import ESV table
df = pd.read_excel(file) if ".xlsx" in file else pd.read_csv(file)

# Select sample columns
sample_cols = [col for col in df.columns if sample_abbrev in col]
# Calculate number of reads across samples
readsums = df[sample_cols].sum(axis=1)

# Plot read abundances of taxa across ranks
if boldigger:
    ranks = ["Phylum", "Class", "Order", "Family", "Genus", "Species"]
else:
    ranks = ["superkingdom", "phylum", "class", "order", "family", "genus", "species"]
## Loop over ranks
for rank in ranks:
    ## Group taxa and sum up number of reads
    rank_df = pd.DataFrame({rank: df[rank], "readsum": readsums})
    grouped_df = (
        rank_df.groupby([rank])
        .sum()
        .sort_values(["readsum"], ascending=False)[:num_taxa_barplots]
    )

    ## Define title
    if len(grouped_df) >= num_taxa_barplots:
        barplot_title = f"{dataset}: {rank} ({num_taxa_barplots} most abundant taxa)"
    else:
        barplot_title = f"{dataset}: {rank}"

    ## Plot
    fig = px.bar(
        grouped_df,
        labels={"value": "Number of reads", rank: "Taxa"},
        title=barplot_title,
        width=graph_width,
    )
    fig.update_layout(showlegend=False)
    fig.show()

# Plot resolution (requires columsn lowest_rank in df)
resolution_df = df["lowest_rank"].fillna("No match").value_counts()
resolution_df = resolution_df.reindex(ranks + ["No match"])
fig = px.bar(
    resolution_df,
    labels={"value": "Count", "lowest_rank": "Rank"},
    title="Taxonomic resolution",
)
fig.update_layout(showlegend=False)
fig.show()
