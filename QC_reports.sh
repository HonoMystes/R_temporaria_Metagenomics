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
 echo "this enables the comparison of the reads before and after Quality Control"
 echo "By excuting fastqc on the sequences before and after fastp"
 echo "multiqc is then used to summarise the reports from fastqc"
 echo "Note: this script must be run in an environment with multiqc and fastqc"
 echo ""
}

quality=$(cat ConfigFile.yml | yq '.directory_name.quality' | sed 's/\"//g')
path_file=$(cat ConfigFile.yml | yq '.raw.data_directory' | sed 's/\"//g')
threads=$(cat ConfigFile.yml | yq 'raw.threads' | sed 's/\"//g')

# Before QC
fastqc $path_file/*.fastq.gz -t $threads
multiqc $path_file/*.zip

# After QC
fastqc ./$quality\*.fastq.gz -t $threads
multiqc ./$quality/*.zip

echo "Ready to be compared!"
