source("helpers/preprocessing.r")
source("helpers/processing.r")
source("helpers/track_metadata.r")
library(ggstatsplot)

print("Loading metadata...")
raw_metadata_extended_df <- get_raw_metadata_extended()
new_metadata_df <- data.frame(matrix(ncol=6,nrow=0, dimnames=list(NULL, c("filename", "trackname", "run", "number", "behavior", "scale_factor"))))

print("Metadata loaded.")

print("Run preprocessing...")
for (row in 1:nrow(raw_metadata_extended_df)) {
    name <- raw_metadata_extended_df[row, "filename"]
    scf <-  raw_metadata_extended_df[row, "scale_factor"]
    searching_behavior <- raw_metadata_extended_df[row, "behavior"]
    
    # First step: rename columns of track files
    renamed_tracks_file_path <- rename_track_columns(name,  "preprocessing/renamed_cols/")

    # Second step: Smooth trajectory
    smoothed_file_name <- smooth_trajectory(renamed_tracks_file_path, 3, 41, "preprocessing/smoothed/")
    
    splitted_file_names <- split_by_motivation(smoothed_file_name, "preprocessing/splitted/")
    
    for (split_name in splitted_file_names) {
      # Third step: Buffer trajectory
      is_homing <- grepl("homing", split_name)
      buffered_file_name <- buffer_trajectory(split_name, scf, 0.5, "preprocessing/buffered/", homing = is_homing)
      
      # Third step: Annotate tracks with vegetation information
      vegetation_label_file_name <- intersect_track_and_veg(buffered_file_name, "preprocessing/with_vegetation/")
      
      raw_metadata_extended_df[row,]['filename'] <- vegetation_label_file_name
      if(is_homing){
        raw_metadata_extended_df[row,]['behavior'] <- 'homing'
      }else{
        raw_metadata_extended_df[row,]['behavior'] <- searching_behavior
      }
      new_row = raw_metadata_extended_df[row,]
      new_metadata_df <- rbind(new_metadata_df, new_row)
    }
    print(paste0(name, " processed."))
}
print("Preprocessing complete.")

print("Computing indices...")
observation_indices <- trajs_write_indices(new_metadata_df)
if (!dir.exists(file.path('validation_data'))){
  dir.create(file.path('validation_data'), recursive = TRUE)
}
outpath <- paste0("validation_data/observation_indices.csv")
write.csv(observation_indices, outpath, row.names = FALSE)
print(paste0("Indices calculated and saved to file (", outpath, ")"))

print("Performing tests of equal differences and creating plots...")
equality_reporter <- data.frame(
  Indice = c(),
  Equal = c()
)
equality_reporter_vegetation <- data.frame(
  Indice = c(),
  Equal = c()
)
test_types_vegetation <- list()
test_types <- list()
# plot data as boxplot with points
y_vals <- list("mean_speed", 
               "sd_speed", 
               "min_speed", 
               "max_speed", 
               "mean_open_speed", 
               "sd_open_speed", 
               "mean_veg_speed", 
               "sd_veg_speed", 
               "min_veg_speed", 
               "max_veg_speed", 
               "min_open_speed", 
               "max_open_speed", 
               "sinuosity2", 
               "straightness", 
               "Emax", 
               "directional_change_mean", 
               "directional_change_sd", 
               "absolute_vegetation_time", 
               "relative_vegetation_time"
)

for (ic in y_vals) {
  test_types <- append(test_types, get_test_type("behavior", ic, observation_indices))
  equally_distributed <- test_significance("behavior", ic, observation_indices, plot = FALSE)
  equality_reporter <- rbind(equality_reporter, c(ic, equally_distributed))
}

ylab_vals <- list(
                  "Mean speed (m/s)", 
                  "Standard Deviation Speed (m/s)", 
                  "Minimum Speed (m/s)", 
                  "Maximum Speed (m/s)",   
                  "Mean Speed on Sand (m/s)", 
                  "SD of Speed on Sand (m/s)", 
                  "Mean Speed in Shrubs (m/s)", 
                  "SD of Speed in Shrubs (m/s)", 
                  "Minimum Speed in Shrubs (m/s)", 
                  "Maximum Speed in Shrubs (m/s)", 
                  "Minimum Speed on Sand (m/s)", 
                  "Maximum Speed on Sand (m/s)", 
                  "Corrected Sinuosity", 
                  "Straightness", 
                  "Maximum Expected Displacement", 
                  "Mean Directional Change (°/s)", 
                  "SD of Directional Change (°/s)", 
                  "Absolute Time within Shrubs (s)", 
                  "Relative Time in Shrubs"
)

plot_values <- mapply(list, y_vals, test_types, ylab_vals, SIMPLIFY=F)

if (!dir.exists(file.path('analysis_plots_r'))){
  dir.create(file.path('analysis_plots_r'), recursive = TRUE)
}

for (combi in plot_values) {
  df <- observation_indices[is.finite(observation_indices[, combi[[1]]]), ]
  df$behavior <- factor(df$behavior,levels = c("initial search", "oriented search", "homing"))
  p <- ggbetweenstats(
      data = df,
      x = behavior,
      y = !!rlang::sym(combi[[1]]),
      plot.type = "box", # for boxplot
      type = combi[[2]], # for wilcoxon
      centrality.plotting = FALSE, # remove median
      pairwise.display = 'all',
      bf.message = FALSE,
      effsize.type = "unbiased",
      xlab = "Motivation",
      ylab = combi[[3]]
    )
  # p <- p + scale_x_discrete(labels=c("z_homing" = "homing", "oriented search" = "oriented search",
  #                                    "a_initial search" = "initial search"))
  ggsave(filename = paste0("analysis_plots_r/", combi[[1]], ".pdf"), device = "pdf", plot = p, width = 5.5, height = 4.45, dpi = 600, units = "in")
}

# Speed comparison by land cover type
veg_means_only <- data.frame(val = observation_indices[is.finite(observation_indices[, "mean_veg_speed"]), ]$mean_veg_speed,
                             sd = observation_indices[is.finite(observation_indices[, "mean_veg_speed"]), ]$sd_veg_speed)
veg_means_only["landcover"] <- "shrub"
open_means_only <- data.frame(val = observation_indices$mean_open_speed, sd = observation_indices$sd_open_speed)
open_means_only["landcover"] <- "sand"
all_means <- rbind(veg_means_only, open_means_only)

# Test for differences in mean speed
bartlett_mean <- bartlett.test(val ~ landcover, data = all_means)
normality_df <- test_for_normality_groups(val ~ landcover, all_means, TRUE)

test_type <- "p"
for (p in normality_df$val[,2]) {
  if (p < 0.05) {
    test_type <- "np"
  }
}
if (bartlett_mean$p.value < 0.05) {
  test_type <- "np"
}

# Plot mean speed by land cover
p <- ggbetweenstats(
  data = all_means,
  x = landcover,
  y = val,
  plot.type = "box", # for boxplot
  type = test_type, # for wilcoxon
  centrality.plotting = FALSE, # remove median
  pairwise.display = 'all',
  bf.message = FALSE,
  effsize.type = "unbiased",
  xlab = "Land cover",
  ylab = "Mean speed (m/s)",
  package = "ggsci",
  palette = "default_jco"
)
ggsave(filename = "analysis_plots_r/mean_speed_by_vegetation.pdf", device = "pdf", plot = p, width = 5.5, height = 4.45, dpi = 600, units = "in")

# Repeat for SD of speed
bartlett_sd <- bartlett.test(sd ~ landcover, data = all_means)
normality_df <- test_for_normality_groups(sd ~ landcover, all_means, TRUE)
test_type <- "p"
for (p in normality_df$sd[,2]) {
  if (p < 0.05) {
    test_type <- "np"
  }
}
if (bartlett_sd$p.value < 0.05) {
  test_type <- "np"
}
p <- ggbetweenstats(
  data = all_means,
  x = landcover,
  y = sd,
  plot.type = "box", # for boxplot
  type = test_type, # for wilcoxon
  centrality.plotting = FALSE, # remove median
  pairwise.display = 'all',
  bf.message = FALSE,
  effsize.type = "unbiased",
  xlab = "Land cover",
  ylab = "SD speed (m/s)",
  package = "ggsci",
  palette = "default_jco",
)
ggsave(filename = "analysis_plots_r/sd_speed_by_vegetation.pdf", device = "pdf", plot = p, width = 5.5, height = 4.45, dpi = 600, units = "in")

print("Test complete and plots saved in directory ./analysis_plots_r")

