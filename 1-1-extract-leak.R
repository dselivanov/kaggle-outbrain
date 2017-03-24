source("misc.R")
clicks = readRDS(sprintf("%s/clicks.rds", RDS_DATA_PATH))
clicks = clicks[is.na(clicked), .(display_id, ad_id)]

events = readRDS(sprintf("%s/events.rds", RDS_DATA_PATH))
events = events[, .(display_id, uuid)]

dt = events[clicks, on = .(display_id = display_id)]
rm(events, clicks)

promo = readRDS(sprintf("%s/promo.rds", RDS_DATA_PATH))
dt = dt[promo, .(display_id, ad_id, promo_document_id, uuid), on = .(ad_id = ad_id), nomatch = 0]

views = list.files(VIEWS_DIR, full.names = TRUE) %>% 
  mclapply(readRDS, mc.preschedule = F, mc.cores = 4) %>% 
  rbindlist()
views[, timestamp := NULL]

dt = views[dt, .(display_id, ad_id) , on = .(uuid = uuid, document_id = promo_document_id), nomatch = 0]; rm(views)
dt = dt[, .(leak = 1), keyby = .(display_id, ad_id)]
save_rds_compressed(dt, LEAK_PATH)
