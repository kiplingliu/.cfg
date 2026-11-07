---
name: split-book
description: Split an OCR'd book's single markdown file (books/<name>/<name>.md) into one file per chapter under chapters/, and write a README. Use when the user asks to split an OCR'd book.
---

# Split an OCR'd book into chapters

Input: `books/<name>/` holding `<name>.md` (OCR output), usually `<name>.pdf`,
and `<name>.zip` (figure images). Target layout:

```
books/<name>/
  README.md
  chapters/00-front-matter.md, 01-<slug>.md, ..., appendix-a-<slug>.md
  <name>.pdf  <name>.zip      (untouched)
```

The chapter files are an exact byte split of the original markdown — never edit
the text, fix OCR, or change heading levels. Just pick where each chapter
starts.

## Steps

1. List the headings: `python .claude/skills/split-book/split.py headings
   books/<name>/<name>.md` For big books, redirect to a file in the scratchpad
   and read it in parts.
2. Read the book's table of contents (search for `Contents`) to learn the real
   chapter list. If there's a PDF, it is the authority for the chapter list,
   since the OCR'd TOC can be garbled: `uv run -q
   .claude/skills/split-book/pdf.py outline books/<name>/<name>.pdf` prints its
   bookmarks with PDF page numbers. With no bookmarks, read the contents pages
   with `pdf.py text <pdf> FIRST LAST`. Map each chapter to the heading line
   where it starts. OCR headings are unreliable: levels vary (`#`/`##`/`###`),
   numbers get dropped, and a chapter's title may be missing entirely. When a
   heading is missing, read around the expected spot and pick the first line of
   the chapter's content (e.g. its first section or opening box). Chapter-level
   only — sections stay inside their chapter. If the book has parts (Part I,
   ...) containing chapters, split by chapter and let a part's title page fall
   at the start of its first chapter.
3. Write a plan file in the scratchpad, one line per chapter:
   ```
   138 01-basic-notions
   1236 02-systems-of-linear-equations
   9001 appendix-a-some-title
   ```
   Stems: two-digit chapter number (the book's own numbering) + lowercase ASCII
   slug of the title (punctuation dropped, words joined by `-`). Appendices:
   `appendix-<letter>-<slug>`. Back matter worth separating (bibliography,
   index) gets its own stem like `99-index` or `back-matter`. Everything before
   the first line becomes `00-front-matter.md` automatically (preface, TOC).
4. Run `python .claude/skills/split-book/split.py split books/<name>/<name>.md
   <plan>`. It writes `chapters/`, verifies the files join back byte-for-byte,
   then deletes `<name>.md`.
5. Spot-check: print the first non-blank line of every chapter file and confirm
   each is that chapter's start.
6. If there's a PDF, check the split against it:
   - Every chapter (and appendix) in the PDF outline/contents has exactly one
     file, in the same order, and no file is a chapter the PDF doesn't have.
   - Each file starts on the right page. Image links like `_page_41_Figure_2`
     carry the 0-based PDF page (PDF page 42), so the nearest ones around a
     chapter's start line should be close to its outline page. Where that is
     ambiguous or a title heading was missing, run `pdf.py text <pdf> <page>`
     and compare the chapter's opening text with the file's first lines. Fix the
     plan and re-split if anything is off: `cat` the chapters back together in
     order into `<name>.md` first (`split` needs it), then delete `chapters/`.
7. Write `books/<name>/README.md` in this style:
   ```
   # <Title> (<Author>)

   - `chapters/`: the book, one file per chapter. Read these.
   - `<name>.pdf`: the original. `<name>.zip`: figure images.

   OCR'd from the PDF: code, numbers, and formulas may be wrong; check the PDF
   when something looks off.

   - <anything surprising about the split, e.g. chapters whose title heading
     was lost, numbering you inferred, what's in front/back matter>
   ```
   Only list files that exist (drop the pdf mention if there's no pdf). Keep the
   notes to real anomalies; omit the list if there are none.
