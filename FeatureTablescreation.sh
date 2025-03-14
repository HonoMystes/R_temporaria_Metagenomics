#!/bin/bash
#This code is the second part of the metagenomic analysis of my thesis, using the qiime2 software
#After cuting the primers and analysing the "interactive Quality Plot" in the file trimmed-seqs_{$data}.qzv the perfered numbers in the configuration file are edited.
#The script runs with the argument of the name of the population
# the < | sed 's/\"//g'> is needed since the qiime enviroment adds ""
#Copywrite Daniela Deodato, January 2025

function help {
echo ""
echo "This code is the second part of the metagenomic analysis of my thesis, using the qiime2 software"
echo "After cuting the primers and analysing the "interactive Quality Plot" in the file trimmed-seqs_${data}.qzv the perfered numbers in the configuration file are edited. "
echo "the script runs with the argumentof the name of the population"
echo ""
}

#Variables
data=$1 #name of the directory with the samples
cutadapt_file_art=artifact/trimmed-seqs_$data.qza
metadata=$(cat ConfigFile.yml | yq '.raw.metadata' | sed 's/\"//g')
num_min_seq=$(cat ConfigFile.yml | yq '.size.num_min_seq' | sed 's/\"//g')
trim_forward=$(cat ConfigFile.yml | yq '.trim.trim_forward' | sed 's/\"//g')
trim_reverse=$(cat ConfigFile.yml | yq '.trim.trim_reverse' | sed 's/\"//g')
trunc_forward=$(cat ConfigFile.yml | yq '.trunc.trunc_forward' | sed 's/\"//g')
trunc_reverse=$(cat ConfigFile.yml | yq '.trunc.trunc_reverse' | sed 's/\"//g')
outputDir=$(cat ConfigFile.yml | yq '.directory_name.output_dir_cutadapt' v)
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_tbl' | sed 's/\"//g')
freq_tbl_viz=$(cat ConfigFile.yml | yq '.tables.freq_tbl_viz' | sed 's/\"//g')
seqs_rep=$(cat ConfigFile.yml | yq '.tables.seqs_rep' | sed 's/\"//g')
seqs_rep_viz=$(cat ConfigFile.yml | yq '.tables.seqs_rep_viz' | sed 's/\"//g')

#Possible errors
#check the number of arguments
if [ $# -ne 1 ];
 then
  help
  echo "ERROR: wrong number of arguments"
  echo "This script requires only one argument to run"
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

qiime demux filter-samples \
  --i-demux $cutadapt_file_art \
  --m-metadata-file $metadata \
  --p-where 'CAST([forward sequence count] AS INT) > $num_min_seq' \
  --o-filtered-demux ${cutadapt_file_art}_fil

#check if the file was created
[ ! -e "${cutadapt_file_art}_fil" ] && help && echo "ERROR: ${cutadapt_file_art}_fil not found" && exit 1

###
#Denoising
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ${cutadapt_file_art}_fil \
  --p-trim-left-f $trim_forward \
  --p-trim-left-r $trim_reverse \
  --p-trunc-len-f $trunc_forward \
  --p-trunc-len-r $trunc_reverse \
  --o-table $freq_tbl \
  --o-representative-sequences $seqs_rep \
  --o-denoising-stats artifact/denoising-stats_$data.qza
#alterar os seguintes parametros baseado nos nossos dados no --i-demultiplexed-seqs

#check if the files were created
[ ! -e "$freq_tbl" ] && help && echo "ERROR: $freq_tbl not found" && exit 1

[ ! -e "$seqs_rep" ] && help && echo "ERROR: $seqs_rep not found" && exit 1

###Exclude Chimeras
echo "Examining for chimeras"
echo "Running de novo" 
qiime vsearch uchime-denovo \
  --i-table $freq_tbl \
  --i-sequences $seqs_rep \
  --output-dir $data_uchime-dn-out

qiime metadata tabulate \
  --m-input-file $data_uchime-dn-out/stats.qza \
  --o-visualization $data_uchime-dn-out/stats.qzv

#Feature tables
qiime feature-table filter-features \
  --i-table $freq_tbl \
  --m-metadata-file $data_uchime-dn-out/nonchimeras.qza \
  --o-filtered-table $freq_tbl

qiime feature-table filter-seqs \
  --i-data $seqs_rep \
  --m-metadata-file $data_uchime-dn-out/nonchimeras.qza \
  --o-filtered-data $seqs_rep

qiime feature-table summarize \
  --i-table $freq_tbl \
  --o-visualization $freq_tbl_viz

echo "check $freq_tbl_viz to know what to do on script phyloDiv.sh"