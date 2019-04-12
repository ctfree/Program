#!/usr/bin/env Rscript

# setwd("enron")
# set.seed(1)
# source("script/read.r")
# write.csv(mails, "mails.csv", row.names=FALSE)
install.packages('markovchain')
install.packages('devtools', dependencies=TRUE, repos='http://cran.rstudio.com/')
install.packages('markovchain')



devtools::install_github('spedygiorgio/markovchain')
6library(markovchain)
library(dplyr)
# SDR Funnel is our sales representative stages, AE Funnel is our account executive stages, and CW is a successfully closed deal
seq <- c('SDR Funnel','SDR Funnel','AE Funnel','AE Funnel','AE Funnel','AE Funnel','AE Funnel','AE Funnel','CW')
verifyMarkovProperty(seq)
# 