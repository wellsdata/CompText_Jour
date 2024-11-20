import pyarrow as pa
import os
import pyarrow.feather as feather

def read_and_bind_arrow_files(input_dir, output_file, specific_files=None):
    tables = []
    
    # If specific files are provided, use them; otherwise, use all files in the directory
    if specific_files:
        files_to_read = specific_files
    else:
        files_to_read = [f for f in os.listdir(input_dir) if f.endswith(".feather")]
    
    # Read the specified Arrow files
    for filename in files_to_read:
        file_path = os.path.join(input_dir, filename)
        table = pa.ipc.RecordBatchFileReader(pa.memory_map(file_path)).read_all()
        tables.append(table)
        print(f"{filename} finished adding to memory map")
    
    # Combine all tables into a single table
    combined_table = pa.concat_tables(tables)
    
    # Write the combined table to a single Feather file
    feather.write_feather(combined_table, output_file)

if __name__ == "__main__":
    input_dir = "data_by_year/arrow/"
    output_dir = "all_data/"
    output_filename = "all_articles_all_years_combined.feather"
    output_filepath = os.path.join(output_dir, output_filename)
    
    # Create the output directory if it doesn't exist
    output_dir = os.path.dirname(output_dir)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    #specific_files = "1922"
    specific_files = [f"articles_1922.feather"]
    #specific_files = [f"articles_{year}.feather" for year in [1774] + list(range(1798, 1963))]
    read_and_bind_arrow_files(input_dir, output_filepath, specific_files=specific_files)
