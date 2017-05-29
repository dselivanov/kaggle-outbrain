# Preliminary step

## Splitting page_views
In order to conveniently work woth `page_views.csv.zip` file we need to split it into chunks, so we can process each chunk independently and in memory.

```sh
mkdir page_views_chunks
unzip -p page_views.csv.zip | split --line-bytes=300m --filter='gzip --fast > ./page_views_chunks/$FILE.gz'
```

## Configuration and utilities

You can adjust configuration in `conf.R` file - paths to data, number of cores to use, number of partitions, etc. **Need to specify path to initial data files and path to page views chunks from step above**

Misc functions are in `misc.R` file.

# Baseline 1

Here we won't use `page_views` - only data from `clicks_train.csv.zip`, `events.csv.zip`. To run baseline you need to run:

1. `Rscript 0-0-prepare-baseline-1.R` - prepares data `clicks`, `events`, `promo` files.
1. `Rscript 0-1-prepare-baseline-1.R` - creates ans saves model matrix to disk (**partition by `uuid`**).
1. `Rscript 0-2-run-baseline-1.R` - fit FTRL to model matrix chunks from step above.
1. `Rscript 0-3-predict-baseline-1.R` - generate submission file (without leak)

Rough timings provided at the top of each file.

# Baseline 2

To run baseline you need to run:

1. `Rscript 1-0-prepare-baseline-2.R` - preprocess `page_views` - filter not relevant page views and **partition by `uuid`**.
1. `Rscript 1-1-prepare-baseline-2.R` - creates ans saves model matrix to disk (incluing hashed interactions between page views and advertisement and user context).
1. `Rscript 1-1-extract-leak.R` - extracts leak
1. `Rscript 1-2-run-baseline-2.R` - fit FTRL to model matrix chunks from step above.
1. `Rscript 1-3-predict-baseline-2.R` - generate two submission files - with and without leak

Rough timings provided at the top of each file.
