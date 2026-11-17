#!/bin/bash
#SBATCH --job-name=busco_maker
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=03:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/out/16%x_%j.out
#SBATCH --error=logs/err/16%x_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch

set -euo pipefail
WORKDIR="/data/users/ankunzimana/assembly-annotation-course"
COURSEDIR="/data/courses/genome_annotation_resources/2026"
AGAT_SIF="$COURSEDIR/containers/AGAT_v1.4.1.sif"
ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"
OUTDIR="$WORKDIR/output/MAKER"
FINALDIR="$OUTDIR/final"

protein="assembly.all.maker.proteins.fasta"
transcript="assembly.all.maker.transcripts.fasta"

ANALYSIS="apptainer exec --cleanenv --bind $COURSEDIR --bind $WORKDIR --pwd $FINALDIR $ANALYSIS_SIF"
# NOTE: all paths below are fully qualified on purpose. The seqkit calls run
# inside the container (whose cwd is $FINALDIR via --pwd) while the .ids
# redirect happens in the host shell (cwd = $WORKDIR); with relative paths the
# .ids file and the seqkit output end up in different directories and the
# longest FASTA is never created.
# Longest isoform per gene (gene = everything before -R*, ties: first one wins)
pick_longest () {
    local in=$1 out=$2
    $ANALYSIS seqkit fx2tab -n -i -l "$in" \
      | awk -F'\t' '{ id=$1; g=id; sub(/-R[A-Z]+$/, "", g)
                      if (!(g in len) || $2 > len[g]) { len[g]=$2; best[g]=id } }
                    END { for (g in best) print best[g] }' > "${out}.ids"
    $ANALYSIS seqkit grep -f "${out}.ids" "$in" -o "$out"
    echo "$out: $(grep -c '>' "$out") sequences (from $(grep -c '>' "$in"))"
}
pick_longest "$FINALDIR/${protein}.renamed.filtered.fasta" "$FINALDIR/${protein}.renamed.longest.fasta"
pick_longest "$FINALDIR/${transcript}.renamed.filtered.fasta" "$FINALDIR/${transcript}.renamed.longest.fasta"

cd "$FINALDIR"
module load BUSCO/5.4.2-foss-2021a
export PYTHONNOUSERSITE=1
# Run BUSCO on the LONGEST protein and transcript sequences.
# Skip runs whose completed summary already exists; otherwise force (-f) so a
# stale directory from a failed earlier attempt does not abort the job.
if [ ! -f "busco_proteins/short_summary.specific.brassicales_odb10.busco_proteins.txt" ]; then
    busco -f -i "${protein}.renamed.longest.fasta" -l brassicales_odb10 -o busco_proteins \
        -m proteins -c 4
fi
if [ ! -f "busco_transcripts/short_summary.specific.brassicales_odb10.busco_transcripts.txt" ]; then
    busco -f -i "${transcript}.renamed.longest.fasta" -l brassicales_odb10 -o busco_transcripts \
        -m transcriptome -c 4
fi

cd $WORKDIR
#AGAT annotation statistics
apptainer exec --cleanenv --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" "$AGAT_SIF" \
    agat_sp_statistics.pl --gff filtered.genes.renamed.gff3 --output annotation.stat
