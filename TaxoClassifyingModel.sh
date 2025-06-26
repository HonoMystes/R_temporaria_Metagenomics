#!/bin/bash
#This is the third part of the metagenomic analysis of my thesis, using qiime2
#This script requires the same arguement used for the previous 2
#This script creates a classifing model specific of the region 16S of the SILVA database in qiime2 
#The reference file is pulled form the qiime2 repository
#It uses the metadata file, the frequencies and the sequencies tables obtained in the previous script
#The resulting output is the taxonomy of our data 
# the < | sed 's/\"//g'> is needed since the qiime enviroment adds ""
##Copywrite Daniela Deodato, January 2025

#stops if error
set -e

function help {
echo ""
echo "This is the third part of the metagenomic analysis of my thesis, using qiime2"
echo "This script requires the same arguement used for the previous 2"
echo "This script creates a classifing model specific of the region 16S of the SILVA database in qiime2"
echo "The reference file is pulled form the qiime2 repository"
echo "It uses the metadata file, the frequencies and the sequencies tables obtained in the previous script"
echo "the script runs with the argument of the name of the population"
echo "The resulting output is the taxonomy of our data"
echo ""
}

#variables
data=$1
metadata=$(cat ConfigFile.yml | yq '.raw.metadata' | sed 's/\"//g')
threads=$(cat ConfigFile.yml | yq '.raw.threads' | sed 's/\"//g')
artifact=$(cat ConfigFile.yml | yq '.directory_name.artifact' | sed 's/\"//g')
visualizations=$(cat ConfigFile.yml | yq '.directory_name.visualizations' | sed 's/\"//g')
classifier=$(cat ConfigFile.yml | yq '.taxonomy.classifier' | sed 's/\"//g')
version=$(cat ConfigFile.yml | yq '.taxonomy.version' | sed 's/\"//g')
target=$(cat ConfigFile.yml | yq '.taxonomy.target' | sed 's/\"//g')
ref_file_taxa="silva_ref_taxa.qza"
ref_file_seq="silva_ref_seqs.qza"
ref_file_taxa_origin="origin_${ref_file_taxa}"
ref_file_seq_origin="origin_${ref_file_seq}"
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_tbl' | sed 's/\"//g')
seqs_rep=$(cat ConfigFile.yml | yq '.tables.seqs_rep' | sed 's/\"//g')
taxo_rep=$(cat ConfigFile.yml | yq '.tables.taxa_seqs' | sed 's/\"//g')
taxo_tbl=$(cat ConfigFile.yml | yq '.tables.taxa_freq' | sed 's/\"//g')
taxo_rep_viz=$(cat ConfigFile.yml | yq '.tables.taxa_seqs_viz' | sed 's/\"//g')
taxo_tbl_viz=$(cat ConfigFile.yml | yq '.tables.taxa_freq_viz' | sed 's/\"//g')
prim_f=$(cat ConfigFile.yml | yq '.illumina.primer_f' | sed 's/\"//g')
prim_r=$(cat ConfigFile.yml | yq '.illumina.primer_r' | sed 's/\"//g')
taxo=$(cat ConfigFile.yml | yq '.taxonomy.taxo_data' | sed 's/\"//g')

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
if [ ! -e "$artifact/$freq_tbl" ];
 then
  help
  echo "ERROR: file $artifact/$freq_tbl not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
 fi

#check if representative sequences table exists
if [ ! -e "$artifact/$seqs_rep" ];
 then
  help
  echo "ERROR: file $artifact/$seqs_rep not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
 fi

#Get SILVA database

qiime rescript get-silva-data \
    --p-version "$version" \
    --p-target "$target" \
    --p-include-species-labels \
    --p-no-rank-propagation \
    --o-silva-sequences rna_$ref_file_seq_origin \
    --o-silva-taxonomy $ref_file_taxa_origin

#making into FeatureTable[sequence]
qiime rescript reverse-transcribe \
    --i-rna-sequences rna_$ref_file_seq_origin \
    --o-dna-sequences $ref_file_seq_origin

#removing sequences that contain 5 or more ambiguous bases (IUPAC compliant ambiguity bases) and any homopolymers that are 8 or more bases in length. 
qiime rescript cull-seqs \
    --i-sequences $ref_file_seq_origin \
    --o-clean-sequences "cleaned_$ref_file_seq_origin"

#filter ref file based on the classification to avoid references being lost
qiime rescript filter-seqs-length-by-taxon \
    --i-sequences "cleaned_$ref_file_seq_origin" \
    --i-taxonomy $ref_file_taxa_origin \
    --p-labels Archaea Bacteria Eukaryota \
    --p-min-lens 900 1200 1400 \
    --o-filtered-seqs "filt_$ref_file_seq_origin" \
    --o-discarded-seqs "discard_$ref_file_seq_origin"

#dereplicate to remove redundant sequence data from the database
#uniq approach retains identical sequence records that have differing taxonomies
qiime rescript dereplicate \
    --i-sequences "filt_$ref_file_seq_origin"  \
    --i-taxa $ref_file_taxa_origin \
    --p-mode 'uniq' \
    --o-dereplicated-sequences derep_uniq_$ref_file_seq_origin \
    --o-dereplicated-taxa derep_uniq_$ref_file_taxa_origin

#make amplicon-region specific classifier
#extract sequences 
qiime feature-classifier extract-reads \
    --i-sequences derep_uniq_$ref_file_seq_origin \
    --p-f-primer $prim_f \
    --p-r-primer $prim_r \
    --p-n-jobs $threads \
    --p-read-orientation 'forward' \
    --o-reads derep_uniq_${ref_file_seq}

#dereplicate seqs 'cause the extracted amplicon regions may now be identical over this shorter region
qiime rescript dereplicate \
    --i-sequences derep_uniq_${ref_file_seq} \
    --i-taxa derep_uniq_$ref_file_taxa_origin \
    --p-mode 'uniq' \
    --o-dereplicated-sequences $ref_file_seq \
    --o-dereplicated-taxa $ref_file_taxa

#train feature classifier
qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads $ref_file_seq \
    --i-reference-taxonomy $ref_file_taxa \
    --o-classifier $artifact/$classifier

#test classifier
qiime feature-classifier classify-sklearn \
  --i-classifier $artifact/$classifier \
  --i-reads $ref_file_seq \
  --o-classification $artifact/taxonomy.qza

#tabulate to visualize in qiime 2
qiime metadata tabulate \
  --m-input-file $artifact/taxonomy.qza \
  --o-visualization $visualizations/taxonomy.qzv

#apply classifier to our data
qiime feature-classifier classify-sklearn \
  --i-classifier $artifact/$classifier \
  --i-reads $artifact/$seqs_rep \
  --o-classification $artifact/$taxo

qiime metadata tabulate \
  --m-input-file $artifact/$taxo \
  --o-visualization $visualizations/${data}_taxonomy.qzv

#filter tables
qiime taxa filter-table \
  --i-table $artifact/$freq_tbl \
  --i-taxonomy $artifact/$taxo \
  --p-mode contains \
  --p-include p__ \
  --p-exclude 'p__;,Chloroplast,Mitochondria' \
  --o-filtered-table $artifact/$taxo_tbl

qiime feature-table filter-seqs \
  --i-data $artifact/$seqs_rep \
  --i-table $artifact/$taxo_tbl \
  --o-filtered-data $artifact/$taxo_rep

qiime feature-table summarize \
  --i-table $artifact/$taxo_tbl \
  --m-sample-metadata-file $metadata\
  --o-visualization $visualizations/$taxo_tbl_viz

qiime feature-table tabulate-seqs \
  --i-data $artifact/$taxo_rep \
  --o-visualization $visualizations/$taxo_rep_viz

#barplot to observe taxonomy in our data
qiime taxa barplot \
  --i-table $artifact/$taxo_tbl \
  --i-taxonomy $artifact/$taxo \
  --m-metadata-file $metadata \
  --o-visualization $visualizations/${data}_taxa_bar_plots.qzv

#organize
mv ./*.qza $artifact/

echo "Check the "$visualizations/${data}_taxonomy.qzv" file in qiime2 to see the confidance of the classifier of the reference file with the data"
echo "The $visualizations/${data}_taxa_bar_plots.qzv shows the taxonomic composition"
echo "The classifying model is $artifact/$classifier"
