import sys
import re
import pandas as pd
import matplotlib.pyplot as plt

unwanted=['RF39','CCD24','Bacteroidetes_VC2.1_Bac22',' ','0319-6G20','NS11-12_marine_group','Incertae_Sedis',
'67-14','UCG-010','Clade_II','A4b','SM2D12','F082','gir-aah93h0','NS11-12_marine_grou','cvE6','KF-JG30-B3',
'env.OPS_17','37-13','Family_XI','WD2101_soil_group','JG30-KF-CM45', '0319-6G20','RF39','CCD24','','env', 'WCHB1-41']

if len(sys.argv) != 5:
    print("Usage: python3 abundace_%.py <taxa_rank> <input_file> <output_file_total> <output_file_top5>")
    sys.exit(1)

# Load data
rank= sys.argv[1]  
file = sys.argv[2]
output_file = sys.argv[3]
output_file_top5 = sys.argv[4]
df = pd.read_csv(file, low_memory=False)

# Extract phylum names from columns
order_regex = r'o__([A-Za-z0-9_\-\[\]\(\)]+)' # match after p__
order_cols = []
order_names = []
for col in df.columns:
    m = re.search(order_regex, col)
    if m and m.group(1) not in unwanted:
        order_cols.append(col)
        order_names.append(m.group(1))

# Calculate percentages per sample (row)
order_sums = df[order_cols].sum(axis=1)
df_percent = df.copy()
for col in order_cols:
    df_percent[col] = df[col] / order_sums * 100

# Build melted table for calculation
melted = df_percent.melt(
    id_vars=['temp','diet','P'],
    value_vars=order_cols,
    var_name='taxonomy',
    value_name='abundance_%'
)

# Add order column
melted[f'{rank}'] = melted['taxonomy'].apply(lambda x: re.search(order_regex, x).group(1) if re.search(order_regex, x) else 'NA')
# Calculate mean percentage abundance per diet/temp/order
pivot = melted.groupby(['temp','diet','P',f'{rank}'])['abundance_%'].mean().reset_index()
# Output as table (wide format for easier viewing)
wide_table = pivot.pivot_table(index=[f'{rank}'], columns=['temp','diet', 'P'], values='abundance_%').fillna(0)
# Rename index
wide_table.index.name = f'Bacteria_{rank}'
# Flatten column multi-index into single-level with format temp + diet + P
wide_table.columns = wide_table.columns.map(lambda x: f"{str(x[0])}{str(x[1])}{str(x[2])}")
# Save to csv
wide_table.to_csv(output_file)
#############################
# Top 5 orders per category
# Prepare dictionary to hold top 5 orders per category
top5_dict = {}
 # Sort the orders descending by abundance in the collumns of the table wide_table
for cat in wide_table.columns:
    top5_order = wide_table[cat].sort_values(ascending=False).head(5)
    top5_dict[cat] = top5_order
# Create a DataFrame from the dictionary, aligning by order index
top5_df = pd.DataFrame(top5_dict).fillna(0)
# Save to CSV
top5_df.to_csv(output_file_top5)

top5df = pd.read_csv(output_file_top5, index_col=0)
top5_df = top5df.T
other = 100 - top5_df.sum(axis=1)
top5_df['Other'] = other
cols= [c for c in top5_df.columns if c != 'Other'] + ['Other']
top5_df = top5_df[cols]

#calculate the total abundance per treatment (including "Other")
top5_df['total'] = top5_df.sum(axis=1)
# Optionally keep sorting by total, but we will enforce a specific plotting order below.
#top5_df = top5_df.sort_values('total', ascending=False)

# Define desired sample category order and reindex (missing categories will be added with zeros)
desired_order = ['14A0','14A3','14M0','14M3','14P0','14P3',
                 '20A0','20A3','20M0','20M3','20P0','20P3']
top5_df = top5_df.reindex(desired_order).fillna(0)

#eliminate the 'total' column after reindexing for plotting
top5_df.drop('total', axis=1, inplace=True)

#plotting
top5_df.plot(kind='bar', stacked=True, figsize=(12, 6))
plt.ylabel('Relative Abundance (%)')
plt.xlabel('Sample Category (Temp + Diet + P)')
plt.title('Top 5 Bacterial Order Relative Abundance by Sample Category')
plt.legend(title='Bacterial Orders', bbox_to_anchor=(1.05, 1), loc='upper left')
plt.tight_layout()
plt.savefig('Top5_Bacterial_Order_Abundance.png', dpi=300, bbox_inches='tight')
plt.show()

############# TEMPERATURE ONLY #############

# Add order column
melted[f'{rank}'] = melted['taxonomy'].apply(lambda x: re.search(order_regex, x).group(1) if re.search(order_regex, x) else 'NA')
# Calculate mean percentage abundance per diet/temp/order
pivot = melted.groupby(['temp', f'{rank}'])['abundance_%'].mean().reset_index()
# Output as table (wide format for easier viewing)
wide_table = pivot.pivot_table(index=[f'{rank}'], columns=['temp'], values='abundance_%').fillna(0)
# Rename index
wide_table.index.name = f'Bacteria_{rank}'
# Save to csv
output_file_temp = f'Bacterial_{rank}_Abundance_by_temperature.csv'
wide_table.to_csv(output_file_temp)
#############################
# Top 5 orders per category
# Prepare dictionary to hold top 5 orders per category
top5_dict = {}
 # Sort the orders descending by abundance in the collumns of the table wide_table
for cat in wide_table.columns:
    top5_order = wide_table[cat].sort_values(ascending=False).head(5)
    top5_dict[cat] = top5_order
# Create a DataFrame from the dictionary, aligning by order index
top5_df = pd.DataFrame(top5_dict).fillna(0)
# Save to CSV
output_file_top5_temp= f'Top5_Bacterial_{rank}_Abundance_by_temperature.csv'
top5_df.to_csv(output_file_top5_temp)

top5df = pd.read_csv(output_file_top5_temp, index_col=0)
top5_df = top5df.T
other = 100 - top5_df.sum(axis=1)
top5_df['Other'] = other
cols= [c for c in top5_df.columns if c != 'Other'] + ['Other']
top5_df = top5_df[cols]

#calculate the total abundance per treatment (including "Other")
top5_df['total'] = top5_df.sum(axis=1)
#sort by 'total' abundance descending
top5_df = top5_df.sort_values('total', ascending=False)
#eliminate the 'total' column after sorting for plotting
top5_df.drop('total', axis=1, inplace=True)

#plotting
top5_df.plot(kind='bar', stacked=True, figsize=(12, 6))
plt.ylabel('Relative Abundance (%)')
plt.xlabel('Sample Category (Temperature)')
plt.title(f'Top 5 Bacterial {rank} Relative Abundance by Temperature')
plt.legend(title=f'Bacterial {rank}', bbox_to_anchor=(1.05, 1), loc='upper left')
plt.tight_layout()
plt.savefig(f'Top5_Bacterial_{rank}_Abundance_by_temperature.png', dpi=300, bbox_inches='tight')
plt.show()

##################DIET ONLY ######################

# Add order column
melted[f'{rank}'] = melted['taxonomy'].apply(lambda x: re.search(order_regex, x).group(1) if re.search(order_regex, x) else 'NA')
# Calculate mean percentage abundance per diet/temp/order
pivot = melted.groupby(['diet', f'{rank}'])['abundance_%'].mean().reset_index()
# Output as table (wide format for easier viewing)
wide_table = pivot.pivot_table(index=[f'{rank}'], columns=['diet'], values='abundance_%').fillna(0)
# Rename index
wide_table.index.name = f'Bacteria_{rank}'
# Save to csv
output_file_diet = f'Bacterial_{rank}_Abundance_by_diet.csv'
wide_table.to_csv(output_file_diet)
#############################
# Top 5 orders per category
# Prepare dictionary to hold top 5 orders per category
top5_dict = {}
 # Sort the orders descending by abundance in the collumns of the table wide_table
for cat in wide_table.columns:
    top5_order = wide_table[cat].sort_values(ascending=False).head(5)
    top5_dict[cat] = top5_order
# Create a DataFrame from the dictionary, aligning by order index
top5_df = pd.DataFrame(top5_dict).fillna(0)
# Save to CSV
output_file_top5_diet= f'Top5_Bacterial_{rank}_Abundance_by_diet.csv'
top5_df.to_csv(output_file_top5_diet)

top5df = pd.read_csv(output_file_top5_diet, index_col=0)
top5_df = top5df.T
other = 100 - top5_df.sum(axis=1)
top5_df['Other'] = other
cols= [c for c in top5_df.columns if c != 'Other'] + ['Other']
top5_df = top5_df[cols]

#calculate the total abundance per treatment (including "Other")
top5_df['total'] = top5_df.sum(axis=1)
#sort by 'total' abundance descending
top5_df = top5_df.sort_values('total', ascending=False)
#eliminate the 'total' column after sorting for plotting
top5_df.drop('total', axis=1, inplace=True)

#plotting
top5_df.plot(kind='bar', stacked=True, figsize=(12, 6))
plt.ylabel('Relative Abundance (%)')
plt.xlabel('Sample Category Diet')
plt.title(f'Top 5 Bacterial {rank} Relative Abundance by Diet')
plt.legend(title=f'Bacterial {rank}', bbox_to_anchor=(1.05, 1), loc='upper left')
plt.tight_layout()
plt.savefig(f'Top5_Bacterial_{rank}_Abundance_by_diet.png', dpi=300, bbox_inches='tight')
plt.show()

###############P ONLY #######################

# Add order column
melted[f'{rank}'] = melted['taxonomy'].apply(lambda x: re.search(order_regex, x).group(1) if re.search(order_regex, x) else 'NA')
# Calculate mean percentage abundance per diet/temp/order
pivot = melted.groupby(['P', f'{rank}'])['abundance_%'].mean().reset_index()
# Output as table (wide format for easier viewing)
wide_table = pivot.pivot_table(index=[f'{rank}'], columns=['P'], values='abundance_%').fillna(0)
# Rename index
wide_table.index.name = f'Bacteria_{rank}'
# Save to csv
output_file_P = f'Bacterial_{rank}_Abundance_by_P.csv'
wide_table.to_csv(output_file_P)
#############################
# Top 5 orders per category
# Prepare dictionary to hold top 5 orders per category
top5_dict = {}
 # Sort the orders descending by abundance in the collumns of the table wide_table
for cat in wide_table.columns:
    top5_order = wide_table[cat].sort_values(ascending=False).head(5)
    top5_dict[cat] = top5_order
# Create a DataFrame from the dictionary, aligning by order index
top5_df = pd.DataFrame(top5_dict).fillna(0)
# Save to CSV
output_file_top5_P= f'Top5_Bacterial_{rank}_Abundance_by_P.csv'
top5_df.to_csv(output_file_top5_P)

top5df = pd.read_csv(output_file_top5_P, index_col=0)
top5_df = top5df.T
other = 100 - top5_df.sum(axis=1)
top5_df['Other'] = other
cols= [c for c in top5_df.columns if c != 'Other'] + ['Other']
top5_df = top5_df[cols]

#calculate the total abundance per treatment (including "Other")
top5_df['total'] = top5_df.sum(axis=1)
#sort by 'total' abundance descending
top5_df = top5_df.sort_values('total', ascending=False)
#eliminate the 'total' column after sorting for plotting
top5_df.drop('total', axis=1, inplace=True)

#plotting
top5_df.plot(kind='bar', stacked=True, figsize=(12, 6))
plt.ylabel('Relative Abundance (%)')
plt.xlabel('Sample Category (P)')
plt.title(f'Top 5 Bacterial {rank} Relative Abundance by P')
plt.legend(title=f'Bacterial {rank}', bbox_to_anchor=(1.05, 1), loc='upper left')
plt.tight_layout()
plt.savefig(f'Top5_Bacterial_{rank}_Abundance_by_P.png', dpi=300, bbox_inches='tight')
plt.show()