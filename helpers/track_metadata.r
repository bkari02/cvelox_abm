# Returns metadata for raw ant tracks 
get_raw_metadata_extended <- function() {
  tracks <- as.data.frame(rbind(
    # First track for ant03 is in different coordinate system - other scale factor!
    c("raw_ant_data/tracks/Ant03/Ant03R01_labels.csv", "A03R01", "01", "03", "initial search", 9 / 3631 * 0.569427),
    c("raw_ant_data/tracks/Ant03/Ant03R02_labels.csv", "A03R02", "02", "03", "oriented search", 9 / 3631),
    c("raw_ant_data/tracks/Ant03/Ant03R03_labels.csv", "A03R03", "03", "03", "oriented search", 9 / 3631),
    c("raw_ant_data/tracks/Ant03/Ant03R05_labels.csv", "A03R05", "05", "03", "oriented search", 9 / 3631),
    c("raw_ant_data/tracks/Ant05/Ant05R08_labels.csv", "A05R08", "08", "05", "initial search", 8.1512 / 3536),
    c("raw_ant_data/tracks/Ant05/Ant05R09_labels.csv", "A05R09", "09", "05", "oriented search", 8.1512 / 3536),
    c("raw_ant_data/tracks/Ant05/Ant05R10_labels.csv", "A05R10", "10", "05", "oriented search", 8.1512 / 3536),
    c("raw_ant_data/tracks/Ant06/Ant06R03_labels.csv", "A06R03", "03", "06", "initial search", 7.5847 / 3902),
    c("raw_ant_data/tracks/Ant06/Ant06R04_labels.csv", "A06R04", "04", "06", "oriented search", 7.5847 / 3902),
    c("raw_ant_data/tracks/Ant06/Ant06R05_labels.csv", "A06R05", "05", "06", "oriented search", 7.5847 / 3902),
    c("raw_ant_data/tracks/Ant11/Ant11R04_labels.csv", "A11R04", "04", "11", "oriented search", 7.6172 / 3068),
    c("raw_ant_data/tracks/Ant11/Ant11R05_labels.csv", "A11R05", "05", "11", "oriented search", 7.6172 / 3068),
    c("raw_ant_data/tracks/Ant11/Ant11R06_labels.csv", "A11R06", "06", "11", "oriented search", 7.6172 / 3068)
  ), stringsAsFactors = FALSE)
  colnames(tracks) <- c("filename", "trackname", "run", "number", "behavior", "scale_factor")
  return(tracks)
}

# Returns metadata for model output trajectories for a given experiment ID
get_model_output_metadata <- function(exp_name) {
    metadata_files <- list.files(path=paste0("Experiments/", exp_name, "/trjs"), pattern="metadata.csv", full.names=TRUE, recursive=TRUE)
    all_tracks <- data.frame()
    for (mdf in metadata_files) {
        tracks <- read.csv2(mdf, dec = ".", header = TRUE)
        all_tracks <- rbind(all_tracks, tracks)
    }
    return(all_tracks)
}