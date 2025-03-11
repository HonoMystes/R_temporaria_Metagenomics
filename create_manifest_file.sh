#This script makes a tsv file named manifest file with two columns
#One with the name of the sample_id and another with the path to the file

#variables
path_file=$(cat ConfigFile.yml | yq '.raw.data_directory')
manifest=$(cat ConfigFile.yml | yq '.raw.manifest')
#path="/scratch/FPM/frogs_metagenomics/01-raw_data/Rana_temporaria"
#manifest=manifest.tsv
INFILE_R1=./names_R1.txt
INFILE_R2=./names_R2.txt

#list of names
ls $path_file/*_R1.fastq.gz > $INFILE_R1


#header
echo "sample-id\tforward-absolute-filepath\treverse-absolute-filepath" > $manifest

#filling tsv
while read LINE; do
	sample_id=$(basename -s .fastq.gz $LINE | sed 's/_R1//g')
        R2=$(echo $LINE | sed 's/_R1/_R2/g')
        echo "$sample_id\t$LINE\t$R2" >> $manifest
done < $INFILE_R1


echo "manifest file created from path $path_file"
