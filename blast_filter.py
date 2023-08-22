#!/usr/bin/env python3

"""
A script to filter BLAST hits with assigned taxonomy.

By Chris Hempel (christopher.hempel@kaust.edu.sa) on 20 Jan 2022
"""

import datetime
import pandas as pd
import argparse
import warnings

# Define that warnings are not printed to console
warnings.filterwarnings("ignore")


# Define funtion to print datetime and text
def time_print(text):
    datetime_now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"{datetime_now}  ---  " + text)


# Define function to filter bitscores
def bitscore_cutoff(x):
    min_bitscore = x.max() - x.max() * 0.02
    return x[x >= min_bitscore]


# Define a class to format helptext of options properly, taken from
# https://www.google.com/search?q=argsparse+recognize+newline+in+help&oq=argsparse+
# recognize+newline+in+help&aqs=chrome..69i57j33i22i29i30.12450j0j7&sourceid=chrome&ie=UTF-8
class SmartFormatter(argparse.HelpFormatter):
    def _split_lines(self, text, width):
        if text.startswith("R|"):
            return text[2:].splitlines()
        return argparse.HelpFormatter._split_lines(self, text, width)


# Define arguments
parser = argparse.ArgumentParser(
    description="Filter BLAST output.", formatter_class=SmartFormatter
)
parser.add_argument(
    "inputfile", help="Input file in BLAST standard output format and .csv format."
)
parser.add_argument(
    "filter_mode",
    choices=["soft", "strict"],
    help=(
        "R|Mode of filtering.\n\nsoft:\nKeeps the best hit (highest bitscore) "
        "for each sequence. If multiple hits have the same highest bitscore, an LCA "
        "approach is applied (assigns the taxonomy to each sequence based on all "
        "taxonomic ranks that are identical in the remaining hits of each sequence)."
        "\n\nstrict:\nPerforms 3 steps:\n  (1) bitscore filtering - keeps all hits with "
        "a bitscore >= argument -b and within argument -p percentage of the best bitscore "
        "per sequence.\n  (2) similarity cutoff - only keeps the taxonomy of hits up "
        "to a certain rank, depending on the hits blast percentage identity and cutoff "
        "values given in argument -c.\n  (3) LCA approach - assigns the taxonomy to "
        "each sequence based on all taxonomic ranks that are identical in the "
        "remaining hits of each sequence."
    ),
)
parser.add_argument(
    "-p",
    "--percentage",
    default=2,
    type=int,
    help=(
        "Percentage threshold to perform bitscore filtering on when choosing "
        'filter_mode option "strict" (default=2).'
    ),
)
parser.add_argument(
    "-l",
    "--length",
    default=100,
    type=int,
    help=(
        "Alignment length threshold to perform bitscore filtering on when "
        'choosing filter_mode option "strict" (default=100).'
    ),
)
parser.add_argument(
    "-b",
    "--bitscore",
    default=150,
    type=int,
    help=(
        "Bitscore threshold to perform bitscore filtering on when choosing "
        'filter_mode option "strict" (default=150).'
    ),
)
parser.add_argument(
    "-c",
    "--cutoff",
    metavar="N",
    nargs=6,
    default=[98, 95, 90, 85, 80, 75],
    type=int,
    help=(
        "Similarity cutoff per hit based on BLAST pident values when choosing "
        'filter_mode option "strict". pident cutoffs have to be specified via integers '
        "divided by spaces, in the order for ranks species, genus, family, order, "
        "class, phylum. Taxonomy is only kept for a rank of a hit if the hits pident "
        "is >= the respective cutoff (default=98 95 90 85 80 75)."
    ),
)
parser.add_argument(
    "-i",
    "--keep_pident",
    choices=["yes", "no"],
    default="no",
    type=str,
    help=(
        "Flag to keep percentage identity information for filtered taxa. "
        "If yes, percentage identify is kept (for OTUs with identical taxa "
        " matches, the max percentage identity value is kept) (default=no)."
    ),
)
parser.add_argument(
    "-o", "--out", default="blast_filtered.txt", type=str, help="Name of output file."
)
args = parser.parse_args()

# Set arguments
file = args.inputfile
filter_mode = args.filter_mode
percentage = args.percentage / 100
length = args.length
bitscore_threshold = args.bitscore
cutoff = args.cutoff
keep_pident = args.keep_pident
out = args.out

# Define ranks to use
ranks = ["superkingdom", "phylum", "class", "order", "family", "genus", "species"]
# Define which columns to load in
req_cols = ["qseqid", "pident", "length", "bitscore"] + ranks

# Only read in columns we need
time_print("Reading in file...")
df = pd.read_csv(
    file,
    index_col=False,
    usecols=req_cols,
    dtype={"qseqid": str, "bitscore": float, "pident": float},
).fillna("NA")

# Drop rows containing "Unknown" = taxid could not be translated
df = df[~df[ranks].apply(lambda row: row.str.contains("Unknown")).any(axis=1)]

if filter_mode == "soft":
    time_print(
        "Grouping qseqids and filtering hits based on the highest bitscore of each qseqid..."
    )
    idx = df.groupby(["qseqid"])["bitscore"].transform(max) == df["bitscore"]
    df = df[idx]

elif filter_mode == "strict":
    time_print("Filtering hits based on bitscore and length...")
    df.loc[(df["length"] < 100) & (df["bitscore"] < 155), ranks] = "NA"

    time_print(
        "Grouping qseqids and filtering hits based on bitscore cutoff for each qseqid..."
    )
    idx = (
        df.groupby(["qseqid"])["bitscore"].transform(bitscore_cutoff) == df["bitscore"]
    )
    df = df[idx]

    time_print("Applying similarity cutoff...")
    df.loc[df["pident"] < cutoff[0], "species"] = "NA"
    df.loc[df["pident"] < cutoff[1], "genus"] = "NA"
    df.loc[df["pident"] < cutoff[2], "family"] = "NA"
    df.loc[df["pident"] < cutoff[3], ["order", "suborder", "infraorder"]] = "NA"
    df.loc[df["pident"] < cutoff[4], ["class", "subclass"]] = "NA"
    df.loc[df["pident"] < cutoff[5], ["phylum", "subphylum"]] = "NA"

# Keep only relevant columns and put species to last column
df_tax = df[["qseqid"] + ranks]

## Make a df mask: group dfs, check if ranks have more than one taxon, and if yes, True, else False
time_print("Performing LCA filter...")
lca_mask = df_tax.groupby(["qseqid"]).transform(lambda x: len(set(x)) != 1)

## Replace ranks in df with "NA" based on mask
df_tax = df_tax.mask(lca_mask, "NA")

# Add qseqid info
df_tax["qseqid"] = df["qseqid"]

if keep_pident == "yes":
    # Add pident info
    df_tax["pident"] = df["pident"]

## Drop duplicate rows == aggregate taxonomic info
df = df_tax.drop_duplicates()

if keep_pident == "yes":
    # Per OTU and identical taxon match, keep the max pident
    idx_pident = df.groupby(["qseqid"] + ranks)["pident"].transform(max) == df["pident"]
    df = df[idx_pident]
    df.rename(columns={"pident": "percentage_similarity"})

# Change column name and save df
df = df.rename(columns={"qseqid": "sequence_name"})
df.to_csv(
    "/Users/christopherhempel/Desktop/blast-sofyotus-ncbi_coi_downloads_with_taxonomy_and_pident_filtered",
    index=False,
)

time_print("Filtering done.")
