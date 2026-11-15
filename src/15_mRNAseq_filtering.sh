#!/bin/bash
#SBATCH --job-name=mRNAseq_filtering
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/15%x_%j.out
#SBATCH --error=logs/err/15%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"
OUTDIR="$WORKDIR/output/MAKER"
FINALDIR="$OUTDIR/final"

protein="assembly.all.maker.proteins.fasta"
transcript="assembly.all.maker.transcripts.fasta"

# Extreact remaining mRNA after filtering
grep  -P "\tmRNA\t" filtered.genes.renamed.gff3 | awk '{print $9}' | cut -d ';' -f1 | \
    sed 's/ID=//g' > list.txt


apptainer exec --cleanenv --bind $COURSEDIR --bind $WORKDIR --pwd $FINALDIR $ANALYSIS_SIF \
    seqkit grep -f list.txt ${transcript}.renamed.fasta -o ${transcript}.renamed.filtered.fasta

apptainer exec --cleanenv --bind $COURSEDIR --bind $WORKDIR --pwd $FINALDIR $ANALYSIS_SIF \
    seqkit grep -f list.txt ${protein}.renamed.fasta -o ${protein}.renamed.filtered.fasta
