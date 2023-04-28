library(trajr)
library(ggstatsplot)
library(ggpubr)

# Returns the absolute time in vegetation in seconds
abs_vegetation_duration <- function(trj) {
  sum(trj$vegetation == 1) / 50
}

# Returns the relative time in vegetation (time in vegetation / total time)
rel_vegetation_duration <- function(trj) {
  veg <- sum(trj$vegetation == 1)
  open <- sum(trj$vegetation != 1)
  return(veg / (veg + open))
}


MAX_HOVER_SPEED <- 0.01
# Returns hover time (threshold 0.01 m/s)
longest_hover_time <- function(trj) {
  intervals <- TrajSpeedIntervals(trj, slowerThan = MAX_HOVER_SPEED)
  max(c(0, intervals$duration))
}

# Calculates velocity and acceleration and attaches to trajectory
analyze_speed <- function(trj) {
    velocity <- TrajVelocity(trj)
    # remove redundant metadata
    attributes(trj$velocity) <- NULL
    trj$velocity <- velocity
    trj$speed <- Mod(velocity)
    trj$veloDir <- Arg(velocity)
    trj$accel <- Mod(TrajAcceleration(trj))
    return(trj)
}

# Calculates indices for a single trajectory
calc_traj_indices <- function(trj) {
  metadata <- attributes(trj)$metadata
  # calulate velocity/speed
  derivs <- TrajDerivatives(trj)
  trj <- analyze_speed(trj)
  # split speed by land cover type
  open_speed_only <- na.omit(trj[trj$vegetation == "0", ]$speed)
  veg_speed_only <- na.omit(trj[trj$vegetation == "1", ]$speed)
  list(
    # calculate a bunch of indices here (not all have been used in later analysis)
    absolute_vegetation_time = abs_vegetation_duration(trj),
    relative_vegetation_time = rel_vegetation_duration(trj),
    # Hover time (not used, but might be helpful for further analysis)
    longest_hover_time = longest_hover_time(trj),
    mean_speed = mean(na.omit(derivs$speed)),
    sd_speed = sd(na.omit(derivs$speed)),
    min_speed = min(na.omit(derivs$speed)),
    max_speed = max(na.omit(derivs$speed)),
    mean_veg_speed = mean(veg_speed_only),
    sd_veg_speed = sd(veg_speed_only),
    min_veg_speed = suppressWarnings(min(veg_speed_only)),
    max_veg_speed = suppressWarnings(max(veg_speed_only)),
    mean_open_speed = mean(open_speed_only),
    sd_open_speed = sd(open_speed_only),
    min_open_speed = min(open_speed_only),
    max_open_speed = max(open_speed_only),
    sinuosity2 = TrajSinuosity2(trj),
    straightness = TrajStraightness(trj),
    Emax = TrajEmax(trj),
    EmaxB = TrajEmax(trj, eMaxB = TRUE),
    directional_change_mean = mean(TrajDirectionalChange(trj)),
    directional_change_sd = sd(TrajDirectionalChange(trj))
  )
}

# Reads all trajectories specified in a metadata dataframe and computes indices 
trajs_write_indices <- function(track_metadata, frames_per_second = 50, debug = FALSE, plot = TRUE, log=FALSE) {
  # read track files and convert into scaled trajectory (metric units)
  csv_struct <- list(x = "x", y = "y")
  trjs <- TrajsBuild(track_metadata$filename,
    fps = frames_per_second, scale = track_metadata$scale_factor, spatialUnits = "m",
    timeUnits = "s", csvStruct = csv_struct, csvReadFn = read.csv2, dec = ".",
    smoothP = NA, smoothN = NA, translateToOrigin = TRUE,
  )
  for (i in c(1:length(trjs))) {
    attr(trjs[[i]], "metadata") <- track_metadata[i,]
    attr(trjs[[i]], "plot") <- plot
  }

  # calculate indices for each trajectory
  indices <- TrajsMergeStats(trjs, calc_traj_indices)
  # return a data frame containing metadata and indices
  cbind(track_metadata, indices)
}


# Tests for normal distribution in groups within a dataframe
test_for_normality_groups <- function(formulae, df, plot_data = FALSE) {
    agg_df <- aggregate(formulae,
            data = df,
            FUN = function(x) {
                    if (length(x) > 3) {
                        if(plot_data){
                            plot(ggqqplot(x), main = formulae)
                        }
                        y <- shapiro.test(x)
                        } else {
                            y <- NULL
                            }
                    c(y$statistic, y$p.value)
                }
            )
    return(agg_df)
}

# Checks whether non-parametric or parametric test is appropriate for testing 
# for differences in mean values for a given data set, then performs test
test_significance <- function(group_col, value_col, df, plot = FALSE) {
    # and perform kruskal wallis or anova.
    formulae <- as.formula(paste(value_col, group_col, sep = "~"))
    equal_variance <- bartlett.test(formulae, data = df)
    if (equal_variance$p.value < 0.05 || is.na(equal_variance$p.value)) {
            print(paste0("No equal variance for ", value_col))
            kruskal <- kruskal.test(formulae, data = df)
            return(kruskal$p.value > 0.05)
    } else {
        normality_df <- test_for_normality_groups(formulae, df, plot)
        normality <- TRUE
        for (p in normality_df$value_col) {
            if (p < 0.05) {
                normality <- FALSE
            }
        }
        if (normality) {
            print(paste0(value_col," has equal variance and is normally distributed"))
            one_way <- aov(formulae, data = df)
            aov_sum <- summary(one_way)
            if (aov_sum[[1]]$`Pr(>F)`[1] < 0.05) {
                # Significant difference (p < 0.05)"
                return(FALSE)
            } else {
                # No significant difference (p > 0.05")
                return(TRUE)
            }
        } else {
            print(paste0(value_col," has equal variance but is not normaly distributed"))
            kruskal <- kruskal.test(formulae, data = df)
            return(kruskal$p.value > 0.05)
        }
    }
}

# Checks whether non-parametric or parametric test is appropriate and returns test type as string
get_test_type <- function(group_col, value_col, df) {
  # = test equal variances and normal distributed values
  formulae <- as.formula(paste(value_col, group_col, sep = "~"))
  equal_variance <- bartlett.test(formulae, data = df)
  if (equal_variance$p.value < 0.05 || is.na(equal_variance$p.value)) {
    # if variance is not equal use non-parametric test 
    return("np")
  } else {
    normality_df <- test_for_normality_groups(formulae, df, FALSE)
    normality <- TRUE
    for (p in normality_df$value_col) {
      if (p < 0.05) {
        normality <- FALSE
      }
    }
    if (normality) {
      # if values have equal variance and they are normally distributed 
      # use non-parametric test 
      return("p")
    } else {
      # if values are not normally distributed use non-parametric test 
      return("np")
    }
  }
}