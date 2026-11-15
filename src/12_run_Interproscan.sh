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

# Update GFF with InterProScan results
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind $COURSEDIR \
    --bind $WORKDIR --pwd $FINALDIR $MAKER_SIF ipr_update_gff ${gff}.renamed.gff \
    output.iprscan > ${gff}.renamed.iprscan.gff

# Examine AED values 
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind $COURSEDIR \
    --bind $WORKDIR --pwd $FINALDIR $MAKER_SIF perl /usr/local/bin/AED_cdf_generator.pl -b 0.025 \
    ${gff}.renamed.gff > assembly.maker.renamed.gff.AED.txt

# Filter the GFF file for quality
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp --bind $COURSEDIR \
    --bind $WORKDIR --pwd $FINALDIR $MAKER_SIF perl /usr/local/bin/quality_filter.pl \
    -s ${gff}.renamed.gff > ${gff}_ipr_quality_filtered.gff


# Filter the GFF file for gene features
grep -P "\tgene\t|\tCDS\t|\texon\t|\tfive_prime_UTR\t|\tthree_prime_UTR\t|\tmRNA\t" \
    ${gff}_ipr_quality_filtered.gff > filtered.genes.renamed.gff3

sed -i '1i##gff-version 3' filtered.genes.renamed.gff3

cut -f3 filtered.genes.renamed.gff3 | sort | uniq


# Extreac remaining mRNA after filtering
grep  -P "\tmRNA\t" filtered.genes.renamed.gff3 | awk '{print $9}' | cut -d ';' -f1 | \
    sed 's/ID=//g' > list.txt

ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

apptainer exec --cleanenv --bind $COURSEDIR --bind $WORKDIR --pwd $FINALDIR $ANALYSIS_SIF \
    seqkit grep -f list.txt ${transcript}.renamed.fasta -o ${transcript}.renamed.filtered.fasta

apptainer exec --cleanenv --bind $COURSEDIR --bind $WORKDIR --pwd $FINALDIR $ANALYSIS_SIF \
    seqkit grep -f list.txt ${protein}.renamed.fasta -o ${protein}.renamed.filtered.fasta
