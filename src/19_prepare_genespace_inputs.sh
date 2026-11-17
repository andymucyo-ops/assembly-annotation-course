#!/bin/bash
#SBATCH --job-name=prepare_genespace
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/19%x_%j.out
#SBATCH --error=logs/err/19%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

set -euo pipefail
WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
FINALDIR="$WORKDIR/output/MAKER/final"
GENES="$FINALDIR/filtered.genes.renamed.gff3"
OUTDIR="$WORKDIR/output/comparisons"
GENESPACE_DIR="$OUTDIR/GENESPACE"

# EDIT before running: your accession name, exactly as it appears in
# `ls "$COURSEDIR/data/Lian_et_al/GENESPACE/bed"` (GENESPACE does not allow "-").
Accession=Ishikawa
# EDIT before running: three accessions different from your own.
other1=Etna_2
other2=Altai_5
other3=Are_6

mkdir -p "$GENESPACE_DIR/bed" "$GENESPACE_DIR/peptide" "$GENESPACE_DIR/tmp"

# Extract gene coordinates from your filtered GFF3. BED is 0-based and has four
# tab-separated columns: scaffold, start, end and gene ID. Subtract 1 from the
# GFF3 start to obtain a 0-based BED start.
grep -P "\tgene\t" "$GENES" > "$GENESPACE_DIR/temp_genes.gff3"
# Get the first attribute in column 9 which is ID=gene_name.
awk 'BEGIN{OFS="\t"} {split($9,a,";"); split(a[1],b,"="); print $1, $4-1, $5, b[2]}' \
    "$GENESPACE_DIR/temp_genes.gff3" > "$GENESPACE_DIR/bed/${Accession}.bed"

# Reuse your longest-protein FASTA from Week 3, where you selected one longest
# protein per gene before running BUSCO: ${protein}.renamed.longest.fasta.
# Match FASTA IDs to BED gene IDs by removing MAKER transcript suffixes such as -RA.
LONGEST_PROTEINS="$FINALDIR/assembly.all.maker.proteins.fasta.renamed.longest.fasta"

# The longest-isoform FASTA is produced by 16_run_busco.sh (pick_longest).
# GENESPACE needs a real protein FASTA, so fail early with a clear message if
# it is missing, empty, or not a FASTA (line 1 must start with '>').
if [ ! -s "$LONGEST_PROTEINS" ] || ! head -n 1 "$LONGEST_PROTEINS" | grep -q '^>'; then
    echo "Longest-protein FASTA missing, empty, or not a FASTA: $LONGEST_PROTEINS" >&2
    echo "Run src/16_run_busco.sh first (its pick_longest step creates it)." >&2
    exit 1
fi

# Remove transcript suffixes and descriptions from FASTA headers.
# (tr -d '\r' runs first so the $ anchors in the seds see clean line ends.)
tr -d '\r' < "$LONGEST_PROTEINS" | sed '/^>/s/ .*//' | sed '/^>/s/-R[A-Z]*$//' \
    > "$GENESPACE_DIR/peptide/${Accession}.fa"

# Guard against an empty or headerless output (GENESPACE needs '>' on line 1).
if [ ! -s "$GENESPACE_DIR/peptide/${Accession}.fa" ] || \
   ! head -n 1 "$GENESPACE_DIR/peptide/${Accession}.fa" | grep -q '^>'; then
    echo "Peptide FASTA empty or missing '>' header: $GENESPACE_DIR/peptide/${Accession}.fa" >&2
    exit 1
fi

# Add TAIR10. The supplied TAIR10 FASTA already uses gene IDs and contains one
# protein per gene.
cp "$COURSEDIR/data/TAIR10.bed" "$GENESPACE_DIR/bed/TAIR10.bed"
cp "$COURSEDIR/data/TAIR10.fa" "$GENESPACE_DIR/peptide/TAIR10.fa"

# Add three other accessions from Lian et al. The prepared filenames already use
# underscores, and the BED starts are already 0-based; no conversion is needed.
for other in "$other1" "$other2" "$other3"; do
    cp "$COURSEDIR/data/Lian_et_al/GENESPACE/bed/${other}.bed" \
        "$GENESPACE_DIR/bed/${other}.bed"
    cp "$COURSEDIR/data/Lian_et_al/GENESPACE/peptide/${other}.fa" \
        "$GENESPACE_DIR/peptide/${other}.fa"
done

# Validate matching IDs: each accession should report no duplicate IDs, no
# differences between BED and FASTA IDs, no missing IDs, and no extra IDs.
for acc in "$Accession" TAIR10 "$other1" "$other2" "$other3"; do
    # The peptide file must be a real FASTA with at least one '>' record,
    # otherwise a bare ID list would pass the ID comparison below unnoticed.
    n_hdr=$(grep -c '^>' "$GENESPACE_DIR/peptide/${acc}.fa" || true)
    if [ "${n_hdr}" -eq 0 ]; then
        echo "${acc}: peptide file has no FASTA records (not a valid protein FASTA)" >&2
        exit 1
    fi
    awk '{print $4}' "$GENESPACE_DIR/bed/${acc}.bed" | sort > "$GENESPACE_DIR/tmp/${acc}.bed.ids"
    sed '/^>/s/-R[A-Z]*$//; s/^>//' "$GENESPACE_DIR/peptide/${acc}.fa" | sort > "$GENESPACE_DIR/tmp/${acc}.fa.ids"
    echo "== ${acc} =="
    echo "FASTA records:          ${n_hdr}"
    echo "duplicate BED IDs:      $(uniq -d "$GENESPACE_DIR/tmp/${acc}.bed.ids" | wc -l | tr -d ' ')"
    echo "duplicate FASTA IDs:    $(uniq -d "$GENESPACE_DIR/tmp/${acc}.fa.ids" | wc -l | tr -d ' ')"
    echo "in BED not in FASTA:    $(comm -23 "$GENESPACE_DIR/tmp/${acc}.bed.ids" "$GENESPACE_DIR/tmp/${acc}.fa.ids" | wc -l | tr -d ' ')"
    echo "in FASTA not in BED:    $(comm -13 "$GENESPACE_DIR/tmp/${acc}.bed.ids" "$GENESPACE_DIR/tmp/${acc}.fa.ids" | wc -l | tr -d ' ')"
done
