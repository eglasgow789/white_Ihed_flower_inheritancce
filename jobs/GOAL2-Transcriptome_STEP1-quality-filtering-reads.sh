#!/bin/sh
#SBATCH --time=10:00:00
#SBATCH --mem-per-cpu=2G
#SBATCH --cpus-per-task=15
#SBATCH --mail-user=damian.hernandez@utoronto.ca
#SBATCH --mail-type=ALL
#SBATCH --output=20250730_rna.out

module load StdEnv/2023 apptainer/1.3.5

LABREPO=../comp_env/ #location of pipeline scripts for executing analysis
SEQREPO=~/projects/def-jstinchc/sequencing_repo #location of sequencing data. this should be your raw_data folder after downloading the sequencing or wherever you chose to store it
ORADPATH=../comp_env/orad.2.7.0.linux/orad #path to local installation of ORAD version 2.7.0 from Illumina. Note that if you download and decompress this software with `GOAL0-setup-environment_STEP1-apptainer-building.sh`, this will be located in the comp_env folder

apptainer exec $LABREPO/20250729_sickkids_decom-qual-trim.sif sh ./pipeline_scripts/orad_decompression_fastqc_apptainer.sh \
    -e $ORADPATH \
    -r $LABREPO/oradata/homo_sapiens \
    -f ../processed_data/20250730_rna \
    -d $SEQREPO/Ipomoea_hederacea/RNA_2025_flowercolor \
    -l ../manual_manifests/fastq_files.txt \
    -c 15 \
    -p 20

#e: path to orad executable
#r: path to the directory containing the ora reference
#f: path to output raw fastq files after decompression
#d: path where raw ORA data is located
#c: number of cores for multicore processing
#p: PHRED score cut-off for TrimGalore. 20 is the default for 2-color chemistry in TrimGalore
#l: file containing read prefixes for paired-end reads

#### OPTIONAL HARD-TRIMMING ####
#We chose to do hard-trimming. This did not change the main take-aways of our differential expression analyses. While the hard-trimming was unnecessary for transcriptome analyses, we chose to do it to ensure high integrity of input sequences for mapping.

RAWQDIR=../processed_data/20250730_rna #f: path to output raw fastq files after decompression
CORES=15 #c: number of cores for multicore processing
PHRED=20 #p: PHRED score cut-off for TrimGalore. 20 is the default for 2-color chemistry in TrimGalore
FASTQ_LIST=../manual_manifests/fastq_files.txt #l: file containing read prefixes for paired-end reads
MULTIQCOUT=${RAWQDIR}_multiqc #m: directory to store multiqcoutput
TRIMGALOUT=${RAWQDIR}_trimgal #o: directory to store TrimGalore output

#Make directory for storing TrimGalore output
mkdir ${TRIMGALOUT}_hard
mkdir ${TRIMGALOUT}_hard3

#Run trim_galore variable and do a while loop for paired-end files
#20 is used for --2colour because it is the default phred score for the -q, which is the standard quality cutoff
while read i
do
echo "start trimming $i"
apptainer exec $LABREPO/20250729_sickkids_decom-qual-trim.sif trim_galore \
	--fastqc \
	--2colour $PHRED \
	--cores $CORES \
	-o ${TRIMGALOUT}_hard \
	--paired ${RAWQDIR}_trimgal/$i\_R1_001_val_1.fq.gz ${RAWQDIR}_trimgal/$i\_R2_001_val_2.fq.gz \
	--hardtrim5 145

apptainer exec $LABREPO/20250729_sickkids_decom-qual-trim.sif trim_galore \
       --fastqc \
       --2colour $PHRED \
       --cores $CORES \
       -o ${TRIMGALOUT}_hard3 \
       --paired ${RAWQDIR}_trimgal_hard/$i\_R1_001_val_1.145bp_5prime.fq.gz ${RAWQDIR}_trimgal_hard/$i\_R2_001_val_2.145bp_5prime.fq.gz \
       --hardtrim3 135

echo "done trimming $i"
done<$FASTQ_LIST

#mkdir ${TRIMGALOUT}_hard3fq
apptainer exec $LABREPO/20250729_sickkids_decom-qual-trim.sif fastqc --outdir ${TRIMGALOUT}_hard3fq ${TRIMGALOUT}_hard3/*.gz -t $CORES

#Make output directory (done)
mkdir ${MULTIQCOUT}_trimmed_hard


apptainer exec $LABREPO/20250729_sickkids_decom-qual-trim.sif multiqc ${TRIMGALOUT}_hard3fq --outdir ${MULTIQCOUT}_trimmed_hard

