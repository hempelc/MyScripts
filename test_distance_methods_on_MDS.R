# Test the impact of different distance methods
# NOT: requires a phyloseq object!
# In plot_ordination, we coloured based on an env variable. replace as you see fit.
dists <- unlist(distanceMethodList)
dists <- dists[-(1:3)]
dists = dists[-which(dists=="ANY")]
dists = dists[-which(dists=="mountford")]
plist <- vector("list", length=length(dists))
names(plist) = dists
for( i in dists ){
  # Calculate distance matrix
  iDist <- distance(physeq_agg_rel_n0, method=i)
  # Calculate ordination
  iMDS  <- ordinate(physeq_agg_rel_n0, "MDS", distance=iDist)
  ## Make plot
  # Don't carry over previous plot (if error, p will be blank)
  p <- NULL
  # Create plot, store as temp variable, p
  p <- plot_ordination(physeq_agg_rel_n0, iMDS, color="Depth.category")
  # Add title to each plot
  p <- p + ggtitle(paste("MDS using distance method ", i, sep=""))
  # Save the graphic to file.
  plist[[i]] = p
}
df = ldply(plist, function(x) x$data)
names(df)[1] <- "distance"
p = ggplot(df, aes(Axis.1, Axis.2, color=Depth.category)) +
  geom_point(size=0.5, alpha=0.5) +
  facet_wrap(~distance, scales="free") +
  theme_bw() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank()
  ) +
  scale_color_manual(values = c("red2", "forestgreen", "blue3", "yellow2", "grey"))
ggsave("/Users/christopherhempel/Desktop/distance-summary-plot-rsde.png", p, width = 13, height = 9, units = "in")

# Check distance effect on clr transformed data
# Note:
# If any values are zero, the clr transform routine first adds a small pseudocount of min(relative abundance)/2 to all values. To avoid this, you can replace any zeros in advance by setting zero_replace to a number > 0.
# Better do manually
physeq_agg_rel_n0_clr <- microbiome::transform(physeq_agg_rel_n0, "clr")

# Test the impact of different distance methods
dists <- unlist(distanceMethodList)
dists <- dists[-(1:3)]
dists = dists[-which(dists=="ANY")]
dists = dists[-which(dists=="mountford")]
dists = dists[-which(dists=="bray")]
dists = dists[-which(dists=="kulczynski")]
dists = dists[-which(dists=="jaccard")]
dists = dists[-which(dists=="morisita")]
dists = dists[-which(dists=="horn")]
dists = dists[-which(dists=="binomial")]
dists = dists[-which(dists=="chao")]
dists = dists[-which(dists=="binary")]
plist <- vector("list", length=length(dists))
names(plist) = dists
for( i in dists ){
  # Calculate distance matrix
  iDist <- distance(physeq_agg_rel_n0_clr, method=i)
  # Calculate ordination
  iMDS  <- ordinate(physeq_agg_rel_n0_clr, "MDS", distance=iDist)
  ## Make plot
  # Don't carry over previous plot (if error, p will be blank)
  p <- NULL
  # Create plot, store as temp variable, p
  p <- plot_ordination(physeq_agg_rel_n0_clr, iMDS, color="Depth.category")
  # Add title to each plot
  p <- p + ggtitle(paste("MDS using distance method ", i, sep=""))
  # Save the graphic to file.
  plist[[i]] = p
}
df = ldply(plist, function(x) x$data)
names(df)[1] <- "distance"
p = ggplot(df, aes(Axis.1, Axis.2, color=Depth.category)) +
  geom_point(size=0.5, alpha=0.5) +
  facet_wrap(~distance, scales="free") +
  theme_bw() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank()
  ) +
  scale_color_manual(values = c("red2", "forestgreen", "blue3", "yellow2", "grey"))
ggsave("/Users/christopherhempel/Desktop/distance-summary-plot-rsde_clr.png", p, width = 13, height = 9, units = "in")
