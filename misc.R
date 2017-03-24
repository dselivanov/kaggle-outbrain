source("conf.R")

suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(doParallel))
library(methods)
library(Matrix)
library(magrittr)

if (.Platform$OS.type != "unix") {
  cl <- makePSOCKcluster(N_CORES_PREPROCSESSING)
  registerDoParallel(cl)
  message(sprintf("Detected Windows platform. Cluster with %d cores and name \"cl\"  registred. 
                  Stop it with `stopCluster(cl)` at the end.", N_CORES_PREPROCSESSING))
} else {
  registerDoParallel(N_CORES_PREPROCSESSING)
}

fread_zip = function( file , ...) {
  fn = basename(file)
  file = path.expand(file)
  # cut ".zip" suffix using substr
  path = paste("unzip -p", file, substr(x = fn, 1, length(fn) - 4))
  fread(path, ...)
}

string_hasher = function(x, h_size = UUID_HASH_SIZE) {
  text2vec:::hasher(x, h_size)
}
  
save_rds_compressed = function(x, file, compression_level = 1L) {
  con = gzfile(file, open = "wb", compression = compression_level)
  saveRDS(x, file = con)
  close.connection(con)
}

create_feature_matrix = function(dt, features,  h_space_size = h_space_size) {
  # 0-based indices
  row_index = rep(0L:(nrow(dt) - 1L), length(features))
  # note that here we adding `text2vec:::hasher(feature, h_space_size)` - hash offset for this feature
  # this reduces number of collisons because. If we won't apply such scheme - identical values of 
  # different features will be hashed to same value
  col_index = Map(function(fnames) {
    # here we calculate offset for each feature
    # hash name of feature to reduce number of collisions 
    # because for eample if we won't hash value of platform=1 will be hashed to the same as advertiser_id=1
    offset = string_hasher(paste(fnames, collapse = "_"), h_space_size)
    # calculate index = offest + sum(feature values)
    index = (offset + Reduce(`+`, dt[, fnames, with = FALSE])) %% h_space_size
    as.integer(index)
  }, features) %>% 
    unlist(recursive = FALSE, use.names = FALSE)
  
  m = sparseMatrix(i = row_index, j = col_index, x = 1,
                   dims = c(nrow(dt), h_space_size),
                   index1 = FALSE, giveCsparse = FALSE, check = FALSE)
  m
}
