#------------------------------------------------------------------------------------------------
# this takes ~6 minutes on 4 core laptop (4 cores + 4 hyperthreads)
#------------------------------------------------------------------------------------------------

source("misc.R")
if(!("FTRL" %in% installed.packages()[, "Package"]))
  devtools::install_github("dselivanov/FTRL")
library(FTRL)
#------------------------------------------------------------------------------------------
# cross vaidation related stuff - pick chunks on which we want validate
#------------------------------------------------------------------------------------------
CV_CHUNKS = c(0L:1L)
cv = lapply(CV_CHUNKS, function(x) readRDS(sprintf("%s/%03d.rds", RDS_BASELINE_2_MATRIX_DIR_CV, x)))
y_cv = lapply(cv, function(x) x[["y"]]) %>% do.call(c, .) %>% as.numeric
X_cv = lapply(cv, function(x) x[["X"]]) %>% do.call(rbind, .) %>% as("RsparseMatrix")
rm(cv)
dt_cv = lapply(CV_CHUNKS, function(x) readRDS(sprintf("%s/%03d.rds", RDS_BASELINE_1_MATRIX_DIR_CV, x))[['dt']]) %>% 
  rbindlist
#------------------------------------------------------------------------------------------
# TUNE hyperparameters on train-cv data  (alpha, beta, lambda, etc)
#------------------------------------------------------------------------------------------
ftrl = FTRL$new(alpha = 0.05, beta = 0.5, lambda = 10, l1_ratio = 1, dropout = 0)
for(i in 0:(N_PART - 1)) {
  data = readRDS(sprintf("%s/%03d.rds", RDS_BASELINE_2_MATRIX_DIR_TRAIN, i))
  y = as.numeric(data$y)
  # update model
  ftrl$partial_fit(X = data$X, y = y, nthread = N_THREAD_FTRL)
  
  if(i %% 16 == 0) {
    train_auc = glmnet::auc(y, ftrl$predict(data$X))
    p = ftrl$predict(X_cv)
    dt_cv_copy = copy(dt_cv[, .(display_id, clicked = y_cv, p = -p)])
    setkey(dt_cv_copy, display_id, p)
    mean_map12 = dt_cv_copy[ , .(map_12 = 1 / which(clicked == 1)), by = display_id][['map_12']] %>% 
      mean %>% round(5)
    cv_auc = glmnet::auc(y_cv, p)
    message(sprintf("%s batch %d train_auc = %f, cv_auc = %f, map@12 = %f", Sys.time(), i, train_auc, cv_auc, mean_map12))
  }
}
# should see something like:

# 2017-03-20 12:16:08 batch 0 train_auc = 0.710411, cv_auc = 0.694262, map@12 = 0.622700
# 2017-03-20 12:16:56 batch 16 train_auc = 0.757205, cv_auc = 0.737353, map@12 = 0.661460
# 2017-03-20 12:17:45 batch 32 train_auc = 0.764964, cv_auc = 0.744705, map@12 = 0.667260
# 2017-03-20 12:18:32 batch 48 train_auc = 0.768712, cv_auc = 0.748336, map@12 = 0.669640
# 2017-03-20 12:19:20 batch 64 train_auc = 0.774420, cv_auc = 0.750475, map@12 = 0.671950
# 2017-03-20 12:20:08 batch 80 train_auc = 0.776758, cv_auc = 0.752392, map@12 = 0.672740
# 2017-03-20 12:20:55 batch 96 train_auc = 0.779824, cv_auc = 0.753797, map@12 = 0.674520
# 2017-03-20 12:21:41 batch 112 train_auc = 0.783549, cv_auc = 0.754981, map@12 = 0.675260

#------------------------------------------------------------------------------------------
# TRAIN FOR SUBMISSION ON FULL DATA (train + cv)
#------------------------------------------------------------------------------------------
message(sprintf("%s start train model on full train data (train + cv files)", Sys.time()))
ftrl = FTRL$new(alpha = 0.05, beta = 0.5, lambda = 10, l1_ratio = 1, dropout = 0)
for (dir in c(RDS_BASELINE_2_MATRIX_DIR_TRAIN, RDS_BASELINE_2_MATRIX_DIR_CV)) {
  for(i in 0:(N_PART - 1)) {
    data = readRDS(sprintf("%s/%03d.rds", dir, i))
    y = as.numeric(data$y)
    # update model
    ftrl$partial_fit(X = data$X, y = y, nthread = N_THREAD_FTRL)
    
    if(i %% 16 == 0) {
      message(sprintf("%s batch %03d of %s done", Sys.time(), i, basename(dir)))
    }
  }
}

save_rds_compressed(ftrl$dump(), PATH_MODEL_2)
