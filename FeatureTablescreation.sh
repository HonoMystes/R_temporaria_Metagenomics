#!/bin/bash
#This code is the second part of the metagenomic analysis of my thesis, using the qiime2 software
#After cuting the primers and analysing the "interactive Quality Plot" in the file trimmed-seqs_{$data}.qzv the perfered numbers in the configuration file are edited.
#The script runs with the argument of the name of the population
# the < | sed 's/\"//g'> is needed since the qiime enviroment adds ""
#Copyright Daniela Deodato, January 2025

#stops if error
set -e

function help {
echo ""
echo "This code is the second part of the metagenomic analysis of my thesis, using the qiime2 software"
echo "After cuting the primers and analysing the "interactive Quality Plot" in the file artifacts_PopLund/${data}.qzv the perfered numbers in the configuration file are edited. "
echo "the script runs with the argumentof the name of the population"
echo ""
}

#Variables
data=$1 #name of the directory with the samples
metadata=$(cat ConfigFile.yml | yq '.raw.metadata' | sed 's/\"//g')
threads=$(cat ConfigFile.yml | yq '.raw.threads' | sed 's/\"//g')
num_min_seq=$(cat ConfigFile.yml | yq '.denoise.num_min_seq' | sed 's/\"//g')
length=$(cat ConfigFile.yml | yq '.denoise.length' | sed 's/\"//g')
trim_f=$(cat ConfigFile.yml | yq '.denoise.trim_f' | sed 's/\"//g')
trim_r=$(cat ConfigFile.yml | yq '.denoise.trim_r' | sed 's/\"//g')
trunc_f=$(cat ConfigFile.yml | yq '.denoise.trunc_f' | sed 's/\"//g')
trunc_r=$(cat ConfigFile.yml | yq '.denoise.trunc_r' | sed 's/\"//g')
chimera_method=$(cat ConfigFile.yml | yq '.denoise.chimera_method' | sed 's/\"//g')
overlap=$(cat ConfigFile.yml | yq '.denoise.min_overlap' | sed 's/\"//g')
tucker=$(cat ConfigFile.yml | yq '.denoise.chimeric_parent_over_abundance' | sed 's/\"//g')
outputDir=$(cat ConfigFile.yml | yq '.directory_name.output_dir_cutadapt' | sed 's/\"//g')
artifact=$(cat ConfigFile.yml | yq '.directory_name.artifact' | sed 's/\"//g')
visualizations=$(cat ConfigFile.yml | yq '.directory_name.visualizations' | sed 's/\"//g')
persample=${outputDir}per-sample-fastq-counts.tsv
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_tbl' | sed 's/\"//g')
freq_tbl_viz=$(cat ConfigFile.yml | yq '.tables.freq_tbl_viz' | sed 's/\"//g')
seqs_rep=$(cat ConfigFile.yml | yq '.tables.seqs_rep' | sed 's/\"//g')
seqs_rep_viz=$(cat ConfigFile.yml | yq '.tables.seqs_rep_viz' | sed 's/\"//g')
cutadapt_file_art=$artifact/$data.qza
fil=$artifact/filter.qza

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

#check if cutadapt file exists
if [ ! -e "$cutadapt_file_art" ];
 then
  help
  echo "ERROR: file $cutadapt_file_art not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
 fi

qiime demux filter-samples \
  --i-demux $cutadapt_file_art \
  --m-metadata-file $persample \
  --p-where "CAST([forward sequence count] AS INT) > $num_min_seq" \
  --o-filtered-demux $fil

echo "pass filter_sample"

#check if the file was created
[ ! -e "$fil" ] && help && echo "ERROR: $fil not found" && exit 1

#DADA2 denoise with minimum overlap defined by the use
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs $fil \
  --p-trim-left-f $trim_f \
  --p-trim-left-r $trim_r \
  --p-trunc-len-f $trunc_f \
  --p-trunc-len-r $trunc_r \
  --p-chimera-method $chimera_method \
  --p-min-fold-parent-over-abundance $tucker \
  --p-min-overlap $overlap \
  --p-n-threads $threads \
  --o-table $artifact/$freq_tbl \
  --o-representative-sequences $artifact/$seqs_rep \
  --o-denoising-stats $artifact/dada2_stats.qza

echo "pass denoising"

##visualize stats deblur
qiime metadata tabulate \
  --m-input-file $artifact/dada2_stats.qza  \
  --o-visualization $visualizations/dada2_stats.qzv

#check if the files were created
[ ! -e "$artifact/$freq_tbl" ] && help && echo "ERROR: $artifact/$freq_tbl not found" && exit 1

[ ! -e "$artifact/$seqs_rep" ] && help && echo "ERROR: $artifact/$seqs_rep not found" && exit 1

qiime feature-table summarize \
  --i-table $artifact/$freq_tbl \
  --m-sample-metadata-file $metadata \
  --o-visualization $visualizations/$freq_tbl_viz

qiime feature-table tabulate-seqs \
 --i-data $artifact/$seqs_rep \
 --o-visualization $visualizations/$seqs_rep_viz

echo "check $visualizations/w_chimeraPopLund_freq_table.qzv to know what to do on script phyloDiv.sh"
echo "This script took $SECONDS seconds to run. =^w^="
