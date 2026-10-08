# CRISP-DM phase 5 - Evaluation. Applies the decision rules of DECISIONS.md (1.4 + amendment A1)
# to H1-H5, evaluates held-out prediction and calibration, model diagnostics, robustness, and
# draws the figures. Run after src/03_modeling.R:  Rscript src/04_evaluation.R
suppressMessages({library(glmmTMB); library(data.table); library(nanoparquet); library(ggplot2)})
set.seed(20261008)
SESOI <- c(0.97, 1.03); H5_MIN <- 0.01
TAB <- function(x) file.path("outputs/tables", x); FIG <- function(x) file.path("outputs/figures", x)
coef <- rbindlist(lapply(Sys.glob(TAB("03_coef_*.csv")), fread))
row <- function(mod, tm) coef[model == mod & term == tm][1]

d <- as.data.table(read_parquet("data/processed/model_data.parquet"))
for (v in c("month", "image_shot", "image_category", "description_category")) set(d, j = v, value = factor(d[[v]]))
test <- d[split == "test"]

# ---- Model diagnostics (A1-7) -------------------------------------------------------------------
diag <- unique(coef[, .(model, n, accounts, theta, sigma_u, loglik, aic, converged, pdHess)])
fwrite(diag, TAB("04_model_diagnostics.csv"))

# Randomised quantile residuals for M2, conditional on predicted u_j (Dunn & Smyth 1996).
m2 <- readRDS("data/models/M2.rds")
mu <- predict(m2, type = "response"); th <- sigma(m2); y <- d$likes
lo <- pnbinom(y - 1, size = th, mu = mu); hi <- pnbinom(y, size = th, mu = mu)
rqr <- qnorm(pmin(pmax(lo + runif(length(y)) * (hi - lo), 1e-12), 1 - 1e-12))
qs <- c(.01, .05, .25, .5, .75, .95, .99)
fwrite(data.table(q = qs, empirical = quantile(rqr, qs), normal = qnorm(qs), mean = mean(rqr), sd = sd(rqr)),
       TAB("04_m2_rqr_quantiles.csv"))
p <- ggplot(data.table(r = rqr), aes(r)) + geom_histogram(aes(y = after_stat(density)), bins = 80, fill = "grey60") +
  stat_function(fun = dnorm, linetype = 2) + coord_cartesian(xlim = c(-4, 4)) +
  labs(x = "Randomised quantile residual (M2)", y = "Density") + theme_bw(8)
ggsave(FIG("fig5_m2_residuals.png"), p, width = 3.4, height = 2.4, dpi = 300)
rm(mu, lo, hi, rqr); invisible(gc())

# ---- H5: joint marginal log score on held-out accounts (A1-6) ---------------------------------
gh <- function(n) {                      # Golub-Welsch: nodes/weights for weight exp(-x^2)
  b <- sqrt(seq_len(n - 1) / 2); J <- matrix(0, n, n)
  J[cbind(1:(n - 1), 2:n)] <- b; J[cbind(2:n, 1:(n - 1))] <- b
  e <- eigen(J, symmetric = TRUE); list(x = e$values, w = e$vectors[1, ]^2)   # weights sum to 1
}
logsumexp_rows <- function(M, logw) { mx <- apply(M, 1, max); mx + log(exp(M - mx) %*% exp(logw)) }
score <- function(m, nodes) {
  q <- gh(nodes); eta <- predict(m, newdata = test, re.form = NA, type = "link", allow.new.levels = TRUE)
  su <- sqrt(VarCorr(m)$cond$account[1]); th <- sigma(m); u <- sqrt(2) * su * q$x
  ll <- sapply(u, function(uk) dnbinom(test$likes, size = th, mu = exp(eta + uk), log = TRUE))
  list(acct = as.vector(logsumexp_rows(rowsum(ll, test$account), log(q$w))), eta = eta, su = su, th = th)
}
m0t <- readRDS("data/models/M0_train.rds"); m2t <- readRDS("data/models/M2_train.rds")
s0 <- score(m0t, 30); s2 <- score(m2t, 30)
s0b <- score(m0t, 60); s2b <- score(m2t, 60)
npost <- as.vector(rowsum(rep(1, nrow(test)), test$account))
diff <- s2$acct - s0$acct
point <- sum(diff) / sum(npost)
boot <- replicate(1000, { i <- sample.int(length(diff), replace = TRUE); sum(diff[i]) / sum(npost[i]) })
half_of <- test[, .(half = half[1]), keyby = account]$half                # rowsum() sorts by account
h5_half <- sapply(c("A", "B"), function(h) sum(diff[half_of == h]) / sum(npost[half_of == h]))

# Calibration: single-post marginal predictive CDF, randomised PIT (Czado, Gneiting & Held 2009).
pit <- function(s) {
  q <- gh(30); u <- sqrt(2) * s$su * q$x; y <- test$likes
  Fm <- function(k) as.vector(sapply(u, function(uk) pnbinom(k, size = s$th, mu = exp(s$eta + uk))) %*% q$w)
  lo <- Fm(y - 1); lo[y == 0] <- 0; hi <- Fm(y); lo + runif(length(y)) * (hi - lo)
}
p0 <- pit(s0); p2 <- pit(s2)
cal <- rbindlist(lapply(list(M0 = p0, M2 = p2), function(v)
  data.table(cover50 = mean(v > .25 & v < .75), cover90 = mean(v > .05 & v < .95),
             pit_mean = mean(v), pit_sd = sd(v), ks_D = max(abs(ecdf(v)(seq(0, 1, .001)) - seq(0, 1, .001))))),
  idcol = "model")
fwrite(cal, TAB("04_h5_calibration.csv"))
ph <- rbind(data.table(model = "M0 (controls)", pit = p0), data.table(model = "M2 (visual)", pit = p2))
p <- ggplot(ph, aes(pit)) + geom_histogram(aes(y = after_stat(density)), breaks = seq(0, 1, .05), fill = "grey60") +
  geom_hline(yintercept = 1, linetype = 2) + facet_wrap(~model, ncol = 2) +
  labs(x = "Randomised PIT, held-out accounts", y = "Density") + theme_bw(8)
ggsave(FIG("fig6_pit.png"), p, width = 3.4, height = 2.2, dpi = 300)

rate <- test$likes / test$followers
h5 <- data.table(
  metric = c("logscore_post_M0", "logscore_post_M2", "delta_post", "delta_lo95", "delta_hi95",
             "delta_A", "delta_B", "delta_account_weighted", "delta_post_60nodes",
             "spearman_rate_M0", "spearman_rate_M2", "test_posts", "test_accounts"),
  value = c(sum(s0$acct) / sum(npost), sum(s2$acct) / sum(npost), point, quantile(boot, c(.025, .975)),
            h5_half, mean(diff / npost), sum(s2b$acct - s0b$acct) / sum(npost),
            cor(rate, exp(s0$eta + s0$su^2 / 2) / test$followers, method = "spearman"),
            cor(rate, exp(s2$eta + s2$su^2 / 2) / test$followers, method = "spearman"),
            nrow(test), length(diff)))
fwrite(h5, TAB("04_h5_prediction.csv"))

# ---- Confirmatory table (pre-registered rule + A1-5) --------------------------------------------
spec <- data.table(H = c("H1", "H2", "H3", "H4"), mod = c("M1", "M2", "M2", "M1W"),
                   term = c("z_AestheticScore", "person_present", "z_VividColorScore", "m_z_AestheticScore"),
                   sided = c("one", "one", "one", "two"))
H <- rbindlist(lapply(seq_len(nrow(spec)), function(k) {
  s <- spec[k]; f <- row(s$mod, s$term); a <- row(paste0(s$mod, "_A"), s$term); b <- row(paste0(s$mod, "_B"), s$term)
  pv <- function(r) if (s$sided == "one") r$p_one_gt else r$p_two
  # TOST against the SESOI band on the log scale
  p_tost <- max(pnorm((f$est - log(SESOI[1])) / f$se, lower.tail = FALSE),
                pnorm((f$est - log(SESOI[2])) / f$se, lower.tail = TRUE))
  data.table(H = s$H, model = s$mod, term = s$term, est = f$est, se = f$se, irr = f$irr,
             lo95 = f$lo95, hi95 = f$hi95, lo90 = f$lo90, hi90 = f$hi90, p = pv(f), p_tost = p_tost,
             A = a$irr, pA = pv(a), B = b$irr, pB = pv(b),
             replicated = sign(a$est) == sign(f$est) & sign(b$est) == sign(f$est) & pv(a) < .05 & pv(b) < .05)
}))
H5p <- max(mean(boot <= 0), 1 / 1000)              # one-sided paired-bootstrap p (resolution 1/1000)
H <- rbind(H, data.table(H = "H5", model = "M2 vs M0 (test)", term = "delta log score (nats/post)",
                         est = point, lo95 = quantile(boot, .025), hi95 = quantile(boot, .975), p = H5p,
                         A = h5_half[["A"]], B = h5_half[["B"]], replicated = all(h5_half > 0)), fill = TRUE)
H[, p_holm := p.adjust(p, "holm")]
H[H != "H5", p_tost_holm := p.adjust(p_tost, "holm")]
H[, outside := fifelse(H == "H5", lo95 >= H5_MIN, lo95 > SESOI[2] | hi95 < SESOI[1])]
H[, inside_prereg := fifelse(H == "H5", lo95 > -H5_MIN & hi95 < H5_MIN, lo90 >= SESOI[1] & hi90 <= SESOI[2])]
H[, verdict := fifelse(p_holm < .05 & outside & replicated, "Supported",
                       fifelse(inside_prereg & (H == "H5" | p_tost_holm < .05), "Negligible", "Inconclusive"))]
fwrite(H, TAB("04_confirmatory.csv"))
print(H[, .(H, term, est = signif(est, 4), irr = signif(irr, 4), lo95 = signif(lo95, 4), hi95 = signif(hi95, 4),
            p_holm = signif(p_holm, 3), p_tost_holm = signif(p_tost_holm, 3), A = signif(A, 4), B = signif(B, 4),
            replicated, verdict)])
print(h5); print(cal)

# SESOI sensitivity (A1-5): verdict of H1-H4 at +-1%, 3%, 5%.
sens <- rbindlist(lapply(c(.01, .03, .05), function(e) H[H != "H5", .(H, band = e,
  outside = lo95 > 1 + e | hi95 < 1 - e, inside = lo90 >= 1 - e & hi90 <= 1 + e)]))
fwrite(sens, TAB("04_sesoi_sensitivity.csv"))

# ---- Secondary quantities requested by review ------------------------------------------------
v <- vcov(m2)$cond; b <- fixef(m2)$cond; g <- c(person_present = 1, log_n_person = log(2))
one_person <- sum(b[names(g)] * g); se1 <- sqrt(drop(t(g) %*% v[names(g), names(g)] %*% g))
el <- function(m) { r <- row(m, "log_followers"); c(r$est, r$est - 1.96 * r$se, r$est + 1.96 * r$se) }
extra <- data.table(
  quantity = c("IRR one person vs none (M2, combined)", "follower elasticity R1_M1", "follower elasticity R1_M2"),
  rbind(exp(one_person + c(0, -1.96, 1.96) * se1), el("R1_M1"), el("R1_M2")))
setnames(extra, c("quantity", "est", "lo95", "hi95"))
fwrite(extra, TAB("04_extra_quantities.csv"))

focal <- c("z_AestheticScore", "person_present", "z_VividColorScore")
rob <- coef[term %in% focal & grepl("^(M1|M2|R[1-6]_M1|R[1-6]_M2|R5_M2W)$", model),
            .(model, term, irr, lo95, hi95, n, converged, pdHess)]
fwrite(rob[order(term, model)], TAB("04_robustness.csv"))

# Construct plausibility of the image features (review point 6): cross-classifier agreement.
shot <- d[, .(posts = .N, person_share = mean(person_present), mean_z_DoF = mean(z_DoFScore),
              mean_z_Object = mean(z_ObjectScore), mean_z_Light = mean(z_LightScore)), by = image_shot][order(-person_share)]
fwrite(shot, TAB("04_feature_plausibility_by_shot.csv"))
attr_cols <- grep("^z_", names(d), value = TRUE)
fwrite(as.data.table(round(cor(d[split == "train", ..attr_cols]), 3), keep.rownames = "feature"),
       TAB("04_attribute_correlations_train.csv"))

# ---- Figures ------------------------------------------------------------------------------------
pretty <- c(z_BalancingElements = "Balancing elements", z_ColorHarmony = "Colour harmony",
            z_ContentAesthetics = "Content", z_DoFScore = "Depth of field", z_LightScore = "Lighting",
            z_ObjectScore = "Object emphasis", z_RuleOfThirdsScore = "Rule of thirds",
            z_VividColorScore = "Vivid colour", person_present = "Person present",
            log_n_person = "log(1 + persons)", log_n_objects = "log(1 + objects)")
lab <- function(x) ifelse(x %in% names(pretty), pretty[x],
                          sub(" Shot$", "", sub("Selife", "Selfie", gsub("image_shot|image_category", "", x))))
mm <- coef[model == "M2" & (grepl("^z_", term) | term %in% c("person_present", "log_n_person", "log_n_objects"))]
mm[, kind := "Content"][grepl("^z_", term), kind := "Aesthetic\n(per SD)"]
p <- ggplot(mm, aes(irr, reorder(lab(term), irr), xmin = lo95, xmax = hi95)) +
  annotate("rect", xmin = SESOI[1], xmax = SESOI[2], ymin = -Inf, ymax = Inf, alpha = .15) +
  geom_vline(xintercept = 1, linetype = 2) + geom_pointrange(size = .2) +
  facet_grid(kind ~ ., scales = "free_y", space = "free_y") +
  labs(x = "IRR of likes per recorded follower (95% CI)\ngrey band = SESOI [0.97, 1.03]", y = NULL) + theme_bw(8)
ggsave(FIG("fig2_m2_visual_irr.png"), p, width = 3.4, height = 3.6, dpi = 300)

ct <- coef[model == "M2" & grepl("^image_(shot|category)", term)]
ct[, kind := fifelse(grepl("^image_shot", term), "Shot scale\n(ref: Medium)", "Image category\n(ref: Lifestyle)")]
p <- ggplot(ct, aes(irr, reorder(lab(term), irr), xmin = lo95, xmax = hi95)) +
  annotate("rect", xmin = SESOI[1], xmax = SESOI[2], ymin = -Inf, ymax = Inf, alpha = .15) +
  geom_vline(xintercept = 1, linetype = 2) + geom_pointrange(size = .2) +
  facet_grid(kind ~ ., scales = "free_y", space = "free_y") +
  labs(x = "IRR of likes per recorded follower (95% CI)", y = NULL) + theme_bw(8)
ggsave(FIG("fig3_m2_categories_irr.png"), p, width = 3.4, height = 5.2, dpi = 300)

ab <- merge(coef[model == "M2_A", .(term, A = irr)], coef[model == "M2_B", .(term, B = irr)], by = "term")
ab <- ab[!grepl("^month|^description_category|Intercept|caption|hashtag|mention|business", term)]
p <- ggplot(ab, aes(A, B)) + geom_abline(linetype = 2) + geom_point(alpha = .7, size = 1) +
  scale_x_log10() + scale_y_log10() +
  labs(x = "IRR, half A accounts", y = "IRR, half B accounts",
       subtitle = sprintf("Visual terms of M2; r(log IRR) = %.3f", cor(log(ab$A), log(ab$B)))) + theme_bw(8)
ggsave(FIG("fig4_replication.png"), p, width = 3.4, height = 3.2, dpi = 300)

# Headline figure: confirmatory estimates H1-H4, full sample and both halves, against the SESOI band.
cf <- rbindlist(lapply(seq_len(nrow(spec)), function(k) {
  s <- spec[k]
  rbindlist(lapply(c("", "_A", "_B"), function(sfx) {
    r <- row(paste0(s$mod, sfx), s$term)
    data.table(H = s$H, sample = c(Full = "Full", `_A` = "Half A", `_B` = "Half B")[[if (sfx == "") "Full" else sfx]],
               irr = r$irr, lo95 = r$lo95, hi95 = r$hi95)
  }))
}))
cf[, H := factor(H, levels = rev(spec$H), labels = rev(c("H1 Aesthetic (M1)", "H2 Person (M2)",
                                                           "H3 Vivid colour (M2)", "H4 Between - within (M1-W)")))]
p <- ggplot(cf, aes(irr, H, xmin = lo95, xmax = hi95, shape = sample, colour = sample)) +
  annotate("rect", xmin = SESOI[1], xmax = SESOI[2], ymin = -Inf, ymax = Inf, alpha = .15) +
  geom_vline(xintercept = 1, linetype = 2) +
  geom_pointrange(position = position_dodge(width = .6), size = .25) +
  scale_colour_manual(values = c(Full = "black", `Half A` = "#4C72B0", `Half B` = "#DD8452")) +
  labs(x = "IRR (95% CI); grey = SESOI", y = NULL, colour = NULL, shape = NULL) +
  theme_bw(8) + theme(legend.position = "bottom")
ggsave(FIG("fig0_confirmatory.png"), p, width = 3.4, height = 2.8, dpi = 300)

# Robustness forest: focal terms across specifications.
spec_lab <- c(M1 = "Main", M2 = "Main", R1_M1 = "R1 followers free", R1_M2 = "R1 followers free",
              R2_M1 = "R2 2019 only", R2_M2 = "R2 2019 only", R3_M1 = "R3 comments", R3_M2 = "R3 comments",
              R4_M1 = "R4 >= 2 posts", R4_M2 = "R4 >= 2 posts", R5_M2W = "R5 full Mundlak",
              R6_M1 = "R6 no extremes", R6_M2 = "R6 no extremes")
rb <- copy(rob)[model %in% names(spec_lab)]
rb[, spec := factor(spec_lab[model], levels = rev(unique(spec_lab)))]
rb[, term := factor(term, levels = focal, labels = c("Aesthetic (H1)", "Person (H2)", "Vivid colour (H3)"))]
p <- ggplot(rb, aes(irr, spec, xmin = lo95, xmax = hi95)) +
  annotate("rect", xmin = SESOI[1], xmax = SESOI[2], ymin = -Inf, ymax = Inf, alpha = .15) +
  geom_vline(xintercept = 1, linetype = 2) + geom_pointrange(size = .2) +
  facet_wrap(~term, ncol = 1, scales = "free") +
  labs(x = "IRR (95% CI)", y = NULL) + theme_bw(8)
ggsave(FIG("fig7_robustness.png"), p, width = 3.4, height = 5.0, dpi = 300)
