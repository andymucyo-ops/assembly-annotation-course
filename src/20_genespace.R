# Step 2: Prepare GENESPACE in R. Run inside the genespace_latest.sif container
# by 20_run_genespace.sh; the GENESPACE working directory is passed as argument.
library(GENESPACE)
args <- commandArgs(trailingOnly = TRUE)
# get the folder where the genespace workingDirectory is located
wd <- args[1]
gpar <- init_genespace(wd = wd, path2mcscanx = "/usr/local/bin", nCores = 20)
# run genespace
out <- run_genespace(gpar)
pangenome <- query_pangenes(out,
  bed = NULL,
  refGenome = "TAIR10",
  transform = TRUE,
  showArrayMem = TRUE,
  showNSOrtho = TRUE,
  maxMem2Show = Inf)
# save pangenome object as rds
saveRDS(pangenome, file = file.path(wd, "pangenome_matrix.rds"))
