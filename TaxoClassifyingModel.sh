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
classifier=$(cat ConfigFile.yml | yq '.taxonomy.classifier' | sed 's/\"//g')
ref_file_taxa=$(cat ConfigFile.yml | yq '.taxonomy.ref_taxa' | sed 's/\"//g')
ref_file_seq=$(cat ConfigFile.yml | yq '.taxonomy.ref_seq' | sed 's/\"//g')
ref_file_taxa_origin="origin_${ref_file_taxa}"
ref_file_seq_origin="origin_${ref_file_seq}"
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_tbl' | sed 's/\"//g')
seqs_rep=$(cat ConfigFile.yml | yq '.tables.seqs_rep' | sed 's/\"//g')
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

#Get SILVA database
qiime rescript get-silva-data \
    --p-version '138.2' \
    --p-target 'SSURef_NR99' \
    --o-silva-sequences "rna_$ref_file_seq_origin" \
    --o-silva-taxonomy $ref_file_taxa_origin

#making into FeatureTable[sequence]
qiime rescript reverse-transcribe \
    --i-rna-sequences "rna_$ref_file_seq_origin" \
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
    --o-dereplicated-sequences "derep_uniq_$ref_file_seq_origin" \
    --o-dereplicated-taxa "derep_uniq_$ref_file_taxa_origin"

#make amplicon-region specific classifier 

#extract sequences
qiime feature-classifier extract-reads \
    --i-sequences "derep_uniq_$ref_file_seq_origin" \
    --p-f-primer $prim_f \
    --p-r-primer $prim_r \
    --p-n-jobs 2 \
    --p-read-orientation 'forward' \
    --o-reads "derep_uniq_$ref_file_seq"

#dereplicate seqs 'cause the extracted amplicon regions may now be identical over this shorter region
qiime rescript dereplicate \
    --i-sequences "derep_uniq_$ref_file_seq" \
    --i-taxa "derep_uniq_$ref_file_taxa_origin" \
    --p-mode 'uniq' \
    --o-dereplicated-sequences $ref_file_seq \
    --o-dereplicated-taxa  $ref_file_taxa

#train feature classifier
qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads $ref_file_seq \
    --i-reference-taxonomy $ref_file_taxa \
    --o-classifier $classifier

#test classifier
qiime feature-classifier classify-sklearn \
  --i-classifier $classifier \
  --i-reads $ref_file_seq \
  --o-classification taxonomy.qza
#tabulate to visualize in qiime 2
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv

#apply classifier to our data
qiime feature-classifier classify-sklearn \
  --i-classifier $classifier \
  --i-reads $seqs_rep \
  --o-classification $taxo


qiime metadata tabulate \
  --m-input-file $taxo \
  --o-visualization ${data}_taxonomy.qzv

#barplot to observe taxonomy in our data
qiime taxa barplot \
  --i-table $freq_tbl \
  --i-taxonomy $taxo \
  --m-metadata-file $metadata \
  --o-visualization ${data}_taxa_bar_plots.qzv

#organize
mv ./*.qza artifact/
mv ./*.qzv 

echo "Check the "${data}_taxonomy.qzv" file in qiime2 to see the confidance of the classifier of the reference file with the data"
echo "The ${data}_taxa_bar_plots.qzv shows the taxonomic composition"
echo "The classifying model is $classifier"

#train the sample classifier for the prevision model
#backburner por enquanto
