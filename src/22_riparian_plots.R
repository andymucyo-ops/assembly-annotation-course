# Step 6: Visualize synteny with riparian plots (run after GENESPACE has
# completed). Run inside the genespace_latest.sif container by
# 22_run_riparian.sh.
library(GENESPACE)

# EDIT these two lines: the GENESPACE working directory and your accession
# name (must match the BED/FASTA filenames from 19_prepare_genespace_inputs.sh).
wd <- "/home/ankunzimana/data/assembly-annotation-course/output/comparisons/GENESPACE"
focal_genome <- "Ishikawa"

load(file.path(wd, "results", "gsParams.rda")) # Loads gsParam.
dir.create(file.path(wd, "processed_riparian"), showWarnings = FALSE)

# Compare your accession with TAIR10, ordering scaffolds by synteny.
plot_riparian(
  gsParam,
  genomeIDs = c("TAIR10", focal_genome),
  refGenome = "TAIR10",
  reorderBySynteny = TRUE,
  pdfFile = file.path(wd, "processed_riparian", "my_accession_vs_TAIR10.pdf")
)

# Improve scaffold order and display orientation. A scaffold assembled in the
# reverse orientation can produce a twisted braid.
# EDIT: replace YOUR_SCAFFOLD with a scaffold whose main syntenic connection
# runs in reverse (add more names with c("scaffold1", "scaffold2") if needed).
flips <- data.frame(genome = focal_genome, chr = c("contig_2", "contig_132", "contig_158"))
plot_riparian(
  gsParam,
  genomeIDs = c("TAIR10", focal_genome),
  refGenome = "TAIR10",
  reorderBySynteny = TRUE,
  syntenyWeight = 1,
  invertTheseChrs = flips,
  pdfFile = file.path(
    wd,
    "processed_riparian",
    "my_accession_vs_TAIR10_oriented.pdf"
  )
)

# Show all five genomes. This uses the flips table defined above to reverse
# only the listed scaffolds in their specified genomes.
plot_riparian(
  gsParam,
  refGenome = "TAIR10",
  reorderBySynteny = TRUE,
  syntenyWeight = 1,
  invertTheseChrs = flips,
  scalePlotWidth = 1.5,
  pdfFile = file.path(wd, "processed_riparian", "all_genomes_TAIR10.pdf")
)
