# /// script
# dependencies = ["pypdf"]
# ///
"""Look at the original PDF to check a chapter split.

  uv run pdf.py outline BOOK.pdf          bookmarks as `page  title`, indented by level
  uv run pdf.py text BOOK.pdf FIRST [LAST]  extracted text of pages FIRST..LAST

Page numbers are 1-based PDF pages (not the printed page labels).
"""
import sys

from pypdf import PdfReader


def outline(reader, items=None, depth=0):
    for item in reader.outline if items is None else items:
        if isinstance(item, list):
            outline(reader, item, depth + 1)
        else:
            page = reader.get_destination_page_number(item)
            print(f"{page + 1:>5}  {'  ' * depth}{item.title}")


def text(reader, first, last):
    for n in range(first, last + 1):
        print(f"===== page {n} =====")
        print(reader.pages[n - 1].extract_text())


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) == 2 and args[0] == "outline":
        reader = PdfReader(args[1])
        if not reader.outline:
            sys.exit("no outline; read the contents pages with `text` instead")
        outline(reader)
    elif len(args) in (3, 4) and args[0] == "text":
        first = int(args[2])
        text(PdfReader(args[1]), first, int(args[3]) if len(args) == 4 else first)
    else:
        sys.exit(__doc__)
