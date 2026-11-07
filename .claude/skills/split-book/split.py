"""Split an OCR'd book's markdown into one file per chapter.

  python split.py headings BOOK.md         list headings with line numbers
  python split.py split BOOK.md PLAN.txt   write chapters/ next to BOOK.md

PLAN.txt has one chapter per line: `<start line> <file stem>`, e.g.
`138 01-vector-spaces`. Lines before the first start go to 00-front-matter.md.
The split is byte-exact: the chapters are checked to join back into BOOK.md,
and only then is BOOK.md deleted.
"""
import re
import sys
from pathlib import Path


def read_lines(path):
    # Split on b"\n" only, keeping endings, so joining gives back the exact bytes.
    data = path.read_bytes()
    return data, re.findall(rb"[^\n]*\n|[^\n]+$", data)


def headings(md):
    _, lines = read_lines(md)
    for n, line in enumerate(lines, 1):
        if line.startswith(b"#"):
            print(f"{n}: {line.decode('utf-8', 'replace').rstrip()}")


def split(md, plan_path):
    data, lines = read_lines(md)
    plan = []
    for row in plan_path.read_text(encoding="utf-8").splitlines():
        if row.strip() and not row.lstrip().startswith("#"):
            start, stem = row.split(maxsplit=1)
            plan.append((int(start), stem.strip().removesuffix(".md")))

    starts = [s for s, _ in plan]
    if starts != sorted(set(starts)) or starts[0] < 1 or starts[-1] > len(lines):
        sys.exit(f"start lines must be increasing and within 1..{len(lines)}")
    if starts[0] > 1:
        plan.insert(0, (1, "00-front-matter"))
    stems = [stem for _, stem in plan]
    if len(stems) != len(set(stems)):
        sys.exit("duplicate file stems in plan")

    out = md.parent / "chapters"
    out.mkdir(exist_ok=True)
    chunks = []
    for i, (start, stem) in enumerate(plan):
        end = plan[i + 1][0] if i + 1 < len(plan) else len(lines) + 1
        chunk = b"".join(lines[start - 1 : end - 1])
        (out / f"{stem}.md").write_bytes(chunk)
        chunks.append(chunk)
        print(f"{stem}.md  lines {start}-{end - 1}  {len(chunk)} bytes")

    if b"".join(chunks) != data:
        sys.exit(f"chapters do not join back into {md.name}; left it in place")
    md.unlink()
    print(f"verified {len(plan)} files; deleted {md.name}")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "headings":
        headings(Path(sys.argv[2]))
    elif len(sys.argv) == 4 and sys.argv[1] == "split":
        split(Path(sys.argv[2]), Path(sys.argv[3]))
    else:
        sys.exit(__doc__)
