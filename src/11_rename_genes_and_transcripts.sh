#!/bin/bash

#SBATCH --job-name=Rename_g_&_t
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/11%x_%j.out
#SBATCH --error=logs/err/11%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"
OUTDIR="$WORKDIR/output/MAKER"
FINALDIR="$OUTDIR/final"

if [ ! -e $FINALDIR ]; then mkdir -p "$FINALDIR/tmp"; fi

protein="assembly.all.maker.proteins.fasta"
transcript="assembly.all.maker.transcripts.fasta"
gff="assembly.all.maker.noseq.gff"
prefix="ISK" #Ishikawa 

cp "$OUTDIR/$gff" "$FINALDIR/${gff}.renamed.gff"
cp "$OUTDIR/$protein" "$FINALDIR/${protein}.renamed.fasta"
cp "$OUTDIR/$transcript" "$FINALDIR/${transcript}.renamed.fasta"

cd "$FINALDIR"

cut -f9 ${gff}.renamed.gff | cut -d ';' -f1 | sed 's/ID=//g' | head

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind "$COURSEDIR" \
    --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    maker_map_ids --prefix $prefix --justify 7 ${gff}.renamed.gff > id.map

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind "$COURSEDIR" \
    --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    map_gff_ids id.map ${gff}.renamed.gff

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind "$COURSEDIR" \
    --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    map_fasta_ids id.map ${protein}.renamed.fasta

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind "$COURSEDIR" \
    --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    map_fasta_ids id.map ${transcript}.renamed.fasta
