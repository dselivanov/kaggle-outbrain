source("misc.R")
library(FTRL)
model_dump = readRDS(PATH_MODEL_2)
ftrl = FTRL$new()
ftrl$load(model_dump); rm(model_dump)

ad_probabilities = lapply(0:(N_PART - 1), function(i) {
  test_data_chunk = readRDS(sprintf("%s/%03d.rds", RDS_BASELINE_1_MATRIX_DIR_TEST, i))
  dt = test_data_chunk$dt[, .(display_id, ad_id)]
  test_data_chunk = readRDS(sprintf("%s/%03d.rds", RDS_BASELINE_2_MATRIX_DIR_TEST, i))
  X = test_data_chunk$X
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
fwrite(x = ad_subm, file = PATH_MODEL_2_SUBMISSION_FILE); rm(ad_subm)

# on LB this gives
# 0.67867 - Private Score
# 0.67854 - Public Score

#------------------------------------------------------------
# exploit leak
#------------------------------------------------------------
leak = readRDS(LEAK_PATH)
ad_probabilities_leak = leak[ad_probabilities, on = .(display_id=display_id, ad_id = ad_id)]
ad_probabilities_leak[is.na(leak), leak := 0]
ad_probabilities_leak[, p_neg_leak := pmin(p_neg, -leak)]
setkey(ad_probabilities_leak, display_id, p_neg_leak)

ad_subm_leak = ad_probabilities_leak[, .(ad_id = paste(ad_id, collapse = " ")), keyby = display_id]
fwrite(x = ad_subm_leak, file = PATH_MODEL_2_SUBMISSION_FILE_LEAK)
