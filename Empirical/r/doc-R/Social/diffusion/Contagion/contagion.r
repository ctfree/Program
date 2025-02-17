# Example from Anand, Craig and Von Peter (2015, p.628)
# Total Liabilities
L <- c(a = 4, b = 5, c = 5, d = 0, e = 0, f = 2, g = 4)

# Total Assets
A <- c(a = 7, b = 5, c = 3, d = 1, e = 3, f = 0, g = 1)

# Loads the package
library(NetworkRiskMeasures)
#> Loading required package: Matrix

# Maximum Entropy Estimation
ME <- matrix_estimation(rowsums = A, colsums = L, method = "me")
ME <- round(ME, 2)
ME

# Minimum Density Estimation
set.seed(192) # seed for reproducibility
MD <- matrix_estimation(A, L, method = "md")
MD

data("sim_data")
head(sim_data)


# seed - min. dens. estimation is stochastic
set.seed(15) 
# minimum density estimation
# verbose = F to prevent printing
md_mat <- matrix_estimation(sim_data$assets, sim_data$liabilities, method = "md", verbose = F)
# rownames and colnames for the matrix
rownames(md_mat) <- colnames(md_mat) <- sim_data$bank

library(ggplot2)
library(ggnetwork)
library(igraph)

# converting our network to an igraph object
gmd <- graph_from_adjacency_matrix(md_mat, weighted = T)

sim_data$degree <- igraph::degree(gmd)
sim_data$btw    <- igraph::betweenness(gmd)
sim_data$close  <- igraph::closeness(gmd)
sim_data$eigen  <- igraph::eigen_centrality(gmd)$vector
sim_data$alpha  <- igraph::alpha_centrality(gmd, alpha = 0.5)

sim_data$imps <- impact_susceptibility(exposures = gmd, buffer = sim_data$buffer)
sim_data$impd <- impact_diffusion(exposures = gmd, buffer = sim_data$buffer, weights = sim_data$weights)$total

# DebtRank simulation
contdr <- contagion(exposures = md_mat, buffer = sim_data$buffer, weights = sim_data$weights, 
                    shock = "all", method = "debtrank", verbose = F)
summary(contdr)

plot(contdr)

contdr_summary <- summary(contdr)
sim_data$DebtRank <- contdr_summary$summary_table$additional_stress

contthr <-  contagion(exposures = md_mat, buffer = sim_data$buffer, weights = sim_data$weights, 
                      shock = "all", method = "threshold", verbose = F)
summary(contthr)

contthr_summary <- summary(contthr)
sim_data$cascade <- contthr_summary$summary_table$additional_stress

head(sim_data)

rankings <- sim_data[1]
rankings <- cbind(rankings, lapply(sim_data[c("DebtRank","cascade","degree","eigen","impd","assets", "liabilities", "buffer")], 
                                   function(x) as.numeric(factor(-1*x))))
rankings <- rankings[order(rankings$DebtRank), ]
head(rankings, 10)
cor(rankings[-1])


s <- seq(0.01, 0.25, by = 0.01)
shocks <- lapply(s, function(x) rep(x, nrow(md_mat)))
names(shocks) <- paste(s*100, "pct shock")

cont <- contagion(exposures = gmd, buffer = sim_data$buffer, shock = shocks, weights = sim_data$weights, method = "debtrank", verbose = F)
summary(cont)
