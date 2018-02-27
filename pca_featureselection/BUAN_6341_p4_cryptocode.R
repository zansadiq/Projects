# Install packages
# install.packages("dplyr")
# install.packages("class")
# install.packages("nnet")
# install.packages("lubridate")
# install.packages("caret)
# install.packages("data.table")
# install.packages("mclust")
# install.packages("mlbench")
# install.packages("ggplot2")
# install.packages("devtools")
# install_github("ggbiplot", "vqv")
# install.packages("fastICA")

# Import libraries
library(dplyr)
library(class)
library(nnet)
library(lubridate)
library(caret)
library(data.table)
library(mclust)
library(mlbench)
library(ggplot2)
library(devtools)
library(ggbiplot)
library(fastICA)

# Working directory
# setwd("/Users/zansadiq/Documents/School/Fall 2017/BUAN6341/Homework/zan_buan6341_assignment4")
setwd("E:/AML - BUAN 6341")

set.seed(100)

options(scipen = 6)

# Load the data
crypto_data <- read.csv("all_data.csv")

# Fix the variables
crypto_data$time <- ymd_hms(as.character(crypto_data$time)) 

crypto_data$btc_change_label <- factor(crypto_data$btc_change_label, levels = c(0,1,2), labels = c("buy", "hold", "sell") )

#Manually create "target var"
crypto_data$targetVar <- crypto_data$btc_change_label
crypto_data <- select(crypto_data, -btc_change, -btc_change_label)

# Function to compute classification error
classification_error <- function(conf_mat) {
  conf_mat = as.matrix(conf_mat)
  
  error = 1 - sum(diag(conf_mat)) / sum(conf_mat)
  
  return (error)
}

# Split the datasets
trainObs <- sample(nrow(crypto_data), .6 * nrow(crypto_data), replace = FALSE)
valObs <- sample(nrow(crypto_data), .2 * nrow(crypto_data), replace = FALSE)
testObs <- sample(nrow(crypto_data), .2 * nrow(crypto_data), replace = FALSE)

# Create the training/va/test datasets
trainDS <- crypto_data[trainObs,]
valDS <- crypto_data[valObs,]
testDS <- crypto_data[testObs,]

# K-Means
crypto_cluster <- kmeans(crypto_data[,2:21], 3, nstart = 20)

# Plot 
crypto_cluster$cluster <- as.factor(crypto_cluster$cluster)

crypto_kmeans_plot <- ggplot(crypto_data, aes(btc_price, trade_volume_usd, color = crypto_cluster$cluster)) +
                             geom_point() +
                             ggtitle("Crypto K-Means, BTC Price v. Trade Volume") +
                             theme(plot.title = element_text(hjust = 0.5)) +
                             xlab ("BTC Price") +
                             ylab ("Trade Volume")

# Expectation-Maximization

# Create a vector for the target variable
classes <- as.numeric(crypto_data$targetVar)

# Remove time variable and target
inData <- crypto_data[,c(-1,-22)]

pairs <- clPairs(inData, classes)

fit <- Mclust(inData, x = classification)

summary(fit, parameters = TRUE)

classification <- plot(fit, what = "classification", 
                            xlab = "BTC Price",
                            ylab = "Trade Volume",
                            main = "Expectation-Maximization, Cryptocurrency Data")

# Create binary variables for targetVar
crypto_data$buy <- as.factor(ifelse(crypto_data$targetVar == 'buy', 1, 0))
crypto_data$hold <- as.factor(ifelse(crypto_data$targetVar == 'hold', 1, 0))
crypto_data$sell <- as.factor(ifelse(crypto_data$targetVar == 'sell', 1, 0))

crypto_data <- crypto_data[,-22]

# Control
buy_control <- trainControl(method = "repeatedcv", number = 10, repeats = 3)
hold_control <- trainControl(method = "repeatedcv", number = 10, repeats = 3)
sell_control <- trainControl(method = "repeatedcv", number = 10, repeats = 3)

# Feature Selection
# train the model
buy_model <- train(buy ~ ., data = crypto_data, method = "rf", preProcess = "scale", trControl = buy_control, importance = TRUE)
hold_model <- train(hold ~ ., data = crypto_data, method ="rf", preProcess = "scale", trControl = hold_control, importance = TRUE)
sell_model <- train(sell ~ ., data = crypto_data, method ="rf", preProcess = "scale", trControl = sell_control, importance = TRUE)

buy_importance <- varImp(buy_model, scale = FALSE)
hold_importance <- varImp(hold_model, scale = FALSE)
sell_importance <- varImp(sell_model, scale = FALSE)

# plot importance
buy_imp <- plot(buy_importance)
hold_imp <- plot(buy_importance)
sell_imp <- plot(buy_importance)

# Define the control using a random forest selection function
control <- rfeControl(functions = rfFuncs, method = "cv", number = 10)
  
# Run the RFE algorithm
results <- rfe(crypto_data[, 2:21], crypto_data[, 22], sizes = c(2:21), rfeControl = control)
 
# Summarize the results
print(results)
  
# List the chosen features
predictors(results)
  
# Plot the results
plot(results, type = c("g", "o"))

# PCA
crypto_pca_data <- trainDS[,2:21]
crypto_pca_val_data <- valDS[,2:21]
crypto_pca_test_data <- testDS[,2:21]

# Select target information
crypto_target <- trainDS[,22]
crypto_val_target <- valDS[,22]
crypto_test_target <- testDS[,22]

crypto_pca <- prcomp(crypto_pca_data, center = TRUE, scale. = TRUE)

plot(crypto_pca, type = "l")

predict(crypto_pca, newdata = crypto_val_target)

# Visualize the principal components
fancy <- ggbiplot(crypto_pca, obs.scale = 1, var.scale = 1, group = crypto_target, ellipse = TRUE, circle = TRUE)
fancy <- fancy + scale_color_discrete(name = '')
fancy <- fancy + theme(legend.direction = 'horizontal', legend.position = 'top')

print(fancy)

# ICA
# Scale the data
crypto_scaled <- scale(crypto_data[,2:21])

# Number of independent components chosen from feature selection process
crypto_ica <- fastICA(crypto_scaled, n.comp = 6)

# Fix the margins
graphics.off()
par("mar")
par(mar = rep(2, 4))

# Visualize the results
crypto_pairs <- pairs(crypto_ica$S, col = rainbow(3)[crypto_data[,22]])

crypto_ica_plot <- plot(crypto_ica$S[,1], crypto_ica$S[,1], col = rainbow(3)[crypto_data[,22]], xlab = "Comp1", ylab = "Comp1")

# Rerun clustering
fs_crypto_dat <- crypto_data[,c("btc_price", "eth_price", "trade_volume_btc", "btc_price", "n_blocks_total", "trade_volume_usd", "totalbtc", "targetVar")]

# K-Means
crypto_new_cluster <- kmeans(fs_crypto_dat[,-8], 3, nstart = 20)

# Plot 
crypto_new_cluster$cluster <- as.factor(crypto_new_cluster$cluster)

crypto_new_kmeans_plot <- ggplot(fs_crypto_dat, aes(btc_price, trade_volume_usd, color = crypto_new_cluster$cluster)) +
                                 geom_point() +
                                 ggtitle("New Crypto K-Means, BTC Price v. Trade Volume") +
                                 theme(plot.title = element_text(hjust = 0.5)) +
                                 xlab ("BTC Price") +
                                 ylab ("Trade Volume")

# Expectation-Maximization

# Create a vector for the target variable
new_classes <- as.numeric(fs_crypto_dat$targetVar)

# Remove time variable and target
new_inData <- fs_crypto_dat[,-8]

new_pairs <- clPairs(new_inData, new_classes)

new_fit <- Mclust(new_inData, x = classification)

summary(new_fit, parameters = TRUE)

new_classification <- plot(fit, what = "classification", 
                           xlab = "BTC Price",
                           ylab = "Trade Volume",
                           main = "New Expectation-Maximization, Cryptocurrency Data")

# Run NN on reduced data
fs_crypto_num_vars <- sapply(fs_crypto_dat, is.numeric)
fs_crypto_dat[fs_crypto_num_vars] <- lapply(fs_crypto_dat[fs_crypto_num_vars], scale)

crypto_ann_predFunc <-function(inData, layer, trainPct, iteration ) {
  
  trainP <- trainPct * .6
  valP <- trainPct * .2
  testP <- trainPct * .2
  
  #SplitData
  trainObs <- sample(nrow(inData), trainP * nrow(inData), replace = FALSE)
  valObs <- sample(nrow(inData), valP * nrow(inData), replace = FALSE)
  testObs <- sample(nrow(inData), testP * nrow(inData), replace = FALSE)
  
  # Create the training/va/test datasets
  trainDS <- inData[trainObs,]
  valDS <- inData[valObs,]
  testDS <- inData[testObs,]
  
  # ANN
  ideal_trainDS <- class.ind(trainDS$targetVar)
  ideal_valDS <- class.ind(valDS$targetVar)
  ideal_testDS <- class.ind(testDS$targetVar)
  
  nn <- nnet(select(trainDS, -targetVar), ideal_trainDS, size = layer, softmax = TRUE, maxit = iteration)
  # val_nn <- nnet(select(valDS, -time, -targetVar), ideal_valDS, size = size, softmax = TRUE)
  # test_nn <- nnet(select(testDS, -time, -targetVar), ideal_testDS, size = size, softmax = TRUE)
  
  train_pred <- predict(nn, select(trainDS, -targetVar), type = "class")
  val_pred <- predict(nn, select(valDS, -targetVar), type = "class")
  test_pred <- predict(nn, select(testDS, -targetVar), type = "class")
  
  train_conf <- table(true = trainDS$targetVar, pred = train_pred)
  val_conf <- table(true = valDS$targetVar, pred = val_pred)
  test_conf <- table(true = testDS$targetVar, pred = test_pred)
  
  train_error <- classification_error(train_conf)
  val_error <- classification_error(val_conf)
  test_error <- classification_error(test_conf)
  
  return(list(train_error = train_error,
              val_error = val_error,
              test_error = test_error))
}

# Vary the dataset size
trainPcts <- seq(.1, 1, by = .05)
numPcts <- length(trainPcts)

#Create empty vectors to store train/test error rates
crypto_nn_plot_errors_train <- rep(0, numPcts)
crypto_nn_plot_errors_val <- rep(0, numPcts)
crypto_nn_plot_errors_test <- rep(0, numPcts)

iter <- 1
for(i in trainPcts){
  cat("Running iteration ",iter, "\n")
  
  thisTrainPct <- i
  
  #Perform predictions
  crypto_nn_out <- crypto_ann_predFunc(fs_crypto_dat, 10, thisTrainPct, 200)

  #grab train/test "final" error rates for the crypto dataset
  crypto_nn_plot_errors_train[iter] <- crypto_nn_out$train_error
  crypto_nn_plot_errors_val[iter] <- crypto_nn_out$val_error
  crypto_nn_plot_errors_test[iter] <- crypto_nn_out$test_error
  
  iter <- iter + 1
}

# Crypto ANN
crypto_plot_nndata <- as.data.table(cbind(trainPcts, crypto_nn_plot_errors_train, crypto_nn_plot_errors_val, crypto_nn_plot_errors_test))

crypto_plot_nndat <- melt(crypto_plot_nndata, id = c("trainPcts"))

crypto_plot_nnplot <- ggplot(data = crypto_plot_nndat,
                             aes(x = trainPcts, y = value, colour = variable)) +
                             geom_line()+
                             ggtitle("Crypto ANN, N vs. Classification Error Rates") +
                             theme(plot.title = element_text(hjust = 0.5)) +
                             xlab ("N") +
                             ylab ("Classification Error")
