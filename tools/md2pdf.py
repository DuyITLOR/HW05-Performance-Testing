#!/usr/bin/env python3
"""Convert a Markdown file to a styled PDF via python-markdown + Chrome headless."""
import sys, os, subprocess, html

import markdown

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

CSS = """
@page { size: A4; margin: 16mm 14mm; }
* { box-sizing: border-box; }
body { font-family: -apple-system, "Helvetica Neue", Arial, "Segoe UI", sans-serif;
       font-size: 10.5pt; line-height: 1.5; color: #1a1a1a; }
h1 { font-size: 20pt; border-bottom: 2px solid #333; padding-bottom: 4px; margin-top: 0; }
h2 { font-size: 15pt; border-bottom: 1px solid #ccc; padding-bottom: 3px; margin-top: 18px; }
h3 { font-size: 12.5pt; margin-top: 14px; }
h4 { font-size: 11pt; margin-top: 12px; }
p, li { font-size: 10.5pt; }
code { font-family: "SF Mono", "Menlo", Consolas, monospace; font-size: 9pt;
       background: #f3f3f3; padding: 1px 4px; border-radius: 3px; }
pre { background: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 5px;
      padding: 10px; overflow-x: auto; white-space: pre-wrap; word-break: break-word; }
pre code { background: none; padding: 0; font-size: 8.5pt; }
table { border-collapse: collapse; width: 100%; margin: 10px 0; font-size: 8.8pt;
        page-break-inside: auto; }
tr { page-break-inside: avoid; }
th, td { border: 1px solid #bbb; padding: 4px 6px; text-align: left; vertical-align: top;
         word-break: break-word; }
th { background: #eef1f4; font-weight: 600; }
blockquote { border-left: 3px solid #ccc; margin: 8px 0; padding: 2px 12px;
             color: #444; background: #fafafa; }
a { color: #0b5fff; text-decoration: none; word-break: break-all; }
hr { border: none; border-top: 1px solid #ddd; margin: 14px 0; }
h1, h2, h3, h4 { page-break-after: avoid; }
img { max-width: 100%; }
.pdf-page-break { break-before: page; page-break-before: always; }
.task3-flowchart { break-inside: avoid; page-break-inside: avoid; margin: 6px 0 10px;
                   text-align: center; }
.task3-flowchart img { display: block; width: auto; max-width: 100%; max-height: 205mm;
                       margin: 0 auto; }
.task3-flowchart figcaption { margin-top: 4px; font-size: 8.5pt; color: #555; }
"""

def convert(md_path, pdf_path):
    with open(md_path, encoding="utf-8") as f:
        text = f.read()
    body = markdown.markdown(
        text,
        extensions=["tables", "fenced_code", "sane_lists", "attr_list", "toc", "md_in_html"],
    )
    title = html.escape(os.path.basename(md_path))
    full = f"""<!doctype html><html lang="vi"><head><meta charset="utf-8">
<title>{title}</title><style>{CSS}</style></head><body>{body}</body></html>"""
    # write temp HTML in same dir as source so relative paths resolve
    tmp_html = os.path.splitext(md_path)[0] + "._tmp.html"
    with open(tmp_html, "w", encoding="utf-8") as f:
        f.write(full)
    try:
        subprocess.run([
            CHROME, "--headless=new", "--disable-gpu", "--no-sandbox",
            "--no-pdf-header-footer",
            f"--print-to-pdf={pdf_path}",
            "file://" + os.path.abspath(tmp_html),
        ], check=True, capture_output=True, timeout=120)
    finally:
        if os.path.exists(tmp_html):
            os.remove(tmp_html)
    return os.path.getsize(pdf_path)

if __name__ == "__main__":
    md, pdf = sys.argv[1], sys.argv[2]
    size = convert(md, pdf)
    print(f"OK {pdf} ({size//1024} KB)")
