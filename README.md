# R_temporaria_Metagenomics
Scripts used for my thesis project on the metagenomic analysis of Rana temporaria gut microbiota

At the moment the current scripts and files are:

- The *demu.sh* script will perform the quality control of our samples using the fastp command the resulting path to that out put will be used in the creation of a manifest file (tsv file) to start importing the demultiplexed and quality checked sequences into artifact type using the tsv file created and cutting the primers with cutadapt.  
- The *FeatureTablecreation.sh* script to filter, denoise, filter out chimeras and create de feature tables (frequency and representative sequnces) and representative sequences to be used for the taxonomic, phylogenetic and diversity analysis.
- The *TaxoClassifyingModel.sh* script trains the classifing model specific of the 16S for the taxonomy using the SILVA database and creates the taxonomy of our data, for better analysis the taxonomy results can be visualized by aid of a bar plot.
- The *phyloDiv.sh* modifies the representaive sequences table based on the taxonomy and performs the phylogeny and diversit analysis.
- The *Div2.sh* script is the second part of the diversity analysis after determining the rarefraction curve, to perform the diferential abundance.
- The *ConfigFile.yml* the configuration file to be used in the other scripts that contains different variables.
- The License and the file you are currently reading the README file. 

Copywrite Daniela Deodato year 2025.
