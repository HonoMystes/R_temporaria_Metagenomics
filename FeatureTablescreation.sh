#!/bin/bash
#This code is the second part of the metagenomic analysis of my thesis, using the qiime2 software
#After cuting the primers and analysing the "interactive Quality Plot" in the file trimmed-seqs_{$data}.qzv the perfered numbers in the configuration file are edited.
#The script runs with the arguments: sequences directory name and metadata file
#Copywrite Daniela Deodato, January 2025

function help {
echo ""
echo "This code is the second part of the metagenomic analysis of my thesis, using the qiime2 software"
echo "After cuting the primers and analysing the "interactive Quality Plot" in the file trimmed-seqs_{$data}.qzv the perfered numbers in the configuration file are edited. "
echo "#The script runs with the arguments: sequences directory name and metadata file"
echo ""
}

#Variables
data=$1 #name of the directory with the samples
cutadapt_file_viz=trimmed-seqs_{$data}.qzv
cutadapt_file_art=trimmed-seqs_{$data}.qza
metadata=$2 #metadata file

num_min_seq=$(cat ConfigFile.yml | yq '.size.num_min_seq')
trim_forward=$(cat ConfigFile.yml | yq '.trim.trim_forward')
trim_reverse=$(cat ConfigFile.yml | yq '.trim.trim_reverse')
trunc_forward=$(cat ConfigFile.yml | yq '.trunc.trunc_forward')
trunc_reverse=$(cat ConfigFile.yml | yq '.trunc.trunc_reverse')
outputDir=$(cat ConfigFile.yml | yq '.directory_name.output_dir_cutadapt')
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_tbl')
freq_tbl_viz=$(cat ConfigFile.yml | yq '.tables.freq_tbl_viz')
seqs_rep=$(cat ConfigFile.yml | yq '.tables.seqs_rep')
seqs_rep_viz=$(cat ConfigFile.yml | yq '.tables.seqs_rep_viz')

#Possible errors
#check the number of arguments
if [ $# -ne 2 ];
 then
  help
  echo "ERRO: Número de argumentos errado" > Erro.1.txt
  cat Erro.1.txt
  echo "Este script requer dois argumentos para correr"
  exit 1
 fi

#verify id the cutadapt file exists
if [ ! -e "$cutdapt_file" ];
 then
  help
  echo "ERRO: O ficheiro $cutadapt_file não existe" > Erro.2.txt
  cat Erro.2.txt
  echo "Por favor verifique se o nome do ficheiro está correto e se está na diretoria"
  exit 1
 fi
#verify if the metadata file exists
if [ ! -e "$metadata" ];
 then
  help
  echo "ERRO: O ficheiro $metadata não existe" > Erro.3.txt
  cat Erro.3.txt
  echo "Por favor verifique se o nome do ficheiro metadata está correto e se está na diretoria"
  exit 1
 fi

 #filtering samples

qiime demux filter-samples \
  --i-demux $cutadapt_file_art \
  --m-metadata-file ./$outputDir/per-sample-fastq-counts.tsv \
  --p-where 'CAST([forward sequence count] AS INT) > {$num_min_seq}' \
  --o-filtered-demux $cutadapt_file_art
#alterar para número de sequencias que se quer in p-where
###
#denoising

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs $cutadapt_file_art \
  --p-trim-left-f $trim_forward \
  --p-trim-left-r $trim_reverse \
  --p-trunc-len-f $trunc_forward \
  --p-trunc-len-r $trunc_reverse \
  --o-table $freq_tbl \
  --o-representative-sequences $seqs_rep \
  --o-denoising-stats denoising-stats_{$data}.qza
#alterar os seguintes parametros baseado nos nossos dados no --i-demultiplexed-seqs
###
#Feature tables
qiime feature-table summarize \
  --i-table $freq_tbl \
  --o-visualization $freq_tbl_viz \
  --m-sample-metadata-file $metadata

qiime feature-table tabulate-seqs \
  --i-data $seqs_rep \
  --o-visualization $seqs_rep_viz

qiime metadata tabulate \
  --m-input-file denoising-stats_{$data}.qza \
  --o-visualization denoising-stats_{$data}.qzv

###Exclude Chimeras

echo "Examining for chimeras"
echo "Running de novo" 
qiime vsearch uchime-denovo \
  --i-table $freq_tbl \
  --i-sequences $seqs_rep \
  --output-dir {$data}_uchime-dn-out

qiime metadata tabulate \
  --m-input-file {$data}_uchime-dn-out/stats.qza \
  --o-visualization {$data}_uchime-dn-out/stats.qzv

qiime feature-table filter-features \
  --i-table $freq_tbl \
  --m-metadata-file {$data}_uchime-dn-out/nonchimeras.qza \
  --o-filtered-table $freq_tbl

qiime feature-table filter-seqs \
  --i-data $seqs_rep \
  --m-metadata-file {$data}_uchime-dn-out/nonchimeras.qza \
  --o-filtered-data $seqs_rep

qiime feature-table summarize \
  --i-table $freq_tbl \
  --o-visualization $freq_tbl_viz

echo "check $freq_tbl_viz to know what to do on script phyloDiv.sh"