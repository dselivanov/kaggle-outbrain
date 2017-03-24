source("misc.R")
library(FTRL)
model_dump = readRDS(PATH_MODEL_1)
ftrl = FTRL$new()
ftrl$load(model_dump); rm(model_dump)

ad_probabilities = lapply(0:(N_PART - 1), function(i) {
  test_data_chunk = readRDS(sprintf("%s/%03d.rds", RDS_BASELINE_1_MATRIX_DIR_TEST, i))
  X = test_data_chunk$X
  dt = test_data_chunk$dt[, .(display_id, ad_id)]
  rm(test_data_chunk);
  dt[, p := ftrl$predict(X)]
  if(i %% 16 == 0)
    message(sprintf("%s %03d", Sys.time(), i))
  dt
}) %>% rbindlist()

# create p_neg - data.table setkey sort in ascedenting order
ad_probabilities[, p_neg := -p]
setkey(ad_probabilities, display_id, p_neg)

# create submission 
ad_subm = ad_probabilities[, .(ad_id = paste(ad_id, collapse = " ")), keyby = display_id]
fwrite(x = ad_subm, file = PATH_MODEL_1_SUBMISSION_FILE)
