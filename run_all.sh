#!/bin/sh
# Full CRISP-DM pipeline, phases 2-6. Model fits are cached in data/models/.
set -e
cd "$(dirname "$0")"
.venv/bin/python -I src/01_data_understanding.py
.venv/bin/python -I src/02_data_preparation.py
Rscript src/03_modeling.R
Rscript src/04_evaluation.R
./paper/build.sh
