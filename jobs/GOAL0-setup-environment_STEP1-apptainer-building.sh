#!/bin/sh

#The purpose of this script is to build the apptainers needed for the computational environments in this project.

#these are loaded modules in our SLURM environment for Compute Canada.
module load StdEnv/2023 apptainer/1.3.5

ENVPATH=../comp_env #path where the yaml and def files are located and where to store the sif outputs

cd $ENVPATH

#build apptainer for decompressing and quality filtering reads
apptainer build --fakeroot 20250729_sickkids_decom-qual-trim.sif 20250729_sickkids_decom-qual-trim.def 

#build apptainer for aligners
apptainer build --fakeroot 20250730_aligners.sif 20250730_aligners.def

#install DRAGEN ORAD v2.7.0 from Illumina if a local installation is not available on your system
wget https://s3.amazonaws.com/webdata.illumina.com/downloads/software/dragen-decompression/orad.2.7.0.linux.tar.gz

tar -xzvf orad.2.7.0.linux.tar.gz

wget https://webdata.illumina.com/downloads/software/dragen/references/ora-270/oradata_all_species.tar.gz

tar -xzvf oradata_all_species.tar.gz

rm orad.2.7.0.linux.tar.gz
rm oradata_all_species.tar.gz