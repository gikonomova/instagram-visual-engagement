# R dependencies. glmmTMB is pinned to 1.1.9: later versions need RTMB, which does not
# compile against R 4.1. On macOS/arm64 with Homebrew gfortran, build TMB with
#   FLIBS=-L$(dirname $(gfortran -print-libgcc-file-name)) -lgfortran -lquadmath -lm
# in a file passed via R_MAKEVARS_USER.
options(repos = "https://cloud.r-project.org")
install.packages(c("TMB", "data.table", "nanoparquet", "ggplot2"))
install.packages("https://cloud.r-project.org/src/contrib/Archive/glmmTMB/glmmTMB_1.1.9.tar.gz",
                 repos = NULL, type = "source")
