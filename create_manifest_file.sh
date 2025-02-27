#This script makes a tsv file named manifest file with two columns
#One with the name of the sample_id and another with the path to the file

#variables
#path=$(cat ConfigFile.yml | yq '.raw.data_directory)
#manifest=$(cat ConfigFile.yml | yq '.raw.manifest)
path="/scratch/FPM/frogs_metagenomics/01-raw_data/Rana_temporaria"
manifest=manifest.tsv
INFILE=./names.txt

#list of names
ls $path/*.fastq.gz > $INFILE

#header
echo "sample_id\tpath" > $manifest

#filling tsv
for LINE in $(cat $INFILE)
do
        sample_id=$(basename -s .fastq.gz $LINE)
        echo "$sample_id\t$LINE" >> $manifest
done

echo "manifest file created from path $path"