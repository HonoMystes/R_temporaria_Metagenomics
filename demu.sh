#!/bin/bash
#Este código é a primeira parte da análise metagenómica da minha tese usando o software qiime2
#começando com a importação de amostras para .qza (artefacto) para correr no qiime2 e demultiplexing
#os ficheiros de base vão ser do tipo .fastq.gz (no diretório dos dados) e tsv para a metadata.
#O diretório com os dados tem que ter os ficheiros das sequencias: foward.fastq.gz, reverse.fastq.gz e barcode.fastq.gz
#O nome dessa pasta e o nome do ficheiro metadata seram usados como argumentos
#Criado por Daniela Deodato, Janeiro 2025

function help {
echo ""
echo "Este código é a primeira parte da análise metagenómica da minha tese usando o software qiime2"
echo "começando com a importação de amostras para .qza (artefacto) para correr no qiime2 e demultiplexing"
echo "os ficheiros de base vão ser do tipo .fastq.gz (no diretório dos dados) e tsv para a metadata."
echo "O diretório com os dados tem que ter os ficheiros das sequencias: foward.fastq.gz, reverse.fastq.gz e barcode.fastq.gz"
echo "O nome dessa pasta e o nome do ficheiro metadata seram usados como argumentos"
echo "Please make sure you have the qiime enviroment activated"
echo ""
}

#Variáveis
data=$1 #nome do diretório 
data_directory='{$data}'/ #diretório 
metadata=$2 #trocar pelo ficheiro metadata
outputDir="output_demux_results"

#Possiveis erros
#verificar se o número de argumentos está correto
if [ $# -ne 2 ];
 then
  help
  echo "ERRO: Número de argumentos errado" > Erro.1.txt
  cat Erro.1.txt
  echo "Este script requer dois argumentos para correr"
  exit 1
 fi
a pasta existe
if [ ! -d "$data_directory" ];
 then
  help
  echo "ERRO: A pasta $data_directory não existe" > Erro.2.txt
  cat Erro.2.txt
  echo "Por favor verifique se o nome da pasta está correto e se está na diretoria"
  exit 1
 fi
#verificar se o ficheiro metadata existe
if [ ! -e "$metadata" ];
 then
  help
  echo "ERRO: O ficheiro $metadata não existe" > Erro.3.txt
  cat Erro.3.txt
  echo "Por favor verifique se o nome do ficheiro metadata está correto e se está na diretoria"
  exit 1
 fi

#analysis
echo "Importing into artifact type"
qiime tools import \
   --type EMPPairedEndSequences \
   --input-path $data_directory \
   --output-path {$data}.qza

echo "Demultiplexing"
qiime demux emp-paired \
   --m-barcodes-file $metadata \
   --m-barcodes-column BarcodeSequence \
   --p-rev-comp-mapping-barcodes \ #se o barcode estiver na sequencia reverse complement
   --i-seqs {$data}.qza \
   --o-per-sample-sequences demux_{$data}.qza \
   --o-error-correction-details demux_{$data}-details.qza

#cutadapt
qiime cutadapt trim-paired \
        --i-demultiplexed-sequences $demux_{$data}.qza \
        --p-front-f CCTACGG \
        --p-front-r GACTACHV \
        --p-error-rate 0 \
        --o-trimmed-sequences trimmed-seqs_{$data}.qza \
        --verbose

#sumariazar após o demultiplexing para vizualização
echo "Summarizing demultiplexing"
qiime demux summarize \
   --i-data trimmed-seqs_{$data}.qza \
   --o-visualization trimmed-seqs_{$data}.qzv

#vizualização
echo "Preparing visualization"
qiime tools export \
  --input-path trimmed-seqs_{$data}.qzv \
  --output-path ./demux_{$data}/

echo "Check the trimmed-seqs_{$data}.qzv file to know what to do on the next step."