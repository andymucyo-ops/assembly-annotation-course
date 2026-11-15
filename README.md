# Repeat and Gene Annotation of the *Arabidopsis thaliana* Ishikawa Accession

A reproducible, containerized SLURM pipeline for annotating the genome of the *Arabidopsis thaliana* **Ishikawa (ISK)** accession, built for the *Organization and Annotation of Eukaryote Genomes* course.

The pipeline has two parts:

- **Part A — Repetitive elements (EDTA):** build a de-novo TE library, annotate the genome, classify intact LTR retrotransposons, and characterize TE composition, clades and divergence landscapes.
- **Part B — Protein-coding genes (MAKER):** evidence-driven gene annotation using the EDTA TE library, transcript and protein evidence, followed by Pfam/InterProScan functional annotation, AED-based quality control, and gene ID renaming with the `ISK` prefix.

TE annotation is performed first because a reliable repeat library is required as `rmlib` input for MAKER, which otherwise mistypes repetitive elements as genes.

## Workflow

```
Genome (Flye assembly)
        │
 ── Part A: Repetitive elements (EDTA) ───────────────────────────
 01 EDTA (TE library + genome annotation)
        ├──► 02 TEsorter (intact LTRs) ──► 03 LTR identity plots
        ├──► 04 circlize genome-level TE plot
        ├──► 05 extract Copia/Gypsy ────► 06 TEsorter II (library classes)
        └──► 07 parseRM (RM output) ────► 08 divergence landscape plot
        │
 ── Part B: Protein-coding genes (MAKER) ─────────────────────────
 09 MAKER ──► 10 gff3/fasta merge ──► 11 rename IDs (ISK prefix)
        ──► 12 InterProScan (Pfam) ──► 13 update GFF
        ──► 14 AED statistics + quality filter ──► 15 filtered FASTAs
```

## Requirements

- A SLURM-managed cluster with [Apptainer](https://apptainer.org/).
- All software runs inside course-provided containers; nothing needs to be installed locally.

| Container | Software | Used in |
|-----------|----------|---------|
| `EDTA_v2.3.0_TIRLearner4.sif` | EDTA 2.3.0 | 01 |
| `TEsorter_1.3.0.sif` | TEsorter 1.3.0 | 02, 06 |
| `Annotation_analysis_R4.4.sif` | R 4.4 + tidyverse/circlize/ComplexHeatmap, samtools, seqkit | 03, 04, 05, 07, 08, 12, 15 |
| `MAKER_3.01.03.sif` | MAKER 3.01.03 (gff3_merge, fasta_merge, map_ids, QC utilities) | 09–11, 13, 14 |
| `InterProScan_5.70.sif` | InterProScan 5.70 | 12 |

**Reference data (course-provided):**

- `TAIR10_cds_20110103_representative_gene_model_updated` — *A. thaliana* coding sequences, used by EDTA to strip gene-derived sequences from the TE library.
- InterProScan 5.70 data directory (Pfam models).
- MAKER control-file templates (`maker_opts.ctl`, `maker_bopts.ctl`, `maker_exe.ctl`, `maker_evm.ctl`).

**Job resources** (as configured in the `#SBATCH` headers):

| Step | CPUs | Memory | Walltime |
|------|------|--------|----------|
| 01 EDTA | 20 | 96G | 4 days |
| 02 TEsorter | 4 | 8G | 1 h |
| 03–08 plots / parsing | 4 | 2–5G | 1 h each |
| 09 MAKER | 20 | 64G | 9 h |
| 10–15 merge / QC | 8 | 16–32G | 2 h each |

## Input

A genome assembly FASTA (Flye assembly of the Ishikawa accession), expected at:

```
$WORKDIR/data/assemblies/flye/assembly.fasta
```

## Setup

1. Set your project directory in the scripts:

   ```bash
   export WORKDIR="$HOME/assembly-annotation-course"
   ```

   Replace the hardcoded `$WORKDIR` in each script with your own path (scripts currently use a `#/data/users/<user>/assembly-annotation-course` style path).

2. Edit the input paths where needed:

   - **01**: `GENOME` (your assembly) and `CDS` (TAIR10 CDS reference).
   - **05, 07**: `genome` variable (`assembly.fasta`).
   - **09**: copy the four MAKER control-file templates into the project root and edit `maker_opts.ctl`:

     ```
     genome = <your genome FASTA>
     est    = <your Trinity transcript FASTA>
     rmlib  = <EDTA TE library: output/EDTA/assembly.fasta.mod.EDTA.TElib.fa>
     ```

     Protein references point to the course data directory.

3. One **interactive prerequisite** before steps 04 and 08 (generates the `.fai` index used for the circlize ideogram):

   ```bash
   apptainer exec -C --bind "$WORKDIR" "$COURSEDIR/containers/Annotation_analysis_R4.4.sif" \
       samtools faidx "$WORKDIR/data/assemblies/flye/assembly.fasta"
   ```

## Running the pipeline

Submit the scripts in numerical order from the project root:

```bash
mkdir -p logs/out logs/err

# Part A — repeat annotation
sbatch src/01-run_EDTA.sh                         # TE library + genome annotation (longest step)
sbatch src/02-run_TEsorter_full_length_LTRs.sh    # classify intact LTRs
sbatch src/03_full_length_LTR.sh                  # LTR identity plots per clade
sbatch src/04_annotation_circlize.sh              # genome-level TE circos plot
sbatch src/05_extraction.sh                       # extract Copia/Gypsy library sequences
sbatch src/06_TESorter._II.sh                     # classify extracted libraries
sbatch src/07_RepeatMasker.sh                     # parse EDTA RepeatMasker output (parseRM)
sbatch src/08_plot_div.sh                         # TE divergence landscape

# Part B — gene annotation
sbatch src/09_run_maker.sh                        # MAKER annotation
sbatch src/10_gff_merge.sh                        # merge per-scaffold GFFs, produce FASTAs
sbatch src/11_rename_genes_and_transcripts.sh     # rename IDs with ISK prefix
sbatch src/12_run_Interproscan.sh                 # Pfam annotation of proteins
sbatch src/13_update_gff.sh                       # add InterProScan results to GFF
sbatch src/14_gff_filtering.sh                    # AED stats + quality filtering
sbatch src/15_mRNAseq_filtering.sh                # extract filtered transcripts/proteins
```

Jobs write stdout/stderr to `logs/out/` and `logs/err/`.

## Output directory layout

```
output/
├── EDTA/                     # 01 — TE library, TEanno.gff3, RM.out
├── LTR_full_length/          # 02–03 — intact LTRs, TEsorter classes, plots/
├── circlize/                 # 04 — circos TE plot
├── Extraction/               # 05 — Copia/Gypsy library FASTAs
├── TESorter/                 # 06 — clade classification of libraries
├── ParseRM/                  # 07 — parseRM divergence tables
├── Diversity/                # 08 — divergence landscape plot
└── MAKER/                    # 09–15
    ├── *.maker.output/       # raw MAKER output
    ├── assembly.all.maker.*.gff / .fasta
    └── final/                # curated results
        ├── id.map
        ├── *.renamed.gff
        ├── *.renamed.iprscan.gff
        ├── filtered.genes.renamed.gff3
        ├── *.renamed.filtered.fasta
        ├── assembly.maker.renamed.gff.AED.txt
        └── pfam_by_AED.txt
```

## Key results

- **TE annotation** (`output/EDTA/`): the EDTA TE library and genome-wide annotation of the Ishikawa assembly.
- **Intact LTR retrotransposons** (`output/LTR_full_length/plots/`): Copia and Gypsy clade-level LTR identity histograms and a global comparison.
- **Divergence landscape** (`output/Diversity/diversity_plot.pdf`): sequence in Mbp per divergence bin per TE family (Helitrons excluded, see EDTA FAQ).
- **Gene annotation** (`output/MAKER/final/`):
  - `filtered.genes.renamed.gff3` — quality-filtered annotation with `ISK` gene IDs.
  - `*.renamed.filtered.fasta` — filtered proteins and transcripts.
  - `assembly.maker.renamed.gff.AED.txt` — AED cumulative distribution.
  - `pfam_by_AED.txt` — mRNAs and Pfam support by AED category (≤0.5 vs >0.5).

## Notes and known caveats

- **04_annotation_circlize.sh** contains a broken line continuation (line 26 ends without `\`); run the two `apptainer exec` commands manually if the job fails.
- **12_run_Interproscan.sh** and **15_mRNAseq_filtering.sh** both perform the same filtered FASTA extraction; step 15 exists so the extraction can be re-run independently after filtering.
- **08_plot_div.R** has a placeholder for the age calculation (divergence → years) that was left as an exercise.
- The per-scaffold MAKER output count and final gene number are the main metrics to check after steps 10 and 14.

## Repository structure

| Script | Purpose |
|--------|---------|
| `01-run_EDTA.sh` | Build TE library + genome-wide TE annotation (EDTA, `--sensitive 1`, `--wholeelement 1`) |
| `02-run_TEsorter_full_length_LTRs.sh` | Classify intact LTR elements with TEsorter (rexdb-plant) |
| `03_full_length_LTR.sh` / `03_LTR_identity.R` | LTR identity distributions per clade (Copia/Gypsy) |
| `04_annotation_circlize.sh` / `04_annotation_circlize.R` | Circos-style TE density plot on the 20 longest scaffolds |
| `05_extraction.sh` | Extract Copia/Gypsy sequences from the EDTA library |
| `05_parseRM.pl` | parseRM 5.8.2 (third-party tool, see credits) |
| `06_TESorter._II.sh` | TEsorter classification of the extracted Copia/Gypsy libraries |
| `07_RepeatMasker.sh` | Filter 0% divergence hits and parse EDTA's RepeatMasker output with parseRM |
| `08_plot_div.sh` / `08_plot_div.R` | TE divergence landscape (Mbp per divergence bin) |
| `09_run_maker.sh` | MAKER 3.01.03 annotation with evidence (ESTs, proteins, TE library) |
| `10_gff_merge.sh` | `gff3_merge` (full + no-seq GFFs) and `fasta_merge` |
| `11_rename_genes_and_transcripts.sh` | Rename gene/transcript IDs with `maker_map_ids` (prefix `ISK`) |
| `12_run_Interproscan.sh` | Pfam annotation of renamed proteins (InterProScan) + FASTA extraction |
| `13_update_gff.sh` | Merge InterProScan results into the GFF (`ipr_update_gff`) |
| `14_gff_filtering.sh` | AED distribution, Pfam-support statistics, `quality_filter.pl`, feature extraction |
| `15_mRNAseq_filtering.sh` | Extract filtered transcripts/proteins with `seqkit grep` |

## Credits and references

- **EDTA** — Ou *et al.*, 2019, *Genome Research* (https://github.com/oushujun/EDTA)
- **TEsorter** — Zhang *et al.*, 2022, *Plant Biotechnology Journal* (rexdb-plant database)
- **MAKER** — Cantarel *et al.*, 2008, *Genome Research*
- **InterProScan** — Jones *et al.*, 2014, *Bioinformatics* (Pfam: Mistry *et al.*, 2021, *Nucleic Acids Research*)
- **RepeatMasker** — Smit, Hubley & Green
- **parseRM** (v5.8.2, `05_parseRM.pl`) — Aurélie Kapusta, bundled third-party script
- **circlize / ComplexHeatmap / ggplot2** — R graphics packages used for visualization

Built as coursework for the *Organization and Annotation of Eukaryote Genomes* course (University of Bern), using the course container and reference infrastructure.
