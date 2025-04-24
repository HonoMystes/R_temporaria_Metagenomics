#Aditional script for taxa analysis 
#Copyright Daniela Deodato 2025
import sys
import yaml
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib_venn import venn2
from matplotlib_venn import venn3

if len(sys.argv) != 4:
    print("Usage: python3 taxaVsSample.py <input_file> <collumn_in_focous> <output_file>")
    sys.exit(1)

# Get command line arguments
input_file = sys.argv[1]
focous = sys.argv[2]
output_file = sys.argv[3]


df = pd.read_csv(input_file)
with open('ConfigFile.yml', 'r') as f:
    metadata=yaml.safe_load(f) 

metadata_values=metadata['discriminats']
taxa_col = [col for col in df.columns if col not in metadata_values]
numb_var = df[focous].nunique()
dif_var = df[focous].unique()
print(f'Number of different variables: {numb_var}')
print(f'Variables: {dif_var}')

if numb_var == 2:
    taxa1=set(df[df[focous ] == dif_var[0]] [taxa_col].loc[:,(df[df[focous] == dif_var[0]] [taxa_col] != 0).any()].columns)
    taxa2=set(df[df[focous ] == dif_var[1]] [taxa_col].loc[:,(df[df[focous] == dif_var[1]] [taxa_col] != 0).any()].columns)
    both=taxa1 & taxa2
    only_1=taxa1 - taxa2
    only_2=taxa2 - taxa1
    results_1=f'Taxa present only in {dif_var[0]}: ({len(only_1)}), {only_1}'
    results_2=f'Taxa present only in {dif_var[1]}: ({len(only_2)}), {only_2}'
    results_1_2=f'Taxa present only in both {focous} {dif_var}: ({len(both)}), {both}'
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
    venn2([taxa1, taxa2], set_labels=(dif_var[0],dif_var[1]), set_colors=('skyblue', 'darksalmon'))
    plt.title(f"Taxa in based on {focous}")
    plt.show()
elif numb_var == 3:
    taxa1=set(df[df[focous ] == dif_var[0]] [taxa_col].loc[:,(df[df[focous] == dif_var[0]] [taxa_col] != 0).any()].columns)
    taxa2=set(df[df[focous ] == dif_var[1]] [taxa_col].loc[:,(df[df[focous] == dif_var[1]] [taxa_col] != 0).any()].columns)
    taxa3=set(df[df[focous ] == dif_var[2]] [taxa_col].loc[:,(df[df[focous] == dif_var[2]] [taxa_col] != 0).any()].columns)
    both=taxa1 & taxa2 & taxa3
    only_1=taxa1 - taxa2 - taxa3
    only_2=taxa2 - taxa1 - taxa3
    only_3=taxa3 - taxa2 - taxa1
    results_1=f'Taxa present only in {dif_var[0]}: ({len(only_1)}), {only_1}'
    results_2=f'Taxa present only in {dif_var[1]}: ({len(only_2)}), {only_2}'
    results_3=f'Taxa present only in {dif_var[2]}: ({len(only_3)}), {only_3}'
    results_1_2=f'Taxa present only in {dif_var[0]} and {dif_var[1]}: ({len(taxa1&taxa2-taxa3)}), {taxa1&taxa2-taxa3}'
    results_1_3=f'Taxa present only in {dif_var[0]} and {dif_var[2]}: ({len(taxa1&taxa3-taxa2)}), {taxa1&taxa3-taxa2}'
    results_3_2=f'Taxa present only in {dif_var[2]} and {dif_var[1]}: ({len(taxa3&taxa2-taxa1)}), {taxa3&taxa2-taxa1}'
    results_1_2_3=f'Taxa present in all {focous} {dif_var}: ({len(both)}), {both}'
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
    venn3([taxa1, taxa2, taxa3], set_labels=(dif_var[0],dif_var[1],dif_var[2]), set_colors=('firebrick', 'goldenrod', 'palegreen'))
    plt.title(f"Taxa in based on {focous}")
    plt.show()
else:
    print("The collumns must have either 2 or 3 different variables")