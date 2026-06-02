#!/bin/sh
#SBATCH --time=7:00:00
#SBATCH --mem-per-cpu=2G
#SBATCH --cpus-per-task=4
#SBATCH --mail-user=damian.hernandez@utoronto.ca
#SBATCH --mail-type=ALL
#SBATCH --output=20260108_mosdepth.out

module load StdEnv/2023 apptainer/1.3.5 samtools/1.22.1

LABREPO=../comp_env/ #location of apptainers for executing analysis
SEQREPO=~/scratch/amanda_bam #location of sorted bam files for coverage analysis

#get coverage for all samples with windows of 100 bp and quality thresholds of 30
mkdir ../processed_data/mosdepth_out/
for i in $(ls $SEQREPO/*_sorted_dupsMarked.bam)
do
    #echo $i
    j="${i##*/}"
    #echo $j
    apptainer exec $LABREPO/mosdepth_apptainer.sif mosdepth -t 4 ../processed_data/mosdepth_out/$j -b 100 -Q 30 $i
done

#repeat for unpigmented plants
#merge the reads from both sequencing lanes. samtools merge will combine sorted bam files and keep the sort order according to the documentation
samtools merge -f -o ../processed_data/merged_white_flower_parent_sorted.bam ../raw_data/white_flower_parent_alingment_4015_2_S38_L003_sorted.bam ../raw_data/white_flower_parent_alingment_4015_2_S38_L004_sorted.bam
samtools index -M ../processed_data/merged_white_flower_parent_sorted.bam

#run mosdepth with same parameters as above
apptainer exec $LABREPO/mosdepth_apptainer.sif mosdepth -t 4 ../processed_data/mosdepth_out/white_flower_parent -b 100 -Q 30 ../processed_data/merged_white_flower_parent_sorted.bam

#gunzip all of the regions.bed files
gunzip ../processed_data/mosdepth_out/*regions.bed.gz