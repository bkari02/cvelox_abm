library(tools)
library(sf)
library(trajr)

rename_track_columns <- function(filename, outfolder) {
    # read track and rename columns, then save to file
    track <- read.csv(filename, header = TRUE)
    names(track)[names(track) == "X..x"] <- "x"
    names(track)[names(track) == "X.cookie."] <- "cookie"
    new_name <- paste0(
        outfolder,
        basename(file_path_sans_ext(filename)), ".csv"
    )
    if (!dir.exists(file.path(outfolder))){
      dir.create(file.path(outfolder), recursive = TRUE)
    }
    write.table(track,
        file = new_name,
        row.names = FALSE, sep = ";"
    )
    return(new_name)
}


map_panoramic_image_file_name <- function(name) {
    # get the appropriate vegetation shape file for an ant
    basepath <- "raw_ant_data/vegetation/"
    endpath <- "_vegetation"
    extension <- ".shp"
    ifelse(grepl("Ant03", name),
      paste0(basepath, "Ant03/ant03", endpath, extension),
      ifelse(grepl("Ant05", name),
        paste0(basepath, "Ant05/ant05", endpath, extension),
        ifelse(grepl("Ant06", name),
          paste0(basepath, "Ant06/ant06", endpath, extension),
          paste0(basepath, "Ant11/ant11", endpath, extension)
        )
      )
    )
}

smooth_trajectory <- function(trackname, poly, window_length, outfolder) {
    # load track data from csv and convert to trajectory object
    track <- read.csv2(trackname, dec = ".", header = TRUE)
    trj <- TrajFromCoords(track, fps = 50)

    # smooth trajectory with SG filter
    trj_smooth <- TrajSmoothSG(trj, p = as.numeric(poly), n = as.numeric(window_length))
    
    # save smoothed trajectory to file
    out_file_name <- paste0(
        outfolder,
        basename(file_path_sans_ext(trackname)),
        "_smooth_p", poly, "_n", window_length, ".", file_ext(trackname)
    )
    if (!dir.exists(file.path(outfolder))){
      dir.create(file.path(outfolder), recursive = TRUE)
    }
    write.table(trj_smooth, file = out_file_name, row.names = FALSE, sep = ";")
    return(out_file_name)
}

buffer_trajectory <- function(trackname, scf, buffer_dist, outfolder, homing = TRUE) {
    # read track and transform into Trajectory with metric units
    track <- read.csv2(trackname, dec = ".", header = TRUE)
    trj <- TrajFromCoords(track, xCol = "x", yCol = "y", fps = 50)
    trj <- TrajScale(trj, scale = as.numeric(scf), units = "m")
    # get first and last point (nest and feeder, or reversed)
    traj_tail <- st_point(c(tail(trj, n = 1)$x, tail(trj, n = 1)$y))
    head <- st_point(c(trj[1, ]$x, trj[1, ]$y))
    # convert to sf object 
    sf_trj <- st_as_sf(trj, coords = c("x", "y"))
    # compute distance between each point of trajectory and the nest and feeder
    sf_trj$tail_dist <- st_distance(sf_trj$geometry, traj_tail, by_element = FALSE)
    sf_trj$head_dist <- st_distance(sf_trj$geometry, head, by_element = FALSE)
    trj$tail_dist <- sf_trj$tail_dist
    trj$head_dist <- sf_trj$head_dist
    # create masks with buffer distance 
    trj$tail_mask <- trj$tail_dist > buffer_dist
    trj$tail_mask_inv <- trj$tail_dist <= buffer_dist
    trj$tail_cumsum_inv <- cumsum(trj$tail_mask_inv)
    trj$head_mask <- trj$head_dist > buffer_dist
    trj$head_mask_inv <- trj$head_dist <= buffer_dist
    trj$head_cumsum_inv <- cumsum(trj$head_mask_inv)
    # split where buffer distance is lower than buffer
    tail_masked_trj <- trj[trj$tail_mask, ]
    tail_split_trj_list <- split(tail_masked_trj, f = tail_masked_trj$tail_cumsum_inv)
    # make sure to only get the main trajectory (sometimes there is more than one part returned) 
    ind_tail <- sapply(tail_split_trj_list, nrow)
    tail_buffered_trj <- tail_split_trj_list[ind_tail == max(ind_tail)][[1]]
    # if homing cut both, head and tail with buffer, else only tail
    if (homing) {
      head_masked_trj <- tail_buffered_trj[tail_buffered_trj$head_mask, ]
      head_split_trj_list <- split(head_masked_trj, f = head_masked_trj$head_cumsum_inv)
      ind_head <- sapply(head_split_trj_list, nrow)
      head_buffered_trj <- head_split_trj_list[ind_head == max(ind_head)][[1]]
    } else {
      head_buffered_trj <- tail_buffered_trj
    }
    # revert scaling and save to file
    buffered_trj <- TrajScale(head_buffered_trj, scale = 1 / as.numeric(scf), units = "arbitrary")
    out_file_name <- paste0(
        outfolder,
        basename(file_path_sans_ext(trackname)),
        "_buffered.", file_ext(trackname)
    )
    if (!dir.exists(file.path(outfolder))){
      dir.create(file.path(outfolder), recursive = TRUE)
    }
    write.table(buffered_trj, file = out_file_name, row.names = FALSE, sep = ";")
    return(out_file_name)
}

intersect_track_and_veg <- function(trackname, outfolder) {
    # load vegetation shapefile
    veg <- st_read(map_panoramic_image_file_name(trackname), quiet = TRUE)
    st_crs(veg) <- NA_crs_

    # load track data from csv and convert to trajectory object
    track <- read.csv2(trackname, dec = ".", header = TRUE)
    trj <- TrajFromCoords(track, fps = 50)

    # compute intersection with vegetation
    trj_sf <- st_as_sf(trj,
        coords = c("x", "y"),
        remove = FALSE
    )
    if(grepl("Ant03R01", trackname)){
      # Ant 03 Run 01 is a special case, where vegetation is already labeled 
      # and the panorama of ant03 is on another coordinate system! 
      # Thus, just use the existing labels for Ant 03 Run 01.
      names(trj_sf)[names(trj_sf) == "X.bush."] <- "vegetation"
    }else{
      # otherwise use intersection with polygons from panorama to annotate data
      intersection_veg_sgbp <- st_intersects(trj_sf, veg)
      vegetation_logical <- lengths(intersection_veg_sgbp) > 0
      trj_sf$vegetation <- ifelse(vegetation_logical, 1, 0)
    }
    
    # write to file
    out_file_name <- paste0(
        outfolder,
        basename(file_path_sans_ext(trackname)),
        "_vegetation.", file_ext(trackname)
    )
    if (!dir.exists(file.path(outfolder))){
      dir.create(file.path(outfolder), recursive = TRUE)
    }
    write.table(trj_sf, file = out_file_name, row.names = FALSE, sep = ";")
    return(out_file_name)
}

split_by_motivation <- function(filename, outfolder) {
    #  Read file
    track <- read.csv2(filename, dec = ".", header = TRUE)

    # Split dataframe into multiple dataframe based on cookie value
    split_tracks <- split(track, track$cookie)

    # Write each into a seperate csv
    splitted_names_list <- c()
    for (subtrack in split_tracks) {
        if (subtrack$cookie[1] == 0) {
            new_filename <- paste0(
                outfolder,
                tools::file_path_sans_ext(basename(filename)), "_searching", ".csv"
            )
        } else {
            new_filename <- paste0(
                outfolder,
                tools::file_path_sans_ext(basename(filename)), "_homing", ".csv"
            )
        }
        splitted_names_list <- append(splitted_names_list, new_filename)
        if (!dir.exists(file.path(outfolder))){
          dir.create(file.path(outfolder), recursive = TRUE)
        }
        write.table(subtrack, new_filename, row.names = FALSE, sep = ";")
    }
    return(splitted_names_list)
}
