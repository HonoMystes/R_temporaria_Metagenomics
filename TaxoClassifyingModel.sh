#!/bin/bash
#This is the third part of the metagenomic analysis of my thesis, using qiime2
#it will use the genome reference file SILVA https://data.qiime2.org/2024.10/common/silva-138-99-tax.qza
#it will also use the featureTable[sequence] of the ref file


#Get SILVA database
qiime rescript get-silva-data \
    --p-version '138.2' \
    --p-target 'SSURef_NR99' \
    --o-silva-sequences silva-138.2-ssu-nr99-rna-seqs.qza \
    --o-silva-taxonomy silva-138.2-ssu-nr99-tax.qza

#making into FeatureTable[sequence]
qiime rescript reverse-transcribe \
    --i-rna-sequences silva-138.2-ssu-nr99-rna-seqs.qza \
    --o-dna-sequences silva-138.2-ssu-nr99-seqs.qza

#removing sequences that contain 5 or more ambiguous bases (IUPAC compliant ambiguity bases) and any homopolymers that are 8 or more bases in length. 
qiime rescript cull-seqs \
    --i-sequences silva-138.2-ssu-nr99-seqs.qza \
    --o-clean-sequences silva-138.2-ssu-nr99-seqs-cleaned.qza

#filter ref file based on the classification to avoid references being lost
qiime rescript filter-seqs-length-by-taxon \
    --i-sequences silva-138.2-ssu-nr99-seqs-cleaned.qza \
    --i-taxonomy silva-138.2-ssu-nr99-tax.qza \
    --p-labels Archaea Bacteria Eukaryota \
    --p-min-lens 900 1200 1400 \
    --o-filtered-seqs silva-138.2-ssu-nr99-seqs-filt.qza \
    --o-discarded-seqs silva-138.2-ssu-nr99-seqs-discard.qza

#dereplicate to remove redundant sequence data from the database
#uniq approach retains identical sequence records that have differing taxonomies (ask)
qiime rescript dereplicate \
    --i-sequences silva-138.2-ssu-nr99-seqs-filt.qza  \
    --i-taxa silva-138.2-ssu-nr99-tax.qza \
    --p-mode 'uniq' \
    --o-dereplicated-sequences silva-138.2-ssu-nr99-seqs-derep-uniq.qza \
    --o-dereplicated-taxa silva-138.2-ssu-nr99-tax-derep-uniq.qza

#make amplicon-region specific classifier 

#extract sequences
qiime feature-classifier extract-reads \
    --i-sequences silva-138.2-ssu-nr99-seqs-derep-uniq.qza \
    --p-f-primer GTGYCAGCMGCCGCGGTAA \
    --p-r-primer GGACTACNVGGGTWTCTAAT \
    --p-n-jobs 2 \
    --p-read-orientation 'forward' \
    --o-reads silva-138.2-ssu-nr99-seqs-515f-806r.qza

#dereplicate seqs 'cause the extracted amplicon regions may now be identical over this shorter region
qiime rescript dereplicate \
    --i-sequences silva-138.2-ssu-nr99-seqs-515f-806r.qza \
    --i-taxa silva-138.2-ssu-nr99-tax-derep-uniq.qza \
    --p-mode 'uniq' \
    --o-dereplicated-sequences silva-138.2-ssu-nr99-seqs-515f-806r-uniq.qza \
    --o-dereplicated-taxa  silva-138.2-ssu-nr99-tax-515f-806r-derep-uniq.qza

#train classifier
qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads silva-138.2-ssu-nr99-seqs-515f-806r-uniq.qza \
    --i-reference-taxonomy silva-138.2-ssu-nr99-tax-515f-806r-derep-uniq.qza \
    --o-classifier silva-138.2-ssu-nr99-515f-806r-classifier.qza

classifier="silva-138.2-ssu-nr99-515f-806r-classifier.qza"
ref_file="silva-138.2-ssu-nr99-tax-515f-806r-derep-uniq.qza"
data=$1
seqs="{$data}_uchime-dn-out/rep-seqs-nonchimeric-wo-borderline.qza"