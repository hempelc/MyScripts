# Nonpareil processing

library(Nonpareil)
library(viridis)
library(ggplot2)
library(tibble)

# Dir containing nonpareil set file and .npo files
setwd("/Users/christopherhempel/Desktop/elisa/qc/deepseep/nonpareil_deepseep")

# Read in df
df <- read.table('nonpareil_set_file.tsv', sep='\t', header=TRUE, as.is=TRUE)
# Add colours based on n samples and viridis palette
colour_num = nrow(df)
df$colours = viridis_pal()(n = colour_num)

# Generate nonpareil curves
attach(df)
png("nonpareil_curves.png", width = 600, height = 400)
nps <- Nonpareil.set(File, col=colours, labels=Name, plot.opts=list(plot.observed=FALSE, plot.diversity=FALSE))
dev.off()
detach(df)

# Plot coverage_df
## Generate and polish df
coverage_df = data.frame(summary(nps)[,"C"]*100)
## Reset the index column to a new column
coverage_df = rownames_to_column(coverage_df)
## Set colnames
colnames(coverage_df) <- c("sample", "coverage")
## Reorder rows and turn samples to factor to keep order in ggplot
coverage_df <- coverage_df[order(coverage_df$coverage), ]
coverage_df$sample <- factor(coverage_df$sample, levels = coverage_df$sample)

## Calculate the average coverage for hline
average_coverage <- mean(coverage_df$coverage)

## Plot
coverage_plot <- ggplot(coverage_df, aes(x = sample, y = coverage)) +
  geom_bar(stat = "identity", fill = "orange") +
  labs(title = "Nonpareil coverage", x = "Sample", y = "Coverage") +
  geom_hline(yintercept = average_coverage, color = "black", linetype = "dashed") +
  ylim(0,100)

ggsave("coverages.png", width = 6, height=4)
