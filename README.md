# R_temporaria_Metagenomics
Scripts used for my thesis project on the metagenomic analysis of Rana temporaria gut microbiota

At the moment the current scripts and files are:

- The *demu.sh* script for importing the data into artifact type and cutting the primers with cutadapt.  
- The *FeatureTablecreation.sh* script to filter, denoise, filter out chimeras and create de feature tables (frequency and representative sequnces) and representative sequences to be used for the taxonomic, phylogenetic and diversity analysis.
- The *TaxoClassifyingModel.sh* script trains the classifing model specific of the 16S for the taxonomy using the SILVA database and creates the taxonomy of our data.
- The *phyloDiv* modifies the representaive sequences table based on the taxonomy and performs the phylogeny and diversity analysis.
- The *ConfigFile.yml* the configuration file to be used in the other scripts that contains different variables.
- The License and the file you are currently reading the README file. 

Copywrite Daniela Deodato year 2025.
