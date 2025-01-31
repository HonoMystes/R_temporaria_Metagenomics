#!/bin/bash
#This code is the first part of the metagenomic analysis of my thesis, using the qiime2 software
#starting with importing samples to .qza (artefact) to run in qiime2 and then cutting the primers with cutadapt
#The base files will be .fastq.gz format (in the data directory) and tsv for the metadata.
#The data directory must contain the sequence files: R1.fastq.gz (forward) and R2.fastq.gz (reverse)
#The name of this directory and the name of the metadata file will be used as arguments in that order.
#Copywrite Daniela Deodato, January 2025

function help {
echo ""
echo "This code is the first part of the metagenomic analysis of my thesis, using the qiime2 software"
echo "starting with importing samples to .qza (artefact) to run in qiime2 and then cutting the primers with cutadapt"
echo "The base files will be .fastq.gz format (in the data directory) and tsv for the metadata."
echo "The data directory must contain the sequence files: R1.fastq.gz (forward) and R2.fastq.gz (reverse)"
echo "The name of this directory and the name of the metadata file will be used as arguments in that order"
echo "Please make sure you have the qiime enviroment activated"
echo ""
}

#Variables
data=$1 #directory name
data_directory='{$data}'/ #directory 
metadata=$2 #switch to metadata file
outputDir=$(cat ConfigFile.yml | yq '.directory_name.output_dir_cutadapt')

#Possible errors
#check the number of arguments
if [ $# -ne 2 ];
 then
  help
  echo "ERROR: wrong number of arguments"
  echo "This script requires 2 arguments to run"
  exit 1
 fi
a pasta existe
if [ ! -d "$data_directory" ];
 then
  help
  echo "ERROR: directory $data_directory not found" 
  echo "Please check if the name is correct and the folder is in the current directory"
  exit 1
 fi

#check if metadata file exists
if [ ! -e "$metadata" ];
 then
  help
  echo "ERROR: file $metadata not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
 fi

#Importing data into artifact
echo "Importing into artifact type"
qiime tools import \
   --type EMPPairedEndSequences \
   --input-path $data_directory \
   --output-path {$data}.qza

#Cutting primers with cutadapt
#cutadapt
echo "Cutting primers with cutadapt"
qiime cutadapt trim-paired \
        --i-demultiplexed-sequences {$data}.qza \
        --p-front-f CCTACGG \
        --p-front-r GACTACHV \
        --p-error-rate 0 \filtrar amostras
        --verbose

#Summarize for vizualization
echo "Summarizing demultiplexing"
qiime demux summarize \
   --i-data trimmed-seqs_{$data}.qza \
   --o-visualization trimmed-seqs_{$data}.qzv

#Vizualization
echo "Preparing visualization"
qiime tools export \
  --input-path trimmed-seqs_{$data}.qzv \
  --output-path $outputDir

echo "Check the "Interactive Quality Plot" tab in trimmed-seqs_{$data}.qzv file to know what to do on the next step."