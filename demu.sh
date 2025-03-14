#!/bin/bash
#This code is the first part of the metagenomic analysis of my thesis, using the qiime2 software
#starting with importing samples to .qza (artefact) to run in qiime2 and then cutting the primers with cutadapt
#The samples are in a directory with the path to each sample in the manifest file.
#The primers sequencies and output directory name are taken from de ConfigFile.yml
#The name of this population will be used as the argument
#Copywrite Daniela Deodato, January 2025

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
manifest=$(cat ConfigFile.yml | yq '.raw.manifest' | sed 's/\"//g')
outputDir=$(cat ConfigFile.yml | yq '.directory_name.output_dir_cutadapt' | sed 's/\"//g')
prim_f=$(cat ConfigFile.yml | yq '.illumina.primer_f' | sed 's/\"//g')
prim_r=$(cat ConfigFile.yml | yq '.illumina.primer_r' | sed 's/\"//g')

#Possible errors
#check the number of arguments
if [ $# -ne 1 ];
 then
  help
  echo "ERROR: wrong number of arguments"
  echo "This script requires only one argument to run"
  exit 1
 fi

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

#Importing data into artifact
echo "Importing into artifact type"
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path $manifest \
  --output-path $data.qza \
  --input-format PairedEndFastqManifestPhred33V2

#check to see if the import worked
 #verify if the manifest file exists
if [ ! -e "$data.qza" ];
 then
  help
  echo "ERROR: file $data.qza  not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
  else
  echo "$data.qza file present"
 fi

#Cutting primers with cutadapt
#cutadapt
echo "Cutting primers with cutadapt"
qiime cutadapt trim-paired \
        --i-demultiplexed-sequences $data.qza \
        --p-adapter-f $prim_f \
        --p-adapter-r $prim_r \
        --p-error-rate 0 \
        --o-trimmed-sequences trimmed-seqs_$data.qza \
        --verbose

#Summarize for vizualization
echo "Summarizing demultiplexing"
qiime demux summarize \
   --i-data trimmed-seqs_$data.qza \
   --o-visualization trimmed-seqs_$data.qzv

#Vizualization
echo "Preparing visualization"
qiime tools export \
  --input-path trimmed-seqs_$data.qzv \
  --output-path $outputDir

echo "Check the "Interactive Quality Plot" tab in trimmed-seqs_$data.qzv in $outputDir file to know what to do on the next step."
