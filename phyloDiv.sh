#!/bin/bash
#This is the forth part of the metagenomic analysis of my thesis, using qiime2
#This script will make the phylogeny analysis and the first part of the diversity analysis
# the < | sed 's/\"//g'> is needed since the qiime enviroment adds ""

#variables
data=$1
metadata=$(cat ConfigFile.yml | yq '.raw.metadata' | sed 's/\"//g')
seqs_rep=$(cat ConfigFile.yml | yq '.tables.seqs_rep' | sed 's/\"//g')
freq_tbl=$(cat ConfigFile.yml | yq '.tables.freq_tbl' | sed 's/\"//g')
classifier=$(cat ConfigFile.yml | yq '.taxonomy.classifier' | sed 's/\"//g')
taxo=$(cat ConfigFile.yml | yq '.taxonomy.taxo_data' | sed 's/\"//g')
samp_depth=$(cat ConfigFile.yml | yq '.diversity.sampling_depth' | sed 's/\"//g')
seed=$(cat ConfigFile.yml | yq '.phylogeny.seed' | sed 's/\"//g')
rapid_boot=$(cat ConfigFile.yml | yq '.phylogeny.rapid_boot_seed' | sed 's/\"//g')
boot_rep=$(cat ConfigFile.yml | yq '.phylogeny.boot_rep' | sed 's/\"//g')
raref_cap=$(cat ConfigFile.yml | yq '.diversity.raref_cap' | sed 's/\"//g')
outputDir_viz=$(cat ConfigFile.yml | yq '.directory_name.viz_dir_div' | sed 's/\"//g')

#filter representative sequencies table with the taxonomy artifact
qiime taxa filter-table \
  --i-table $seqs_rep \
  --i-taxonomy $taxo \
  --p-mode contains \
  --p-include p__ \
  --o-filtered-table $seqs_rep

#align sequences
qiime alignment mafft \
  --i-sequences $seqs_rep \
  --o-alignment aligned_rep_seqs.qza

#phylogeny using raxml
qiime phylogeny raxml-rapid-bootstrap \
  --i-alignment aligned_rep_seqs.qza \
  --p-seed $seed \
  --p-rapid-bootstrap-seed $rapid_boot \
  --p-bootstrap-replicates $boot_rep \
  --p-substitution-model GTRCAT \
  --o-tree raxml_cat_bootstrap_tree.qza \
  --verbose
#rooting the tree to use the uniFrac diversity methods
qiime phylogeny midpoint-root \
  --i-tree raxml_cat_bootstrap_tree.qza \
  --o-rooted-tree rooted_tree.qza

#diversity analysis
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted_tree.qza \
  --i-table $freq_tbl \
  --p-sampling-depth $samp_depth \
  --m-metadata-file $metadata \
  --output-dir diversity_core_metrics

#alpha diversity see parkinson's mouse

#rarefraction
qiime diversity alpha-rarefaction \
  --i-table $freq_tbl \
  --m-metadata-file $metadata \
  --output-dir $outputDir_viz \
  --o-visualization ./$outputDir_viz/alpha_rarefaction_curves.qzv \
  --p-min-depth 10 \
  --p-max-depth 4250 #check freq_file 

qiime diversity alpha-group-significance \
  --i-alpha-diversity ./diversity_core_metrics/faith_pd_vector.qza \
  --m-metadata-file $metadata \
  --o-visualization ./$outputDir_viz/faiths_pd_statistics.qzv
qiime diversity alpha-group-significance \
 --i-alpha-diversity ./diversity_core_metrics/evenness_vector.qza \
 --m-metadata-file $metadata \
 --o-visualization ./$outputDir_viz/evenness_statistics.qzv

#analysis of variance (ANOVA) to test whether multiple effects significantly impact alpha diversity
qiime longitudinal anova \
  --m-metadata-file ./diversity_core_metrics/faith_pd_vector.qza \
  --m-metadata-file $metadata \
  --p-formula 'faith_pd ~ temperature * diet' \
  --o-visualization ./$outputDir_viz/faiths_pd_anova.qzv

#beta diversity
qiime diversity beta-group-significance \
  --i-distance-matrix diversity_core_metrics/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file $metadata \
  --m-metadata-column temperature \
  --o-visualization ./$outputDir_viz/unweighted_unifrac_temp_significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix diversity_core_metrics/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file $metadata \
  --m-metadata-column temperature \
  --o-visualization ./$outputDir_viz/weighted-unifrac_temp_significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix diversity_core_metrics/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file $metadata \
  --m-metadata-column diet \
  --o-visualization ./$outputDir_viz/unweighted_unifrac_diet_significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix diversity_core_metrics/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file $metadata \
  --m-metadata-column diet \
  --o-visualization ./$outputDir_viz/weighted_unifrac_diet_significance.qzv

#emperor plots
qiime emperor plot \
  --i-pcoa diversity_core_metrics/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file $metadata \
  --p-custom-axes lat \
  --o-visualization ./$outputDir_viz/unifrac_emperor_lat.qzv
qiime emperor plot \
  --i-pcoa diversity_core_metrics/bray_curtis_pcoa_results.qza \
  --m-metadata-file $metadata \
  --p-custom-axes lat \
  --o-visualization ./$outputDir_viz/bray_curtis_emperor_lat.qzv

#filter samples based on rarefraction depth
qiime feature-table filter-samples \
  --i-table $freq_tbl \
  --p-min-frequency $raref_cap \
  --o-filtered-table ./table_${raref_cap}.qza

qiime taxa barplot \
  --i-table ./table_${raref_cap}.qza \
  --i-taxonomy $taxo \
  --m-metadata-file $metadata \
  --o-visualization ./$outputDir_viz/taxa_${raref_cap}_barplot.qzv

#diferential abundance
qiime feature-table filter-features \
  --i-table ./table_${raref_cap}.qza \
  --p-min-frequency 50 \
  --p-min-samples 4 \
  --o-filtered-table ./table_${raref_cap}_abund.qza

#searching for differencies in the gut microbiome between temp and diet
qiime composition ancombc \
  --i-table ./table_${raref_cap}_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'diet' \
  --o-differentials ./ancombc_diet.qza

qiime composition da-barplot \
  --i-data ./ancombc_diet.qza \
  --p-significance-threshold 0.001 \
  --o-visualization ./$outputDir_viz/da_barplot_diet.qzv

qiime composition ancombc \
  --i-table ./table_${raref_cap}_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'temp' \
  --o-differentials ./ancombc_temp.qza

qiime composition da-barplot \
  --i-data ./ancombc_temp.qza \
  --p-significance-threshold 0.001 \
  --o-visualization ./$outputDir_viz/da_barplot_temp.qzv

qiime composition ancombc \
  --i-table ./table_${raref_cap}_abund.qza \
  --m-metadata-file $metadata \
  --p-formula 'diet + temp' \
  --o-differentials ./ancombc_diet_temp.qza

qiime composition da-barplot \
  --i-data ./ancombc_diet_temp.qza \
  --p-significance-threshold 0.001 \
  --o-visualization ./$outputDir_viz/da_barplot_diet_temp.qzv

