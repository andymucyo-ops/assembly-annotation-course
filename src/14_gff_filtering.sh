#!/bin/bash
#SBATCH --job-name=gff_quality_filter
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/14%x_%j.out
#SBATCH --error=logs/err/14%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"
OUTDIR="$WORKDIR/output/MAKER"
FINALDIR="$OUTDIR/final"

gff="assembly.all.maker.noseq.gff"


# Examine AED values 
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind $COURSEDIR \
    --bind $WORKDIR --pwd $FINALDIR $MAKER_SIF perl /usr/local/bin/AED_cdf_generator.pl -b 0.025 \
    ${gff}.renamed.gff > assembly.maker.renamed.gff.AED.txt


# Assessement of the number of genes falling within the AED range of 0-0.5
awk -F'\t' '$3=="mRNA" {
    match($9, /_AED=[0-9.]+/); aed = substr($9, RSTART+5, RLENGTH-5) + 0
    bin = (aed <= 0.5) ? "AED<=0.5" : "AED>0.5"
    n[bin]++; if ($9 ~ /Pfam:/) p[bin]++; tot++; ptot += ($9 ~ /Pfam:/)
} END {
    for (b in n) printf "%s: %d mRNAs, %d mit Pfam (%.1f%%)\n", b, n[b], p[b], 100*p[b]/n[b]
    printf "Total: %d mRNAs, %d with Pfam (%.1f%%)\n", tot, ptot, 100*ptot/tot
}' ${gff}.renamed.iprscan.gff > "$FINALDIR/pfam_by_AED.txt"


# Filter the GFF file for quality
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind $COURSEDIR \
    --bind $WORKDIR --pwd $FINALDIR $MAKER_SIF perl /usr/local/bin/quality_filter.pl \
    -s ${gff}.renamed.gff > ${gff}_ipr_quality_filtered.gff


# Filter the GFF file for gene features
grep -P "\tgene\t|\tCDS\t|\texon\t|\tfive_prime_UTR\t|\tthree_prime_UTR\t|\tmRNA\t" \
    ${gff}_ipr_quality_filtered.gff > filtered.genes.renamed.gff3

sed -i '1i##gff-version 3' filtered.genes.renamed.gff3

cut -f3 filtered.genes.renamed.gff3 | sort | uniq
