#!/bin/sh
#SBATCH --time=6:00:00
#SBATCH --mem-per-cpu=2G
#SBATCH --cpus-per-task=15
#SBATCH --mail-user=damian.hernandez@utoronto.ca
#SBATCH --mail-type=ALL
#SBATCH --output=20260304_rna_star.out

module load StdEnv/2023 apptainer/1.3.5

LABREPO=../comp_env #location of the computational environments
SEQREPO=../raw_data #location of the genome data

#Initialize variables
INDEXDIR=../processed_data/20260304_Ihed_index #i: path to index or to store index
CORES=15 #c: number of cores for multicore processing
GENFASTA="${SEQREPO}/I_hederacea_v1.0.fa" #f: path to genome fasta
GENGTF="${SEQREPO}/I.hed-braker-rna-orthodb.gtf" #g: path to genome gtf annotation
READLEN=149 #l: read length minus 1 of your trimmed sequences. If unsure, STAR suggests using the program default of 100 which generally works well
FILEMANIFEST="../manual_manifests/rna_file_manifest_hard.txt" #m: path to three-column tab-delimited file in which the first column is read 1, second read 2 (or - if only using single-end reads), and third a unique sample name
ALIGNOUT=../processed_data/20260304_star_align_out #a: path to output alignments and gene counts from star alignment
SANINDEX=13 #necessary for indexing genome. This is usually between 10 and 15. If you're unsure, use this formula: min(14, log2(GenomeLength)/2 - 1)

#Create directory to store genome index
mkdir $INDEXDIR

#Build index. For --sjdbOverhang, this should be your read length - 1 to build the junction database but the default value of 100 should be okay if anything
#running --genomeSAindexNbases 13 because that was recommended in an earlier run due to the genome size. it's not that different from the default 14
apptainer exec $LABREPO/20250730_aligners.sif STAR \
    --runThreadN $CORES \
    --runMode genomeGenerate \
    --genomeDir $INDEXDIR \
    --genomeFastaFiles $GENFASTA \
    --sjdbGTFfile $GENGTF \
    --sjdbOverhang $READLEN \
    --genomeSAindexNbases $SANINDEX

#Map reads to index
mkdir $ALIGNOUT
while IFS=$'\t' read -r -a col
do
 echo "${col[0]}"
 echo "${col[1]}"
 echo "${col[2]}"

 apptainer exec $LABREPO/20250730_aligners.sif STAR \
 	--runThreadN $CORES \
        --genomeDir $INDEXDIR \
	--readFilesIn ${col[0]} ${col[1]} \
        --readFilesCommand gunzip -c \
	--outSAMtype BAM SortedByCoordinate \
        --quantMode GeneCounts \
	--outFileNamePrefix $ALIGNOUT/${col[2]}

done < $FILEMANIFEST

#multiqc of star mapping per sample
apptainer exec $LABREPO/20250729_sickkids_decom-qual-trim.sif multiqc --filename $ALIGNOUT/20260304_multiqc.html $ALIGNOUT
