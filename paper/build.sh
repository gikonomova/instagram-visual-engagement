#!/bin/sh
# paper.md + references.md -> paper.docx in CSIR journal styles.
set -e
cd "$(dirname "$0")"
cat paper.md references.md | pandoc -f markdown -o paper.docx --reference-doc=csir-reference.docx --resource-path=..:.
../.venv/bin/python -I postprocess.py paper.docx
