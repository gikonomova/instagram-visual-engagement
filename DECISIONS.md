# Decision log

Every analysis choice is recorded here with **why**, structured by CRISP-DM phase.
Entries are append-only. A changed decision gets a new entry that points back to the old one.
The confirmatory hypotheses (section 1.4) were committed **before** any model relating visual
features to likes was fitted. The git history shows that ordering.

---

## Phase 1 - Business understanding

**D01 Research question.** Which visual properties of an Instagram photo are associated with
more likes *once audience size is accounted for*?
*Why:* raw likes mostly measure follower count. Creators and marketers can control what they
post but not, in the short term, how many followers they have. So the question that matters to
them is about likes per follower.

**D02 Success criteria (scientific).** A finding counts only if it is (a) statistically
significant after multiplicity correction, (b) larger than a pre-set smallest effect size of
interest (SESOI), and (c) replicated in two disjoint halves of the accounts. Prediction gains are
measured on accounts the model never saw.
*Why:* with ~580K posts almost any coefficient is "significant". Significance alone carries no
information at this scale, so effect size and replication do the work.

**D03 Methodology: CRISP-DM.** Phases map to files: business/data understanding -> this log and
`src/01_*`; preparation -> `src/02_*`; modelling -> `src/03_*`; evaluation -> `src/04_*`;
deployment -> `paper/` and the reproducible pipeline (`run_all.sh`).

## Phase 2 - Data understanding

**D04 Dataset.** `vargr/ig_train_dataset` on Hugging Face, auto-converted parquet, SHA-256
`0aa06bbf...61d5` (repo revision `cb6e88ac`). It has 605,868 English-language posts from 485,125
accounts, posted 2012-02 to 2019-08, with pre-computed image features.
*Why:* it is the only Instagram dataset on the Hub that combines image-derived features,
engagement counts, follower counts, and dates (see `README.md`, dataset survey).

**D05 Known provenance gaps.** The dataset card is empty. The feature names match the AADB
aesthetic attributes (Kong et al., 2016), shot types look like a cinematographic shot-scale
classifier, and objects look like COCO detector labels. None of this is documented by the
uploader. `image_grade` and `description_grade` have no definition anywhere.
*Consequence:* the undefined grades are excluded (D07). All visual scores are treated as
model-derived proxies, not ground truth. This is stated as a limitation.

**D06 Blinding.** Profiling (`src/01_*`) looked at marginal distributions, feature-feature
correlations, and account structure only. It did not look at any feature-likes relationship
before the hypotheses below were committed.

**D07 Feature exclusions.** Dropped: `MotionBlurScore` (|values| < 4e-33, numerically zero),
`RepetitionScore` and `SymmetryScore` (constant 0.5, SD 0.003), `image_grade` and
`description_grade` (undefined), `image_dimensions` (constant 3 for 99.99% of rows).
`AestheticScore` correlates 0.61-0.86 with six of the attributes, so it is a composite. It is
analysed in its own model (M1) and not alongside the attributes (M2), to avoid collinear,
uninterpretable coefficients.

## Phase 3 - Data preparation

**D08** Drop the 232 posts with `followers == 0`, where log(followers) is undefined.
**D09** Keep photos only (`post_type == 1`, drops 21,807 videos). Video scores describe a single
cover frame, which is a different construct.
**D10** Use month-of-posting fixed effects, with months before 2018 pooled ("pre2018").
*Why:* likes accumulate over time and scrape dates are unknown. Month fixed effects absorb the
average exposure-time difference and any platform-wide shifts. Months before 2018 are sparse.
**D11** Continuous visual features are z-scored, so exp(beta) is the incidence-rate ratio (IRR)
per 1 SD.
**D12** Splits are made at account level with deterministic SHA-256 hashes of `profile_id`:
20% of accounts form the held-out test set (H5), and a separate hash forms replication halves
A and B.
*Why:* splitting by post would leak account identity across the splits.
**D13** Personal data handling: usernames, bios, and captions are never written to disk after
loading. Captions are used only to derive three counts (length, hashtags, mentions). Only
aggregate results are committed.

Result: 583,830 posts from 469,330 accounts (`outputs/tables/02_sample_flow.json`).

## Phase 4 - Modelling (pre-registered)

### 1.4 Confirmatory hypotheses and analysis plan

Common model: negative binomial (NB2) GLMM with a log link,

    log E[likes_ij] = log(followers_j) + X_ij b + C_ij g + u_j,  u_j ~ N(0, s_u^2)

where j indexes accounts, log(followers) is an **offset**, and C are controls: month fixed
effects, business account, caption topic (`description_category`), log caption length,
log hashtag count, and log mention count. Fitting uses glmmTMB (Laplace approximation).

- **M1** X = z(AestheticScore).
- **M2** X = 8 z-scored AADB attributes + person_present + log(1 + n_person) +
  log(1 + n_objects) + shot type (ref: Medium Shot) + image category (ref: Lifestyle).
- **M1-W** M1 with the Mundlak decomposition: the visual term is split into the account mean
  (between) and the deviation from the account mean (within), for AestheticScore and
  person_present.

| H | Claim | Test | Direction |
|---|---|---|---|
| H1 | Higher overall aesthetic quality -> more likes per follower | IRR of z(AestheticScore), M1 | > 1, one-sided |
| H2 | A detected person -> more likes per follower | IRR of person_present, M2 | > 1, one-sided |
| H3 | More vivid colour -> more likes per follower | IRR of z(VividColorScore), M2 | > 1, one-sided |
| H4 | Within-account and between-account aesthetic effects differ | Wald test that between - within = 0, M1-W | two-sided |
| H5 | Visual features improve prediction for unseen accounts | Mean per-post NB log score on test accounts, M2 vs controls-only; 95% account-cluster bootstrap CI (B = 1000) of the difference | > 0 |

**Decision rule.** The 5 p-values are Holm-adjusted at family-wise alpha = 0.05.
- **Supported:** adjusted p < 0.05, the 95% CI lies entirely outside the SESOI band, and the
  sign and significance replicate in both halves A and B.
- **Negligible:** the 90% CI lies entirely inside the band (equivalence test, TOST).
- **Inconclusive:** anything else.

**SESOI:** IRR band [0.97, 1.03], i.e. ±3% likes per SD or per binary switch.
*Why ±3%:* it is roughly the smallest change a content creator could detect against week-to-week
noise. It is fixed now so it cannot be tuned to the results later.

**Robustness (pre-specified, not part of the decision rule):**
- R1: log(followers) as a free covariate instead of an offset (the offset forces elasticity = 1).
- R2: posts from 2019 only (shorter exposure-time spread).
- R3: comments as the outcome.
- R4: accounts with 2 or more posts only (where u_j is identified separately from NB dispersion).

**Feasibility fallback (pre-specified).** If a full-sample fit does not converge or exceeds
24 h, H1-H4 are estimated on a seeded random 50% of accounts, with the other 50% as replication.
This would replace the A/B halves and is reported as a deviation.

Everything not listed above is **exploratory** and is labelled as such in the paper.
