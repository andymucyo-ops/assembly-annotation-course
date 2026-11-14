#!/bin/bash
#SBATCH --job-name=div_plots
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=2G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/08_%x_%j.out
#SBATCH --error=logs/err/08_%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

# IMPORTANT NOTE:
# first run the following command in an interactive session to guarantee a successful execution:
# apptainer exec -C --bind "$WORKDIR" "$COURSEDIR/containers/Annotation_analysis_R4.4.sif" samtools faidx "$WORKDIR"/data/assembly_flye.fasta

# set paths
WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
OUTDIR="$WORKDIR/output/Diversity"

cd $WORKDIR
if [ ! -e $OUTDIR ]; then mkdir -p $OUTDIR; fi

# execute the prepared R script
apptainer exec -C --bind "$WORKDIR" --bind "$COURSEDIR" \
"$COURSEDIR/containers/Annotation_analysis_R4.4.sif" \
Rscript --vanilla "$WORKDIR/src/08_plot_div.R"
