# data munging for all letter distortion experiment data.
library(plyr)
library(dplyr)

top_dir <- getwd()
# top_dir <- '~/Dropbox/Projects/letter-distortion-detection'
out_dir <- file.path(top_dir, "results", "r-analysis-final-paper")

# raw data experiment 1 --------------------------------------------------------------
fname <- file.path(top_dir, "results", "experiment_1", "all_data.csv")
raw_dat_1 <- read.csv(fname)

raw_dat_1$distortion <- revalue(raw_dat_1$distortion,
                                c(" bex" = "BPN",
                                  " rf" = "RF"))

raw_dat_1$subject <- factor(raw_dat_1$subject)
raw_dat_1$subject <- revalue(raw_dat_1$subject,
                             c("2" = "TW",
                               "5" = "ST",
                               "7" = "AM",
                               "8" = "RM",
                               "9" = "MF"))

raw_dat_1$targ_letter <- revalue(raw_dat_1$targ_letter,
                                 c(" D" = "D",
                                   " H" = "H",
                                   " K" = "K",
                                   " N" = "N"))
raw_dat_1$targ_letter <- factor(raw_dat_1$targ_letter,
                                levels = c("K", "H", "D", "N"))

# Threshold data expt 1 ----------------------------------------------------------

fname <- file.path(top_dir, "results", "saskia_analysis", "sensitivitydata", "alldatasensexp1+2.csv")
threshold_dat <- read.csv(fname, sep='\t')

threshold_dat$distortion <- threshold_dat$distortiontype
threshold_dat$distortiontype <- NULL

threshold_dat$distortion <- revalue(threshold_dat$distortion,
                                    c(" Bex" = "BPN",
                                      " RF" = "RF"))

threshold_dat$log_freq <- log(threshold_dat$freq)

# remove space:
threshold_dat$flanked <- revalue(threshold_dat$flanked,
                                    c(" flanked" = "flanked",
                                      " unflanked" = "unflanked"))
# reorder:
threshold_dat$flanked <- factor(threshold_dat$flanked,
                                levels = c("unflanked", "flanked"))

threshold_dat_1 <- threshold_dat


# raw data experiment 2 --------------------------------------------------------------
fname <- file.path(top_dir, "results", "experiment_2", "all_data.csv")
raw_dat_2 <- read.csv(fname)

raw_dat_2$distortion <- revalue(raw_dat_2$distortion,
                                c(" bex" = "BPN",
                                  " rf" = "RF"))

raw_dat_2$subject <- factor(raw_dat_2$subject)
raw_dat_2$subject <- revalue(raw_dat_2$subject,
                             c("2" = "TW",
                               "5" = "ST",
                               "7" = "AM"))

# expt 2 thresholds ------------------------------------------------------------------
fname <- file.path(top_dir, "results", "saskia_analysis", "sensitivitydata", "alldatasensexp3c.csv")
threshold_dat <- read.csv(fname, sep='\t')

threshold_dat$distortion <- threshold_dat$distortiontype
threshold_dat$distortiontype <- NULL

threshold_dat$n_dist_flanks <- threshold_dat$distflanker
threshold_dat$distflanker <- NULL

threshold_dat$experiment <- threshold_dat$exp3
threshold_dat$exp3 <- NULL

threshold_dat$distortion <- revalue(threshold_dat$distortion,
                                    c(" Bex" = "BPN",
                                      " RF" = "RF"))

threshold_dat$experiment <- revalue(threshold_dat$experiment,
                                    c(" a" = "a",
                                      " b" = "b",
                                      " c" = "c"))

threshold_dat_2 <- threshold_dat


# export data -------------------------------------------------------------

save(threshold_dat_1, raw_dat_1, threshold_dat_2, raw_dat_2,
     file = file.path(out_dir, "all_data.RData"))

# export to csv too:
write.csv(threshold_dat_1,
          file = file.path(out_dir, "expt_1_thresholds.csv"))

write.csv(raw_dat_1,
          file = file.path(out_dir, "expt_1_raw.csv"))

write.csv(threshold_dat_2,
          file = file.path(out_dir, "expt_2_thresholds.csv"))

write.csv(raw_dat_2,
          file = file.path(out_dir, "expt_2_raw.csv"))
