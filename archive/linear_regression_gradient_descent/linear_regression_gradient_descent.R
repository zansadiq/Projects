library(dplyr)
library(tidyr)
library(data.table)
library(ggplot2)
library(gridExtra)
library(reshape2)

# Working directory
setwd("/Users/zansadiq/Documents/School/Fall 2017/BUAN6341")

# Load the data
data <- read.csv("Data/Bike-Sharing-Dataset/hour.csv")

# Select the useable features
data1 <- data[, c("season", "mnth", "hr", "holiday", "weekday", "workingday", "weathersit", "temp", "atemp", "hum", "windspeed", "cnt")]

data1 <- as.data.table(data1)

# Set seed
set.seed(100)

# Function to normalize the data
normalize <- function(x) {
 return ((x - min(x)) / (max(x) - min(x)))
}

dfNorm <- data1 %>% 
  mutate_at(.vars = vars(season, mnth, hr, weekday, weathersit),
            .funs = funs(normalize))

# Split the data
trainingObs<-sample(nrow(dfNorm), 0.70*nrow(dfNorm), replace = FALSE)

# Create the training dataset
trainingDS<-dfNorm[trainingObs,]

# Create the test dataset
testDS<-dfNorm[-trainingObs,]

# Create the variables
y <- trainingDS$cnt
y_test <- testDS$cnt
X <- as.matrix(trainingDS[-ncol(trainingDS)])
X_test <- as.matrix(testDS[-ncol(testDS)])

int <- rep(1, length(y))

# Add intercept column to X
X <- cbind(int, X)
X_test <- cbind(int, X_test)

# Gradient descent 
gradientDesc <- function(x, y, x_test, y_test, learn_rate, conv_threshold, max_iter) {
  n <- nrow(x) 
  m <- runif(ncol(x), 0, 1)
  yhat <- x %*% m
  
  cost <- sum((y - yhat) ^ 2) / (2 * n)

  converged = F
  iterations = 0
  
  while(converged == F) {
    ## Implement the gradient descent algorithm
    m <- m - learn_rate * (1/n * t(x) %*% (yhat - y))
    yhat <- x %*% m
    new_cost <- (sum((y - yhat) ^ 2) / (2 * n))
    
    # Function for test set
    yhat_test <- x_test %*% m
    new_cost_test <- sum((y_test - yhat_test) ^ 2) / (2 * nrow(x_test))
    
    if(abs(cost - new_cost) <= conv_threshold) {
      converged = T
    }
    iterations = iterations + 1
    cost <- new_cost
    
    if(iterations >= max_iter) break
  }
  return(list(converged = converged, 
              num_iterations = iterations, 
              cost = cost,
              new_cost = new_cost,
              coefs = m,
              new_cost_test = new_cost_test) )
}

# EXPERIMENT 1:
# Iterate through learning rates and plot results
learn_rates <- seq(.00005, .001, by = .000025)
thresholds <- seq(.00005, .0005, by = .00005)
iterations <- seq(10000, 100000, by = 5000)
num_tests <- length(learn_rates)
num_thresholds <- length(thresholds)
num_iterations <- length(iterations)
plot_errors_train <- rep(NA, num_tests)
plot_errors_test <- rep(NA, num_tests)
plot_threshold_errors_train <- rep(NA, num_thresholds)
plot_threshold_errors_test <- rep(NA, num_thresholds)
plot_iterations_errors_train <- rep(NA, num_iterations)
plot_iterations_errors_test <- rep(NA, num_iterations)

# Experiment with learning rates
iter <- 1
for(i in learn_rates){
  cat("Running iteration ",iter, "\n")

  #Perform gradient descent
  learn_rate <- i
  out_alpha <- gradientDesc(X, y, X_test, y_test, learn_rate, 0.001, 100000)
  
  cat("Finished gradient descent", learn_rate, "\n")
  cat("Converged =", out_alpha$converged, "\n")
  
  #grab "final" error rate for last iteration
  plot_errors_train[iter] <- out_alpha$new_cost
  plot_errors_test[iter] <- out_alpha$new_cost_test
  iter <- iter + 1
}

out_alpha$coefs

plot_errors_train
plot_errors_test

# EXPERIMENT 2:
# Vary the convergence threshold and report the results
iter <- 1
for(i in thresholds){
  cat("Running iteration ",iter, "\n")

  #Perform gradient descent
  threshold <- i
  out_threshold <- gradientDesc(X, y, X_test, y_test, .001, threshold, 100000)
  
  cat("Finished gradient descent", "\n")
  cat("Threshold value =", threshold, "\n" )
  cat("Converged =  ", out_threshold$converged, "\n")
  
  #grab "final" error rate for last iteration
  plot_threshold_errors_train[iter] <- out_threshold$new_cost
  plot_threshold_errors_test[iter] <- out_threshold$new_cost_test
  iter <- iter + 1
}

plot_threshold_errors_train
plot_threshold_errors_test

# Vary the number of iterations
iter <- 1
for(i in iterations){
  cat("Running iteration ",iter, "\n")
 
  #Perform gradient descent
  num_iterations <- i
  out_iterations <- gradientDesc(X, y, X_test, y_test, .001, .00005, num_iterations)
  
  cat("Finished gradient descent", "\n")
  cat("Iterations =", num_iterations, "\n" )
  cat("Converged =  ", out_threshold$converged, "\n")
  
  #grab "final" error rate for last iteration
  plot_iterations_errors_train[iter] <- out_iterations$new_cost
  plot_iterations_errors_test[iter] <- out_iterations$new_cost_test
  iter <- iter + 1
}

plot_iterations_errors_train
plot_iterations_errors_test

# Plot the errors
plot_data <- as.data.table(cbind(learn_rates, plot_errors_train, plot_errors_test))

plot_dat <- melt(plot_data, id = c("learn_rates"))

plot_plot <- ggplot(data = plot_dat,
       aes(x = learn_rates, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Cost Function vs. Learning Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("Learning Rates") +
  ylab ("Cost (J)")

# Plot the threshold values
plot_threshold_data <- as.data.table(cbind(thresholds, plot_threshold_errors_train, plot_threshold_errors_test))

plot_threshold_dat <- melt(plot_threshold_data, id = c("thresholds"))

plot_threshold_plot <- ggplot(data = plot_threshold_dat,
                    aes(x = thresholds, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Cost Function vs. Convergence Threshold") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("Convergence Threshold") +
  ylab ("Cost (J)")

# Plot the cost per iteration
plot_iteration_data <- as.data.table(cbind(iterations, plot_iterations_errors_train, plot_iterations_errors_test))

plot_iteration_dat <- melt(plot_iteration_data, id = c("iterations"))

plot_iteration_plot <- ggplot(data = plot_iteration_dat,
                              aes(x = iterations, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Cost Function vs. Number of Iterations") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("Number of iterations") +
  ylab ("Cost (J)")

# EXPERIMENT 3:
# Randomly pick 3 features
fts <- sample(1:11, 3) 

# 9 4 5 
random_model_train <- trainingDS[, c("atemp", "holiday", "weekday", "cnt")]

random_model_test <- testDS[, c("atemp", "holiday", "weekday", "cnt")]

# Create the variables
random_model_y <- random_model_train$cnt
random_model_y_test <- random_model_test$cnt
random_model_X <- as.matrix(random_model_train[-ncol(random_model_train)])
random_model_X_test <- as.matrix(random_model_test[-ncol(random_model_test)])

int <- rep(1, length(random_model_y))

# Add intercept column to X
random_model_X <- cbind(int, random_model_X)
random_model_X_test <- cbind(int, random_model_X_test)

# Run the optimized gradient descent
random_model_out <- gradientDesc(random_model_X, random_model_y, random_model_X_test, random_model_y_test, .001, .00005, 100000)

# EXPERIMENT 4:
# Selected features 
select_train <- trainingDS[, c("hr", "atemp", "hum", "cnt")]

select_test <- testDS[, c("hr", "atemp", "hum", "cnt")]

# Create the variables
select_y <- select_train$cnt
select_y_test <- select_test$cnt
select_X <- as.matrix(select_train[-ncol(select_train)])
select_X_test <- as.matrix(select_test[-ncol(select_test)])

int <- rep(1, length(select_y))

# Add intercept column to X
select_X <- cbind(int, select_X)
select_X_test <- cbind(int, select_X_test)

select_out <- gradientDesc(select_X, select_y, select_X_test, select_y_test, .001, .00005, 100000)

rm_results <- cbind(random_model_out$coefs, random_model_out$cost, random_model_out$new_cost_test)

select_results <- cbind(select_out$coefs, select_out$cost, select_out$new_cost_test)
