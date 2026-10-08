---
title: "Visual Features and Likes per Recorded Follower on Instagram: A Pre-Registered Mixed-Model Analysis of 583,830 Posts"
---

::: {custom-style="CSIRAuthors"}
Galya Aymalieva

Sofia University "St. Kliment Ohridski", Faculty of Economics and Business Administration, 125 Tsarigradsko Shose Blvd., Block 3, 1113, Sofia, Bulgaria

gikonomova@uni-sofia.bg
:::

::: {custom-style="CSIRkeywords"}
**Abstract -** Do visual properties of a photograph predict how many likes it earns once audience size is taken into account? We analysed 583,830 Instagram photographs from 469,330 public accounts with a pre-registered negative binomial mixed model. The model has an account random intercept and uses the log of the recorded follower count as an offset. A finding counted only if it passed Holm-corrected significance, exceeded a ±3% smallest effect size of interest (with equivalence tests for null claims), and replicated in two disjoint halves of accounts. Higher overall aesthetic quality (+{{H1_pct}}% likes per follower per SD; IRR {{H1_irr}}, 95% CI {{H1_ci}}) and the presence of a detected person (IRR {{H2_irr}}, {{H2_ci}}) were supported. The aesthetic association held within accounts (IRR {{c_M1W_z_AestheticScore}}), and its between-account component differed only negligibly. Colour vividness, often recommended to creators, had a practically negligible association (IRR {{H3_irr}}, {{H3_ci}}). On 94,172 held-out accounts, visual features improved the joint log predictive score by {{H5_delta}} nats per post (95% CI {{H5_ci}}). A freely estimated follower elasticity of {{EL_M1}} shows that likes grow sublinearly with audience size. The study demonstrates an auditable CRISP-DM workflow for large-sample social-media inference.
:::

**DOI:** -----\
**Corresponding author:** Galya Aymalieva, Sofia University "St. Kliment Ohridski"\
***Email**: gikonomova@uni-sofia.bg*

*Received: -----.* *Revised: -----.* *Accepted: -----.* *Published: -----.*

© 2026 Galya Aymalieva. This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License. The article is published with Open Access at <http://csirjournal.com/>

::: {custom-style="CSIRkeywords"}
**Keywords --** social media analytics, computational aesthetics, negative binomial mixed model, pre-registration, equivalence testing, CRISP-DM
:::

# Introduction

Instagram is the largest image-first social platform, and the number of likes a post receives
is its most visible engagement signal. Brands, influencers, and public-sector communicators
invest in visual production in the belief that how a picture looks affects how well it
performs. A computational literature supports this belief. Computer-vision features have been
associated with engagement in influencer marketing [1], food marketing [2], tourism [3, 4],
architectural photography [5], and public-health communication [6]. Image content has been
shown to matter beyond text in marketing research [7], and photographs containing faces have
been reported to attract more likes [8].

Two features of this literature limit what a practitioner can take from it. First, most studies
analyse a few hundred to a few tens of thousands of posts from a limited set of accounts
[1-6]. Larger studies [18, 26] focus on prediction or profiling rather than on isolating visual
associations. In cross-sectional data, account identity, audience size, and visual style are
entangled. Accounts with larger audiences may also have larger production budgets, so their
photographs are both more polished and more liked. Second, results are typically reported as
statistical significance from exploratory modelling. At the sample sizes now common in
social-media research, a p-value alone is uninformative [9], and screening many features
without a prior protocol invites researcher degrees of freedom [10].

This paper addresses both limitations. We analyse 583,830 photo posts from 469,330 public
accounts with a negative binomial generalised linear mixed model (NB-GLMM) in which the log of
the **recorded follower count** enters as an offset. Each coefficient is therefore a
multiplicative association with *likes relative to the recorded follower count*. This is a
pragmatic normalisation: follower counts are not impressions, and Section 3.1 discusses how they
differ. A random intercept per account captures stable account-level heterogeneity, and a
Mundlak decomposition [11, 12] separates within-account from between-account associations. The
work follows the CRISP-DM process model [13, 14]. The five confirmatory hypotheses, the
smallest effect size of interest (SESOI), the multiplicity correction, and the replication
criterion were committed to a version-controlled protocol *before* any model relating visual
features to likes was estimated [10]. One amendment, made before any confirmatory result
existed, clarified the decision rules (Section 4.5).

We ask two research questions:

- **RQ1.** Which visual properties (overall aesthetic quality, colour vividness, presence of a
  detected person) are associated with likes per recorded follower by an amount that is both
  statistically significant and larger than a pre-specified practical threshold? Do these
  associations replicate across disjoint sets of accounts?
- **RQ2.** Do visual features improve the prediction of likes for accounts the model has not
  seen, beyond follower count, timing, and caption controls?

In brief, two visual properties pass all criteria: overall aesthetic quality (+{{H1_pct}}% likes
per recorded follower per SD) and the presence of a person (about +{{ONE_PERSON_pct}}%). The aesthetic
association holds within accounts. Colour vividness has a practically negligible association.
Visual features improve held-out prediction by a small but reliable margin.

The contributions are fourfold. (i) A pre-registered, audience-normalised analysis of visual
features at the scale of over half a million posts. It uses a decision rule that combines
Holm-corrected significance, a ±3% SESOI with equivalence testing [15], and internal split-half
replication, so practically meaningful associations are separated from those that are merely
detectable at large n. (ii) A quantification of within-account versus between-account
associations, which shows how far visual "drivers" reported in cross-sectional studies may
reflect differences between accounts. (iii) A held-out evaluation of predictive value using the
joint log predictive score for new accounts [16], reported together with calibration
diagnostics [27]. (iv) A fully auditable pipeline: code, decision log, protocol and amendment
(as git tags), and aggregate outputs. Figure 1 maps the CRISP-DM phases to the study's
artefacts.

![Figure 1. Study design: CRISP-DM phases and the point at which the protocol was registered.](outputs/figures/figA_study_design.png){width=3.3in}

# Related Work

## Image features and engagement

Early large-scale work on Flickr found that image content predicts view counts, but much less
well than social context such as follower counts [17]. On Instagram, photos with faces were
reported to receive 38% more likes [8]. Our person indicator comes from a general object
detector (the COCO "person" class [22]). It also flags people seen from behind or at a distance,
so it is a broader construct than face detection. Li and Xie [7] found that image presence and
professional quality are associated with engagement on Twitter and Instagram, with effects that
depend on platform and content. Domain studies have used off-the-shelf vision models to code
content: colour schemes in tourism photographs [3], food typicality [2], lines and corners in
travel-agency posts [4], and image classes in anti-vaping campaigns [6]. In experimental
aesthetics, Instagram likes on architectural photographs have been validated as a measure of
aesthetic appeal [5]. Popularity-prediction studies combine user, post, and image features
[18-20]. They report high rank correlations that are driven largely by user features, and they
rarely isolate the visual contribution. Large Instagram corpora have also been used to profile
influencers by topic [26] rather than to estimate visual associations with engagement.

## Computational aesthetics

The AADB dataset and attribute-adaptive ranking network of Kong et al. [21] defined eleven
interpretable photographic attributes alongside an overall aesthetic score: balancing elements,
colour harmony, content, depth of field, lighting, motion blur, object emphasis, repetition,
rule of thirds, symmetry, and vivid colour. These give a vocabulary for *what kind* of
aesthetic quality matters, which a single score cannot. The dataset used here provides
AADB-named attributes, COCO-style object labels, and a shot-scale classification for each
image. Their provenance is discussed in Section 3.2.

## Methodological gaps

Three gaps motivate the design. (a) **Audience normalisation:** many studies model raw likes or
enter followers as an ordinary covariate. An offset fixes the follower elasticity at one, so
coefficients describe likes per recorded follower; we estimate the elasticity explicitly in
robustness check R1. (b) **Account heterogeneity:** a conventional random intercept does not
remove confounding when account characteristics correlate with post-level predictors. The
Mundlak device [11, 12] recovers within-account associations under stated assumptions.
(c) **Inference at scale:** with hundreds of thousands of observations, significance is nearly
guaranteed [9]. A pre-registered [10] effect-size criterion and equivalence test [15] make "no
practically meaningful association" a falsifiable, reportable outcome.

# Data (CRISP-DM Phases 1-3)

## Business understanding and the outcome

The practical question is which visual properties of a photograph, which a creator controls,
are associated with more likes, *given* the size of the creator's following, which a creator
does not control in the short run. The outcome is the like count of each post. Normalisation
uses the follower count recorded once per account at data collection. Three caveats follow and
are carried through the paper. (1) The recorded count can differ from the audience at posting
time, especially for older posts and fast-growing accounts. (2) Followers are not impressions:
not every follower sees a post, and non-followers can like it. (3) The interval between posting
and collection is unknown. Month-of-posting fixed effects absorb average differences in this
interval and platform-wide shifts. They cannot absorb account-specific follower growth or
post-specific collection intervals. Robustness check R2 (2019 posts only) shortens the time
between posting and the follower snapshot. R1 replaces the offset with an estimated elasticity.

## Data understanding

The data are the public Hugging Face dataset *vargr/ig_train_dataset* [23]: revision
`cb6e88ac5c817329219a3cf55711844774a130a0`, parquet SHA-256
`0aa06bbfad98704a8a2b32b89b053a66f9c7032f6ac8822807f04908b38f61d5`. It contains
{{flow_1_raw}} English-language Instagram posts from {{prof_accounts}} accounts, posted between
February 2012 and August 2019, with {{share_2019}}% from 2019. Each post has like and comment
counts, the recorded follower count, a business-account flag, a caption-topic label, detected
object labels, a 12-level shot-scale label, an 18-level image category, and AADB-named
aesthetic scores. Figure 2 shows the heavy-tailed distributions of likes and followers and the
concentration of posts in 2019. Figure 3 shows the composition of the analysis sample by image
category and shot scale. Fashion, travel, food, and beauty images, and selfies and medium shots,
dominate.

![Figure 2. Distributions of likes and recorded followers (log scale) and posts per month.](outputs/figures/fig1_distributions.png){width=3.3in}

![Figure 3. Composition of the analysis sample by image category and shot scale.](outputs/figures/figC_composition.png){width=3.3in}

**Provenance of the visual features.** The dataset card has no documentation, licence, or
description of the sampling process. A search of the Hugging Face Hub, GitHub, and the
literature found no description of the generating pipeline. The attribute names match AADB
[21], the object labels match COCO [22], and the shot-scale labels match common
cinematographic taxonomies. The generating models, their training data, and any calibration
are unknown. We therefore treat all image-derived variables as *model-based proxies* of the
named constructs. We report three checks of internal plausibility instead of a validation
against human ratings, which was not feasible because the dataset does not include the images.
(i) Two independently produced labels agree (Figure 4): a person is detected in {{pl_selfie}}% of images
labelled selfie and {{pl_portrait}}% labelled portrait, but in only {{pl_aerial}}% of aerial
shots. (ii) Depth-of-field scores agree only partly with shot scale. They are highest for portrait
and close-up shots, which typically have a shallow focus, but extreme close-ups score below
average (mean z = {{pl_dof_ecu}}, against {{pl_dof_ews}} for extreme wide shots), which optics
would not predict (Figure 4). We read this as evidence of substantial measurement noise in the
attribute scores.

![Figure 4. Cross-classifier plausibility: share of images with a detected person and mean depth-of-field score, by shot-scale label.](outputs/figures/figD_feature_plausibility.png){width=3.3in} (iii) Three attributes were
numerically degenerate and were excluded: motion blur (all |values| < 4·10⁻³³), repetition, and
symmetry (constant 0.5). The degenerate attributes show that the feature pipeline was not
error-free. Any null or negligible finding below therefore concerns these proxies, not visual
aesthetics in general.

The overall aesthetic score correlates 0.61-0.86 with six attributes, so it is a composite and
is analysed in a separate model (M1). Among the eight retained attributes, the median absolute
pairwise correlation in the training data is {{corr_med}} and the maximum is {{corr_max}}
(Figure 5). Coefficients in M2 are therefore *conditional* associations: the association of one
attribute with the outcome, holding the others fixed.

![Figure 5. Pairwise correlations of the overall aesthetic score and the eight retained attributes (training accounts).](outputs/figures/figE_attribute_correlations.png){width=3.3in}

## Data preparation

The sample flow is sequential (Figure 6):

1. Start with {{flow_1_raw}} posts.
2. Remove {{flow_2_removed_followers_0}} posts with zero recorded followers, for which the
   offset is undefined; one of them is a video. This leaves {{flow_2_remaining}} posts.
3. Remove {{flow_3_removed_videos}} videos, whose scores describe a single cover frame. This
   leaves **{{flow_3_remaining}} photo posts** from {{flow_accounts}} accounts.

No captions are missing. Captions were reduced to three counts and then discarded: caption
length, hashtags, and mentions, each transformed as log(1 + x). The person count and the object
count are also log(1 + x) and are not standardised. The nine continuous aesthetic scores are
z-standardised using the mean and SD of the **training accounts only**, so each IRR is per one
training SD. No usernames, biographies, or captions are stored or published.

Accounts are assigned to partitions by a salted SHA-256 hash of the account identifier. All
posts of an account fall in the same partition, and the procedure is reproducible without
releasing identifiers.

- **Training and test split:** 80% of accounts for training and 20% held out for prediction
  (H5). The test accounts are used only for H5. All preprocessing parameters come from the
  training accounts.
- **Replication halves A and B:** formed with an independent salt, so they cut across the
  training and test split.
- **Confirmatory inference** (H1-H4) uses all accounts, and the halves are used for internal
  replication.
- **Model selection:** none. Every model specification was fixed in the protocol.

![Figure 6. Sequential sample flow and account-level partitions.](outputs/figures/figB_sample_flow.png){width=3.3in}

Table 1 reports, for each partition, the number of multi-post accounts and the share of each
focal predictor's variance that lies within accounts, which is the information available to
within-account estimates.

{{TABLE_PARTITIONS}}

: Table 1. Partitions, multi-post accounts, and the within-account share of predictor variance (sum of squared deviations from account means divided by the total sum of squares).

# Methods (CRISP-DM Phase 4)

## Model

For post $i$ of account $j$, the like count $y_{ij}$ follows a negative binomial (NB2)
distribution with mean $\mu_{ij}$ and variance $\mu_{ij} + \mu_{ij}^2/\theta$:

$$\log \mu_{ij} = \log F_j + \mathbf{x}_{ij}^{\top}\boldsymbol\beta + \mathbf{c}_{ij}^{\top}\boldsymbol\gamma + u_j,\qquad u_j \sim \mathcal N(0,\sigma_u^2)\qquad (1)$$

Here $F_j$ is the recorded follower count (an offset), $\mathbf{x}_{ij}$ are visual features,
and $\mathbf{c}_{ij}$ are controls: month-of-posting fixed effects (months before 2018 pooled),
business account, caption topic (19 levels), and the three caption counts. $\exp(\beta_k)$ is an
incidence-rate ratio (IRR) for likes per recorded follower, per training SD of a continuous
feature or for a binary switch.

- **M1** contains only the overall aesthetic score as its visual term.
- **M2** contains the eight AADB attributes, a person-presence indicator, log(1 + number of
  persons), log(1 + number of objects), shot scale (reference: medium shot), and image category
  (reference: lifestyle). Person presence and person count are entered together, so each has a
  conditional interpretation. The overall contrast for "one detected person versus none" is
  $\exp(\beta_{\text{presence}} + \beta_{\text{count}}\log 2)$, which we report with a
  delta-method CI.
- **M1-W** adds the account means $\bar{x}_j$ of the aesthetic score and of person presence:

$$\log \mu_{ij} = \log F_j + \beta_W x_{ij} + \delta\,\bar x_j + \mathbf{c}_{ij}^{\top}\boldsymbol\gamma + u_j,\qquad \delta = \beta_B - \beta_W\qquad (2)$$

Here $\beta_W$ is the within-account association and $\beta_B = \beta_W + \delta$ is the
between-account association. The decomposition assumes that, given $\bar{x}_j$, $u_j$ is
independent of the post-level covariates and depends on $\bar{x}_j$ linearly. $\beta_W$ is
identified only from accounts with two or more posts (Table 1). Among those accounts,
42-62% of each predictor's variance lies within accounts (Figure 7), so within-account
estimates rest on substantial variation.

![Figure 7. Share of each predictor's variance that lies within accounts, among accounts with two or more posts.](outputs/figures/figF_within_share.png){width=3.3in} M1-W gives means only to the two
focal predictors of H4. The exploratory model **R5** adds account means for *every* post-varying
numeric covariate of M2 and so tests whether the other covariates need the same treatment. The
categorical shot and category dummies receive no means.

Models were fitted by maximum likelihood with the Laplace approximation in glmmTMB 1.1.9 [24]
under R 4.1.2. For every model we record the convergence code and whether the Hessian is
positive definite.

## Separating account heterogeneity from dispersion

For an account with one post, $u_j$ and the NB2 dispersion both inflate the marginal variance.
They are distinguishable only through the shape of the marginal distribution, a lognormal
mixture of negative binomials, so identification of $\sigma_u$ rests mainly on the
{{acc2_all}} multi-post accounts ({{acc2_posts_all}} posts). We therefore report $\theta$ and
$\sigma_u$ for every model (Table 7). We also refit the main models on multi-post accounts only
(R4), where $\sigma_u$ is identified from repeated posts.

## Prediction and calibration (H5)

The predictive target is the **joint** distribution of all posts of a new account. Because the
account is unseen, $u_j$ is integrated out jointly over its posts:

$$\log p(\mathbf y_j) = \log \int \prod_{i=1}^{n_j} \text{NB2}\!\left(y_{ij}\mid \exp(\hat\eta_{ij}+u),\hat\theta\right)\phi(u;0,\hat\sigma_u^2)\,du\qquad (3)$$

Here $\hat\eta_{ij}$ is the fitted fixed-effect linear predictor including the offset,
$n_j$ is the number of posts of account $j$, $\phi$ is the normal density, and the integral is
evaluated by Gauss-Hermite quadrature with 30 nodes (checked against 60). The per-post score is
$\sum_j \log p(\mathbf y_j) / \sum_j n_j$, which weights posts equally; the account-weighted
mean is also reported. Models M0 (controls only) and M2 were fitted on training accounts and
scored on the {{test_accounts}} test accounts ({{test_posts}} posts). The 95% CI of the score
difference comes from 1,000 *paired* bootstrap resamples of test accounts, applying the same
resample to both models. A strictly proper score rewards the true predictive distribution in
expectation [16]. It does not guarantee that the better-scoring model is calibrated, so we
report calibration separately: randomised probability integral transform (PIT) histograms
[27] and the empirical coverage of central 50% and 90% prediction intervals, computed from each
post's marginal predictive distribution.

## Pre-registered hypotheses and decision rules

Table 2 lists the hypotheses. Each was registered with its direction, estimand, model, and test
before estimation.

| H | Claim (association) | Estimand / model | Test |
|---|---|---|---|
| H1 | Higher overall aesthetic score → more likes per recorded follower | IRR per SD, $\beta$ of aesthetic score in M1 | One-sided Wald, IRR > 1 |
| H2 | A detected person → more likes per recorded follower | IRR of person presence in M2 | One-sided Wald, IRR > 1 |
| H3 | More vivid colour → more likes per recorded follower | IRR per SD of vivid colour in M2 | One-sided Wald, IRR > 1 |
| H4 | Within- and between-account aesthetic associations differ | $\exp(\delta)$ in M1-W (eq. 2) | Two-sided Wald, $\delta \ne 0$ |
| H5 | Visual features improve held-out prediction | Δ joint log score per post, M2 − M0 | One-sided paired bootstrap, Δ > 0 |

: Table 2. Confirmatory hypotheses (registered as tag prereg-v1).

The decision rules separate three questions.

**(a) Statistical significance against a null of no association.** Wald tests (one-sided for
H1-H3, two-sided for H4) and the bootstrap test for H5. The five p-values are Holm-adjusted [25].

**(b) Practical importance.** For H1-H4, the 95% CI of the IRR lies entirely outside the SESOI
band [0.97, 1.03]. For H5, which is measured in log-score units, the lower 95% bound of the
score difference must be at least 0.01 nats per post. That threshold is a 1% gain in
geometric-mean predictive probability ($e^{0.01} = 1.010$), the same order as the IRR band.

**(c) Internal replication.** In each half A and B, the estimate has the same sign as in the
full sample and a nominal p < 0.05 with the same sidedness, unadjusted. For H5, the score
difference is positive in the test accounts of both halves.

A hypothesis is **supported** if (a) after Holm adjustment, (b), and (c) all hold. It is
**negligible** if the 90% CI lies inside the band, as pre-registered, *and* the two one-sided
tests (TOST) [15] against 0.97 and 1.03 reject after Holm adjustment across H1-H4. For H5,
negligible means the 95% CI lies within ±0.01. Anything else is **inconclusive**. The ±3% band
was fixed in advance as a convention, not estimated. At the median post (42 likes) it
corresponds to about 1.3 likes, far below the Poisson-level noise of a single post (SD ≈ 6.5
likes). We report verdicts for ±1% and ±5% as a sensitivity analysis (Table 4), together with all
CIs.

Pre-specified robustness checks:
- **R1:** log follower count as a free covariate, which estimates the elasticity;
- **R2:** 2019 posts only;
- **R3:** comments as the outcome;
- **R4:** accounts with two or more posts only.

Two further checks were added in the amendment, before any results:
- **R5:** the full Mundlak model;
- **R6:** without posts above the training 99.9th percentile of likes per recorded follower
  and without accounts with more than 10⁶ followers.

All are exploratory.

## Registration and chronology

The protocol is stored in `DECISIONS.md` in the project repository. It is marked by git tag
`prereg-v1` (commit `ae91829`, 2026-10-08 11:16:07 EEST, pushed to GitHub immediately) and by
amendment tag `amend-A1` (commit `2b7378c`, 11:33:32 EEST). The repository records the
complete chronology. Before registration, the only outcome information inspected was the
marginal distribution of likes (Figure 2) and the dispersion parameters of two control-only
timing fits on random subsamples. These fits contained no visual terms. A first batch of fits
was stopped before any model finished, because the amendment changed the preprocessing. All
confirmatory fits were run after the amendment. A code check on a 6,000-account subsample
followed the amendment and did not alter any specification. Because the registration lives in
a repository the author controls, its independence rests on the git and GitHub timestamps.
Archiving the tagged release with a DOI service would give an independent timestamp.

# Results (CRISP-DM Phase 5)

## Confirmatory hypotheses

Table 3 and Figure 8 summarise the five confirmatory tests. Three hypotheses are supported,
and two are classified as negligible. No hypothesis is inconclusive.

{{TABLE_CONFIRMATORY}}

: Table 3. Confirmatory results. IRRs are per training SD (H1, H3), for presence versus absence (H2), or $\exp(\delta)$ = between/within ratio (H4). H5 is the difference in joint log score per post on held-out accounts. p values are Holm-adjusted across H1-H5 (significance) and across H1-H4 (TOST).

![Figure 8. Confirmatory estimates for the full sample and the two replication halves. Grey band: SESOI [0.97, 1.03].](outputs/figures/fig0_confirmatory.png){width=3.3in}

**H1 (overall aesthetic score): supported.** One training SD higher aesthetic score is
associated with {{H1_pct}}% more likes per recorded follower (IRR {{H1_irr}}, 95% CI
{{H1_ci}}). The interval lies entirely above the SESOI band, and the estimate is reproduced
almost exactly in half A ({{H1_A}}) and half B ({{H1_B}}).

**H2 (person present): supported.** Holding the other visual terms fixed, photographs with a
detected person receive {{H2_pct}}% more likes per recorded follower (IRR {{H2_irr}}, 95% CI
{{H2_ci}}; halves {{H2_A}} and {{H2_B}}). Because person count enters the same model, the
overall contrast for exactly one person against none is IRR {{ONE_PERSON}} {{ONE_PERSON_ci}}.
Each additional person is associated with slightly fewer likes (IRR for log(1 + persons)
{{c_M2_log_n_person}}).

**H3 (vivid colour): negligible, and in the opposite direction.** Conditional on the other
attributes, vivid colour is associated with *fewer* likes (IRR {{H3_irr}}, 95% CI {{H3_ci}}). The
one-sided test for a positive association is not significant (Holm p = {{H3_p}}). The 90% CI
{{H3_ci90}} lies inside the SESOI band and the Holm-adjusted TOST rejects (p = {{H3_ptost}}), so
any association is smaller than ±3% per SD.

**H4 (within versus between accounts): negligible difference.** Between-account and
within-account aesthetic associations differ significantly (ratio {{H4_irr}}, 95% CI {{H4_ci}},
Holm p = {{H4_p}}), but the difference is practically negligible (90% CI {{H4_ci90}}; TOST Holm
p = {{H4_ptost}}). The within-account association alone is IRR {{c_M1W_z_AestheticScore}}, and
the implied between-account association is {{BETWEEN_AES}}. Most of the aesthetic association
therefore holds *within* the same account: an account's better-scored photographs earn more
likes per follower than its own weaker ones.

**H5 (prediction): supported.** On {{test_accounts}} held-out accounts, adding the visual
features improves the joint log predictive score by {{H5_delta}} nats per post (95% paired
bootstrap CI {{H5_ci}}). That is a {{H5_gm}}% gain in geometric-mean predictive probability. The
lower bound exceeds the pre-specified 0.01 threshold. The gain is the same in the test accounts
of both halves ({{H5_A}} and {{H5_B}}), with account weighting ({{H5_acctw}}), and with 60
quadrature nodes ({{H5_60}}). The rank correlation between predicted and observed likes per
recorded follower rises from {{H5_rho0}} (controls only) to {{H5_rho2}}.

Verdicts are stable across practical thresholds (Table 4). H1 and H2 exceed even a ±5% band.
H3 and H4 are inside the band at ±3% and ±5%, but outside it at ±1%, so they are small rather
than exactly zero.

{{TABLE_SENS}}

: Table 4. SESOI sensitivity: whether the 95% CI lies entirely outside the band / the 90% CI lies entirely inside it.

## Exploratory results: attributes, content, and framing

Figure 9 shows all visual terms of M2. Beyond the confirmatory terms, the content attribute
({{c_M2_z_ContentAesthetics}}) is the only aesthetic attribute whose interval lies above the
SESOI band. Lighting ({{c_M2_z_LightScore}}) and rule of thirds ({{c_M2_z_RuleOfThirdsScore}}) are
positive but straddle the band. Object emphasis ({{c_M2_z_ObjectScore}}) is slightly negative,
and depth of field ({{c_M2_z_DoFScore}}) is null. The attributes are correlated (Figure 5), so
these are conditional associations and should not be read as independent levers.

![Figure 9. Visual terms of M2 (IRR per training SD for attributes). Grey band: SESOI.](outputs/figures/fig2_m2_visual_irr.png){width=3.3in}

Framing and genre matter more than any single aesthetic attribute (Figure 10). Relative to
medium shots, close-ups ({{c_M2_image_shotClose_Up_Shot}}), point-of-view shots
({{c_M2_image_shotPoint_of_View_Shot}}), and aerial shots ({{c_M2_image_shotAerial_Shot}})
receive 11-14% fewer likes per recorded follower. Portraits are the only shot scale above the
reference ({{c_M2_image_shotPortrait_Shot}}). Among image categories, sport
({{c_M2_image_categorySport}}), art ({{c_M2_image_categoryArt}}), fashion
({{c_M2_image_categoryFashion}}), and animals ({{c_M2_image_categoryAnimals}}) are above the
lifestyle reference. Text images ({{c_M2_image_categoryText}}) and brand imagery
({{c_M2_image_categoryBrand}}) are below it. Among the controls, business accounts receive fewer
likes per recorded follower ({{c_M2_business}}), as do captions with more mentions
({{c_M2_log_mentions}} per log unit).

![Figure 10. Shot-scale and image-category terms of M2 (IRR against medium shot and lifestyle).](outputs/figures/fig3_m2_categories_irr.png){width=3.3in}

Internal replication extends beyond the confirmatory terms. Across all visual terms of M2, the
log-IRRs estimated in half A and half B correlate at 0.98 (Figure 11).

![Figure 11. Replication of all M2 visual terms across disjoint halves of accounts.](outputs/figures/fig4_replication.png){width=3.3in}

## Robustness

Table 5 and Figure 12 report the focal estimates under each robustness specification.
Freeing the follower coefficient (R1) gives an elasticity of {{EL_M1}} {{EL_M1_ci}}, well below
the value of 1 imposed by the offset. Likes grow less than proportionally with recorded
followers. Under R1 the aesthetic association becomes larger ({{rob_R1_M1_z_AestheticScore}}),
so the offset specification is, if anything, conservative for H1. Restricting to multi-post
accounts (R4), where the account effect is identified from repeated posts, gives the same signs
and similar magnitudes: aesthetic {{rob_R4_M1_z_AestheticScore}}, person
{{rob_R4_M2_person_present}}, vivid colour {{rob_R4_M2_z_VividColorScore}}. {{ROBUST_REST}}

{{TABLE_ROBUST}}

: Table 5. Focal estimates across robustness specifications (exploratory).

![Figure 12. Focal estimates across robustness specifications. Grey band: SESOI.](outputs/figures/fig7_robustness.png){width=3.3in}

## Model adequacy and calibration

{{CONVERGENCE_SENTENCE}} The NB2 dispersion and the account SD are similar across models
(Table 7). In the main model M2, $\hat\theta$ = {{theta_M2}} and $\hat\sigma_u$ = {{su_M2}}. On
multi-post accounts only (R4), $\hat\sigma_u$ = {{su_R4_M2}}, so the account variance is not an
artefact of single-post accounts. Calibration on held-out accounts is adequate but not perfect
(Table 6, Figure 13). Central 50% and 90% prediction intervals cover {{cal_M2_50}} and
{{cal_M2_90}} of observations for M2 ({{cal_M0_50}} and {{cal_M0_90}} for M0). Both PIT
histograms show the same mild excess of observations below the predictive distribution and a
deficit in the extreme upper tail. Calibration is nearly identical for M0 and M2, so the H5 gain
reflects sharper predictions rather than a calibration difference. Conditional randomised
quantile residuals [28] are under-dispersed (Figure 14). This is expected when the predicted
account effect absorbs the single post of most accounts, so the held-out PIT is the more
informative check.

{{TABLE_CALIB}}

: Table 6. Calibration on held-out accounts (single-post marginal predictive distributions).

![Figure 13. Randomised PIT histograms on held-out accounts. A uniform histogram (dashed line) indicates calibration.](outputs/figures/fig6_pit.png){width=3.3in}

![Figure 14. Conditional randomised quantile residuals of M2 with the standard normal density (dashed).](outputs/figures/fig5_m2_residuals.png){width=3.3in}

{{TABLE_DIAG}}

: Table 7. Fitted models: sample, NB2 dispersion θ, account SD σ_u, and convergence checks.

# Discussion

## What the evidence supports

Two visual properties pass every criterion: significance after multiplicity correction, a
practically meaningful size, and internal replication. Photographs with a higher overall
aesthetic score, and photographs that contain a detected person, receive more likes per recorded
follower. The person association (about +{{ONE_PERSON_pct}}% for one person against none) is four times the
aesthetic association per SD (+{{H1_pct}}%). It is also about the same size as the differences
between shot scales and image genres (Figure 10). For a creator choosing *what* to photograph,
this suggests that content and framing carry more weight than polish on any single aesthetic
attribute. In the M2 model, no individual attribute exceeds +4% per SD.

The person result is consistent in direction with the face effect reported by Bakhshi et al.
[8] but smaller (+{{ONE_PERSON_pct}}% against +38%). Three differences can explain the gap: the indicator here
is a general person detector, not a face detector; the outcome is normalised by followers; and
the model conditions on shot scale, genre, and the aesthetic attributes. The aesthetic result
agrees with experimental-aesthetics evidence that Instagram likes track aesthetic appeal [5] and
with the professional-quality effect in [7]. Our design adds that the association is mostly a
within-account phenomenon. H4 found a statistically detectable but practically negligible
difference between between-account and within-account associations, and the within-account
association alone (+4.2% per SD) clears the SESOI band. The aesthetic "driver" is therefore not
mainly an artefact of better-resourced accounts posting better-looking photographs. Within one
account, the better-scored photographs earn more likes per follower.

## What it does not support

Vivid colour, the attribute most often recommended in practitioner advice and studied in
tourism marketing [3], shows no practically meaningful association. Its conditional association
is slightly *negative*, and the equivalence test bounds it inside ±3% per SD. This is a
conditional estimate. Vividness correlates 0.61-0.75 with colour harmony, lighting, content, and
the overall score (Figure 5), so its unique contribution, holding those fixed, is small. That
does not contradict findings that specific colour *schemes* matter in specific genres [3]. It
does indicate that "more vivid" is not, in itself, a general lever.

H3 and H4 illustrate the large-sample p-value problem [9]. Both coefficients are
"significant" at conventional levels, H3 in the unexpected direction, yet both are bounded
inside ±3% with Holm-adjusted equivalence tests. Without the pre-registered SESOI and the
equivalence test, both would probably have been reported as findings.

## Audience normalisation

The free follower elasticity of {{EL_M1}} is a substantive finding in its own right. Likes grow
sublinearly with recorded followers, so likes-per-follower engagement rates systematically
favour small accounts. For research, an offset is a convenient normalisation, but its implied
elasticity of one should be tested rather than assumed. In our data, freeing it strengthened the
aesthetic association (R1), so the offset results are conservative for H1. For practitioners,
engagement-rate comparisons across accounts of very different size need a size adjustment.

## Prediction

Visual features improve out-of-sample prediction for unseen accounts by a modest but reliable
{{H5_delta}} nats per post (a {{H5_gm}}% gain in geometric-mean predictive probability). The rank
correlation of predicted and observed likes per follower rises from {{H5_rho0}} to {{H5_rho2}}.
Most of the remaining variation sits in the account effect ($\hat\sigma_u \approx$ {{su_M2}},
about a 2.5-fold difference in expected likes per follower between accounts one SD apart) and
in post-level noise. Visual features alone therefore cannot forecast an individual post's
performance well, consistent with earlier findings that social context dominates popularity
prediction [17, 18].

## Limitations

**Unvalidated feature provenance.** The image features were supplied without documentation.
Their names match AADB [21] and COCO [22], but the generating models and their accuracy on
Instagram imagery are unknown. Three scores were numerically degenerate, and depth-of-field
scores agree only partly with shot scale (Figure 4). For a single error-prone predictor such as
the overall score, classical measurement error biases the IRR towards one. In M2 the attributes
are correlated, so the direction of bias for any one attribute is not guaranteed. The
negligible findings (H3) concern these proxies, not colour vividness as perceived by viewers.

**Follower snapshot and exposure.** Followers were recorded once per account, at collection.
They are not impressions, and the time between posting and collection is unknown. Month fixed
effects absorb average differences but not account-specific follower growth.

**Observational design.** Mundlak within-account estimates remove stable account-level
confounding under the stated assumptions, but not time-varying confounding. For example, an
account may post its best-produced photographs alongside important announcements. All estimates
are associations, not effects of changing a photograph.

**Sample and generalisability.** The sampling process behind the dataset is undocumented. The
data are English-language only and {{share_2019}}% from 2019, before the platform's shift towards Reels and
short video, and videos were excluded. Instagram's ranking and visual culture have changed
since. Replication is internal (split halves of one dataset), not an independent replication on
new data.

**Calibration.** Predictive distributions are adequately but not perfectly calibrated, with
mild misfit in the tails (Figure 13). A model with a more flexible dispersion structure, such as
dispersion varying by genre, may improve this.

# Conclusion

In 583,830 Instagram photographs, two visual properties are robustly associated with more likes
per recorded follower: higher overall aesthetic quality (+{{H1_pct}}% per SD) and the presence of
a person (about +{{ONE_PERSON_pct}}%). Both pass Holm-corrected significance, a pre-registered ±3% practical
threshold, and split-half replication. The aesthetic association holds within accounts, not
only between them. Colour vividness, often recommended to creators, has a practically
negligible association, bounded by an equivalence test. Visual features add a small but reliable
improvement to predictions for unseen accounts. Methodologically, the study shows how
pre-registration, an explicit smallest effect size of interest, and equivalence testing turn
"significant at n = 583,830" into claims that can be checked. It also shows that audience
normalisation by follower count should be tested: the estimated elasticity is {{EL_M1}}, not 1.
Future work should validate the image features against human ratings, use exposure data
(impressions) where platforms provide them, and test whether the associations hold for short
video.

# Reproducibility Statement

All code, the decision log and protocol (tags `prereg-v1` and `amend-A1`), aggregate outputs,
and the full git history are in the project repository,
<https://github.com/gikonomova/instagram-visual-engagement>. `run_all.sh` downloads the
dataset, verifies its SHA-256 checksum, and reproduces every table and figure. Every number in
this manuscript is inserted from the output tables by `paper/fill.py`. Partitions are
deterministic salted hashes. The bootstrap seed is 20261008.

Software: Python 3.9.6 (pyarrow 21.0.0, pandas 2.3.3, numpy 2.0.2, matplotlib 3.9.4), R 4.1.2
(glmmTMB 1.1.9, TMB, data.table, nanoparquet, ggplot2), and pandoc for the manuscript. The full
R session information is in `outputs/tables/03_sessionInfo.txt`. Raw data and fitted model
objects are not redistributed because they contain account identifiers.

# Ethical Considerations

This is a secondary analysis of a dataset of public Instagram posts that was already publicly
available. No data were collected from, and no contact was made with, any individual. Usernames,
biographies, and captions were never written to disk after loading. Captions were reduced to
three counts, and only aggregate statistics are published. No account is identified.

The dataset is distributed without a licence or documented provenance. We therefore cannot
verify the conditions under which it was collected. This is a limitation for any reuse, and it
is why we redistribute neither the data nor derived post-level records. No institutional
ethics review was obtained for this study. The analysis involves no interaction with human
participants, uses only data that were already public, and reports only aggregate results.

# Data Availability Statement

The source data are publicly available from Hugging Face [23] (revision and checksum in Section
3.2). Analysis code, the registered protocol, and all aggregate outputs underlying the tables and
figures are available at <https://github.com/gikonomova/instagram-visual-engagement> (tags
`prereg-v1`, `amend-A1`). Post-level derived data are not redistributed because they contain
account identifiers. They can be regenerated exactly from the public source with `run_all.sh`.

# Author Contributions (CRediT)

Galya Aymalieva: Conceptualization, Methodology, Software, Formal analysis, Data curation,
Validation, Visualization, Writing -- original draft, Writing -- review & editing.

# Conflict of Interest

The author declares no conflict of interest.

# Funding

This research received no specific grant from any funding agency in the public, commercial, or not-for-profit sectors.

# Declaration of Generative AI and AI-Assisted Technologies in the Writing Process

During the preparation of this work the author used Claude (Anthropic) to assist with code
generation for the analysis pipeline, literature search, and drafting of manuscript sections.
After using this tool, the author reviewed and edited all content and takes full responsibility
for the content of the published paper.

# References

::: {custom-style="CSIRReferences"}
