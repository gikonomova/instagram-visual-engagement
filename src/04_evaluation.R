# CRISP-DM phase 5 - Evaluation. Applies the pre-registered decision rule (DECISIONS.md, 1.4)
# to H1-H5, evaluates out-of-sample prediction (H5), and draws the figures.
# Run after src/03_modeling.R:  Rscript src/04_evaluation.R
suppressMessages({library(glmmTMB); library(data.table); library(nanoparquet); library(ggplot2)})
set.seed(20261008)
SESOI <- c(0.97, 1.03)
coef <- rbindlist(lapply(Sys.glob("outputs/tables/03_coef_*.csv"), fread))
row <- function(mod, tm) coef[model == mod & term == tm][1]

# ---- H5: marginal NB log score on held-out accounts -----------------------------------------
# For an unseen account, u ~ N(0, s_u^2) is integrated out by Gauss-Hermite quadrature, jointly
# over all of that account's posts. Score = sum of account log-likelihoods / number of posts.
gh <- function(n) {                      # Golub-Welsch: nodes/weights for weight exp(-x^2)
  b <- sqrt(seq_len(n - 1) / 2); J <- matrix(0, n, n)
  J[cbind(1:(n - 1), 2:n)] <- b; J[cbind(2:n, 1:(n - 1))] <- b
  e <- eigen(J, symmetric = TRUE); list(x = e$values, w = sqrt(pi) * e$vectors[1, ]^2)
}
q <- gh(30)
prep <- function(dt) {
  dt[, month := factor(month)]; dt[, image_shot := factor(image_shot)]
  dt[, image_category := factor(image_category)]; dt[, description_category := factor(description_category)]
  dt
}
d <- prep(as.data.table(read_parquet("data/processed/model_data.parquet")))
test <- d[split == "test"]
acct_ll <- function(m) {
  eta <- predict(m, newdata = test, re.form = NA, type = "link", allow.new.levels = TRUE)
  su <- sqrt(VarCorr(m)$cond$account[1]); th <- sigma(m)
  # ll[i, k] = log NB(y_i | exp(eta_i + sqrt(2) su x_k), theta)
  u <- sqrt(2) * su * q$x
  ll <- sapply(u, function(uk) dnbinom(test$likes, size = th, mu = exp(eta + uk), log = TRUE))
  per_acct <- rowsum(ll, test$account)                      # accounts x nodes
  mx <- apply(per_acct, 1, max)
  list(ll = mx + log(exp(per_acct - mx) %*% (q$w / sqrt(pi))), mu = exp(eta + su^2 / 2))
}
m0 <- readRDS("data/models/M0_train.rds"); m2 <- readRDS("data/models/M2_train.rds")
a0 <- acct_ll(m0); a2 <- acct_ll(m2)
npost <- as.vector(rowsum(rep(1, nrow(test)), test$account))
diff <- as.vector(a2$ll - a0$ll)
point <- sum(diff) / sum(npost)
boot <- replicate(1000, { i <- sample.int(length(diff), replace = TRUE); sum(diff[i]) / sum(npost[i]) })
half_of <- test[, .(half = half[1]), keyby = account]$half          # rowsum() sorts by account
h5_half <- sapply(c("A", "B"), function(h) sum(diff[half_of == h]) / sum(npost[half_of == h]))
rate <- test$likes / test$followers
h5 <- data.table(
  metric = c("logscore_M0", "logscore_M2", "delta", "delta_lo95", "delta_hi95", "delta_A", "delta_B",
             "spearman_rate_M0", "spearman_rate_M2", "test_posts", "test_accounts"),
  value = c(sum(a0$ll) / sum(npost), sum(a2$ll) / sum(npost), point, quantile(boot, c(.025, .975)),
            h5_half, cor(rate, a0$mu / test$followers, method = "spearman"),
            cor(rate, a2$mu / test$followers, method = "spearman"), nrow(test), length(diff)))
fwrite(h5, "outputs/tables/04_h5_prediction.csv")

# ---- Confirmatory table with Holm correction and SESOI classification ----------------------
H <- rbind(
  cbind(H = "H1", row("M1", "z_AestheticScore"), A = row("M1_A", "z_AestheticScore")$irr,
        pA = row("M1_A", "z_AestheticScore")$p_one_gt, B = row("M1_B", "z_AestheticScore")$irr,
        pB = row("M1_B", "z_AestheticScore")$p_one_gt, p = row("M1", "z_AestheticScore")$p_one_gt),
  cbind(H = "H2", row("M2", "person_present"), A = row("M2_A", "person_present")$irr,
        pA = row("M2_A", "person_present")$p_one_gt, B = row("M2_B", "person_present")$irr,
        pB = row("M2_B", "person_present")$p_one_gt, p = row("M2", "person_present")$p_one_gt),
  cbind(H = "H3", row("M2", "z_VividColorScore"), A = row("M2_A", "z_VividColorScore")$irr,
        pA = row("M2_A", "z_VividColorScore")$p_one_gt, B = row("M2_B", "z_VividColorScore")$irr,
        pB = row("M2_B", "z_VividColorScore")$p_one_gt, p = row("M2", "z_VividColorScore")$p_one_gt),
  cbind(H = "H4", row("M1W", "m_z_AestheticScore"), A = row("M1W_A", "m_z_AestheticScore")$irr,
        pA = row("M1W_A", "m_z_AestheticScore")$p_two, B = row("M1W_B", "m_z_AestheticScore")$irr,
        pB = row("M1W_B", "m_z_AestheticScore")$p_two, p = row("M1W", "m_z_AestheticScore")$p_two),
  fill = TRUE)
H5p <- mean(boot <= 0)                    # one-sided bootstrap p (resolution 1/1000)
H <- rbind(H, data.table(H = "H5", model = "M2 vs M0 (test)", term = "delta log score / post",
                         est = point, irr = NA, lo95 = quantile(boot, .025), hi95 = quantile(boot, .975),
                         A = h5_half[["A"]], B = h5_half[["B"]], p = max(H5p, 1 / 1000)), fill = TRUE)
H[, p_holm := p.adjust(p, "holm")]
H[, outside := H != "H5" & (lo95 > SESOI[2] | hi95 < SESOI[1])]
H[, inside := H != "H5" & lo90 >= SESOI[1] & hi90 <= SESOI[2]]
H[, replicated := fifelse(H == "H5", A > 0 & B > 0,
                          sign(log(A)) == sign(log(irr)) & sign(log(B)) == sign(log(irr)) & pA < .05 & pB < .05)]
H[, verdict := fifelse(H == "H5",
                       fifelse(p_holm < .05 & lo95 > 0 & replicated, "Supported", "Inconclusive"),
                       fifelse(p_holm < .05 & outside & replicated, "Supported",
                               fifelse(inside, "Negligible (equivalence)", "Inconclusive")))]
fwrite(H[, .(H, model, term, est, se, irr, lo95, hi95, lo90, hi90, p, p_holm, A, B, pA, pB,
             replicated, verdict)], "outputs/tables/04_confirmatory.csv")
print(H[, .(H, term, irr = signif(irr, 4), lo95 = signif(lo95, 4), hi95 = signif(hi95, 4),
            p_holm = signif(p_holm, 3), A = signif(A, 4), B = signif(B, 4), verdict)])
print(h5)

# ---- Figures ----------------------------------------------------------------------------------
lab <- function(x) gsub("^z_|Score$", "", gsub("image_shot|image_category", "", x))
m2 <- coef[model == "M2" & (grepl("^z_", term) | term %in% c("person_present", "log_n_person", "log_n_objects"))]
m2[, kind := "Content"][grepl("^z_", term), kind := "Aesthetic\n(per SD)"]
p <- ggplot(m2, aes(irr, reorder(lab(term), irr), xmin = lo95, xmax = hi95)) +
  annotate("rect", xmin = SESOI[1], xmax = SESOI[2], ymin = -Inf, ymax = Inf, alpha = .15) +
  geom_vline(xintercept = 1, linetype = 2) + geom_pointrange(size = .25) +
  facet_grid(kind ~ ., scales = "free_y", space = "free_y") +
  labs(x = "IRR of likes per follower (95% CI)\ngrey band = SESOI [0.97, 1.03]", y = NULL) + theme_bw(8)
ggsave("outputs/figures/fig2_m2_visual_irr.png", p, width = 3.4, height = 3.6, dpi = 300)

cat_terms <- coef[model == "M2" & grepl("^image_(shot|category)", term)]
cat_terms[, kind := fifelse(grepl("^image_shot", term), "Shot scale\n(ref: Medium)",
                            "Image category\n(ref: Lifestyle)")]
p <- ggplot(cat_terms, aes(irr, reorder(lab(term), irr), xmin = lo95, xmax = hi95)) +
  annotate("rect", xmin = SESOI[1], xmax = SESOI[2], ymin = -Inf, ymax = Inf, alpha = .15) +
  geom_vline(xintercept = 1, linetype = 2) + geom_pointrange(size = .25) +
  facet_grid(kind ~ ., scales = "free_y", space = "free_y") +
  labs(x = "IRR of likes per follower (95% CI)", y = NULL) + theme_bw(8)
ggsave("outputs/figures/fig3_m2_categories_irr.png", p, width = 3.4, height = 5.2, dpi = 300)

ab <- merge(coef[model == "M2_A", .(term, A = irr)], coef[model == "M2_B", .(term, B = irr)], by = "term")
ab <- ab[!grepl("^month|^description_category|Intercept", term)]
p <- ggplot(ab, aes(A, B)) + geom_abline(linetype = 2) + geom_point(alpha = .7) +
  scale_x_log10() + scale_y_log10() +
  labs(x = "IRR, half A accounts", y = "IRR, half B accounts",
       subtitle = sprintf("Visual terms of M2; r(log IRR) = %.3f", cor(log(ab$A), log(ab$B)))) + theme_bw(8)
ggsave("outputs/figures/fig4_replication.png", p, width = 3.4, height = 3.2, dpi = 300)
