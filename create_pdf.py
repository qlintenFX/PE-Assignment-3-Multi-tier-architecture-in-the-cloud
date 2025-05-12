import markdown
import pdfkit
import os

def convert_markdown_to_pdf(input_file, output_file):
    # Read markdown content
    with open(input_file, 'r', encoding='utf-8') as f:
        markdown_content = f.read()
    
    # Convert markdown to HTML
    html_content = markdown.markdown(markdown_content, extensions=['tables', 'fenced_code'])
    
    # Add some basic CSS for styling
    styled_html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Multi-tier Architecture in the Cloud</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                line-height: 1.6;
                margin: 40px;
            }}
            h1, h2, h3 {{
                color: #333;
            }}
            h1 {{
                border-bottom: 2px solid #333;
                padding-bottom: 10px;
            }}
            h2 {{
                border-bottom: 1px solid #ccc;
                padding-bottom: 5px;
                margin-top: 30px;
            }}
            table {{
                border-collapse: collapse;
                width: 100%;
                margin: 20px 0;
            }}
            th, td {{
                border: 1px solid #ddd;
                padding: 8px;
                text-align: left;
            }}
            th {{
                background-color: #f2f2f2;
            }}
            code {{
                background-color: #f5f5f5;
                padding: 2px 5px;
                border-radius: 3px;
                font-family: monospace;
            }}
            pre {{
                background-color: #f5f5f5;
                padding: 10px;
                border-radius: 5px;
                overflow-x: auto;
            }}
            pre code {{
                background-color: transparent;
                padding: 0;
            }}
            img {{
                max-width: 100%;
                height: auto;
            }}
        </style>
    </head>
    <body>
        {html_content}
    </body>
    </html>
    """
    
    # Create HTML file
    html_file = 'README.html'
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(styled_html)
    
    # Convert HTML to PDF
    try:
        pdfkit.from_file(html_file, output_file)
        print(f"Successfully created PDF: {output_file}")
    except Exception as e:
        print(f"Error creating PDF: {e}")
    
    # Clean up HTML file
    os.remove(html_file)

if __name__ == "__main__":
    convert_markdown_to_pdf('README.md', 'PE-Assignment-3-Documentation.pdf') 