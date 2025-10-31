#!/bin/bash
# This code is excuted after the demu.sh script 
# Using the existant manifest file created in the script before,
# switches the original path with the sequnces from fastp for the raw ones
# in a new manifest file, that file is then imported to qiime and summarized
# this enables the comparison of the reads before and after Quality Control

#stops if error
set -e

function help {
echo ""
 echo "This code is excuted after the demu.sh script" 
 echo "Using the existant manifest file created in the script before,"
 echo " switches the original path with the sequnces from fastp for the raw ones"
 echo " in a new manifest file, that file is then imported to qiime and summarized"
 echo "this enables the comparison of the reads before and after Quality Control"
 echo ""
}

data=$1 #directory name
path_file=$(cat ConfigFile.yml | yq '.raw.data_directory' | sed 's/\"//g')
manifest=$(cat ConfigFile.yml | yq '.raw.manifest' | sed 's/\"//g')
quality=$(cat ConfigFile.yml | yq '.directory_name.quality' | sed 's/\"//g')
artifact=$(cat ConfigFile.yml | yq '.directory_name.artifact' | sed 's/\"//g')
visualizations=$(cat ConfigFile.yml | yq '.directory_name.visualizations' | sed 's/\"//g')

#Possible errors
#check the number of arguments
if [ $# -ne 1 ];
 then
  help
  echo "ERROR: wrong number of arguments"
  echo "This script requires only one argument to run"
  exit 1
 fi

old=20251004_rana/$quality/out_
new=seqs/

#create new manifest based on the original
sed "s!${old}!${new}!g" $manifest > manifest_bfQC.tsv

#import into qiime artifact
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest_bfQC.tsv \
  --output-path $artifact/bfQc_$data.qza \
  --input-format PairedEndFastqManifestPhred33V2

#check to see if the import worked
 #verify if the manifest file exists
if [ ! -e "$artifact/bfQC_$data.qza" ];
 then
  help
  echo "ERROR: file $artifact/bfQC_$data.qza  not found"
  echo "Please check if the name is correct and the file is in the current directory"
  exit 1
  else
  echo "$artifact/bfQC_$data.qza file present"
fi

#summarize the artifact to analyze the raw reads
#Summarize for vizualization
echo "Summarizing demultiplexing"
qiime demux summarize \
   --i-data $artifact/bfQC_$data.qza \
   --o-visualization $visualizations/$data.qzv

echo "Ready to be compared!"
