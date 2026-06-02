#!/bin/sh
#SBATCH --time=2:00:00
#SBATCH --mem-per-cpu=2G
#SBATCH --cpus-per-task=6
#SBATCH --mail-user=damian.hernandez@utoronto.ca
#SBATCH --mail-type=ALL
#SBATCH --output=20260306_nonararabidopsis_anthogenes_with_new_annotation.out

#the assumed working directory is the pipeline_scripts folder within jobs

module load StdEnv/2023 apptainer/1.3.5

LABREPO=../../comp_env/ #location of pipeline scripts for executing analysis
SEQREPO=~/projects/def-jstinchc/sequencing_repo

#make I. hederacea database
apptainer exec $LABREPO/20250730_aligners.sif diamond makedb --in $SEQREPO/Ipomoea_hederacea/reference_genome/I.hed-braker-rna-orthodb.aa.noasterisk -d ihed_diamond

#F3'5'H
apptainer exec $LABREPO/20250730_aligners.sif diamond blastp -d ihed_diamond.dmnd -q ../../raw_data/tomato-uniprot-d3w9h7.faa --outfmt 6 qseqid sseqid evalue length pident stitle --out ../../processed_data/20260306_tomato_f35h_uniprot-d3w9h7_diamondblastp_moresensitive.txt --threads 6 --more-sensitive

#3'GT
apptainer exec $LABREPO/20250730_aligners.sif diamond blastp -d ihed_diamond.dmnd -q ../../raw_data/gentiana_uniprot-q8h0f2.faa --outfmt 6 qseqid sseqid evalue length pident stitle --out ../../processed_data/20260306_gentiana_3pGT_uniprot-q8h0f2_diamondblastp_moresensitive.txt --threads 6 --more-sensitive

#BZ1
apptainer exec $LABREPO/20250730_aligners.sif diamond blastp -d ihed_diamond.dmnd -q ../../raw_data/tomato_bz1_uniprot-A0A3Q7IMM2.faa --outfmt 6 qseqid sseqid evalue length pident stitle --out ../../processed_data/20260306_tomato_bz1_uniprot-A0A3Q7IMM2_diamondblastp_moresensitive.txt --threads 6 --more-sensitive
