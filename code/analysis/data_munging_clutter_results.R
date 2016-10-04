# data munging for clutter results
library(forcats)
library(dplyr)
library(tidyr)

top_dir <- getwd()
# top_dir <- '~/Dropbox/Projects/letter-distortion-detection'
out_dir <- file.path(top_dir, "results", "clutter_analysis")

# experiment 1 --------------------------------------------------------------
fname <- file.path(top_dir, "results", "clutter_analysis", "expt_1_clutter_results.csv")
dat_1 <- read.csv(fname)

dat_1$distortion <- fct_recode(dat_1$distortion,
                                c("BPN" = "bex",
                                  "RF" = "rf"))

# gather to make a "clutter" column, with two levels (FC and SE):
dat_1 <- dat_1 %>% gather(measure, clutter, c(FC, SE))
dat_1$measure <- factor(dat_1$measure)

# experiment 2 --------------------------------------------------------------
fname <- file.path(top_dir, "results", "clutter_analysis", "expt_2_clutter_results.csv")
dat_2 <- read.csv(fname)

dat_2$distortion <- fct_recode(dat_2$distortion,
                               c("BPN" = "bex",
                                 "RF" = "rf"))

# gather to make a "clutter" column, with two levels (FC and SE):
dat_2 <- dat_2 %>% gather(measure, clutter, c(FC, SE))
dat_2$measure <- factor(dat_2$measure)

# export data -------------------------------------------------------------

# note that these files are double the number of rows as there are
# images because of the "gather" operation -- two measures of clutter.

clutter_dat_1 <- dat_1
clutter_dat_2 <- dat_2

save(clutter_dat_1, clutter_dat_2,
     file = file.path(out_dir, "clutter_data.RData"))
