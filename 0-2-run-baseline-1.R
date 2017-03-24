#------------------------------------------------------------------------------------------------
# this takes ~6 minutes on 4 core laptop (4 cores + 4 hyperthreads)
#------------------------------------------------------------------------------------------------

source("misc.R")
if(!("FTRL" %in% installed.packages()[, "Package"]))
  devtools::install_github("dselivanov/FTRL")
library(FTRL)
#------------------------------------------------------------------------------------------
# cross vaidation related stuff - pick chunks on which we want 
#------------------------------------------------------------------------------------------
CV_CHUNKS = c(0L:1L)
cv = lapply(CV_CHUNKS, function(x) readRDS(sprintf("%s/%03d.rds", RDS_BASELINE_1_MATRIX_DIR_CV, x)))
dt_cv = lapply(cv, function(x) x[["dt"]]) %>% rbindlist
y_cv = lapply(cv, function(x) x[["y"]]) %>% do.call(c, .) %>% as.numeric
X_cv = lapply(cv, function(x) x[["X"]]) %>% do.call(rbind, .) %>% as("RsparseMatrix")
rm(cv)
#------------------------------------------------------------------------------------------
# TUNE hyperparameters on train-cv data  (alpha, beta, lambda, etc)
#------------------------------------------------------------------------------------------
ftrl = FTRL$new(alpha = 0.05, beta = 0.5, lambda = 1, l1_ratio = 1, dropout = 0)
for(i in 0:(N_PART - 1)) {
  data = readRDS(sprintf("%s/%03d.rds", RDS_BASELINE_1_MATRIX_DIR_TRAIN, i))
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
    message(sprintf("%s batch %03d train_auc = %.4f, cv_auc = %.4f, map@12 = %.4f", Sys.time(), i, train_auc, cv_auc, mean_map12))
  }
}
# should see something like:
# 2017-03-20 11:57:22 batch 0 train_auc = 0.747189, cv_auc = 0.701484, map@12 = 0.627510
# 2017-03-20 11:58:17 batch 16 train_auc = 0.761650, cv_auc = 0.726005, map@12 = 0.645210
# 2017-03-20 11:59:13 batch 32 train_auc = 0.763416, cv_auc = 0.730812, map@12 = 0.649480
# 2017-03-20 12:00:08 batch 48 train_auc = 0.763170, cv_auc = 0.733345, map@12 = 0.650920
# 2017-03-20 12:01:02 batch 64 train_auc = 0.765652, cv_auc = 0.734658, map@12 = 0.652810
# 2017-03-20 12:01:54 batch 80 train_auc = 0.764900, cv_auc = 0.735988, map@12 = 0.653920
# 2017-03-20 12:02:48 batch 96 train_auc = 0.765840, cv_auc = 0.736944, map@12 = 0.654550
# 2017-03-20 12:03:40 batch 112 train_auc = 0.767763, cv_auc = 0.737670, map@12 = 0.654870

#------------------------------------------------------------------------------------------
# TRAIN FOR SUBMISSION ON FULL DATA (train + cv)
#------------------------------------------------------------------------------------------
message(sprintf("%s start train model on full train data (train + cv files)", Sys.time()))
ftrl = FTRL$new(alpha = 0.05, beta = 0.5, lambda = 1, l1_ratio = 1, dropout = 0)
for (dir in c(RDS_BASELINE_1_MATRIX_DIR_TRAIN, RDS_BASELINE_1_MATRIX_DIR_CV)) {
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
message(sprintf("%s training done. Saving model...", Sys.time()))
save_rds_compressed(ftrl$dump(), PATH_MODEL_1)
