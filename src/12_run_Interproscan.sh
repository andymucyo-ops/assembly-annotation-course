#!/bin/bash
#SBATCH --job-name=InteproScan
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/12%x_%j.out
#SBATCH --error=logs/err/12%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
INTERPROSCAN_SIF="$COURSEDIR/containers/InterProScan_5.70.sif"
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"
OUTDIR="$WORKDIR/output/MAKER"
FINALDIR="$OUTDIR/final"

if [ ! -e $FINALDIR ]; then mkdir -p "$FINALDIR/tmp"; fi

protein="assembly.all.maker.proteins.fasta"
transcript="assembly.all.maker.transcripts.fasta"
gff="assembly.all.maker.noseq.gff"


# run Interproscan on all protein files
apptainer exec --cleanenv --pwd $FINALDIR \
    --bind "$COURSEDIR/data/interproscan-5.70-102.0/data:/opt/interproscan/data" \
    --bind $COURSEDIR --bind $WORKDIR \
    --bind "$FINALDIR/tmp":\temp \
    $INTERPROSCAN_SIF \
    /opt/interproscan/interproscan.sh \
    --appl pfam --disable-precalc -f TSV \
    --goterms --iprlookup --seqtype p \
    -i ${protein}.renamed.fasta -o output.iprscan

