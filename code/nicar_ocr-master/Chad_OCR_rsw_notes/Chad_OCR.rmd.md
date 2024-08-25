NICAR: PDF processing with OCR and command-line tools: https://github.com/profrobwells/nicar_ocr?tab=readme-ov-file


```python
import sys
```



```python
!brew install tesseract
```

```python
!brew install xpdf
```

```python
!xcode-select --install
```

```python
!brew install libtiff
```

```python
!brew install ghostscript
```

```python
!brew install imagemagick
```

```python
!pdftotext /Users/robwells/Code/misc_notes/notes/Manafort_filing.pdf name-of-my-text-file.txt
```

```python
!pdftotext -table /Users/robwells/Code/misc_notes/notes/07012018-report-final.pdf tabular-test1.txt
```

In python, create a loop to extract all pdf documents in the folder pdfs and export the text into a folder called extracted. here's the basic code. !pdftotext /Users/robwells/Code/misc_notes/Manafort_filing.pdf name-of-my-text-file.txt
ChatGPT
You can achieve this using the os module to navigate through files and folders and the subprocess module to execute the pdftotext command. Below is the Python code to accomplish this:


```python
import os
import subprocess

# Path to the folder containing PDFs
pdf_folder = '/Users/robwells/Code/misc_notes/pdfs'

# Path to the folder where extracted text will be saved
extracted_folder = '/Users/robwells/Code/misc_notes/extracted'

# Create the extracted folder if it doesn't exist
if not os.path.exists(extracted_folder):
    os.makedirs(extracted_folder)

# Loop through all files in the PDF folder
for filename in os.listdir(pdf_folder):
    if filename.endswith('.pdf') or filename.endswith('.png'):
        # Construct the input and output paths
        input_path = os.path.join(pdf_folder, filename)
        output_filename = os.path.splitext(filename)[0] + '.txt'
        output_path = os.path.join(extracted_folder, output_filename)

        # Run pdftotext command
        subprocess.run(['pdftotext', input_path, output_path])

        print(f"Text extracted from {filename} and saved to {output_filename}.")

```


```python
!pdftotext /Users/robwells/Code/misc_notes/pdfs/Firemen2.pdf firemen2.txt
```

```python
!brew install tesseract
```


To convert png files, it's a two step process. First use tesseract to convert to searchable pdf and then pdftotext to text


```python
!tesseract -h
```

```python
!tesseract /Users/robwells/Code/misc_notes/pdfs/'a lynching in ohio.png' out pdf
```

```python
!pdftotext out.pdf out.txt
```
