import json
import datasets

SUPPORTED_YEARS = ["1774"]
# Add years from 1798 to 1964 to the supported years
SUPPORTED_YEARS = SUPPORTED_YEARS + [str(year) for year in range(1798, 1964)]

def make_year_file_splits():
    """
    Collects a list of available files for each year.

    Returns:
        dict: A dictionary mapping each year to its corresponding file URL.
        list: A list of years.
    """

    base_url = "https://huggingface.co/datasets/dell-research-harvard/AmericanStories/resolve/main/"

    # Make a list of years from 1774 to 1960
    # TODO: can we set up to check the actual files in the repo instead of relying on the offline list?
    year_list = SUPPORTED_YEARS
    data_files = [f"faro_{year}.tar.gz" for year in year_list]
    url_list = [base_url + file for file in data_files]
    
    splits = {year: file for year, file in zip(year_list, url_list)}
    years = year_list

    return splits, years


_CITATION = """\
Coming Soon
"""

_DESCRIPTION = """\
American Stories offers high-quality structured data from historical newspapers suitable for pre-training large language models to enhance the understanding of historical English and world knowledge. It can also be integrated into external databases of retrieval-augmented language models, enabling broader access to historical information, including interpretations of political events and intricate details about people's ancestors. Additionally, the structured article texts facilitate the application of transformer-based methods for popular tasks like detecting reproduced content, significantly improving accuracy compared to traditional OCR methods. American Stories serves as a substantial and valuable dataset for advancing multimodal layout analysis models and other multimodal applications.
"""

_FILE_DICT, _YEARS = make_year_file_splits()


class CustomBuilderConfig(datasets.BuilderConfig):
    """BuilderConfig for AmericanStories dataset with different configurations."""

    def __init__(self, year_list=None, **kwargs):
        """
        BuilderConfig for AmericanStories dataset.

        Args:
            year_list (list): A list of years to include in the dataset.
            **kwargs: Additional keyword arguments forwarded to the superclass.
        """
        super(CustomBuilderConfig, self).__init__(**kwargs)
        self.year_list = year_list

class AmericanStories(datasets.GeneratorBasedBuilder):
    """Dataset builder class for AmericanStories dataset."""

    VERSION = datasets.Version("0.1.0")

    BUILDER_CONFIGS = [
        CustomBuilderConfig(
            name="all_years",
            version=VERSION,
            description="All years in the dataset"
        ),
        CustomBuilderConfig(
            name="subset_years",
            version=VERSION,
            description="Subset of years in the dataset",
            year_list=["1774", "1804"]
        ),
        CustomBuilderConfig(
            name="all_years_content_regions",
            version=VERSION,
            description="All years in the dataset",
        ),
        CustomBuilderConfig(
            name="subset_years_content_regions",
            version=VERSION,
            description="Subset of years in the dataset",
            year_list=["1774", "1804"],
        )
    ]
    
    DEFAULT_CONFIG_NAME = "subset_years"
    BUILDER_CONFIG_CLASS = CustomBuilderConfig

    def _info(self):
        """
        Specifies the DatasetInfo object for the AmericanStories dataset.

        Returns:
            datasets.DatasetInfo: The DatasetInfo object.
        """
        if not self.config.name.endswith("content_regions"):
            features = datasets.Features(
                {
                    "article_id": datasets.Value("string"),
                    "newspaper_name": datasets.Value("string"),
                    "edition": datasets.Value("string"),
                    "date": datasets.Value("string"),
                    "page": datasets.Value("string"),
                    "headline": datasets.Value("string"),
                    "byline": datasets.Value("string"),
                    "article": datasets.Value("string"),
                }
            )
        else:
            features = datasets.Features(
                {
                    "raw_data_string": datasets.Value("string"),
                }
            )

        return datasets.DatasetInfo(
            description=_DESCRIPTION,
            features=features,
            citation=_CITATION,
        )

    def _split_generators(self, dl_manager):
        """
        Downloads and extracts the data, and defines the dataset splits.

        Args:
            dl_manager (datasets.DownloadManager): The DownloadManager instance.

        Returns:
            list: A list of SplitGenerator objects.
        """
        if self.config.name == "subset_years":
            print("Only taking a subset of years. Change name to 'all_years' to use all years in the dataset.")
            if not self.config.year_list:
                raise ValueError("Please provide a valid year_list")
            elif not set(self.config.year_list).issubset(set(SUPPORTED_YEARS)):
                raise ValueError(f"Only {SUPPORTED_YEARS} are supported. Please provide a valid year_list")

        urls = _FILE_DICT
        year_list = _YEARS

        # Subset _FILE_DICT and year_list to only include years in config.year_list
        if self.config.year_list:
            urls = {year: urls[year] for year in self.config.year_list if year in SUPPORTED_YEARS}
            year_list = self.config.year_list

        print(urls)
        archive = dl_manager.download(urls)

        # Return a list of splits, where each split corresponds to a year
        return [
            datasets.SplitGenerator(
                name=year,
                gen_kwargs={
                    "files": dl_manager.iter_archive(archive[year]),
                    "year_dir": "/".join(["mnt", "122a7683-fa4b-45dd-9f13-b18cc4f4a187", "ca_rule_based_fa_clean", "faro_" + year]),
                    "split": year,
                    "associated": True if not self.config.name.endswith("content_regions") else False,
                },
            ) for year in year_list
        ]

    def _generate_examples(self, files, year_dir, split, associated):
        """
        Generates examples for the specified year and split.

        Args:
            year_dir (str): The directory path for the year.
            associated (bool): Whether or not the output should be contents associated into an "article" or raw contents.

        Yields:
            tuple: The key-value pair containing the example ID and the example data.
        """
        if associated:
            print('Loading associated')
            for filepath, f in files:
                if filepath.startswith(year_dir):
                    try :
                        data = json.loads(f.read().decode('utf-8'))
                    except:
                        print("Error loading file: " + filepath)
                        continue
                    if "lccn" in data.keys():
                        filepath = filepath.split("/")[-1]
                        scan_id = filepath.split('.')[0]
                        scan_date = filepath.split("_")[0]
                        scan_page = filepath.split("_")[1]
                        scan_edition = filepath.split("_")[-2][8:]
                        newspaper_name = data["lccn"]["title"]
                        full_articles_in_data = data["full articles"]
                        for article in full_articles_in_data:
                            article_id = str(article["full_article_id"]) + "_" + scan_id
                            yield article_id, {
                                "article_id": article_id,
                                "newspaper_name": newspaper_name,
                                "edition": scan_edition,
                                "date": scan_date,
                                "page": scan_page,
                                "headline": article["headline"],
                                "byline": article["byline"],
                                "article": article["article"],
                            }
        else:
            for filepath, f in files:
                if filepath.startswith(year_dir):                    
                    try :
                        data = json.loads(f.read().decode('utf-8'))
                    except:
                        # print("Error loading file: " + filepath)
                        continue
                    ###Convert json to strng
                    data=json.dumps(data)
                    scan_id=filepath.split('.')[0]
                    ##Yield the scan id and the raw data string
                    yield scan_id, {
                        "raw_data_string": str(data)
                    }
