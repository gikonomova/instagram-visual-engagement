# CRISP-DM phase 4 - Modelling. Fits the pre-registered models (DECISIONS.md, section 1.4).
# Fitted objects are cached in data/models/ (git-ignored: they embed account IDs).
# Coefficient tables go to outputs/tables/03_*.csv.
# Run: Rscript src/03_modeling.R [model ...]   (no arguments = all models)
suppressMessages({library(glmmTMB); library(data.table); library(nanoparquet)})

d <- as.data.table(read_parquet("data/processed/model_data.parquet"))
d[, month := relevel(factor(month), ref = "2019-05")]
d[, image_shot := relevel(factor(image_shot), ref = "Medium Shot")]
d[, image_category := relevel(factor(image_category), ref = "Lifestyle")]
d[, description_category := relevel(factor(description_category), ref = "diaries_&_daily_life")]
# Mundlak terms (M1-W): account means. For a single-post account, mean = value and within = 0.
mund <- c("z_AestheticScore", "z_BalancingElements", "z_ColorHarmony", "z_ContentAesthetics",
          "z_DoFScore", "z_LightScore", "z_ObjectScore", "z_RuleOfThirdsScore", "z_VividColorScore",
          "person_present", "log_n_person", "log_n_objects", "log_caption_chars", "log_hashtags",
          "log_mentions")
d[, paste0("m_", mund) := lapply(.SD, mean), by = account, .SDcols = mund]
d[, year := substr(as.character(month), 1, 4)]

ctrl  <- "month + business + description_category + log_caption_chars + log_hashtags + log_mentions"
attrs <- paste0("z_", c("BalancingElements", "ColorHarmony", "ContentAesthetics", "DoFScore",
                        "LightScore", "ObjectScore", "RuleOfThirdsScore", "VividColorScore"))
vis2  <- paste(c(attrs, "person_present", "log_n_person", "log_n_objects", "image_shot",
                 "image_category"), collapse = " + ")
f <- function(rhs, y = "likes", offset = TRUE)
  as.formula(paste(y, "~", if (offset) "offset(log_followers) +", rhs, "+", ctrl, "+ (1 | account)"))

two_plus <- d[, .N, by = account][N >= 2, account]
# R6 (amendment A1-8): drop extreme observations. Thresholds come from training accounts only.
rate_cut <- quantile(d[split == "train", likes / followers], 0.999)
trimmed <- d[likes / followers <= rate_cut & followers <= 1e6]
# R5 (amendment A1-3): Mundlak means for every post-varying numeric covariate of M2.
vis2_w <- paste(vis2, "+", paste0("m_", setdiff(mund, "z_AestheticScore"), collapse = " + "))
specs <- list(
  M1      = list(f("z_AestheticScore"), d),
  M2      = list(f(vis2), d),
  M1W     = list(f("z_AestheticScore + m_z_AestheticScore + person_present + m_person_present"), d),
  M1W_A   = list(f("z_AestheticScore + m_z_AestheticScore + person_present + m_person_present"), d[half == "A"]),
  M1W_B   = list(f("z_AestheticScore + m_z_AestheticScore + person_present + m_person_present"), d[half == "B"]),
  M1_A    = list(f("z_AestheticScore"), d[half == "A"]),
  M1_B    = list(f("z_AestheticScore"), d[half == "B"]),
  M2_A    = list(f(vis2), d[half == "A"]),
  M2_B    = list(f(vis2), d[half == "B"]),
  R1_M1   = list(f("z_AestheticScore + log_followers", offset = FALSE), d),
  R1_M2   = list(f(paste(vis2, "+ log_followers"), offset = FALSE), d),
  R2_M1   = list(f("z_AestheticScore"), d[year == "2019"]),
  R2_M2   = list(f(vis2), d[year == "2019"]),
  R3_M1   = list(f("z_AestheticScore", y = "comments"), d),
  R3_M2   = list(f(vis2, y = "comments"), d),
  R4_M1   = list(f("z_AestheticScore"), d[account %in% two_plus]),
  R4_M2   = list(f(vis2), d[account %in% two_plus]),
  R5_M2W  = list(f(vis2_w), d),
  R6_M1   = list(f("z_AestheticScore"), trimmed),
  R6_M2   = list(f(vis2), trimmed),
  M0_train = list(f("1"), d[split == "train"]),        # H5, evaluated in src/04
  M2_train = list(f(vis2), d[split == "train"])
)

tidy <- function(m, name) {
  s <- summary(m)$coefficients$cond
  data.table(model = name, term = rownames(s), est = s[, 1], se = s[, 2], z = s[, 3],
             p_two = s[, 4], p_one_gt = pnorm(-s[, 3]),
             irr = exp(s[, 1]),
             lo95 = exp(s[, 1] - 1.959964 * s[, 2]), hi95 = exp(s[, 1] + 1.959964 * s[, 2]),
             lo90 = exp(s[, 1] - 1.644854 * s[, 2]), hi90 = exp(s[, 1] + 1.644854 * s[, 2]),
             n = nobs(m), accounts = uniqueN(m$frame$account),
             sigma_u = sqrt(VarCorr(m)$cond$account[1]), theta = sigma(m),
             loglik = as.numeric(logLik(m)), aic = AIC(m), converged = m$fit$convergence == 0,
             pdHess = m$sdr$pdHess)
}

dir.create("data/models", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)
# Priority order: confirmatory models first, then robustness. Several workers can run this
# script at once. A lock directory per model stops two workers fitting the same model.
todo <- commandArgs(trailingOnly = TRUE)
if (!length(todo)) todo <- c("M1", "M2", "M1W", "M2_train", "M0_train", "M1_A", "M1_B", "M2_A",
                             "M2_B", "M1W_A", "M1W_B", "R1_M2", "R1_M1", "R4_M2", "R4_M1", "R6_M2",
                             "R6_M1", "R2_M2", "R2_M1", "R5_M2W", "R3_M2", "R3_M1")
stopifnot(setequal(todo, names(specs)) || all(todo %in% names(specs)))
# Warm start (D18): once M1 exists, start dispersion and RE SD at its estimates. This changes only
# the optimiser's starting point, not the maximum-likelihood target.
warm <- function() {
  if (!file.exists("data/models/M1.rds")) return(NULL)
  m1 <- readRDS("data/models/M1.rds")
  list(theta = log(sqrt(VarCorr(m1)$cond$account[1])), betad = log(sigma(m1)))
}
for (nm in todo) {
  rds <- sprintf("data/models/%s.rds", nm)
  if (!file.exists(rds)) {
    if (!dir.create(sprintf("data/models/%s.lock", nm), showWarnings = FALSE)) next
    t0 <- Sys.time()
    st <- if (specs[[nm]][[1]][[2]] == "likes") warm() else NULL   # comments (R3) differ in scale
    m <- glmmTMB(specs[[nm]][[1]], family = nbinom2, data = specs[[nm]][[2]], start = st,
                 control = glmmTMBControl(optCtrl = list(iter.max = 1e4, eval.max = 1e4)))
    saveRDS(m, rds)
    message(nm, ": ", round(difftime(Sys.time(), t0, units = "mins"), 1), " min")
  }
  fwrite(tidy(readRDS(rds), nm), sprintf("outputs/tables/03_coef_%s.csv", nm))
}
writeLines(capture.output(sessionInfo()), "outputs/tables/03_sessionInfo.txt")
