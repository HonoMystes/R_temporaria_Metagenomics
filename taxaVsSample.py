#Aditional script for taxa analysis 
#Copyright Daniela Deodato 2025
import sys
import yaml
import pandas as pd
import matplotlib 
matplotlib.use('Agg')
from matplotlib import pyplot as plt
from matplotlib_venn import venn2
from matplotlib_venn import venn3

unwanted = ['RF39','CCD24','Bacteroidetes_VC2.1_Bac22',' ','0319-6G20','NS11-12_marine_group','Incertae_Sedis',
'67-14','UCG-010','Clade_II','A4b','SM2D12','F082','gir-aah93h0','NS11-12_marine_grou','cvE6','KF-JG30-B3',
'env.OPS_17','37-13','Family_XI','WD2101_soil_group','JG30-KF-CM45', '0319-6G20','RF39','CCD24','Candidatus_Nomurabacteria','']

def only_phylum(list):
    p=[]
    for name in list:
        start=name.find('p__')
        if start !=-1:
            family=name[start+3:].split(';')[0]
            if family not in unwanted:
                p.append(family)
    return p

def only_class(list):
    cla=[]
    for name in list:
        start=name.find('c__')
        if start !=-1:
            classe=name[start+3:].split(';')[0]
            if classe not in unwanted:
                cla.append(classe)
    return cla

def only_order(list):
    o=[]
    for name in list:
        start=name.find('o__')
        if start !=-1:
            order=name[start+3:].split(';')[0]
            if order not in unwanted:
                o.append(order)
    return o

def only_family(list):
    fam=[]
    for name in list:
        start=name.find('f__')
        if start !=-1:
            family=name[start+3:].split(';')[0]
            if family not in unwanted:
                fam.append(family)
    return fam

def only_genus(list):
    g=[]
    for name in list:
        start=name.find('g__')
        if start !=-1:
            family=name[start+3:].split(';')[0]
            if family not in unwanted:
                g.append(family)
    return g

def only_species(list):
    s=[]
    for name in list:
        start=name.find('s__')
        if start !=-1:
            family=name[start+3:].split(';')[0]
            if family not in unwanted:
                s.append(family)
    return s

if len(sys.argv) != 5:
    print("Usage: python3 taxaVsSample.py <input_file> <taxonomic rank> <collumn_in_focous> <output_file>")
    sys.exit(1)

taxonomic_ranks=['phylum', 'class', 'order', 'family', 'genus', 'species']
# Get command line arguments
input_file = sys.argv[1]
rank = sys.argv[2]
focous = sys.argv[3]
output_file = sys.argv[4]
print(rank)
if rank in taxonomic_ranks:
    rank = sys.argv[2]
else:
    print(f"Invalid taxonomic rank. Choose from: {', '.join(taxonomic_ranks)}")
    sys.exit(1)

def only(var):
    if rank == 'phylum':
        return only_phylum(var)
    elif rank == 'class':
        return only_class(var)
    elif rank == 'order':
        return only_order(var)
    elif rank == 'family':
        return only_family(var)
    elif rank == 'genus':
        return only_genus(var)
    elif rank == 'species':
        return only_species(var)
    
df = pd.read_csv(input_file)
with open('ConfigFile.yml', 'r') as f:
    metadata=yaml.safe_load(f) 

metadata_values=metadata['discriminants']
taxa_col = [col for col in df.columns if col not in metadata_values]
numb_var = df[focous].nunique()
dif_var = df[focous].unique()
print(f'Number of different variables: {numb_var}')
print(f'Variables: {dif_var}')

if numb_var == 2:
    taxa1=set(df[df[focous] == dif_var[0]] [taxa_col].loc[:,(df[df[focous] == dif_var[0]] [taxa_col] != 0).any()].columns)
    taxa2=set(df[df[focous] == dif_var[1]] [taxa_col].loc[:,(df[df[focous] == dif_var[1]] [taxa_col] != 0).any()].columns)
    both=taxa1 & taxa2
    both=only(both)
    only_1=taxa1 - taxa2
    only_1=only(only_1)
    print (len(only_1))
    only_2=taxa2 - taxa1
    only_2=only(only_2)
    results_1=f'Taxa present only in {dif_var[0]}: ({len(only_1)}), {only_1}'
    results_2=f'Taxa present only in {dif_var[1]}: ({len(only_2)}), {only_2}'
    results_1_2=f'Taxa present only in both {focous} {dif_var}: ({len(both)}), {both}'
    #output file for var 0
    with open(f"{dif_var[0]}_{focous}.txt", "w") as f:
        for name in only_1:
            f.write(f'{name}\n')
        f.close()
    #output file for var 1
    with open(f"{dif_var[1]}_{focous}.txt", "w") as f:
        for name in only_2:
            f.write(f'{name}\n')
        f.close()
    #output writting
    with open(output_file, "w") as f:
        f.write(f"Taxa analysis based on {focous}\n")
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_1}\n')
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_2}\n')
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_1_2}\n')
        f.write("---------------------------------------------------------------\n")
        f.close()
    #venn diagram
    plt.figure(figsize=(6,6))
    venn2([set(only(taxa1)), set(only(taxa2))], set_labels=(dif_var[0],dif_var[1]), set_colors=('darksalmon','skyblue' ))
    plt.title(f"Taxa in population based on {focous}")
    plt.savefig(f"Population_taxa_{rank}_ {focous}.png", dpi=300, bbox_inches='tight')
elif numb_var == 3:
    taxa1=set(df[df[focous ] == dif_var[0]] [taxa_col].loc[:,(df[df[focous] == dif_var[0]] [taxa_col] != 0).any()].columns)
    taxa2=set(df[df[focous ] == dif_var[1]] [taxa_col].loc[:,(df[df[focous] == dif_var[1]] [taxa_col] != 0).any()].columns)
    taxa3=set(df[df[focous ] == dif_var[2]] [taxa_col].loc[:,(df[df[focous] == dif_var[2]] [taxa_col] != 0).any()].columns)
    both=taxa1 & taxa2 & taxa3
    both=only(both)
    only_1=taxa1 - taxa2 - taxa3
    only_1=only(only_1)
    only_2=taxa2 - taxa1 - taxa3
    only_2=only(only_2)
    only_3=taxa3 - taxa2 - taxa1
    only_3=only(only_3)
    only_1_2=taxa1&taxa2-taxa3
    only_1_2=only(only_1_2)
    only_1_3=taxa1&taxa3-taxa2
    only_1_3=only(only_1_3)
    only_3_2=taxa3&taxa2-taxa1
    only_3_2=only(only_3_2)
    results_1=f'Taxa present only in {dif_var[0]}: ({len(only_1)}), {only_1}'
    results_2=f'Taxa present only in {dif_var[1]}: ({len(only_2)}), {only_2}'
    results_3=f'Taxa present only in {dif_var[2]}: ({len(only_3)}), {only_3}'
    results_1_2=f'Taxa present only in {dif_var[0]} and {dif_var[1]}: ({len(only_1_2)}), {only_1_2}'
    results_1_3=f'Taxa present only in {dif_var[0]} and {dif_var[2]}: ({len(only_1_3)}), {only_1_3}'
    results_3_2=f'Taxa present only in {dif_var[2]} and {dif_var[1]}: ({len(only_3_2)}), {only_3_2}'
    results_1_2_3=f'Taxa present in all {focous} {dif_var}: ({len(both)}), {both}'
    with open(f"{dif_var[0]}_{focous}.txt", "w") as f:
        for name in only_1:
            f.write(f'{name}\n')
        f.close()
    #output file for var 1
    with open(f"{dif_var[1]}_{focous}.txt", "w") as f:
        for name in only_2:
            f.write(f'{name}\n')
        f.close()
    #output file for var 1
    with open(f"{dif_var[2]}_{focous}.txt", "w") as f:
        for name in only_3:
            f.write(f'{name}\n')
        f.close()    
    #output writting
    with open(output_file, "w") as f:
        f.write(f"Taxa analysis based on {focous}\n")
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_1}\n')
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_2}\n')
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_3}\n')
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_1_2}\n')
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_1_3}\n')
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_3_2}\n')
        f.write("---------------------------------------------------------------\n")
        f.write(f'{results_1_2_3}\n')
        f.write("---------------------------------------------------------------\n")
        f.close()
    #venn diagram
    plt.figure(figsize=(6,6))
    venn3([set(only(taxa1)), set(only(taxa2)), set(only(taxa3))], set_labels=(dif_var[0],dif_var[1],dif_var[2]), set_colors=('firebrick', 'goldenrod', 'palegreen'))
    plt.title(f"Taxa in population based on {focous}")
    plt.savefig(f"Population_taxa_{rank}_ {focous}.png", dpi=300, bbox_inches='tight')
else:
    print("The collumns must have either 2 or 3 different variables")