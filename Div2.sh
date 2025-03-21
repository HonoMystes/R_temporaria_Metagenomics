#!/bin/bash
#This is the fifth part of the metagenomic analysis of my thesis, using qiime2
#This script will make the diversity analysis after analysing the alpha rarefraction in ./$outputDir_viz/alpha_rarefaction_curves.qzv
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
raref_cap=$(cat ConfigFile.yml | yq '.diversity.raref_cap' | sed 's/\"//g')
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

#filter samples based on rarefraction depth
#diferential abundance
qiime feature-table filter-features \
  --i-table ./table_${raref_cap}.qza \
  --p-min-frequency 50 \
  --p-min-samples 4 \
  --o-filtered-table ./table_${raref_cap}_abund.qza

#searching for differencies in the gut microbiome between temp and diet
qiime composition ancombc \
  --i-table ./table_${raref_cap}_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'diet' \
  --o-differentials ./ancombc_diet.qza

qiime composition da-barplot \
  --i-data ./ancombc_diet.qza \
  --p-significance-threshold 0.001 \
  --o-visualization ./$outputDir_viz/da_barplot_diet.qzv

qiime composition ancombc \
  --i-table ./table_${raref_cap}_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'temp' \
  --o-differentials ./ancombc_temp.qza

qiime composition da-barplot \
  --i-data ./ancombc_temp.qza \
  --p-significance-threshold 0.001 \
  --o-visualization ./$outputDir_viz/da_barplot_temp.qzv

qiime composition ancombc \
  --i-table ./table_${raref_cap}_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'diet + temp' \
  --o-differentials ./ancombc_diet_temp.qza

qiime composition da-barplot \
  --i-data ./ancombc_diet_temp.qza \
  --p-significance-threshold 0.001 \
  --o-visualization ./$outputDir_viz/da_barplot_diet_temp.qzv

echo """  
   ∧＿∧
　(｡･ω･｡)つ━☆・*。
⊂/　 /　   ・゜
しーＪ　　　     °。+ * 。　
                        .・゜
                         　ﾟ･｡･ﾟ 
"""
echo "Diversity analysis finished ──★ ˙ ̟"

