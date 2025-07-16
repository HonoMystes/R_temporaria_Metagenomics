# R_temporaria_Metagenomics

### Work in progress....
---
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
    - [taxaVsSample.py](#taxavssamplepy)
        - [Input](#input)
        - [Outputs](#outputs-3)
    - [phyloDiv.sh](#phylodivsh)
        - [Inputs](#inputs-3)
        - [Outputs](#outputs-4)
    - [Div2.sh](#div2sh)
        - [Inputs](#inputs-4)
        - [Outputs](#outputs-5)
4. [Usage](#usage-1)
5. [References](#references)
6. [Citation](#citation)
7. [Copyright](#copyright)

---
## Installing

``` bash 
git clone https://github.com/HonoMystes/R_temporaria_Metagenomics.git
```

---
## Configuration File
The *ConfigFile.yml* will be the only file to be altered depending on the data to be analyze. 
Keep in mind that the "PopName" you will see in this file will be population name, that is the argument you give in all the scripts and therefore it will need to be changed as well in the configuration file to your argument. 
The file is divided into 7 categories:
- *raw*, where is the complete path to our demultiplexed data, the name or path to our metadata file (tsv), the name for the manifest file and the number of threads to be used in the processes;
- *directory_name*, as the name indicates it has the names for the directories;
- *illumina* has the primers used in the sequencing of the samples (check which one are used for the selected NGS technology) and the identifiers of the forward and reverse read of the sequences;
- *denoise* has the minimum number of sequences per sample, truncating and trimming parameters selected after analysing the demultiplexed visualization output obtained after running the *demu.sh* script, the chimera method used, the minimum length of the overlap and the minimum abundance of potential parents of a sequence being tested as chimeric;
- *tables* has the names of the tables created (the ones created from the denoising process, the ones created after the filtering of chimeras and the ones after the filtering by taxa) in artifact and visualization form;
- *taxonomy* contains the version and target of the SILVA database used and the names for the classifier and the taxonomy file created based our data;
- *discriminants* contain a list of the columns not attributed to taxa names in the csv file obtained from the taxa bar plot of the previous step;
- Finally, the *diversity* section contains the parameters of the maximum frequency (see taxonomy filtered frequency table) and the rarefraction depth where the alpha rarefaction stabilizes (see alpha rarefaction curve file).

For a more detailed explanation check the [QIIME2](https://docs.qiime2.org/2024.10/) documentation.

---
## Scripts
Apart from the *taxaVsSample.py* script all other scripts depend on the [QIIME2](https://docs.qiime2.org/2024.10/) program.\
The raw used are demultiplexed paired-end fastq.gz files all in one directory.\
The fastq.gz files must be in one of these formats: sample_name_R1.fastq.gz or sample_name_R2.fastq.gz\
The .qza files are artifact files and .qzv are visualization files of the software QIIME2 used in this code.\
The visualization files can be viewed in [QIIME View](https://view.qiime2.org/).

The current scripts and files are:
### demu.sh
The *demu.sh* script will perform the quality control of our samples using the [fastp](https://github.com/OpenGene/fastp?tab=readme-ov-file#quality-filter) command the resulting path to that output will be used in the creation of a manifest file (.tsv file) to start importing the demultiplexed and quality checked sequences into artifact type using the tsv file created (manifest file).

#### Inputs: 
- Population name (argument);
- In the Configuration file alter the: path to the samples, the name for the manifest file, the name of the directories (demultiplxed, artifact, visualizations, quality and fastp), how the paired-end reads are tagged (Eg.: "_R1") and number of threads to be used.

#### Outputs: 
- Fastp outputs (.fastq.gz);
- Manifest file (.tsv);
- demultiplexed samples artifact (.qza);
- Demultiplxed and quality controled samples' visualization (.qzv).

### FeatureTablecreation.sh
The *FeatureTablecreation.sh* script uses the artifact file generated in the script above to filter based on a minimum number of sequences per sample and merge, denoise and filtering out chimeras using the [DADA2](https://github.com/benjjneb/dada2) package and create de feature tables (frequency and representative sequences) to be filtered by the taxonomy file.

#### Inputs:
- Population name (argument);
- In the Configuration file alter the: metadata path, number of cores to be used, the minimum number of sequences per sample, the truncation value for the right cut of the sequences and the feature tables names (with and without chimeras) both artifacts and visualizations.

#### Outputs:
- Feature Tables (frequency table and representative sequences) with and without chimeras (.qza);
- DADA2 stats, visualization and artifact files (.qzv and .qza);

### TaxoClassifyingModel.sh
The *TaxoClassifyingModel.sh* script trains the classifying model specific of the 16S for the taxonomy using the SILVA database and creates the taxonomy of our data, the taxonomy file is later used to filter the feature tables. For better analysis the taxonomy results can be visualized by aid of a bar plot.

#### Inputs:
- Population name (argument);
- In the Configuration file alter the: metadata path, number of cores to be used, the primers (check what primers were used in the sequencing method), the feature tables in artifact type (must be the same ones created in *FeatureTablecreation.sh*), the version of the SILVA database, the reference sequence target to download, name of the classifier and the taxonomy file.

#### Outputs:
- Silva database outputs for the creation of the classifier (.qza);
- Classifier (.qza);
- Taxonomy file (.qza);
- Feature tables (frequency table and representative sequences) filtered by taxa (.qza and for the frequency table also .qzv);
- Taxonomy Bar Plot.

### taxaVsSample.py
The *taxaVsSample.py* script is a supplementary code to help in the analysis of the taxa found in our samples against a condition(column) in our data. To use this script you need the to download the csv file, from the taxonomy bar plot obtained in the previous script and then indicate wich rank and variable in focus (condition) do we want to analyse.The output generated will make a Venn diagram and a txt file detailing the specific and in common taxa against the condition(column) selected. 

#### Constraints:
The condition(column) must either have a total of 2 or 3 different variables to analysis. 

#### Input:
- csv file from the taxa bar plot

#### Outputs:
- Venn diagram;
- txt file with the taxa in each point of the venn diagram.

### phyloDiv.sh
The *phyloDiv.sh* performs the phylogeny and alpha rarefaction analysis.

#### Inputs:
- Population name (argument);
- In the Configuration file alter the: name of the feature tables (frequency and representative sequences) artifact files filtered by taxonomy, maximum depth value(the value is chosen by observing the taxonomy filtered frequency table number of maximum frequency. tip: check Median Frequency), name of the phylogeny directory and the diversity visualizations directory. 

#### Outputs:
- Aligned sequence (.qza);
- Masked aligned sequences (.qza);
- Rooted and unrooted tree (.qza);
- Alpha rarefaction curve plot (.qzv).

### Div2.sh
The *Div2.sh* script performs the alpha and beta diversity analysis after determining the rarefaction curve with the visualization output created above it also performs the differential analysis of the abundance in our data.

#### Inputs:
- Population name (argument);
- In the Configuration file alter the: metadata file path, name of the feature tables (frequency and representative sequences) artifact files filtered by taxonomy and the number of rarefaction depth

#### Outputs:
- Diversity core metrics based on phylogeny (.qza and .qzv);
- Alpha diversity statistics (evenness, faith_pd and anova faith_pd) (.qzv);
- Beta diversity statistics (weighted and unweighted unifraq significances) (.qzv);
- Differential abundance analysis outputs (.qza and .qzv).

---
## Manual installation

This section is here in case you don't have docker and/or prefer to have the programs installed in your machine.\
Before starting the analysis remember to download and activate de [qiime2](https://docs.qiime2.org/2024.10/install/native/) amplicon environment.
``` bash
conda update conda \
wget -O "https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml" \
conda env create -n qiime2-amplicon-2024.10 --file https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml \
conda activate qiime2-amplicon-2024.10 \
conda install -c bioconda fastp \
snap install yq
```

For the python script we need to install:
``` bash
pip install pyyaml \
pip install pandas \
pip install matplotlib-venn
```
#### Notes:
If the installing of the packages is not working try:
``` bash
sudo apt install pyhton3-pyyaml \
sudo apt install pyhton3-pandas \
sudo apt install pyhton3-matplotlib-venn
```
If the instalation is performed in a conda eviroment do this insted: \
`conda create -n <env_name>`
```bash
conda install pyyaml
conda install pandas
conda install matplotlib
conda install matplotlib-venn
```
In case the conda enviroment for qiime2 (ver.24.10) is no longer available there is a backup in the repository `https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml`

---
## Usage
Update the ConfigFile.yml to your desire and then the analysis by start with running the *demu.sh* script:\
As pointed out above the "PopName" argument refers to the population name in study and must also be edited in the configuration file to your preference.
```bash
demu.sh PopName 
```

After analyzing the output *trimmed-seqs_PopName.qzv* the denoise section of the configuration file is altered for our desired values of minimum number of sequences per sample and truncation value for the right cut of the sequences. The *FeatureTablecreation.sh* is next:
```bash
FeatureTablecreation.sh PopName
```
With the feature tables created we then perform the taxonomic analysis by running the command:
```bash
TaxoClassifyingModel.sh PopName
```
After the download of the csv file in the taxa bar plot we run:
```bash
python3 taxaVsSample.py <input_file> <taxonomic_rank> <collumn_in_focous> <output_file>
```
#### Note:
Make sure that the downloaded csv file taxonomic rank is the same as the one in the command. \
Example:\
level-1.csv -> kingdom\
level-2.csv -> phylum\
level-3.csv -> class\
level-4.csv -> order\
level-5.csv -> family\
level-6.csv -> genus

To start the diversity analysis we must first perform the phylogeny analysis and the alpha rarefaction curve. That is done by running the command:
```bash
phyloDiv.sh PopName
```
The last script to run will perform the alpha and beta diversity analysis as well as the differential abundance analysis with the command:
```bash
Div2.sh PopName
```
---
## References

Amir, A., McDonald, D., Navas-Molina, J. A., Kopylova, E., Morton, J. T., Xu, Z. Z., Kightley, E. P., Thompson, L. R., Hyde, E. R., Gonzalez, A., & Knight, R. (2017). Deblur rapidly resolves single-nucleotide community sequence patterns. MSystems, 2(2), e00191-16.

Bokulich, N. A., Kaehler, B. D., Rideout, J. R., Dillon, M., Bolyen, E., Knight, R., Huttley, G. A., & Caporaso, J. G. (2018). Optimizing taxonomic classification of marker-gene amplicon sequences with QIIME 2’s q2-feature-classifier plugin. Microbiome, 6(1), 90. https://doi.org/10.1186/s40168-018-0470-z

Bolyen E, Rideout JR, Dillon MR, Bokulich NA, Abnet CC, Al-Ghalith GA, Alexander H, Alm EJ, Arumugam M, Asnicar F, Bai Y, Bisanz JE, Bittinger K, Brejnrod A, Brislawn CJ, Brown CT, Callahan BJ, Caraballo-Rodríguez AM, Chase J, Cope EK, Da Silva R, Diener C, Dorrestein PC, Douglas GM, Durall DM, Duvallet C, Edwardson CF, Ernst M, Estaki M, Fouquier J, Gauglitz JM, Gibbons SM, Gibson DL, Gonzalez A, Gorlick K, Guo J, Hillmann B, Holmes S, Holste H, Huttenhower C, Huttley GA, Janssen S, Jarmusch AK, Jiang L, Kaehler BD, Kang KB, Keefe CR, Keim P, Kelley ST, Knights D, Koester I, Kosciolek T, Kreps J, Langille MGI, Lee J, Ley R, Liu YX, Loftfield E, Lozupone C, Maher M, Marotz C, Martin BD, McDonald D, McIver LJ, Melnik AV, Metcalf JL, Morgan SC, Morton JT, Naimey AT, Navas-Molina JA, Nothias LF, Orchanian SB, Pearson T, Peoples SL, Petras D, Preuss ML, Pruesse E, Rasmussen LB, Rivers A, Robeson MS, Rosenthal P, Segata N, Shaffer M, Shiffer A, Sinha R, Song SJ, Spear JR, Swafford AD, Thompson LR, Torres PJ, Trinh P, Tripathi A, Turnbaugh PJ, Ul-Hasan S, van der Hooft JJJ, Vargas F, Vázquez-Baeza Y, Vogtmann E, von Hippel M, Walters W, Wan Y, Wang M, Warren J, Weber KC, Williamson CHD, Willis AD, Xu ZZ, Zaneveld JR, Zhang Y, Zhu Q, Knight R, and Caporaso JG. 2019. Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2. Nature Biotechnology 37: 852–857. https://doi.org/10.1038/s41587-019-0209-9

Callahan, B. J., McMurdie, P. J., Rosen, M. J., Han, A. W., Johnson, A. J. A., & Holmes, S. P. (2016). DADA2: high-resolution sample inference from Illumina amplicon data. Nature Methods, 13(7), 581. https://doi.org/10.1038/nmeth.3869

Jaccard, P. (1908). Nouvelles recherches sur la distribution floral. Bull. Soc. Vard. Sci. Nat, 44, 223–270.

Katoh, K., & Standley, D. M. (2013). MAFFT multiple sequence alignment software version 7: improvements in performance and usability. Molecular Biology and Evolution, 30(4), 772–780. https://doi.org/10.1093/molbev/mst010

Lane, D. (1991). 16S/23S rRNA sequencing. In E. Stackebrandt & M. Goodfellow (Eds.), Nucleic Acid Techniques in Bacterial Systematics (pp. 115–175). John Wiley.

Lin, H., & Peddada, S. D. (2020). Analysis of compositions of microbiomes with bias correction. Nature Communications, 11(1), 3514. https://doi.org/10.1038/s41467-020-17041-7

Martin, M. (2011). Cutadapt removes adapter sequences from high-throughput sequencing reads. EMBnet. Journal, 17(1), pp-10. https://doi.org/10.14806/ej.17.1.200

McDonald, D., Clemente, J. C., Kuczynski, J., Rideout, J. R., Stombaugh, J., Wendel, D., Wilke, A., Huse, S., Hufnagle, J., Meyer, F., Knight, R., & Caporaso, J. G. (2012). The Biological Observation Matrix (BIOM) format or: how I learned to stop worrying and love the ome-ome. GigaScience, 1(1), 7. https://doi.org/10.1186/2047-217X-1-7

Pedregosa, F., Varoquaux, G., Gramfort, A., Michel, V., Thirion, B., Grisel, O., Blondel, M., Prettenhofer, P., Weiss, R., Dubourg, V., Vanderplas, J., Passos, A., Cournapeau, D., Brucher, M., Perrot, M., & Duchesnay, É. (2011). Scikit-learn: Machine learning in Python. Journal of Machine Learning Research, 12(Oct), 2825–2830.

Price, M. N., Dehal, P. S., & Arkin, A. P. (2010). FastTree 2–approximately maximum-likelihood trees for large alignments. PloS One, 5(3), e9490. https://doi.org/10.1371/journal.pone.0009490

Pruesse, E., Quast, C., Knittel, K., Fuchs, B. M., Ludwig, W., Peplies, J., & Glockner, F. O. (2007). SILVA: a comprehensive online resource for quality checked and aligned ribosomal RNA sequence data compatible with ARB. Nucleic Acids Res, 35(21), 7188–7196.

Quast, C., Pruesse, E., Yilmaz, P., Gerken, J., Schweer, T., Yarza, P., Peplies, J., & Glockner, F. O. (2013). The SILVA ribosomal RNA gene database project: improved data processing and web-based tools. Nucleic Acids Res, 41(Database issue), D590-6.

Robeson, M. S., O\textquoterightRourke, D. R., Kaehler, B. D., Ziemski, M., Dillon, M. R., Foster, J. T., & Bokulich, N. A. (2021). RESCRIPt: Reproducible sequence taxonomy reference database management. PLoS Computational Biology. https://doi.org/10.1371/journal.pcbi.1009581

Rognes, T., Flouri, T., Nichols, B., Quince, C., & Mahé, F. (2016). VSEARCH: a versatile open source tool for metagenomics. PeerJ, 4, e2584. https://doi.org/10.7717/peerj.2584

Shannon, C. E. (1948). A mathematical theory of communication. The Bell System Technical Journal, 27(3), 379–423, 623–656. https://doi.org/10.1002/j.1538-7305.1948.tb01338.x

Shifu Chen. 2023. Ultrafast one-pass FASTQ data preprocessing, quality control, and deduplication using fastp. iMeta 2: e107. https://doi.org/10.1002/imt2.107

Shifu Chen, Yanqing Zhou, Yaru Chen, Jia Gu; fastp: an ultra-fast all-in-one FASTQ preprocessor, Bioinformatics, Volume 34, Issue 17, 1 September 2018, Pages i884–i890, https://doi.org/10.1093/bioinformatics/bty560

Sørensen, T. (1948). A method of establishing groups of equal amplitude in plant sociology based on similarity of species and its application to analyses of the vegetation on Danish commons. Biol. Skr., 5, 1–34.

Weiss, S., Xu, Z. Z., Peddada, S., Amir, A., Bittinger, K., Gonzalez, A., Lozupone, C., Zaneveld, J. R., Vázquez-Baeza, Y., Birmingham, A., Hyde, E. R., & Knight, R. (2017). Normalization and microbial differential abundance strategies depend upon data characteristics. Microbiome, 5(1), 27. https://doi.org/10.1186/s40168-017-0237-y

Wes McKinney. (2010). Data Structures for Statistical Computing in Python . In S. van der Walt & Jarrod Millman (Eds.), Proceedings of the 9th Python in Science Conference (pp. 51–56).

---
## Citation

soon...

---
## Copyright

Copyright Daniela Deodato year 2025.
