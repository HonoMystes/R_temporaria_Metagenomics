#!/bin/bash
#This is the forth part of the metagenomic analysis of my thesis, using qiime2
#This script will make the phylogeny analysis and the first part of the diversity analysis
# the < | sed 's/\"//g'> is needed since the qiime enviroment adds ""
#Copywrite Daniela Deodato, January 2025

#stops if error
set -e

function help {
echo ""
echo "This is the fifth part of the metagenomic analysis of my thesis, using qiime2"
echo "This script will make the diversity analysis after analysing the alpha rarefraction in ./$outputDir_viz/alpha_rarefaction_curves.qzv"
echo "the script runs with the argument of the name of the population"
echo ""
}

#variables
data=$1
metadata=$(cat ConfigFile.yml | yq '.raw.metadata' | sed 's/\"//g')
seqs_rep=$(cat ConfigFile.yml | yq '.tables.seqs_wcrep' | sed 's/\"//g')
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_wctbl' | sed 's/\"//g')
max_depth=$(cat ConfigFile.yml | yq '.diversity.max_depth' | sed 's/\"//g')
outputDir_viz=$(cat ConfigFile.yml | yq '.directory_name.viz_dir_div' | sed 's/\"//g')

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

#check if frequency table exists
if [ ! -e "$freq_tbl" ];
 then
  help
  echo "ERROR: file $freq_tbl not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
 fi

#check if representative sequences table exists
if [ ! -e "$seqs_rep" ];
 then
  help
  echo "ERROR: file $seqs_rep not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
 fi

qiime phylogeny align-to-tree-mafft-fasttree \
	--i-sequences $seqs_rep \
	--o-alignment aligned-rep-seqs.qza \
	--o-masked-alignment masked-aligned-rep-seqs.qza \
	--o-tree unrooted-tree.qza \
	--o-rooted-tree tree.qza

mkdir -p phylogeny_$data
mv *aligned* ./phylogeny_$data
mv *tree* ./phylogeny_$data

#alpha diversity see parkinson's mouse
if [ -e $outputDir_viz ];
 then 
 echo "$outputDir_viz directory already exists"
 echo "continuing analysis"
 else
 echo "creating directory for diversity visualiazations"
 mkdir $outputDir_viz
 echo "continuing analysis"
fi

#rarefraction
qiime diversity alpha-rarefaction \
  --i-table $freq_tbl \
  --m-metadata-file $metadata \
  --o-visualization $outputDir_viz/alpha_rarefaction_curves.qzv \
  --p-min-depth 1 \
  --p-max-depth $max_depth

echo "To continue diversity analysis please check the ./$outputDir_viz/alpha_rarefaction_curves.qzv file and run Div2.sh"
