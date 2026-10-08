---
title: "Do Visual Features Drive Instagram Engagement Once Audience Size Is Accounted For? A Pre-Registered Mixed-Model Analysis of 584,000 Posts"
---

::: {custom-style="CSIRAuthors"}
Galya Aymalieva

Sofia University "St. Kliment Ohridski", Faculty of Economics and Business Administration, 125 Tsarigradsko Shose Blvd., Block 3, 1113, Sofia, Bulgaria

gikonomova@uni-sofia.bg
:::

::: {custom-style="CSIRkeywords"}
**Abstract -** {{ABSTRACT}}
:::

**DOI:** -----\
**Corresponding author:** Galya Aymalieva, Sofia University "St. Kliment Ohridski"\
***Email**: gikonomova@uni-sofia.bg*

*Received: -----.* *Revised: -----.* *Accepted: -----.* *Published: -----.*

© 2026 Galya Aymalieva. This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License. The article is published with Open Access at <http://csirjournal.com/>

::: {custom-style="CSIRkeywords"}
**Keywords --** social media analytics, computational aesthetics, negative binomial mixed model, pre-registration, CRISP-DM
:::

# Introduction

Instagram is the largest image-first social platform, and the number of likes a post receives
is the most visible currency of the attention economy. Brands, influencers, and public-sector
communicators spend heavily on visual production in the belief that *how a picture looks*
determines how well it performs. A growing computational literature appears to support this
belief. Deep-learning and computer-vision features have been linked to engagement in influencer
marketing [1], food marketing [2], tourism [3, 4], architecture [5], and public-health
communication [6]. Image content has been shown to matter beyond text in marketing research [7],
and faces in particular have been reported to raise engagement [8].

Two features of this literature limit what it can tell a practitioner. First, most studies
analyse a few hundred to a few tens of thousands of posts from a small number of accounts
[1-5]. At that scale, account identity, audience size, and visual style are entangled: an
account with a large, loyal audience may also have a larger production budget, so its photos
are both better-looking and more liked. Without a within-account comparison, a "visual effect"
cannot be separated from an "account effect". Second, results are usually reported as
statistical significance from exploratory modelling. Sample sizes in social-media data are now
so large that the p-value alone is uninformative [9]. When many features are screened, the
reported "drivers" also risk being artefacts of researcher degrees of freedom [10].

This paper addresses both limitations. We analyse 583,830 photo posts from 469,330 public
accounts with a negative binomial generalised linear mixed model (NB-GLMM) in which **log
follower count enters as an offset**. Every coefficient is therefore a multiplicative effect
on *likes per follower*: the engagement a photo earns relative to the audience that could see
it. A random intercept per account absorbs stable account-level differences, and a Mundlak
within/between decomposition [11, 12] tests directly whether visual effects operate within
accounts or only between them. The work follows the CRISP-DM process model [13, 14]. Most
importantly, all five confirmatory hypotheses, the smallest effect size of interest (SESOI),
the multiplicity correction, and the replication criterion were committed to a public git
repository *before* any model relating visual features to likes was fitted [10].

We ask two research questions:

- **RQ1.** Which visual properties (overall aesthetic quality, colour vividness, presence of
  people) are associated with more likes per follower, by an amount that is both statistically
  significant and practically meaningful, and do those associations replicate across
  independent sets of accounts?
- **RQ2.** Do visual features improve the prediction of engagement for accounts the model has
  never seen, beyond audience size, timing, and caption controls?

{{INTRO_RESULTS}}

The contributions are fourfold. (i) To our knowledge this is the largest audience-normalised
analysis of visual features and Instagram engagement, roughly an order of magnitude larger than
the studies reviewed in Section 2. (ii) It is pre-registered, with a decision rule that combines
Holm-corrected significance, a ±3% SESOI with equivalence testing [15], and split-half
replication. This separates practically meaningful effects from effects that are merely
detectable at large n. (iii) It quantifies within- versus between-account effects, which
indicates how far visual "drivers" reported in cross-sectional studies reflect account selection.
(iv) It evaluates predictive value with a strictly proper scoring rule [16] on held-out accounts,
integrating over the unknown account effect. The full pipeline, decision log, and git history
are public.

# Related Work

## Image features and engagement

Early large-scale work on Flickr showed that image content and low-level features predict view
counts, but much less well than social context such as follower counts [17]. On Instagram,
photos with faces were found to receive 38% more likes [8]. Li and Xie [7], studying Twitter and
Instagram, found that image presence and professional quality raise engagement, with effects
that depend on platform and content. Domain studies have since used off-the-shelf vision models
to code content: colour schemes in tourism photos [3], food typicality via Google Vision [2],
lines and corners in travel-agency posts [4], and image classes in anti-vaping campaigns [6].
In experimental aesthetics, Instagram likes on architectural photographs have been validated as a
measure of aesthetic appeal [5]. Popularity-prediction studies combine user, post, and image
features in machine-learning models [18-20]. They report high rank correlations that are driven
largely by user features, and they rarely isolate the visual contribution.

## Computational aesthetics

The AADB dataset and the attribute-adaptive ranking network of Kong et al. [21] introduced
eleven interpretable photographic attributes (balancing elements, colour harmony, content, depth
of field, lighting, motion blur, object emphasis, repetition, rule of thirds, symmetry, vivid
colour) alongside an overall aesthetic score. Object labels in most applied pipelines follow the
COCO taxonomy [22]. These attributes give an interpretable vocabulary for *what kind* of
aesthetic quality matters, which a single learned "aesthetic score" cannot. The dataset used
here provides AADB-style attributes, COCO-style object labels, and a shot-scale classification
for every image.

## Methodological gaps

Three gaps motivate the design. (a) **Audience normalisation:** many studies model raw likes,
or use followers as an ordinary covariate whose coefficient absorbs much of the variance. An
offset fixes the follower elasticity at one, so coefficients are interpretable as effects on
engagement rate. We test that assumption explicitly (robustness R1). (b) **Account
heterogeneity:** pooled cross-sectional estimates confound visual style with account quality.
The Mundlak approach [11, 12] recovers the within-account effect inside a random-effects model.
(c) **Inference at scale:** with n in the hundreds of thousands, statistical significance is
nearly guaranteed [9]. We therefore pre-register [10] an effect-size criterion and an
equivalence test [15], so that "no meaningful effect" is a reportable, falsifiable outcome.

# Data and Problem Formulation (CRISP-DM Phases 1-3)

## Business and data understanding

The study uses the publicly available Hugging Face dataset *vargr/ig_train_dataset* [23]
(revision cb6e88ac, SHA-256-verified). It contains 605,868 English-language Instagram posts from
485,125 accounts, posted between February 2012 and August 2019. 70.7% of the posts are from 2019.
For each post the dataset provides like and comment counts, follower count, a business-account
flag, a caption-topic label, detected object labels, a 12-level shot-scale label, an 18-level
image category, and AADB-style aesthetic scores. The dataset card provides no documentation of
how the features were generated. We therefore treat all image-derived variables as *model-based
proxies* and report this as a limitation. Fig. 1 shows the heavy-tailed distributions of likes
and followers and the concentration of posts in 2019.

Profiling (Table 1) found three degenerate scores: motion blur (all |values| < 4·10⁻³³),
repetition, and symmetry (constant 0.5). These were excluded. The overall aesthetic score
correlates 0.61-0.86 with six of the attributes, so it is a composite and is analysed in a
separate model. Follower counts are a single snapshot per account, taken at collection time.
The median account contributes one post. Only 53,279 accounts (174,022 posts) contribute two
or more.

{{TABLE1}}

## Data preparation

We removed 232 posts with zero followers, for which the offset is undefined, and 21,807 videos,
whose scores describe a single cover frame. This left 583,830 photo posts from 469,330 accounts.
Captions were reduced to three counts (log length, hashtags, mentions) and then discarded. No
usernames, biographies, or captions are stored or published. Continuous visual features were
z-scored. Accounts were assigned by a salted SHA-256 hash of their identifier to (a) a training
set (80%) and a held-out test set (20%), and (b) two replication halves A and B. All posts of an
account fall in the same partition.

## Model

For post $i$ of account $j$, likes $y_{ij}$ follow a negative binomial (NB2) distribution with
mean $\mu_{ij}$ and dispersion $\theta$:

$$\log \mu_{ij} = \log(\text{followers}_j) + \mathbf{x}_{ij}^{\top}\boldsymbol\beta + \mathbf{c}_{ij}^{\top}\boldsymbol\gamma + u_j,\qquad u_j \sim \mathcal N(0,\sigma_u^2)\qquad (1)$$

where $\mathbf{x}_{ij}$ are visual features and $\mathbf{c}_{ij}$ are controls: month-of-posting
fixed effects (pre-2018 pooled), business account, caption topic (19 levels), and the three
caption counts. Month effects absorb the average difference in time that posts have had to
accumulate likes, as well as platform-wide shifts. Because of the offset, $\exp(\beta_k)$ is an
incidence-rate ratio (IRR) on likes per follower, per SD of a continuous feature or for a binary
switch. Model M1 uses the overall aesthetic score. Model M2 uses the eight non-degenerate AADB
attributes, person presence, log(1 + number of persons), log(1 + number of objects), shot scale
(reference: medium shot), and image category (reference: lifestyle). Model M1-W adds the account
means $\bar{x}_j$ of the aesthetic score and person presence (Mundlak [11]). The coefficient on
$\bar{x}_j$ then equals the between-account minus the within-account effect:

$$\log \mu_{ij} = \log(\text{followers}_j) + \beta_W x_{ij} + \delta\,\bar x_j + \mathbf{c}_{ij}^{\top}\boldsymbol\gamma + u_j,\qquad \delta = \beta_B - \beta_W\qquad (2)$$

Models were fitted by maximum likelihood with the Laplace approximation in glmmTMB 1.1.9 [24]
(R 4.1.2).

## Pre-registered hypotheses and decision rule

The hypotheses (Table 2) were committed to the public repository (commit `ae91829`) before any
outcome model was fitted. The five p-values are Holm-adjusted [25]. A hypothesis is
**supported** if the adjusted p < 0.05, the 95% CI of the IRR lies entirely outside the SESOI
band [0.97, 1.03], and the effect has the same sign and is significant (p < 0.05) in both
replication halves. It is declared **negligible** if the 90% CI lies entirely inside the band
(two one-sided tests [15]). Otherwise it is **inconclusive**. H5 compares the mean per-post
log predictive score of M2 and a controls-only model M0 on held-out accounts. For each new
account the random effect is integrated out jointly over its posts by 30-point Gauss-Hermite
quadrature:

$$\log p(\mathbf y_j) = \log \int \prod_{i} \text{NB}\!\left(y_{ij}\mid e^{\eta_{ij}+u},\theta\right)\phi(u;0,\hat\sigma_u^2)\,du\qquad (3)$$

The 95% CI of the difference comes from 1,000 account-level bootstrap resamples. The log score is
strictly proper [16], so an improvement cannot be obtained by miscalibrated predictions.

{{TABLE2}}

Pre-specified robustness checks were: R1, log(followers) as a free covariate instead of an
offset; R2, posts from 2019 only; R3, comments as the outcome; R4, accounts with two or more
posts only.

{{RESULTS}}

{{DISCUSSION}}

# Reproducibility Statement

All code, the decision log, pre-registration, aggregate outputs, and the git history are
available at <https://github.com/gikonomova/instagram-visual-engagement>. The pipeline
(`run_all.sh`) downloads the dataset, verifies its checksum, and reproduces every table and
figure. Account partitions are deterministic hashes. The bootstrap seed is 20261008. Software:
Python 3.9 (pyarrow 21, pandas 2.3), R 4.1.2, glmmTMB 1.1.9, data.table, ggplot2. Raw data and
fitted model objects are not redistributed because they contain account identifiers.

# Ethical Considerations

The analysis uses a publicly posted secondary dataset of public Instagram posts. No new data
were collected and no individual was contacted. Usernames, biographies, and captions were
never stored after loading. Only aggregate statistics are published. The dataset is distributed
without an explicit licence or documented provenance, which limits the claims that can be made
about collection consent. We report the analysis as secondary research on aggregate patterns
and do not identify any account.

# Declaration of Generative AI and AI-Assisted Technologies in the Writing Process

During the preparation of this work the author used Claude (Anthropic) to assist with code
generation for the analysis pipeline, literature search, and drafting of manuscript sections.
After using this tool, the author reviewed and edited all content and takes full responsibility
for the content of the published paper.

# References

::: {custom-style="CSIRReferences"}
