# D20: restart the optimiser for any cached fit whose nlminb convergence code is non-zero, starting
# from that fit's own estimates. The first fit is kept as <model>_firstfit.rds for the audit trail.
# Usage: Rscript src/03b_refit_nonconverged.R MODEL [MODEL ...]
suppressMessages({library(glmmTMB)})
source_lines <- readLines("src/03_modeling.R")
# Reuse data preparation, specs and tidy() from the main script without running its fitting loop.
eval(parse(text = source_lines[seq_len(grep("^# Priority order", source_lines) - 1)]))

for (nm in commandArgs(trailingOnly = TRUE)) {
  rds <- sprintf("data/models/%s.rds", nm)
  m0 <- readRDS(rds)
  if (m0$fit$convergence == 0) { message(nm, ": already converged"); next }
  p <- m0$fit$parfull
  st <- list(beta = unname(p[names(p) == "beta"]), betad = unname(p[names(p) == "betad"]),
             theta = unname(p[names(p) == "theta"]), b = unname(p[names(p) == "b"]))
  file.copy(rds, sprintf("data/models/%s_firstfit.rds", nm), overwrite = FALSE)
  t0 <- Sys.time()
  m <- glmmTMB(specs[[nm]][[1]], family = nbinom2, data = eval(specs[[nm]][[2]]), start = st,
               control = glmmTMBControl(optCtrl = list(iter.max = 1e4, eval.max = 1e4)))
  message(nm, ": refit ", round(difftime(Sys.time(), t0, units = "mins"), 1), " min, convergence ",
          m$fit$convergence, ", logLik ", round(as.numeric(logLik(m)), 2), " vs first ",
          round(as.numeric(logLik(m0)), 2), ", max |diff beta| ",
          signif(max(abs(fixef(m)$cond - fixef(m0)$cond)), 3))
  saveRDS(m, rds)
  data.table::fwrite(tidy(m, nm), sprintf("outputs/tables/03_coef_%s.csv", nm))
}
