#------------------------------------------------------------------------------------------------
# this takes ~ 35 minutes on 4 core laptop
#------------------------------------------------------------------------------------------------

source("misc.R")

# cl <- makePSOCKcluster(4)
# registerDoParallel(cl)
#------------------------------------------------------------------------------------------------
dirzip = Map(c, 
             c(RDS_BASELINE_1_MATRIX_DIR_TRAIN, RDS_BASELINE_1_MATRIX_DIR_CV, RDS_BASELINE_1_MATRIX_DIR_TEST), 
             c(RDS_BASELINE_2_MATRIX_DIR_TRAIN, RDS_BASELINE_2_MATRIX_DIR_CV, RDS_BASELINE_2_MATRIX_DIR_TEST), 
             USE.NAMES = F)
# dir = dirzip[[1]]
for (dir in dirzip) {
  b1 = dir[[1]]
  b2 = dir[[2]]
  # res = foreach(i = 0L:(N_PART - 1L), .inorder = FALSE, .multicombine = TRUE,
  res = foreach(i = 0L:7L, .inorder = FALSE, .multicombine = TRUE, 
                .packages = c("data.table", "methods", "Matrix", "magrittr", "text2vec"),
                .options.multicore = list(preschedule = FALSE)) %dopar% {
    baseline_1_data = readRDS(sprintf("%s/%03d.rds", b1, i))
    # as we know rows of the data frame corresponds to row number in feature matrix baseline_1_data$x
    baseline_1_data$dt[, i := 0L:(.N - 1L)]
    setkey(baseline_1_data$dt, "uuid")
    # views_data = fst::read.fst(sprintf("%s/%03d.fst", VIEWS_DIR, i), as.data.table = TRUE)
    views_data = readRDS(sprintf("%s/%03d.rds", VIEWS_DIR, i))
    # will just use 1-hot encoded page views, so group by uuid, document_id and drop N at the end
    views_data = views_data[, .N, keyby = .(uuid, document_id)][, .(uuid, document_id)]
    
    # now build interactions - join views and baseline_1_data$dt by uuid
    views_interactions = views_data[
      baseline_1_data$dt, 
      .(
        # row index
        i, 
        # column indices
        j1 = (string_hasher("promo_document_id") + 1.0 * promo_document_id * document_id) %% views_h_size,
        j2 = (string_hasher("campaign_id") + 1.0 * campaign_id * document_id) %% views_h_size,
        j3 = (string_hasher("advertiser_id") + 1.0 * advertiser_id * document_id) %% views_h_size,
        j4 = (string_hasher("advertiser_id + campaign_id") + 1.0 * advertiser_id * campaign_id * document_id) %% views_h_size
      ), 
      on = .(uuid = uuid), 
      allow.cartesian=TRUE, 
      nomatch = 0
    ]
    rm(views_data);gc()
    # turn df into sparse matrix
    m_views = sparseMatrix(i = rep(views_interactions$i, 4), 
                           j = c(views_interactions$j1, views_interactions$j2, views_interactions$j3, views_interactions$j4), 
                           x = 1, dims = c(nrow(baseline_1_data$dt), views_h_size), index1 = F, giveCsparse = F, check = F)
    rm(views_interactions);gc()
    # cbind with events matrix and convert to CSR
    m = cbind(baseline_1_data$X, m_views) 
    y = baseline_1_data$y
    rm(m_views, baseline_1_data); gc()
    m = as(m, "RsparseMatrix");
    # save_rds_compressed(list(X = m, y = y), file = sprintf("%s/%03d.rds", b2, i))
    message(sprintf("%s - chunk %03d", Sys.time(), i))
    rm(m); gc()
    i
  }
}
