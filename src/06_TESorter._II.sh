#!/bin/bash
#SBATCH --job-name=TE_Sorter
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=5G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-22
#SBATCH --output=/data/users/ankunzimana/assembly-annotation-course/logs/out/06_%x_%j.out
#SBATCH --error=/data/users/ankunzimana/assembly-annotation-course/logs/err/06_%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

# set paths
WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
OUTDIR="$WORKDIR/output/TESorter"

# extracing copia and gipsy sequences
#cd "$WORKDIR/output/05_extraction"

# creating output directory
mkdir -p "$WORKDIR/output/TESorter/Copia"
mkdir -p "$WORKDIR/output/TESorter/Gypsy"


# execute TE Sorter for Copia
apptainer exec --bind $WORKDIR /data/courses/genome_annotation_resources/2026/containers/TEsorter_1.3.0.sif \
TEsorter "$WORKDIR/output/Extraction/Copia_sequences.fa" -db rexdb-plant -p 4 -pre "$OUTDIR/Copia/Copia"

# execute TE Sorter for Gypsy
apptainer exec --bind $WORKDIR /data/courses/genome_annotation_resources/2026/containers/TEsorter_1.3.0.sif \
TEsorter "$WORKDIR/output/Extraction/Gypsy_sequences.fa" -db rexdb-plant -p 4 -pre "$OUTDIR/Gypsy/Gypsy"
