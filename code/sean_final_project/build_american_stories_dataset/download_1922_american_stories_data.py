import os
import pyarrow as pa
import pyarrow.feather as feather
import pyarrow.parquet as pq
from datasets import load_dataset
from concurrent.futures import ProcessPoolExecutor, as_completed
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    filename='download_american_stories_data.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def download_article_dataset_for_year(year_value):
    """
    Function to download all articles for a given year and save to Parquet and Apache Arrow formats.
    
    Parameters:
    year_value (str): Year to download articles for.
    """
    try:
        # Load the dataset for the specified year
        dataset_article_level = load_dataset("dell-research-harvard/AmericanStories",
                                             "subset_years",
                                             year_list=[year_value],
                                             trust_remote_code=True
                                             )
        
        # Collect all articles into a list of dictionaries
        articles_list = []
        for article_n in range(len(dataset_article_level[year_value])):
            article = dataset_article_level[year_value][article_n]
            articles_list.append(article)
        
        # Convert the list of dictionaries to an Arrow Table
        table = pa.Table.from_pydict({k: [d[k] for d in articles_list] for k in articles_list[0]})
        
        # Create output directories if they don't exist
        base_output_dir = "data_by_year/"
        parquet_dir = os.path.join(base_output_dir, "parquet")
        arrow_dir = os.path.join(base_output_dir, "arrow")
        os.makedirs(parquet_dir, exist_ok=True)
        os.makedirs(arrow_dir, exist_ok=True)
        
        # Write to Parquet
        output_file_parquet = os.path.join(parquet_dir, f"articles_{year_value}.parquet")
        pq.write_table(table, output_file_parquet)
        
        # Write to Feather (Apache Arrow)
        output_file_feather = os.path.join(arrow_dir, f"articles_{year_value}.feather")
        with pa.OSFile(output_file_feather, 'wb') as f:
            feather.write_feather(table, f)
        
        logging.info(f"Successfully downloaded and saved data for year {year_value}")
    except Exception as e:
        logging.error(f"Error downloading data for year {year_value}: {e}")

def process_year(year):
    base_output_dir = "data_by_year"
    parquet_dir = os.path.join(base_output_dir, "parquet")
    arrow_dir = os.path.join(base_output_dir, "arrow")
    
    # Check if either Parquet or Feather file already exists for the year, skip if so
    output_file_parquet = os.path.join(parquet_dir, f"articles_{year}.parquet")
    output_file_feather = os.path.join(arrow_dir, f"articles_{year}.feather")
    
    if os.path.exists(output_file_parquet) or os.path.exists(output_file_feather):
        logging.info(f"File already exists for year {year}, skipping...")
        return
    
    start_time = datetime.now()
    logging.info(f"Start downloading data for year {year} at {start_time}")
    
    try:
        download_article_dataset_for_year(year)
        end_time = datetime.now()
        logging.info(f"Done: {year} at {end_time}, duration: {end_time - start_time}")
    except Exception as e:
        logging.error(f"Error downloading data for year {year}: {e}")

def run_in_parallel(year_values, max_workers=None):
    if max_workers is None:
        max_workers = os.cpu_count() - 1
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(process_year, year): year for year in year_values}
        for future in as_completed(futures):
            year = futures[future]
            try:
                future.result()
            except Exception as e:
                logging.error(f"Year {year} generated an exception: {e}")

if __name__ == "__main__":
    # Example usage
    year_values = ["1922"]
    # Add years from 1798 to 1964 to the supported years
    #year_values = year_values + [str(year) for year in range(1798, 1964)]
    #year_values = year_values + [str(year) for year in range(1798, 1964)]

    run_in_parallel(year_values)  # max_workers defaults to os.cpu_count() - 1
