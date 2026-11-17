#!/bin/bash
#SBATCH --job-name=process_pangenome
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/21%x_%j.out
#SBATCH --error=logs/err/21%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

set -euo pipefail
WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"
TMPDIR="$WORKDIR/output/comparisons/Annotation_R_tmp"
PANGENOME_R="$WORKDIR/src/process_pangenome.R"

# Copy the course-provided process_pangenome.R once (it contains both the
# presence-frequency analysis and the copy-number comparison).
# EDIT the copied script before the first run:
#   - wd           -> your GENESPACE directory ($WORKDIR/output/comparisons/GENESPACE)
#   - focal_genome -> your accession name (same as $Accession in script 19)
if [ ! -f "$PANGENOME_R" ]; then
    cp "$COURSEDIR/scripts/"*process_pangenome*.R "$PANGENOME_R"
fi

mkdir -p "$TMPDIR"
apptainer exec --cleanenv \
    --bind /data --bind "$WORKDIR" \
    --bind "$TMPDIR":/temp --env TMPDIR=/temp --pwd "$WORKDIR" \
    "$ANALYSIS_SIF" Rscript "$PANGENOME_R"
