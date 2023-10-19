library("microDecon")
library("dplyr")

# Path to ESV file
file <- "/Users/christopherhempel/Desktop/bluehole/18s/bluehole-18s_apscale_ESV_table_with_taxonomy.csv"
outfile <- gsub("\\.csv$", "_microdecon-filtered.csv", file)
# Contained taxonomic ranks
#ranks <- c("Phylum", "Class", "Order", "Family", "Genus", "Species")
ranks <- c("superkingdom", "phylum", "class", "order", "family", "genus", "species")
# Adapt abbreviations for samples and neg controls as necessary (sub-strings that need to be contained within the respective samples)
sample_abbr <- paste("BH", "POS", sep = "|")
neg_abbr <- paste("blank", "NEG", sep = "|")
# OTUs or ESVs?
unit="ESV"

# Import data
df <- read.csv(file, row.names = 1)

# Identify samples and neg controls
neg_controls <- names(df)[grep(neg_abbr, names(df))]
true_samples <- names(df)[grep(sample_abbr, names(df))]
samples <- c(neg_controls, true_samples)

# Generate sample df and format for microDecon
df_samples <- df[samples]
df_samples$ID <- rownames(df_samples)
rownames(df_samples) <- NULL
df_samples <- df_samples[c("ID", names(df_samples)[-ncol(df_samples)] )]

# Separating other information
df_tax <- df[ranks]
df_metadata <- df %>%
  select(-any_of(c(samples, ranks)))

# Decontamination function
# Note: threshold functions are disabled because we already have thresholds as part of the bioinformatics pipeline
# Note2: we can specify different groups of samples with numb.ind, but we only have one group, so this is set to the number of samples
decon_results <- decon(data=df_samples, numb.blanks=length(neg_controls), numb.ind=c(length(true_samples)),taxa=F) # taxa=F because the last column does not contain tax information

# Save filtered df
df_samples_decon <- decon_results$decon.table

# Merge reads and other data
df_tax$ID <- rownames(df_tax)
df_metadata$ID <- rownames(df_metadata)
df_decon <- merge(df_samples_decon, df_tax, by = "ID")
df_decon <- merge(df_decon, df_metadata, by = "ID")

# Restore OTU order
df_decon$NumericValues <- as.numeric(gsub(paste0(unit, "_"), "", df_decon$ID))
df_decon <- df_decon[order(df_decon$NumericValues), ]
df_decon <- df_decon[, -ncol(df_decon)]

# Export df
write.csv(df_decon, outfile, row.names = FALSE)
