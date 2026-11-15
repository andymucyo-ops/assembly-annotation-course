#!/bin/bash
#SBATCH --job-name=Update_gff
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/13%x_%j.out
#SBATCH --error=logs/err/13%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"
OUTDIR="$WORKDIR/output/MAKER"
FINALDIR="$OUTDIR/final"

gff="assembly.all.maker.noseq.gff"


# Update GFF with InterProScan results
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind $COURSEDIR \
    --bind $WORKDIR --pwd $FINALDIR $MAKER_SIF ipr_update_gff ${gff}.renamed.gff \
    output.iprscan > ${gff}.renamed.iprscan.gff

