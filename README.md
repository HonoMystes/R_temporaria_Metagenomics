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

Amir, A., McDonald, D., Navas-Molina, J. A., Kopylova, E., Morton, J. T., Xu, Z. Z., Kightley, E. P., Thompson, L. R., Hyde, E. R., Gonzalez, A., & Knight, R. (2017). Deblur rapidly resolves single-nucleotide community sequence patterns. MSystems, 2(2), e00191-16.

Bokulich, N. A., Kaehler, B. D., Rideout, J. R., Dillon, M., Bolyen, E., Knight, R., Huttley, G. A., & Caporaso, J. G. (2018). Optimizing taxonomic classification of marker-gene amplicon sequences with QIIME 2’s q2-feature-classifier plugin. Microbiome, 6(1), 90. https://doi.org/10.1186/s40168-018-0470-z

Bolyen, E., Rideout, J. R., Dillon, M. R., Bokulich, N. A., Abnet, C. C., Al-Ghalith, G. A., Alexander, H., Alm, E. J., Arumugam, M., Asnicar, F., Bai, Y., Bisanz, J. E., Bittinger, K., Brejnrod, A., Brislawn, C. J., Brown, C. T., Callahan, B. J., Caraballo-Rodríguez, A. M., Chase, J., … Caporaso, J. G. (2019). Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2. Nature Biotechnology, 37(8), 852–857. https://doi.org/10.1038/s41587-019-0209-9

Katoh, K., & Standley, D. M. (2013). MAFFT multiple sequence alignment software version 7: improvements in performance and usability. Molecular Biology and Evolution, 30(4), 772–780. https://doi.org/10.1093/molbev/mst010

Lane, D. (1991). 16S/23S rRNA sequencing. In E. Stackebrandt & M. Goodfellow (Eds.), Nucleic Acid Techniques in Bacterial Systematics (pp. 115–175). John Wiley.

Martin, M. (2011). Cutadapt removes adapter sequences from high-throughput sequencing reads. EMBnet. Journal, 17(1), pp-10. https://doi.org/10.14806/ej.17.1.200

McDonald, D., Clemente, J. C., Kuczynski, J., Rideout, J. R., Stombaugh, J., Wendel, D., Wilke, A., Huse, S., Hufnagle, J., Meyer, F., Knight, R., & Caporaso, J. G. (2012a). The Biological Observation Matrix (BIOM) format or: how I learned to stop worrying and love the ome-ome. GigaScience, 1(1), 7. https://doi.org/10.1186/2047-217X-1-7

McDonald, D., Clemente, J. C., Kuczynski, J., Rideout, J. R., Stombaugh, J., Wendel, D., Wilke, A., Huse, S., Hufnagle, J., Meyer, F., Knight, R., & Caporaso, J. G. (2012b). The Biological Observation Matrix (BIOM) format or: how I learned to stop worrying and love the ome-ome. GigaScience, 1(1), 7. https://doi.org/10.1186/2047-217X-1-7

Pedregosa, F., Varoquaux, G., Gramfort, A., Michel, V., Thirion, B., Grisel, O., Blondel, M., Prettenhofer, P., Weiss, R., Dubourg, V., Vanderplas, J., Passos, A., Cournapeau, D., Brucher, M., Perrot, M., & Duchesnay, É. (2011a). Scikit-learn: Machine learning in Python. Journal of Machine Learning Research, 12(Oct), 2825–2830.
Pedregosa, F., Varoquaux, G., Gramfort, A., Michel, V., Thirion, B., Grisel, O., Blondel, M., Prettenhofer, P., Weiss, R., Dubourg, V., Vanderplas, J., Passos, A., Cournapeau, D., Brucher, M., Perrot, M., & Duchesnay, É. (2011b). Scikit-learn: Machine learning in Python. Journal of Machine Learning Research, 12(Oct), 2825–2830.
Price, M. N., Dehal, P. S., & Arkin, A. P. (2010). FastTree 2–approximately maximum-likelihood trees for large alignments. PloS One, 5(3), e9490. https://doi.org/10.1371/journal.pone.0009490

Pruesse, E., Quast, C., Knittel, K., Fuchs, B. M., Ludwig, W., Peplies, J., & Glockner, F. O. (2007a). SILVA: a comprehensive online resource for quality checked and aligned ribosomal RNA sequence data compatible with ARB. Nucleic Acids Res, 35(21), 7188–7196.

Pruesse, E., Quast, C., Knittel, K., Fuchs, B. M., Ludwig, W., Peplies, J., & Glockner, F. O. (2007b). SILVA: a comprehensive online resource for quality checked and aligned ribosomal RNA sequence data compatible with ARB. Nucleic Acids Res, 35(21), 7188–7196.

Quast, C., Pruesse, E., Yilmaz, P., Gerken, J., Schweer, T., Yarza, P., Peplies, J., & Glockner, F. O. (2013a). The SILVA ribosomal RNA gene database project: improved data processing and web-based tools. Nucleic Acids Res, 41(Database issue), D590-6.

Quast, C., Pruesse, E., Yilmaz, P., Gerken, J., Schweer, T., Yarza, P., Peplies, J., & Glockner, F. O. (2013b). The SILVA ribosomal RNA gene database project: improved data processing and web-based tools. Nucleic Acids Res, 41(Database issue), D590-6.

Robeson, M. S., O\textquoterightRourke, D. R., Kaehler, B. D., Ziemski, M., Dillon, M. R., Foster, J. T., & Bokulich, N. A. (2021). RESCRIPt: Reproducible sequence taxonomy reference database management. PLoS Computational Biology. https://doi.org/10.1371/journal.pcbi.1009581

Rognes, T., Flouri, T., Nichols, B., Quince, C., & Mahé, F. (2016a). VSEARCH: a versatile open source tool for metagenomics. PeerJ, 4, e2584. https://doi.org/10.7717/peerj.2584

Rognes, T., Flouri, T., Nichols, B., Quince, C., & Mahé, F. (2016b). VSEARCH: a versatile open source tool for metagenomics. PeerJ, 4, e2584. https://doi.org/10.7717/peerj.2584

Sørensen, T. (1948). A method of establishing groups of equal amplitude in plant sociology based on similarity of species and its application to analyses of the vegetation on Danish commons. Biol. Skr., 5, 1–34.

Weiss, S., Xu, Z. Z., Peddada, S., Amir, A., Bittinger, K., Gonzalez, A., Lozupone, C., Zaneveld, J. R., Vázquez-Baeza, Y., Birmingham, A., Hyde, E. R., & Knight, R. (2017). Normalization and microbial differential abundance strategies depend upon data characteristics. Microbiome, 5(1), 27. https://doi.org/10.1186/s40168-017-0237-y

Wes McKinney. (2010a). Data Structures for Statistical Computing in Python . In S. van der Walt & Jarrod Millman (Eds.), Proceedings of the 9th Python in Science Conference (pp. 51–56).

Wes McKinney. (2010b). Data Structures for Statistical Computing in Python . In S. van der Walt & Jarrod Millman (Eds.), Proceedings of the 9th Python in Science Conference (pp. 51–56).


Copyright Daniela Deodato year 2025.
