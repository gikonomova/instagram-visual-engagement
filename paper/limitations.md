## Limitations

Several limitations qualify the findings.

**Undocumented feature provenance.** The image features were supplied by the dataset uploader
without documentation. Their names match the AADB attributes [21] and COCO labels [22], but we
cannot verify which models produced them or how accurate those models are on Instagram imagery.
Three scores were numerically degenerate, which shows that the pipeline was not error-free.
For a single error-prone predictor, such as the overall aesthetic score in M1, classical
measurement error biases the IRR towards one. In M2 the attributes are correlated, so the
direction of the bias for any one attribute cannot be guaranteed.

**Cross-sectional follower snapshot.** Follower counts were recorded once per account, at
collection time, not at posting time. For older posts the offset is therefore measured with
error. Robustness check R2 (2019 posts only) limits this problem.

**Exposure time.** Collection dates are unknown, so a post's exposure time cannot be computed
exactly. Month fixed effects absorb average differences, but within-month variation remains.

**Observational design.** The within-account (Mundlak) estimates remove all stable account-level
confounding but not time-varying confounding. For example, an account may post its best-produced
photos for its most important announcements. The estimates are associations, not causal effects
of changing a photo.

**Sample.** The dataset contains only English-language accounts and mostly 2019 posts. The
platform's ranking algorithm and visual culture have changed since then. Engagement norms may
differ for Reels and video, which were excluded.

**Random-effect identification.** Most accounts contribute a single post. For these accounts the
random intercept cannot be separated from post-level overdispersion, and $\sigma_u$ is
identified from the 53,279 multi-post accounts. Robustness check R4 restricts the analysis to
those accounts.
