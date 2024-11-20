import pyarrow.feather as feather
import pandas as pd
from tqdm import tqdm

def display_feather_file(file_path):
    # Read the Feather file into a PyArrow Table with a progress bar
    with tqdm(total=1, desc="Reading Feather file") as pbar:
        table = feather.read_table(file_path)
        pbar.update(1)
    
    # Convert the PyArrow Table to a Pandas DataFrame for easier display
    df = table.to_pandas()
    
    # Print the DataFrame
    print(df)

if __name__ == "__main__":
    file_path = "all_data/all_articles_all_years_combined.feather"  # Replace with the path to your Feather file
    display_feather_file(file_path)