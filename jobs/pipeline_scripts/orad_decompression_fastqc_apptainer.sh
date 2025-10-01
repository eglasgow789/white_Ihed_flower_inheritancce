#!/bin/bash

#Initialize variables
ORAREFERENCE="~/projects/def-jstinchc/script_repo/oradata/homo_sapiens" #r: path to the directory containing the ora reference
RAWQDIR="" #f: path to output raw fastq files after decompression
RAWODIR="" #d: path where raw ORA data is located
CORES=4 #c: number of cores for multicore processing
PHRED=20 #p: PHRED score cut-off for TrimGalore. 20 is the default for 2-color chemistry in TrimGalore
FASTQ_LIST="" #l: file containing read prefixes for paired-end reads
ORAEXEC="" #e: path to orad executable

while getopts "r:f:d:c:p:l:e:" arg
do
    case $arg in
        r)
            ORAREFERENCE="$OPTARG"
            ;;
        f)
            RAWQDIR="$OPTARG"
            ;;
        d)
            RAWODIR="$OPTARG"
            ;;
        c)
            CORES="$OPTARG"
            ;;
        p)
            PHRED="$OPTARG"
            ;;
        l)
            FASTQ_LIST="$OPTARG"
            ;;
	e)
	    ORAEXEC="$OPTARG"
	    ;;
        \?) # Handle invalid options
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :) # Handle missing arguments for options
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Shift positional parameters so that non-option arguments are accessible
shift $((OPTIND - 1))

FASTQCOUT=${RAWQDIR}_fastqc #q: directory to store fastqc output
MULTIQCOUT=${RAWQDIR}_multiqc #m: directory to store multiqcoutput
TRIMGALOUT=${RAWQDIR}_trimgal #o: directory to store TrimGalore output

#Echo the variables for troubleshooting
echo "r = $ORAREFERENCE ... directory containing the ORA index for converting .orad files to fastq"
echo "f = $RAWQDIR ... directory to store output of.orad decompression"
echo "d = $RAWODIR ... directory where the compressed .orad files are located"
echo "q = $FASTQCOUT ... directory to store output of fastqc"
echo "m = $MULTIQCOUT ... directory to store output of multiqc"
echo "c = $CORES ... number of cores requested"
echo "p = $PHRED ... PHRED score cut-off for 2-color chemistry in TrimGalore"
echo "o = $TRIMGALOUT ... directory to store TrimGalore output"
echo "l = $FASTQ_LIST ... text file containing read prefixes for paired end reads with each prefix on a separate line"

#Unzip to scratch
mkdir $RAWQDIR

#Decompress the data
for i in $(ls $RAWODIR/*.ora) 
do
    $ORAEXEC --gz -P $RAWQDIR --ora-reference $ORAREFERENCE $i
done

#Send output to results
mkdir $FASTQCOUT

#Do the fastqc
fastqc -o $FASTQCOUT $RAWQDIR/*.gz

#Run multiqc
mkdir ${MULTIQCOUT}_raw
multiqc $FASTQCOUT --outdir ${MULTIQCOUT}_raw

#Make directory for storing TrimGalore output
mkdir $TRIMGALOUT

#Run trim_galore variable and do a while loop for paired-end files
#20 is used for --2colour because it is the default phred score for the -q, which is the standard quality cutoff
while read i
do
echo "start trimming $i"
trim_galore --fastqc --2colour $PHRED --cores $CORES -o $TRIMGALOUT --paired $RAWQDIR/$i\_R1_001.fastq.gz $RAWQDIR/$i\_R2_001.fastq.gz
echo "done trimming $i"
done<$FASTQ_LIST

#Make output directory (done)
mkdir ${MULTIQCOUT}_trimmed

#Run multiqc
multiqc $TRIMGALOUT --outdir ${MULTIQCOUT}_trimmed
