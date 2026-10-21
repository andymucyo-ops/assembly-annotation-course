
COURSEDIR='/data/courses/genome_annotation_resources/2026'
WORKDIR='/data/users/ankunzimana/assembly-annotation-course'
mkdir -p "$WORKDIR/src" "$WORKDIR/logs"
cd "$WORKDIR"

cp "$COURSEDIR/scripts/01-run_EDTA.sh" src/
# Edit GENOME in scripts/01-run_EDTA.sh to your assembly FASTA.
# sbatch scripts/01-run_EDTA.sh
