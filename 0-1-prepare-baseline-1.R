#------------------------------------------------------------------------------------------------
# this takes ~ 20 minutes (this part is single threaded)
#------------------------------------------------------------------------------------------------

source("misc.R")

events = readRDS(sprintf("%s/events.rds", RDS_DATA_PATH))
clicks = readRDS(sprintf("%s/clicks.rds", RDS_DATA_PATH))
promo  = readRDS(sprintf("%s/promo.rds", RDS_DATA_PATH))

interactions = c('promo_document_id', 'campaign_id', 'advertiser_id', 'document_id', 'platform', 'country', 'state') %>% 
  combn(2, simplify = FALSE)
single_features = c('ad_id', 'campaign_id', 'advertiser_id', 'document_id', 'platform', 'geo_location', 'country', 'state', 'dma')
features_with_interactions = c(single_features, interactions)

for(i in 0L:(N_PART - 1L)) {
  
  dt_chunk = events[uuid %% N_PART == i]
  dt_chunk = clicks[dt_chunk, on = .(display_id = display_id)]
  dt_chunk = promo[dt_chunk, on = .(ad_id = ad_id)]
  setkey(dt_chunk, uuid, display_id, ad_id)
  
  # TRAIN
  dt_temp = dt_chunk[!is.na(clicked) & cv == FALSE]
  X = create_feature_matrix(dt_temp, features_with_interactions, events_h_size)
  chunk = list(X = X, y = dt_temp$clicked, dt = dt_temp[, .(uuid, document_id, promo_document_id, campaign_id, advertiser_id, display_id, ad_id)])
  save_rds_compressed(chunk, sprintf("%s/%03d.rds", RDS_BASELINE_1_MATRIX_DIR_TRAIN, i))
  # CV
  dt_temp = dt_chunk[!is.na(clicked) & cv == TRUE]
  X = create_feature_matrix(dt_temp, features_with_interactions, events_h_size)
  chunk = list(X = X, y = dt_temp$clicked, dt = dt_temp[, .(uuid, document_id, promo_document_id, campaign_id, advertiser_id, display_id, ad_id)])
  save_rds_compressed(chunk, sprintf("%s/%03d.rds", RDS_BASELINE_1_MATRIX_DIR_CV, i))
  # TEST
  dt_temp = dt_chunk[is.na(clicked)]
  X = create_feature_matrix(dt_temp, features_with_interactions, events_h_size)
  chunk = list(X = X, y = dt_temp$clicked, dt = dt_temp[, .(uuid, document_id, promo_document_id, campaign_id, advertiser_id, display_id, ad_id)])
  save_rds_compressed(chunk, sprintf("%s/%03d.rds", RDS_BASELINE_1_MATRIX_DIR_TEST, i))
  
  message(sprintf("%s chunk %03d done", Sys.time(), i))
}