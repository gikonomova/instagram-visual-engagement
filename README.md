# Visual features and audience-normalised engagement on Instagram

Which visual properties of an Instagram photo are associated with more likes **per follower**?
A pre-registered negative-binomial mixed-model analysis of ~584K posts from ~469K accounts,
organised with CRISP-DM.

- **Decision log and pre-registration:** [`DECISIONS.md`](DECISIONS.md). Read this first: every
  filter, variable, and test is justified there, and the hypotheses were committed before any
  outcome model was fitted.
- **Paper:** [`paper/`](paper/), written for the *Computer Science and Interdisciplinary Research
  Journal* (CSIR).

## CRISP-DM map

| Phase | Where |
|---|---|
| 1 Business understanding | `DECISIONS.md` D01-D03 |
| 2 Data understanding | `src/01_data_understanding.py` -> `outputs/tables/01_*`, `fig1` |
| 3 Data preparation | `src/02_data_preparation.py` -> `outputs/tables/02_sample_flow.json` |
| 4 Modelling | `src/03_modeling.R` -> `outputs/tables/03_*`, `outputs/models/` |
| 5 Evaluation | `src/04_evaluation.R` -> `outputs/tables/04_*`, figures |
| 6 Deployment | `paper/`, `run_all.sh` |

## Reproduce

```sh
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
Rscript src/install.R          # see the comment in the file about glmmTMB 1.1.9 on R 4.1
./run_all.sh
```

Software used: Python 3.9, R 4.1.2, glmmTMB 1.1.9. The data is downloaded and checksum-verified
by `src/01_*`. The raw and processed data are not committed (`data/` is git-ignored) because
they contain personal data. Only aggregate outputs are in the repository.

## Data

[`vargr/ig_train_dataset`](https://huggingface.co/datasets/vargr/ig_train_dataset): 605,868
English-language Instagram posts (2012-2019) with likes, comments, follower counts, and
pre-computed image features (AADB-style aesthetic attributes, COCO-style object labels, shot
scale, image category). The dataset card has no documentation or licence. See `DECISIONS.md`
D04-D05 for what this implies.

Other Instagram parquet datasets on the Hub were surveyed and rejected because they lack
engagement or dates: `kkcosmos/instagram-images-with-captions`,
`scene-genie/instagram-dataset-big`, `vargr/main_instagram` (no image features).
