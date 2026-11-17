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

# maker_functional_fasta/gff look up each BLAST subject ID among the first
# tokens of the UniProt FASTA headers (e.g. >sp|P92958|14331_ARATH is keyed as
# "sp|P92958|14331_ARATH"), but BLAST may print only part of the ID (e.g. the
# accession "P92958"). The lookup then misses, the script stores an empty
# string as the hit, and maker_functional_gff crashes with:
# "Can't use string ("") as a HASH ref while "strict refs" in use".
# Rewrite the subject column of the best-hits table so every subject ID is the
# exact first token of its UniProt FASTA header.

# Canonical tokens: first token of every UniProt FASTA header.
awk '/^>/{print substr($1,2)}' "$UNIPROT" | sort -u > "$OUTDIR/tmp/uniprot.tokens"

# Alias table: each |-component of a "sp|ACC|ENTRY" token -> full token.
awk '/^>/ { tok = substr($1,2); n = split(tok, f, "|")
             print tok "\t" tok
             if (n == 3) { print f[2] "\t" tok; print f[3] "\t" tok } }' \
    "$UNIPROT" | sort -u > "$OUTDIR/tmp/uniprot_alias.tsv"

# Rebuild the best-hits table with normalized subject IDs; abort if any subject
# ID cannot be matched to a UniProt FASTA header token.
awk 'BEGIN{OFS="\t"} NR==FNR { alias[$1] = $2; next } {
    if ($2 in alias) { $2 = alias[$2] } else { miss++ }
    print
} END {
    if (miss) { print miss " subject IDs could not be matched to UniProt FASTA" > "/dev/stderr"; exit 1 }
}' "$OUTDIR/tmp/uniprot_alias.tsv" "$OUTDIR/blastp_uniprot.besthits.tsv" \
    > "$OUTDIR/blastp_uniprot.besthits.fixed.tsv"

# Check that every normalized subject ID is an exact FASTA header token.
awk 'NR==FNR { token[$1] = 1; next }
     !($2 in token) { print "Unmatched subject ID: " $2 > "/dev/stderr"; bad = 1 }
     END { exit bad }' "$OUTDIR/tmp/uniprot.tokens" "$OUTDIR/blastp_uniprot.besthits.fixed.tsv"

BESTHITS="$OUTDIR/blastp_uniprot.besthits.fixed.tsv"

# Add the UniProt functions to copies of your filtered protein and gene annotations.
apptainer exec --cleanenv --env TMPDIR=/tmp \
    --bind /data --bind "$WORKDIR" --bind "$OUTDIR/tmp":/tmp \
    --pwd "$OUTDIR" "$MAKER_SIF" \
    maker_functional_fasta "$UNIPROT" "$BESTHITS" "$PROTEINS" \
    > "$OUTDIR/maker_proteins.filtered.Uniprot.fasta"

apptainer exec --cleanenv --env TMPDIR=/tmp \
    --bind /data --bind "$WORKDIR" --bind "$OUTDIR/tmp":/tmp \
    --pwd "$OUTDIR" "$MAKER_SIF" \
    maker_functional_gff "$UNIPROT" "$BESTHITS" "$GENES" \
    > "$OUTDIR/filtered.genes.Uniprot.gff3"
