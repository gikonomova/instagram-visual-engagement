#!/bin/sh
# paper.md + references.md -> CSIR-styled .docx. Usage: build.sh [--draft]
# --draft marks results that are not computed yet as "[pending]" and writes paper_v2_draft.docx.
set -e
cd "$(dirname "$0")"
out=paper_v2.docx; [ "$1" = "--draft" ] && out=paper_v2_draft.docx
cat paper.md references.md > .paper.full.md
../.venv/bin/python -I fill.py .paper.full.md $1 > .paper.filled.md
pandoc -f markdown .paper.filled.md -o "$out" --reference-doc=csir-reference.docx --resource-path=..:.
../.venv/bin/python -I postprocess.py "$out"
rm -f .paper.full.md .paper.filled.md
echo "built paper/$out"
