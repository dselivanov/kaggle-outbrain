UUID_HASH_SIZE = 2**30
events_h_size = 2**24
views_h_size = 2**24
N_PART = 128

# physical cores
N_CORES_PREPROCSESSING = 4
# cores + hyperthreads
N_THREAD_FTRL = 8

RAW_DATA_PATH = "~/projects/kaggle/outbrain/data/raw/"

RDS_DATA_PATH = "~/projects/kaggle/outbrain/data/rds/"
if(!dir.exists(RDS_DATA_PATH))
  dir.create(RDS_DATA_PATH)

PAGE_VIEWS_CHUNKS_PATH = "~/projects/kaggle/outbrain/data/raw/page_views_chunks/"

#--------------------------------------------------------------------------------------------------------
# LEAK
#--------------------------------------------------------------------------------------------------------
LEAK_PATH = sprintf("%s/leak.rds", RDS_DATA_PATH)
#--------------------------------------------------------------------------------------------------------
# MODEL SAVE PATHS 
#--------------------------------------------------------------------------------------------------------
PATH_MODEL_1 = sprintf("%s/model_1.rds", RDS_DATA_PATH)
PATH_MODEL_1_SUBMISSION_FILE = sprintf("%s/model_1_submission.csv", RAW_DATA_PATH)
PATH_MODEL_2 = sprintf("%s/model_2.rds", RDS_DATA_PATH)
PATH_MODEL_2_SUBMISSION_FILE = sprintf("%s/model_2_submission.csv", RAW_DATA_PATH)
PATH_MODEL_2_SUBMISSION_FILE_LEAK = sprintf("%s/model_2_submission_leak.csv", RAW_DATA_PATH)
#--------------------------------------------------------------------------------------------------------
# PAGE VIEWS processing folders
#--------------------------------------------------------------------------------------------------------
VIEWS_INTERMEDIATE_DIR = sprintf("%s/views_filter/", RDS_DATA_PATH)
if(!dir.exists(VIEWS_INTERMEDIATE_DIR)) dir.create(VIEWS_INTERMEDIATE_DIR)
for(i in 0L:(N_PART - 1L)) {
  d = sprintf("%s/%03d/", VIEWS_INTERMEDIATE_DIR, i)
  if(!dir.exists(d)) dir.create(d)
}
VIEWS_DIR = sprintf("%s/views", RDS_DATA_PATH)
if(!dir.exists(VIEWS_DIR)) dir.create(VIEWS_DIR)

#--------------------------------------------------------------------------------------------------------
# BASELINE_1 data folders
#--------------------------------------------------------------------------------------------------------
RDS_BASELINE_1_MATRIX_DIR = sprintf("%s/baseline_1/", RDS_DATA_PATH)
if(!dir.exists(RDS_BASELINE_1_MATRIX_DIR)) dir.create(RDS_BASELINE_1_MATRIX_DIR)

RDS_BASELINE_1_MATRIX_DIR_TRAIN = sprintf("%s/train", RDS_BASELINE_1_MATRIX_DIR)
if(!dir.exists(RDS_BASELINE_1_MATRIX_DIR_TRAIN)) dir.create(RDS_BASELINE_1_MATRIX_DIR_TRAIN)

RDS_BASELINE_1_MATRIX_DIR_CV = sprintf("%s/cv", RDS_BASELINE_1_MATRIX_DIR)
if(!dir.exists(RDS_BASELINE_1_MATRIX_DIR_CV)) dir.create(RDS_BASELINE_1_MATRIX_DIR_CV)

RDS_BASELINE_1_MATRIX_DIR_TEST = sprintf("%s/test", RDS_BASELINE_1_MATRIX_DIR)
if(!dir.exists(RDS_BASELINE_1_MATRIX_DIR_TEST)) dir.create(RDS_BASELINE_1_MATRIX_DIR_TEST)
#--------------------------------------------------------------------------------------------------------
# BASELINE_2 data folders
#--------------------------------------------------------------------------------------------------------
RDS_BASELINE_2_MATRIX_DIR = sprintf("%s/baseline_2/", RDS_DATA_PATH)
if(!dir.exists(RDS_BASELINE_2_MATRIX_DIR)) dir.create(RDS_BASELINE_2_MATRIX_DIR)

RDS_BASELINE_2_MATRIX_DIR_TRAIN = sprintf("%s/train", RDS_BASELINE_2_MATRIX_DIR)
if(!dir.exists(RDS_BASELINE_2_MATRIX_DIR_TRAIN)) dir.create(RDS_BASELINE_2_MATRIX_DIR_TRAIN)

RDS_BASELINE_2_MATRIX_DIR_CV = sprintf("%s/cv", RDS_BASELINE_2_MATRIX_DIR)
if(!dir.exists(RDS_BASELINE_2_MATRIX_DIR_CV)) dir.create(RDS_BASELINE_2_MATRIX_DIR_CV)

RDS_BASELINE_2_MATRIX_DIR_TEST = sprintf("%s/test", RDS_BASELINE_2_MATRIX_DIR)
if(!dir.exists(RDS_BASELINE_2_MATRIX_DIR_TEST)) dir.create(RDS_BASELINE_2_MATRIX_DIR_TEST)
