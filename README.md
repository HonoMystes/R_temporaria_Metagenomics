# R_temporaria_Metagenomics

### Work in progress....

## Table of Contents
1. [Installing](#installing)
2. [Configuration File](#configuration-file)
3. [Scripts](#scripts)
    - [demu.sh](#demush)
        - [Inputs](#inputs)
        - [Outputs](#outputs)
    - [FeatureTablecreate](#featuretablecreationsh)
        - [Inputs](#inputs-1)
        - [Outputs](#outputs-1)
    - [TaxoClassifyingModel.sh](#taxoclassifyingmodelsh)
        - [Inputs](#inputs-2)
        - [Outputs](#outputs-2)
    - [phyloDiv.sh](#phylodivsh)
        - [Inputs](#inputs-3)
        - [Outputs](#outputs-3)
    - [Div2.sh](#div2sh)
        - [Inputs](#inputs-4)
        - [Outputs](#outputs-4)
4. [Usage](#usage)
5. [Citations](#citations)


## Installing

---
## Configuration File
The *ConfigFile.yml* will be the only file to be altered depending on the data to be analyze. 
Keep in mind that the "PopLund" you will see in this file will be population name, that is the argument you give in all the scripts and therefore it will need to be changed as well in the configuration file to your argument. 
The file is divided into 7 categories:
- raw, where is the complete path to our demultiplexed data, the name or path to our metadata file (tsv) and the name for the manifest file;
- directory_name, as the name indicates it has the names for the directories;
- illumina has the primers used in the sequencing of the samples (check which one are used for the selected NGS tecnology);
- denoise has the minimum number of sequences per sample and truncating parameters selected after analysing the trimming visualization output obtained after running the *demu.sh* script;
- tables has the names of the tables created (the ones created from the denoising processe, the ones created after the filtering of chimeras and the ones after the filtering by taxa);
- taxonomy contains the names for the classifier and the taxonomy file created based our our data;
- Finally, the diversity section contains the parameters of the maximum frequency (see taxonomy filtred frequency table) and the rarefraction depth where the alpha rarefraction stabilizes (see alpha rarefraction curve file).
---
## Scripts
The raw used are demultiplexed paired-end fastq.gz files all in one directory. 
The fastq.gz files must be in one of these formats: sample_name_R1.fastq.gz / sample_name_R2.fastq.gz\
The .qza files are artifact files and .qzv are visualization files of the software QIIME2 used in this code.\
The visualization files can be viewed in [QIIME View](https://view.qiime2.org/).

At the moment the current scripts and files are:
### demu.sh
The *demu.sh* script will perform the quality control of our samples using the [fastp](https://github.com/OpenGene/fastp?tab=readme-ov-file#quality-filter) command the resulting path to that out put will be used in the creation of a manifest file (.tsv file) to start importing the demultiplexed and quality checked sequences into artifact type using the tsv file created and cutting the primers with cutadapt.

#### Inputs: 
- Population name (argument);
- In the Configuration file alter the: path to the samples, the name for the manifest file, the name of the directories (cutadapt, artifact, visualizations, quality and fastp), primers sequences and number of threads to be used.

#### Outputs: 
- Fastp outputs (.fastq.gz);
- Manifest file (.tsv);
- demultiplexed samples artifact (.qza);
- Trimmed artifact of our samples (.qza).

### FeatureTablecreation.sh
The *FeatureTablecreation.sh* script uses the trimmed artifact file generated in the script above to filter, denoise (using deblur) our data as well as filtering out chimeras and create de feature tables (frequency and representative sequences) with and without filtering the chimeras to be later filtred by the taxonomy file.

#### Inputs:
- Population name (argument);
- In the Configuration file alter the: metadata path, number of cores to be used, the minimum number of sequences per sample, the truncation value for the right cut of the sequences and the feature tables names (with an without chimeras) both artifacts and visualizations.

#### Outputs:
- Feature Tables (frequency table and representative sequences) with and without chimeras (.qza);
- Deblur stats, visualization and artifact files (.qzv and .qza);
- Chimeras examination (Vsearch uchime-denovo) stats visualization and artfact files(.qzv and .qza). 

### TaxoClassifyingModel.sh
The *TaxoClassifyingModel.sh* script trains the classifing model specific of the 16S for the taxonomy using the SILVA database and creates the taxonomy of our data, the taxonomy file is later used to filter the feature tables. For better analysis the taxonomy results can be visualized by aid of a bar plot.

#### Inputs:
- Population name (argument);
- In the Configuration file alter the: metadata path, number of cores to be used, the primers (must be the same ones used in the *demu.sh*), the name of the chimera filtred feature tables in artifact type (must be the same ones created in *FeatureTablecreation.sh*) and name of the classifier and the taxonomy file.

#### Outputs:
- Silva database outputs for the creation of the classifier (.qza);
- Classifier (.qza);
- Taxonomy file (.qza);
- Feature tables (frequency table and representative sequences) filtred by taxa (.qza and for the frequency table also .qzv);
- Taxonomy Bar Plot.

### phyloDiv.sh
The *phyloDiv.sh* performs the phylogeny and alpha rarefractrion analysis.

#### Inputs:
- Population name (argument);
- In the Configuration file alter the: name of the feature tables (frequecy and representative sequences) artifact files filtred by taxonomy, maximum depth value(the value is chosen by observing the taxonomy filtred frequency table number of maximum frequency. e.g: the maximum frequency=4996 then maximum depth=4230), name of the phylogeny directory and the diversity visualizations directory. 

#### Outputs:
- Aligned sequence (.qza);
- Masked aligned sequences (.qza);
- Rooted and unrooted tree (.qza);
- Alpha rarefraction curve plot (.qzv).

### Div2.sh
The *Div2.sh* script performes the alpha and beta diversity analysis after determining the rarefraction curve with the vizualization output created above it also performes the differential analysis of the abundance in our data.

#### Inputs:
- Population name (argument);
- In the Configuration file alter the: metadata file path, name of the feature tables (frequecy and representative sequences) artifact files filtred by taxonomy and the number of rarefraction depth

#### Outputs:
- Diversity core metrics based on phylogeny (.qza and .qzv);
- Alpha diversity statistics (eveness, faith_pd and anova faith_pd) (.qzv);
- Beta diversity statistics (weighted and unweighted unifraq siginificances) (.qzv);
- Differential abundance analysis outputs (.qza and .qzv).

---
## Usage
Before starting the analysis remember to download and activate de [qiime2](https://docs.qiime2.org/2024.10/) amplicon enviroment.

`conda update conda`

`wget -O "https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml"`

`conda env create -n qiime2-amplicon-2024.10 --file https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml`

`conda activate qiime2-amplicon-2024.10`

Uptade the ConfigFile.yml to your desire and then the analysis by start with running the *demu.sh* script:\
As pointed out above the "PopLund" argument refers to the population name in study and must also be edited in the configuration file to your preference.

`demu.sh PopLund `

After analyzing the output *trimmed-seqs_PopLund.qzv* the denoise section of the configuration file is altered for our deseired values of minimum number of sequences per sample and truncation value for the right cut of the sequences. The *FeatureTablecreation.sh* is next:

`FeatureTablecreation.sh PopLund`

With the feature tables created we then performe the taxonomic analysis by running the command:

`TaxoClassifyingModel.sh PopLund`

To start the diversity analysis we must first perform the phylogeny analysis and the alpha rarefraction curve. That is done by running the command:

`phyloDiv.sh PopLund`

The last script to run will perform the alpha and beta diverity analysis as well as the differential abundance analysis with the command:

`Div2.sh PopLund`

---
## Citations


Copyright Daniela Deodato year 2025.
