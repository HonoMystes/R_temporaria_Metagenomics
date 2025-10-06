import sys
import re
import pandas as pd

unwanted=['RF39','CCD24','Bacteroidetes_VC2.1_Bac22',' ','0319-6G20','NS11-12_marine_group','Incertae_Sedis',
'67-14','UCG-010','Clade_II','A4b','SM2D12','F082','gir-aah93h0','NS11-12_marine_grou','cvE6','KF-JG30-B3',
'env.OPS_17','37-13','Family_XI','WD2101_soil_group','JG30-KF-CM45', '0319-6G20','RF39','CCD24','','env', 'WCHB1-41']

if len(sys.argv) != 4:
    print("Usage: python3 abundace_%.py <input_file> <output_file_total> <output_file_top5>")
    sys.exit(1)

# Load data
file = sys.argv[1]
output_file = sys.argv[2]
output_file_top5 = sys.argv[3]
df = pd.read_csv(file, low_memory=False)

# Extract order names from columns
order_regex = r'o__([A-Za-z0-9_\-\[\]\(\)]+)' # match after o__
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
melted['order'] = melted['taxonomy'].apply(lambda x: re.search(order_regex, x).group(1) if re.search(order_regex, x) else 'NA')
# Calculate mean percentage abundance per diet/temp/order
pivot = melted.groupby(['temp','diet','P','order'])['abundance_%'].mean().reset_index()
# Output as table (wide format for easier viewing)
wide_table = pivot.pivot_table(index=['order'], columns=['temp','diet', 'P'], values='abundance_%').fillna(0)
# Rename index
wide_table.index.name = 'Bacteria_order'
# Flatten column multi-index into single-level with format temp + diet + P, e.g. 14A0 (insted of doing it in the document))
wide_table.columns = wide_table.columns.map(lambda x: f"{x[0]}{x[1]}{x[2]}")
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