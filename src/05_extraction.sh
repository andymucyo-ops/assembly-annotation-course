#!/bin/bash
#SBATCH --job-name=extraction
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=5G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-22
#SBATCH --output=/data/users/ankunzimana/assembly-annotation-course/logs/out/05_%x_%j.out
#SBATCH --error=/data/users/ankunzimana/assembly-annotation-course/logs/err/05_%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

# set paths
WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"

# extracing copia and gipsy sequences
cd "$WORKDIR/output/EDTA"
genome="assembly.fasta"

# creating output directory
mkdir -p "$WORKDIR/output/Extraction"

# Extract Copia sequences
apptainer exec -C --bind "$WORKDIR" "$COURSEDIR/containers/Annotation_analysis_R4.4.sif" \
  seqkit grep -r -p "Copia" "$WORKDIR/output/EDTA/${genome}.mod.EDTA.TElib.fa" \
  > ../Extraction/Copia_sequences.fa

# Extract Gypsy sequences
apptainer exec -C --bind "$WORKDIR" "$COURSEDIR/containers/Annotation_analysis_R4.4.sif" \
  seqkit grep -r -p "Gypsy" "$WORKDIR/output/EDTA/${genome}.mod.EDTA.TElib.fa" \
  > ../Etraction/Gypsy_sequences.fa
