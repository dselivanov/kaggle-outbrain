#------------------------------------------------------------------------------------------------
# this takes ~ 45 minutes on 4 core laptop
#------------------------------------------------------------------------------------------------

source("misc.R")

events = readRDS(sprintf("%s/events.rds", RDS_DATA_PATH))
uuid_events = unique(events$uuid); rm(events)

colnames = c("uuid", "document_id", "timestamp", "platform", "geo_location", "traffic_source")
fls = list.files(PAGE_VIEWS_CHUNKS_PATH, full.names = TRUE)
foreach(f = fls, .inorder = F, .combine = c, .multicombine = TRUE,
        .packages = c("data.table", "magrittr", "text2vec"),
        .options.multicore = list(preschedule = FALSE)) %dopar% {
          if(basename(f) == "xaa.gz") header = TRUE else  header = FALSE
          # will only need c("uuid", "document_id", "timestamp") -  first 3 columns
          # fread can consume UNIX pipe as input, which is not the thing many people know about
          dt = fread(paste("zcat < ", f), header = header, col.names = colnames[1:3], select = 1:3, showProgress = FALSE)
          dt[, uuid := string_hasher(uuid)]
          # filter out not observed uuids
          j = dt[['uuid']] %in% uuid_events
          dt = dt[j, ]
          # partition by uuid and save
          for(i in 0L:(N_PART - 1L)) {
            out = sprintf("%s/%03d/%s.rds", VIEWS_INTERMEDIATE_DIR, i, basename(f))
            save_rds_compressed(dt[uuid %% N_PART == i, ], out)
          }
          rm(dt);gc();
          message(sprintf("%s chunk %s done", Sys.time(), basename(f)))
        }


#------------------------------------------------------------------------------------------------

res = foreach(chunk = 0L:(N_PART - 1L), .inorder = FALSE, .multicombine = TRUE,
              .options.multicore = list(preschedule = FALSE), 
              .packages = c("data.table", "magrittr")) %dopar% {
                dir = sprintf("%s/%03d", VIEWS_INTERMEDIATE_DIR, chunk)
                fls = list.files(dir)
                dt = fls %>% 
                  lapply(function(f) readRDS(sprintf("%s/%s", dir, f))) %>% 
                  rbindlist
                
                save_rds_compressed(dt, sprintf("%s/%03d.rds", VIEWS_DIR, chunk))
                message(sprintf("%s chunk %03d done", Sys.time(), chunk))
              }

unlink(VIEWS_INTERMEDIATE_DIR, recursive = TRUE)
