#!/bin/bash
#This is the third part of the metagenomic analysis of my thesis, using qiime2
#This script creates a classifing model specific of the region 16S of the SILVA database in qiime2  

#variables
classifier=$(cat ConfigFile.yml | yq '.taxonomy.classifier')
ref_file_taxa=$(cat ConfigFile.yml | yq '.taxonomy.ref_taxa')
ref_file_seq=$(cat ConfigFile.yml | yq '.taxonomy.ref_seq')
ref_file_taxa_origin="origin_${ref_file_taxa}"
ref_file_seq_origin="origin_${ref_file_seq}"
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_tbl')

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
    --p-f-primer GTGYCAGCMGCCGCGGTAA \
    --p-r-primer GGACTACNVGGGTWTCTAAT \
    --p-n-jobs 2 \
    --p-read-orientation 'forward' \
    --o-reads "derep_uniq_$ref_file_seq"
#substitute the primers for the ones used in the sequencin (waiting for response)

#dereplicate seqs 'cause the extracted amplicon regions may now be identical over this shorter region
qiime rescript dereplicate \
    --i-sequences "derep_uniq_$ref_file_seq" \
    --i-taxa "derep_uniq_$ref_file_taxa_origin" \
    --p-mode 'uniq' \
    --o-dereplicated-sequences $ref_file_seq \
    --o-dereplicated-taxa  $ref_file_taxa

#train classifier
qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads $ref_file_seq \
    --i-reference-taxonomy $ref_file_taxa \
    --o-classifier $classifier

#test classifier
qiime feature-classifier classify-sklearn \
  --i-classifier $classifier \
  --i-reads $ref_file_taxa \
  --o-classification taxonomy.qza
#tabulate to visualize in qiime 2
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv
#barplot to observe taxonomy
qiime taxa barplot \
  --i-table $freq_tbl \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization taxa-bar-plots.qzv

echo "check the "taxonomy.qzv" file in qiime2 to see the confidance of the classifier and the taxa-bar-plots.qzv to see the taxonomy composition"
echo "The classifying model is $classifier"