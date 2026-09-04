#!/usr/bin/env python
"""Extract sample page content for analysis"""

import requests
from bs4 import BeautifulSoup

url = "https://youth.europa.eu/solidarity/opportunity/52563_en"
resp = requests.get(url, timeout=20)
html = resp.text

# Save HTML to file for inspection
with open("sample_opportunity.html", "w", encoding="utf-8") as f:
    f.write(html)

print(f"HTML saved to sample_opportunity.html ({len(html)} bytes)")

soup = BeautifulSoup(html, "html.parser")

# Find the main content area
main = soup.find("main")
if main:
    # Extract all text content from main
    print("\n=== MAIN CONTENT TEXT ===")
    # Get all p tags
    paragraphs = main.find_all("p")
    print(f"Paragraphs found: {len(paragraphs)}")
    for i, p in enumerate(paragraphs[:5]):
        text = p.get_text(strip=True)
        if text and len(text) > 20:
            print(f"  [{i}] {text[:120]}")
    
    # Get all text content with line breaks
    text_content = main.get_text(separator="\n", strip=True)
    lines = [line.strip() for line in text_content.split("\n") if line.strip() and len(line.strip()) > 10]
    print(f"\nTop 30 non-empty lines:")
    for i, line in enumerate(lines[:30]):
        print(f"  [{i}] {line[:100]}")
