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
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_wctbl' | sed 's/\"//g')
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

if [ -e ./diversity_core_metrics ];
 then
 echo "./diversity_core_metrics directory found"
 echo "erasing old ./diversity_core_metrics directory"
 rm -rf ./diversity_core_metrics
 else
 echo "no ./diversity_core_metrics directory found, continuing analyis"
fi

if [ -e $outputDir_viz ];
 then
 echo "$outputDir_viz directory already exists"
 echo "continuing analysis"
 else
 echo "creating directory for diversity visualiazations"
 mkdir $outputDir_viz
 echo "continuing analysis"
fi

#check if frequency table exists
if [ ! -e "$freq_tbl" ];
 then
  help
  echo "ERROR: file $freq_tbl not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
 fi

qiime diversity core-metrics-phylogenetic \
  --i-table $freq_tbl \
  --i-phylogeny ./phylogeny_$data/tree.qza \
  --m-metadata-file $metadata \
  --p-sampling-depth $raref_cap \
  --output-dir ./diversity_core_metrics

qiime diversity alpha-group-significance \
  --i-alpha-diversity ./diversity_core_metrics/faith_pd_vector.qza \
  --m-metadata-file $metadata \
  --o-visualization $outputDir_viz/faiths_pd_statistics.qzv

qiime diversity alpha-group-significance \
 --i-alpha-diversity ./diversity_core_metrics/evenness_vector.qza \
 --m-metadata-file $metadata \
 --o-visualization $outputDir_viz/evenness_statistics.qzv

 #analysis of variance (ANOVA) to test whether multiple effects significantly impact alpha d    iversity
qiime longitudinal anova \
  --m-metadata-file ./diversity_core_metrics/faith_pd_vector.qza \
  --m-metadata-file $metadata \
  --p-formula 'faith_pd ~ temp * diet' \
  --o-visualization $outputDir_viz/faiths_pd_anova.qzv
 
#beta diversity
qiime diversity beta-group-significance \
  --i-distance-matrix diversity_core_metrics/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file $metadata \
  --m-metadata-column temp \
  --o-visualization $outputDir_viz/unweighted_unifrac_temp_significance.qzv
 
qiime diversity beta-group-significance \
  --i-distance-matrix diversity_core_metrics/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file $metadata \
  --m-metadata-column temp \
  --o-visualization $outputDir_viz/weighted-unifrac_temp_significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix diversity_core_metrics/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file $metadata \
  --m-metadata-column diet \
  --o-visualization $outputDir_viz/unweighted_unifrac_diet_significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix diversity_core_metrics/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file $metadata \
  --m-metadata-column diet \
  --o-visualization $outputDir_viz/weighted_unifrac_diet_significance.qzv

#emperor plots
qiime emperor plot \
  --i-pcoa diversity_core_metrics/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file $metadata \
  --o-visualization $outputDir_viz/unifrac_emperor.qzv
  
qiime emperor plot \
  --i-pcoa diversity_core_metrics/bray_curtis_pcoa_results.qza \
  --m-metadata-file $metadata \
  --o-visualization $outputDir_viz/bray_curtis_emperor.qzv


echo "Starting the Differential Abundance"
#diferential abundance
qiime feature-table filter-features \
  --i-table $freq_tbl \
  --p-min-frequency 50 \
  --p-min-samples 4 \
  --o-filtered-table artifact_$data/table_abund.qza

#searching for differencies in the gut microbiome between temp and diet
qiime composition ancombc \
  --i-table artifact_$data/table_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'diet' \
  --p-prv-cut 0 \
  --o-differentials artifact_$data/ancombc_diet.qza

qiime composition da-barplot \
  --i-data artifact_$data/ancombc_diet.qza \
  --p-significance-threshold 0.001 \
  --o-visualization $outputDir_viz/da_barplot_diet.qzv

qiime composition ancombc \
  --i-table artifact_$data/table_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'temp' \
  --p-prv-cut 0 \
  --o-differentials artifact_$data/ancombc_temp.qza

qiime composition da-barplot \
  --i-data artifact_$data/ancombc_temp.qza \
  --p-significance-threshold 0.001 \
  --o-visualization $outputDir_viz/da_barplot_temp.qzv

qiime composition ancombc \
  --i-table artifact_$data/table_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'diet + temp' \
  --p-prv-cut 0 \
  --o-differentials artifact_$data/ancombc_diet_temp.qza

qiime composition da-barplot \
  --i-data artifact_$data/ancombc_diet_temp.qza \
  --p-significance-threshold 0.001 \
  --o-visualization $outputDir_viz/da_barplot_diet_temp.qzv

echo "Diversity analysis finished ~~***"
echo ''' 
          . .
         ( ,-)------* 
      _(_|   |_)_
 '''




