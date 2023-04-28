#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

source("helpers/preprocessing.r")
source("helpers/processing.r")
source("helpers/track_metadata.r")

# get metadata first
model_ant_metadata <- get_model_output_metadata(args[1])

# split into packages of around 4000 rows
n <- max(1,trunc(nrow(model_ant_metadata)/4000))
metadata_ls <- split(model_ant_metadata, factor(sort(rank(row.names(model_ant_metadata))%%n)))

# calculate all indices, but package wise to not overload memory
all_indices <- data.frame()
i <- 0 
for(pack in metadata_ls){
  indices <- trajs_write_indices(pack, plot=FALSE)
  all_indices <- rbind(all_indices,
             indices)
  print(paste0("Pack ", i, " done."))
  i <- i+1
}

outpath <- paste0("Experiments/",args[1],"/indices/indices_no_resample.csv")
write.csv(all_indices, outpath, row.names = FALSE)
print(paste0("Indices calculated and saved to file (", outpath, ")"))