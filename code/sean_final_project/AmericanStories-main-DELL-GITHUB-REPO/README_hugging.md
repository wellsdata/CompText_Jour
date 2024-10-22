---
license: cc-by-4.0
task_categories:
- text-classification
- text-generation
- text-retrieval
- summarization
- question-answering
language:
- en
tags:
- social science
- economics
- news
- newspaper
- large language modeling
- nlp
- lam
pretty_name: AmericanStories
size_categories:
- 100M<n<1B
---
# Dataset Card for the American Stories dataset

## Dataset Description

- **Homepage:** Coming Soon
- **Repository:** https://github.com/dell-research-harvard/AmericanStories 
- **Paper:** Coming Soon
=- **Point of Contact:** melissa.dell@gmail.com

### Dataset Summary

  The American Stories dataset is a collection of full article texts extracted from historical U.S. newspaper images. It includes nearly 20 million scans from the public domain Chronicling America collection maintained by the Library of Congress. The dataset is designed to address the challenges posed by complex layouts and low OCR quality in existing newspaper datasets.
  It was created using a novel deep learning pipeline that incorporates layout detection, legibility classification, custom OCR, and the association of article texts spanning multiple bounding boxes. It employs efficient architectures specifically designed for mobile phones to ensure high scalability.
  The dataset offers high-quality data that can be utilized for various purposes. It can be used to pre-train large language models and improve their understanding of historical English and world knowledge. 
  The dataset can also be integrated into retrieval-augmented language models, making historical information more accessible, including interpretations of political events and details about people's ancestors.
  Additionally, the structured article texts in the dataset enable the use of transformer-based methods for applications such as detecting reproduced content. This significantly enhances accuracy compared to relying solely on existing OCR techniques.
  The American Stories dataset serves as an invaluable resource for developing multimodal layout analysis models and other multimodal applications. Its vast size and silver quality make it ideal for innovation and research in this domain.

### Languages

English (en)

## Dataset Structure
The raw data on this repo contains compressed chunks of newspaper scans for each year. Each scan has its own JSON file named as the {scan_id}.json. 
The data loading script takes care of the downloading, extraction, and parsing to outputs of two kinds : 

+ Article-Level Output: The unit of the Dataset Dict is an associated article  
+ Scan Level Output: The unit of the Dataset Dict is an entire scan with all the raw unparsed data

### Data Instances
Here are some examples of what the output looks like.

#### Article level 

```
{
  'article_id': '1_1870-01-01_p1_sn82014899_00211105483_1870010101_0773',
  'newspaper_name': 'The weekly Arizona miner.', 
  'edition': '01', 'date': '1870-01-01',
  'page': 'p1',
  'headline': '',
  'byline': '',
  'article': 'PREyors 10 leaving San Francisco for Wash ington City, our Governor, A. r. K. Saford. called upon Generals Thomas and Ord and nt the carrying out of what (truncated)'
}
```

#### Scan level

```
{'raw_data_string': '{"lccn": {"title": "The Massachusetts spy, or, Thomas\'s Boston journal.", "geonames_ids": ["4930956"],....other_keys:values}
```

### Data Fields


#### Article Level

+ "article_id": Unique Id for an associated article
+ "newspaper_name": Newspaper Name
+ "edition": Edition number
+ "date": Date of publication
+ "page": Page number
+ "headline": Headline Text
+ "byline": Byline Text
+ "article": Article Text

#### Scan Level

"raw_data_string": Unparsed scan-level data that contains scan metadata from Library of Congress, all content regions with their bounding boxes, OCR text and legibility classification


### Data Splits

There are no train, test or val splits. Since the dataset has a massive number of units (articles or newspaper scans), we have split the data by year. Once the dataset is loaded,
instead of the usual way of accessing a split as dataset["train"], specific years can be accessed using the syntax dataset["year"] where year can be any year between 1774-1963 as long as there is at least one scan for the year.
The data loading script provides options to download both a subset of years and all years at a time. 

### Accessing the Data

There are 4 config options that can be used to access the data depending upon the use-case. 

```
from datasets import load_dataset

#  Download data for the year 1809 at the associated article level (Default)
dataset = load_dataset("dell-research-harvard/AmericanStories",
    "subset_years",
    year_list=["1809", "1810"]
)

# Download and process data for all years at the article level
dataset = load_dataset("dell-research-harvard/AmericanStories",
    "all_years"
)

# Download and process data for 1809 at the scan level
dataset = load_dataset("dell-research-harvard/AmericanStories",
    "subset_years_content_regions",
    year_list=["1809"]
)

# Download ad process data for all years at the scan level
dataset = load_dataset("dell-research-harvard/AmericanStories",
    "all_years_content_regions")

```


## Dataset Creation

### Curation Rationale

The dataset was created to provide researchers with a large, high-quality corpus of structured and transcribed newspaper article texts from historical local American newspapers. 
These texts provide a massive repository of information about topics ranging from political polarization to the construction of national and cultural identities to the minutiae of the daily lives of people's ancestors. 
The dataset will be useful to a wide variety of researchers including historians, other social scientists, and NLP practitioners.

### Source Data

#### Initial Data Collection and Normalization

The dataset is drawn entirely from image scans in the public domain that are freely available for download from the Library of Congress's website.
We processed all images as described in the associated paper. 

#### Who are the source language producers?

The source language was produced by people - by newspaper editors, columnists, and other sources.

### Annotations

#### Annotation process

Not Applicable

#### Who are the annotators?

Not Applicable

### Personal and Sensitive Information

Not Applicable

## Considerations for Using the Data

### Social Impact of Dataset

 This dataset provides high-quality data that could be used for pre-training a large language model to achieve better understanding of historical English and historical world knowledge. 
 The dataset could also be added to the external database of a retrieval-augmented language model to make historical information - ranging from interpretations of political events to minutiae about the lives of people's ancestors - more widely accessible.
 Furthermore, structured article texts that it provides can facilitate using transformer-based methods for popular applications like detection of reproduced content, significantly improving accuracy relative to using the existing OCR.  
 It can also be used for innovating multimodal layout analysis models and other multimodal applications. 
 
### Discussion of Biases

This dataset contains unfiltered content composed by newspaper editors, columnists, and other sources. 
In addition to other potentially harmful content, the corpus may contain factual errors and intentional misrepresentations of news events. 
All content should be viewed as individuals' opinions and not as a purely factual account of events of the day. 


## Additional Information

### Dataset Curators

Melissa Dell (Harvard), Jacob Carlson (Harvard), Tom Bryan (Harvard) , Emily Silcock (Harvard), Abhishek Arora (Harvard), Zejiang Shen (MIT), Luca D'Amico-Wong (Harvard), Quan Le (Princeton), Pablo Querubin (NYU), Leander Heldring (Kellog School of Business) 

### Licensing Information

The dataset has a CC-BY 4.0 license

### Citation Information

Please cite as:

@misc{dell2023american,
      title={American Stories: A Large-Scale Structured Text Dataset of Historical U.S. Newspapers}, 
      author={Melissa Dell and Jacob Carlson and Tom Bryan and Emily Silcock and Abhishek Arora and Zejiang Shen and Luca D'Amico-Wong and Quan Le and Pablo Querubin and Leander Heldring},
      year={2023},
      eprint={2308.12477},
      archivePrefix={arXiv},
      primaryClass={cs.CL}
}

### Contributions

Coming Soon