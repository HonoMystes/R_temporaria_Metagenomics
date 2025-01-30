#!/bin/bash
#Este código é a segunda parte da análise metagenómica da minha tese usando o software qiime2
#depois de realizado o demultiplexing e analisádo o "interactive Quality Plot" no ficheiro demux_{$data}.qzv 
# durante o decorrer do script inserem-se os valores que se pede com base na análise do ficheiro demux_{$data}.qzv
#Os argumentos usados neste script são o nome do diretório com os ficheiros originais e o ficheiro metadata
#Criado por Daniela Deodato, Janeiro 2025

function help {
echo ""
echo "Este código é a segunda parte da análise metagenómica da minha tese usando o software qiime2"
echo "depois de realizado o demultiplexing e analisádo o "interactive Quality Plot" no ficheiro demux_{$data}.qzv "
echo "durante o decorrer do script inserem-se os valores que se pede com base na análise do ficheiro demux_{$data}.qzv."
echo "Os argumentos usados neste script são o nome do diretório com os ficheiros originais e o ficheiro metadata"
echo ""
}

#Variáveis
data = $1 #nome do dirétório com as sequencias
demux_file = trimmed-seqs_{$data}.qzv
metadata = $2 #trocar pelo ficheiro metadata

num_min_seq = $(cat ConfigFile.yml | yq '.size.num_min_seq')
trim_forward = $(cat ConfigFile.yml | yq '.trim.trim_forward')
trim_reverse = $(cat ConfigFile.yml | yq '.trim.trim_reverse')
trunc_forward = $(cat ConfigFile.yml | yq '.trunc.trunc_forward')
trunc_reverse = $(cat ConfigFile.yml | yq '.trunc.trunc_reverse')


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

#verificar se a pasta existe
if [ ! -e "$demux_file" ];
 then
  help
  echo "ERRO: O ficheiro $demux_file não existe" > Erro.2.txt
  cat Erro.2.txt
  echo "Por favor verifique se o nome do ficheiro está correto e se está na diretoria"
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

 #filtrar amostras

qiime demux filter-samples \
  --i-demux demux_{$data}.qza \
  --m-metadata-file ./demux_{$data}/per-sample-fastq-counts.tsv \
  --p-where 'CAST([forward sequence count] AS INT) > {$num_min_seq}' \  #alterara para número de sequencias que se quer
  --o-filtered-demux demux_{$data}.qza
###
#denoising

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux_{$data}.qza \ #alterar os seguintes parametros baseado nos nossos dados
  --p-trim-left-f $trim_forward \ 
  --p-trim-left-r $trim_reverse \
  --p-trunc-len-f $trunc_forward \
  --p-trunc-len-r $trunc_reverse \
  --o-table table_{$data}.qza \
  --o-representative-sequences rep-seqs_{$data}.qza \
  --o-denoising-stats denoising-stats_{$data}.qza
###
#Feature tables
qiime feature-table summarize \
  --i-table table_{$data}.qza \
  --o-visualization table_{$data}.qzv \
  --m-sample-metadata-file $metadata

qiime feature-table tabulate-seqs \
  --i-data rep-seqs_{$data}.qza \
  --o-visualization rep-seqs_{$data}.qzv

qiime metadata tabulate \
  --m-input-file denoising-stats_{$data}.qza \
  --o-visualization denoising-stats_{$data}.qzv

###Exclude Chimeras

echo "Examining for chimeras"
echo "Running de novo" 
qiime vsearch uchime-denovo \
  --i-table table_{$data}.qza \
  --i-sequences rep-seqs_{$data}.qza \
  --output-dir {$data}_uchime-dn-out

qiime metadata tabulate \
  --m-input-file {$data}_uchime-dn-out/stats.qza \
  --o-visualization {$data}_uchime-dn-out/stats.qzv

qiime feature-table filter-features \
  --i-table table_{$data}.qza \
  --m-metadata-file {$data}_uchime-dn-out/nonchimeras.qza \
  --o-filtered-table {$data}_uchime-dn-out/table-nonchimeric-wo-borderline.qza
qiime feature-table filter-seqs \
  --i-data rep-seqs_{$data}.qza \
  --m-metadata-file {$data}_uchime-dn-out/nonchimeras.qza \
  --o-filtered-data {$data}_uchime-dn-out/rep-seqs-nonchimeric-wo-borderline.qza
qiime feature-table summarize \
  --i-table {$data}_uchime-dn-out/table-nonchimeric-wo-borderline.qza \
  --o-visualization {$data}_uchime-dn-out/table-nonchimeric-wo-borderline.qzv

echo "check {$data}_uchime-dn-out/table-nonchimeric-wo-borderline.qzv to know what to do on script phyloDiv.sh"