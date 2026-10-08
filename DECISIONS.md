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

### Implementation notes (after pre-registration, before results)

**D14 Optimiser settings.** A control-only timing fit on a 60K-post subsample (no visual terms)
reached nlminb's default evaluation limit. All fits therefore use
`iter.max = eval.max = 1e4`. Convergence (`fit$convergence == 0`) and a positive-definite
Hessian (`pdHess`) are recorded for every model in `outputs/tables/03_coef_*.csv`. A model
failing either check is reported as such and is not used for a confirmatory verdict.
*Why:* the timing run showed about 70 s for 20K posts and about 240 s for 60K posts. A full
fit is roughly 1 h, well inside the 24 h fallback threshold, so the full-sample plan stands.

**D15 Software pin.** glmmTMB 1.1.9. Newer versions depend on RTMB, which does not compile
against R 4.1.2 on this machine. TMB's OpenMP parallelism is unavailable with Apple clang, so
fits run single-threaded, with three models in parallel processes.

**D16 Figure format.** Figures are rendered at one CSIR journal column (3.4 in / 8.6 cm) with
8 pt text, to match the journal layout (captions "Figure N." centred below).

---

## Protocol amendment A1 (2026-10-08, ~11:35 EEST, before any confirmatory result)

**Context.** An external pre-submission review of the manuscript skeleton (no results) asked
for clarifications. The first batch of model fits (launched about 11:20) was stopped at 11:29
before any model finished, so no coefficient from any model with visual terms had been
produced. This amendment was written while the restarted fits were running and was committed
before any of them completed (see the git history). The pre-registered rule (section 1.4)
remains the primary rule. Everything added here is either a clarification, a stricter
additional criterion, or labelled exploratory.

**Chronology.**
- 10:58: data profiling (`src/01`).
- 11:03: preparation (`src/02`).
- 11:03-11:20: two control-only timing fits on random subsamples of 20K and 60K posts. These
  had month, business, topic, and caption controls and **no visual terms**. Their only outputs
  were run time, sigma_u, and theta.
- 11:16:07: pre-registration commit `ae91829`, pushed to GitHub immediately.
- 11:20-11:29: first fit batch, stopped with no output.
- 11:31: restart with the amended preprocessing.

The only outcome information seen before registration was the marginal distribution of likes
(Fig. 1) and the control-only dispersion parameters. No association between likes and any
visual feature was examined.

**A1-1 Outcome wording.** The outcome is described as *likes relative to the recorded follower
count*, not as engagement relative to the audience that could see a post. Follower counts are
a single collection-time snapshot and are not impressions. The follower elasticity estimated in
R1 is reported with its 95% CI.

**A1-2 Causal language.** The estimands are conditional associations. The title and text avoid
"drive".

**A1-3 Preprocessing and the Mundlak model.**
- z-scores now use the mean and SD of training accounts only (`02_standardisation.json`).
- The log counts (persons, objects, caption length, hashtags, mentions) are log(1 + x) and are
  not standardised. Missing captions are counted as empty; there are none.
- Assumptions of the Mundlak decomposition:
  - u_j is independent of the post-level covariates given the included account means;
  - the dependence of u_j on those means is linear;
  - within-account coefficients are identified only from accounts with 2 or more posts.
- M1-W includes means only for the two focal predictors of H4. The new exploratory model
  **R5** (M2 plus account means of every post-varying numeric covariate: 8 attributes, person
  terms, object count, caption counts) checks whether the other covariates need the same
  treatment. Shot scale and category dummies get no means; this is noted as a limitation.

**A1-4 Partition descriptives.** `02_partitions.csv` reports, for the full sample, train, test,
and each half: accounts, accounts with 2 or more posts, and the share of each focal predictor's
variance that lies within accounts.

**A1-5 Decision rules, made explicit.**
- *Significance:* Wald z-tests, one-sided for H1-H3 and two-sided for H4, with Holm adjustment
  across H1-H5 (as pre-registered). This tests against a null of no association.
- *Practical importance:* the 95% CI of the IRR lies entirely outside [0.97, 1.03] (as
  pre-registered). This is a separate criterion from significance.
- *Equivalence ("negligible"):* the pre-registered criterion (90% CI inside the band) is
  reported. In addition, a stricter version is applied: TOST p = max of the two one-sided
  p-values against 0.97 and 1.03, Holm-adjusted across H1-H4.
- *Replication:* in each half A and B, the estimate has the same sign as the full-sample
  estimate and nominal p < 0.05 (same sidedness, unadjusted). Practical importance within the
  halves is reported descriptively. This is *internal* replication within one dataset.
- *H5 threshold (new, in log-score units):* H5 is supported if the Holm-adjusted p < 0.05 and
  the lower bound of the 95% bootstrap CI of the score difference is at least **0.01 nats per
  post**. That is a 1% gain in geometric-mean predictive probability (e^0.01 = 1.010), the same
  order as the IRR band. H5 is negligible if the 95% CI lies within ±0.01. The IRR band does
  not apply to H5.
- *Why ±3%:* at the median post (42 likes), 3% is about 1.3 likes. That is far below
  Poisson-level noise for a single post (SD about 6.5 likes, or 15%), so a creator could not
  detect it from their own posts. It is a convention fixed in advance, not an estimate. Verdicts
  at ±1% and ±5% are reported as a sensitivity analysis, and full CIs are given so readers can
  apply their own threshold.

**A1-6 Prediction (H5), specified precisely.**
- The target is the joint predictive distribution of *all* posts of a new account, with u_j
  integrated out jointly.
- The per-post score is the sum over test accounts of log p(y_j), divided by the number of
  test posts, so posts are weighted equally. The account-weighted mean is also reported.
- The bootstrap resamples test accounts and applies the *same* resample to both models
  (paired), 1,000 times.
- Quadrature stability: 30 versus 60 Gauss-Hermite nodes.
- Calibration (exploratory): randomised PIT histogram and the coverage of central 50% and 90%
  prediction intervals, for the single-post marginal predictive of each model [Czado,
  Gneiting & Held 2009].
- Correction: a strictly proper score does not guarantee that a better-scoring model is
  calibrated. Calibration is therefore reported separately.

**A1-7 Diagnostics.**
- For every model: convergence code, pdHess, theta, and sigma_u.
- For M2: randomised quantile residuals [Dunn & Smyth 1996], conditional on the predicted
  u_j, shown as a histogram and QQ summary.
- NB2 variance: Var(y) = mu + mu^2 / theta.

**A1-8 Extreme observations (new robustness check R6).** Refit M1 and M2 without posts whose
likes per follower exceed the training 99.9th percentile and without accounts with more than
10^6 followers.

**A1-9 Registration audit trail.**
- Git tag `prereg-v1` marks `ae91829`; tag `amend-A1` marks this amendment.
- The GitHub repository is private until submission. When it is made public, the commit and
  push timestamps become visible. Archiving the tagged release on Zenodo gives an independent
  DOI timestamp.

**D17 Code verification (after A1).** `src/03` and `src/04` were run end to end on a seeded
6,000-account subsample (7,587 posts) in a scratch copy, to catch code errors before the
full-sample run. This found and fixed a call to `ngrps()`, which needs lme4 attached. Subsample
estimates were used only to confirm that the code runs and were not used for any decision.
Checks:
- 30 versus 60 quadrature nodes changed the H5 score difference by less than 1e-4;
- population-level predictions include the log(followers) offset (eta - offset is about the
  intercept).
