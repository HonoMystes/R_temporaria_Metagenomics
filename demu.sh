#!/bin/bash
#This code is the first part of the metagenomic analysis of my thesis, using the qiime2 software
#starting with importing samples to .qza (artefact) to run in qiime2 and then cutting the primers with cutadapt
#The samples are in a directory with the path to each sample in the manifest file.
#The primers sequencies and output directory name are taken from de ConfigFile.yml
#The name of this population will be used as the argument
# the < | sed 's/\"//g'> is needed since the qiime enviroment adds ""
#Copywrite Daniela Deodato, January 2025

#stops if error
set -e

function help {
echo ""
echo "This code is the first part of the metagenomic analysis of my thesis, using the qiime2 software"
echo "starting with importing samples to .qza (artefact) using the manifest file to run in qiime2 and then cutting the primers with cutadapt"
echo "The samples are in a directory with the path to each sample in the manifest file"
echo "The primers sequencies and output directory name are taken from de ConfigFile.yml"
echo "The name of this population will be used as the argument"
echo "Please make sure you have the qiime enviroment activated"
echo ""
}

#Variables
data=$1 #directory name

path_file=$(cat ConfigFile.yml | yq '.raw.data_directory' | sed 's/\"//g')
manifest=$(cat ConfigFile.yml | yq '.raw.manifest' | sed 's/\"//g')
threads=$(cat ConfigFile.yml | yq '.raw.threads' | sed 's/\"//g')
outputDir=$(cat ConfigFile.yml | yq '.directory_name.output_dir_cutadapt' | sed 's/\"//g')
fastp=$(cat ConfigFile.yml | yq '.directory_name.fastp' | sed 's/\"//g')
quality=$(cat ConfigFile.yml | yq '.directory_name.quality' | sed 's/\"//g')
artifact=$(cat ConfigFile.yml | yq '.directory_name.artifact' | sed 's/\"//g')
visualizations=$(cat ConfigFile.yml | yq '.directory_name.visualizations' | sed 's/\"//g')
prim_f=$(cat ConfigFile.yml | yq '.illumina.primer_f' | sed 's/\"//g')
prim_r=$(cat ConfigFile.yml | yq '.illumina.primer_r' | sed 's/\"//g')
INFILE_R1=./names_R1.txt
INFILE=quality_R1names.txt

#Possible errors
#check the number of arguments
if [ $# -ne 1 ];
 then
  help
  echo "ERROR: wrong number of arguments"
  echo "This script requires only one argument to run"
  exit 1
 fi

#directories
mkdir -p $quality
ls $path_file/*_R1.fastq.gz > $INFILE

#quality filtering the sequencies using fastp, we will use the infile created in create_manifest_file.sh
while read LINE; do
	id=$(basename $LINE)
	id_R2=$(basename $LINE | sed 's/_R1/_R2/g')
	R2=$(echo $LINE | sed 's/_R1/_R2/g')
	fastp -i $LINE -I $R2 -w $threads -h fastp_$id.html -j fastp_$id.json -o ./$quality/out_$id -O ./$quality/out_$id_R2 
done < $INFILE
echo "----------------"
echo $INFILE
mkdir -p $fastp
mv *.html $fastp/
mv *.json $fastp/
#make manifest file
current_directory=$(pwd)
ls $current_directory/$quality/*_R1.fastq.gz > $INFILE_R1

#header
echo "sample-id	forward-absolute-filepath	reverse-absolute-filepath" > $manifest

#filling tsv
while read LINE; do
	sample_id=$(basename -s .fastq.gz $LINE | sed 's/_R1//g' | sed 's/out_//g')
        R2=$(echo $LINE | sed 's/_R1/_R2/g')
        echo "$sample_id	$LINE	$R2" >> $manifest
done < $INFILE_R1

#check if manifest file was created
 #verify if the manifest file exists
if [ ! -e "$manifest" ];
 then
  help
   echo "ERROR: file $manifest not found"
   echo "Please check if the name is correct and the file is in the current directory"
   exit 1
   else
   echo "$manifest file present"
 fi
echo "---------------------------------/"
mkdir -p $artifact
mkdir -p $visualizations

#Importing data into artifact
echo "Importing into artifact type"
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path $manifest \
  --output-path $artifact/$data.qza \
  --input-format PairedEndFastqManifestPhred33V2

#check to see if the import worked
 #verify if the manifest file exists
if [ ! -e "$artifact/$data.qza" ];
 then
  help
  echo "ERROR: file $artifact/$data.qza  not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
  else
  echo "$artifact/$data.qza file present"
fi

#Cutting primers with cutadapt
#cutadapt
echo "Cutting primers with cutadapt"
qiime cutadapt trim-paired \
        --i-demultiplexed-sequences $artifact/$data.qza \
        --p-adapter-f $prim_f \
        --p-adapter-r $prim_r \
        --p-error-rate 0 \
        --p-cores $threads \
        --o-trimmed-sequences $artifact/trimmed-seqs_$data.qza \
        --verbose

#Summarize for vizualization
echo "Summarizing demultiplexing"
qiime demux summarize \
   --i-data $artifact/trimmed-seqs_$data.qza \
   --o-visualization $visualizations/trimmed-seqs_$data.qzv

#to avoid errors with qiime2 if an $outputDir already exists it is erased
if [ -d $outputDir ];
 then
 rm -rf $outputDir
fi

#Vizualization
echo "Preparing visualization"
qiime tools export \
  --input-path $visualizations/trimmed-seqs_$data.qzv \
  --output-path $outputDir

#organizing outputs
mv "$INFILE_R1" "$outputDir"
mv "$INFILE" "$outputDir"

echo "Check the "Interactive Quality Plot" tab in $visualizations/trimmed-seqs_$data.qzv in $outputDir file to know what to do on the next step."
echo ''' 
          . .
         ( .-)-----*¨
      _(_|   |_)_

'''


