source("misc.R")

#--------------------------------------------------------------------------------------------
promo = fread_zip(sprintf("%s/promoted_content.csv.zip", RAW_DATA_PATH))
setnames(promo, 'document_id', 'promo_document_id')
save_rds_compressed(promo, sprintf("%s/promo.rds", RDS_DATA_PATH))
rm(promo)
#--------------------------------------------------------------------------------------------
clicks_train = fread_zip(sprintf("%s/clicks_train.csv.zip", RAW_DATA_PATH))
#--------------------------------------------------------------------------------------------
clicks_test = fread_zip(sprintf("%s/clicks_test.csv.zip", RAW_DATA_PATH))
clicks_test[, clicked :=  NA_integer_]
clicks = rbindlist(list(clicks_train, clicks_test)); 
rm(clicks_test, clicks_train);gc()
save_rds_compressed(clicks, sprintf("%s/clicks.rds", RDS_DATA_PATH))
#--------------------------------------------------------------------------------------------
events = fread_zip(sprintf("%s/events.csv.zip", RAW_DATA_PATH))
# several values in "platform" column has som bad values, so we need to remove these rows or convert to some value
events[ , platform := as.integer(platform)]
# I chose to convert them to most common value
events[is.na(platform), platform := 1L]

events[, uuid := string_hasher(uuid)]

geo3 = strsplit(events$geo_location, ">", T) %>% lapply(function(x) x[1:3]) %>% simplify2array(higher = FALSE)
events[, geo_location := string_hasher(geo_location)]
events[, country      := string_hasher(geo3[1, ])]
events[, state        := string_hasher(geo3[2, ])]
events[, dma          := string_hasher(geo3[3, ])]
rm(geo3); gc()
events[, train := display_id %in% unique(clicks[!is.na(clicked), display_id])]
events[, day := as.integer((timestamp / 1000) / 60 / 60 / 24) ]

set.seed(1L)
events[, cv := TRUE]
# leave 11-12 days for validation as well as 15% of events in days 1-10
events[day <= 10, cv := sample(c(FALSE, TRUE), .N, prob = c(0.85, 0.15), replace = TRUE), by = day]
# sort by uuid - not imoprtant at this point. Why we are doing this will be explained below.
setkey(events, uuid)
# save events for future usage
save_rds_compressed(events, sprintf("%s/events.rds", RDS_DATA_PATH))
#--------------------------------------------------------------------------------------------
