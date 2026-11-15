#!/bin/bash

#SBATCH --job-name=GFF_merge
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/10%x_%j.out
#SBATCH --error=logs/err/10%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"
OUTDIR="$WORKDIR/output/MAKER"

if [ ! -e $OUTDIR ]; then mkdir -p "$OUTDIR/tmp"; fi
cd $OUTDIR

shopt -s nullglob
INDEXES=(*.maker.output/*_master_datastore_index.log)
test "${#INDEXES[@]}" -eq 1
INDEX="${INDEXES[0]}"

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind "$COURSEDIR" \
    --pwd "$OUTDIR" "$MAKER_SIF" \
    gff3_merge -d "$INDEX" \
    -o assembly.all.maker.gff

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind "$COURSEDIR" \
    --pwd "$OUTDIR" "$MAKER_SIF" \
    gff3_merge -n -d "$INDEX" \
    -o assembly.all.maker.noseq.gff

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind "$COURSEDIR" \
    --pwd "$OUTDIR" "$MAKER_SIF" \
    fasta_merge -d "$INDEX" -o assembly
