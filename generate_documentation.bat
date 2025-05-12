@echo off
echo Installing required Python packages...
pip install -r requirements.txt

echo Generating architecture diagram...
python create_diagram.py

echo Converting README to PDF...
python create_pdf.py

echo Documentation generation complete!
echo Architecture diagram: architecture_diagram.png
echo PDF documentation: PE-Assignment-3-Documentation.pdf 