#!/bin/bash
#SBATCH --job-name=uniprot_annotation
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/18%x_%j.out
#SBATCH --error=logs/err/18%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
FINALDIR="$WORKDIR/output/MAKER/final"
PROTEINS="$FINALDIR/assembly.all.maker.proteins.fasta.renamed.filtered.fasta"
UNIPROT="$COURSEDIR/data/uniprot_viridiplantae_reviewed.fa"
OUTDIR="$WORKDIR/output/comparisons"
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"
GENES="$FINALDIR/filtered.genes.renamed.gff3"
mkdir -p "$OUTDIR/tmp"

# Add the UniProt functions to copies of your filtered protein and gene annotations.
apptainer exec --cleanenv --env TMPDIR=/tmp \
    --bind /data --bind "$WORKDIR" --bind "$OUTDIR/tmp":/tmp \
    --pwd "$OUTDIR" "$MAKER_SIF" \
    maker_functional_fasta "$UNIPROT" "$OUTDIR/blastp_uniprot.besthits.tsv" "$PROTEINS" \
    > "$OUTDIR/maker_proteins.filtered.Uniprot.fasta"

apptainer exec --cleanenv --env TMPDIR=/tmp \
    --bind /data --bind "$WORKDIR" --bind "$OUTDIR/tmp":/tmp \
    --pwd "$OUTDIR" "$MAKER_SIF" \
    maker_functional_gff "$UNIPROT" "$OUTDIR/blastp_uniprot.besthits.tsv" "$GENES" \
    > "$OUTDIR/filtered.genes.Uniprot.gff3"
