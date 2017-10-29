# Install packages
# install.packages("dplyr")
# install.packages("class")
# install.packages("nnet")
# install.packages("lubridate")
# install.packages("caret)
# install.packages("data.table")

# Import libraries
library(dplyr)
library(class)
library(nnet)
library(lubridate)
library(caret)
library(data.table)

# Working directory
# setwd("")

set.seed(100)

options(scipen = 6)

# Load the data
crypto_data <- read.csv("all_data.csv")
bank_data <- read.csv("bank-additional-full.csv", header = TRUE, sep = ";")

str(crypto_data)
str(bank_data)

# Fix the variables
crypto_data$time <- ymd_hms(as.character(crypto_data$time)) 

crypto_data$btc_change_label <- factor(crypto_data$btc_change_label, levels = c(0,1,2), labels = c("buy", "hold", "sell") )

#Manually create "target var"
crypto_data$targetVar <- crypto_data$btc_change_label
crypto_data <- select(crypto_data, -btc_change, -btc_change_label)

bank_data$targetVar <- bank_data$y
bank_data <- select(bank_data, -y)

# Function to compute classification error
classification_error <- function(conf_mat) {
  conf_mat = as.matrix(conf_mat)
  
  error = 1 - sum(diag(conf_mat)) / sum(conf_mat)
  
  return (error)
}

# Normalize the data
crypto_num_vars <- sapply(crypto_data, is.numeric)
crypto_data[crypto_num_vars] <- lapply(crypto_data[crypto_num_vars], scale)

bank_num_vars <- sapply(bank_data, is.numeric)
bank_data[bank_num_vars] <- lapply(bank_data[bank_num_vars], scale)

# ANN 
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
  
  nn <- nnet(select(trainDS, -time, -targetVar), ideal_trainDS, size = size, softmax = TRUE, maxit = iteration)
  # val_nn <- nnet(select(valDS, -time, -targetVar), ideal_valDS, size = size, softmax = TRUE)
  # test_nn <- nnet(select(testDS, -time, -targetVar), ideal_testDS, size = size, softmax = TRUE)
  
  train_pred <- predict(nn, select(trainDS, -time, -targetVar), type = "class")
  val_pred <- predict(nn, select(valDS, -time, -targetVar), type = "class")
  test_pred <- predict(nn, select(testDS, -time, -targetVar), type = "class")
  
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

bank_ann_predFunc <-function(inData, layer, trainPct, iteration ) {
  
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
  
  #softmax = True requires more than two response categories
  nn <- nnet(targetVar ~ ., trainDS, size = size, softmax = FALSE, maxit = iteration)
  # val_nn <- nnet(targetVar ~ ., valDS, size = 10, softmax = FALSE, maxit = 200)
  # test_nn <- nnet(targetVar ~ ., testDS, size = 10, softmax = FALSE, maxit = 200)
  
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

# KNN

# Function to make predictions
crypto_knn_predFunc <- function(inData, trainPct) {
  
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
  
  # Function
  caret_crypto_knn <- train(trainDS[, 2:21], trainDS[, 22], method='knn')
  
  # Predictions
  train_pred <- predict(object = caret_crypto_knn, trainDS[, 2:21])
  val_pred <- predict(object = caret_crypto_knn, valDS[, 2:21])
  test_pred <- predict(object = caret_crypto_knn, testDS[, 2:21])
  
  # Confusion matrix
  train_conf <- table(true = trainDS$targetVar, pred = train_pred)
  val_conf <- table(true = valDS$targetVar, pred = val_pred)
  test_conf <- table(true = testDS$targetVar, pred = test_pred)
  
  # Error rates 
  train_error <- classification_error(train_conf)
  val_error <- classification_error(val_conf)
  test_error <- classification_error(test_conf)
  
  return(list(train_error = train_error,
              val_error = val_error,
              test_error = test_error))
}

bank_knn_predFunc <- function(inData, trainPct) {
  
  trainP <- trainPct * .6
  valP <- trainPct * .2
  testP <- trainPct * .2
  
  #Converting outcome variable to numeric
  inData$targetVar <- ifelse(inData$targetVar == 'no', 0, 1)
  
  # Convert factors to numeric
  dmy <- dummyVars(" ~ .", data = inData, fullRank = T)
  inData <- data.frame(predict(dmy, newdata = inData))
  
  inData$targetVar <- as.factor(inData$targetVar)
  
  #SplitData
  trainObs <- sample(nrow(inData), trainP * nrow(inData), replace = FALSE)
  valObs <- sample(nrow(inData), valP * nrow(inData), replace = FALSE)
  testObs <- sample(nrow(inData), testP * nrow(inData), replace = FALSE)
  
  # Create the training/va/test datasets
  trainDS <- inData[trainObs,]
  valDS <- inData[valObs,]
  testDS <- inData[testObs,]
  
  # Function  
  caret_bank_knn <- train(trainDS[, 1:53], trainDS[, 54], method='knn')
  
  # Predictions
  train_pred <- predict(object = caret_bank_knn, trainDS[, 1:53])
  val_pred <- predict(object = caret_bank_knn, valDS[, 1:53])
  test_pred <- predict(object = caret_bank_knn, testDS[, 1:53])
  
  # Confusion matrix
  train_conf <- table(true = trainDS$targetVar, pred = train_pred)
  val_conf <- table(true = valDS$targetVar, pred = val_pred)
  test_conf <- table(true = testDS$targetVar, pred = test_pred)
  
  # Errors
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

# Vary the ANN layers
layers <- seq(5, 15, by = 1)
numlayers <- length(layers)

# Vary the ANN iterations
iterations <- seq(200, 1000, by = 100)
numiter <- length(iterations)

#Create empty vectors to store train/test error rates
crypto_nn_plot_errors_train <- rep(0, numPcts)
crypto_nn_plot_errors_val <- rep(0, numPcts)
crypto_nn_plot_errors_test <- rep(0, numPcts)

bank_nn_plot_errors_train <- rep(0, numPcts)
bank_nn_plot_errors_val <- rep(0, numPcts)
bank_nn_plot_errors_test <- rep(0, numPcts)

crypto_knn_plot_errors_train <- rep(0, numPcts)
crypto_knn_plot_errors_val <- rep(0, numPcts)
crypto_knn_plot_errors_test <- rep(0, numPcts)

bank_knn_plot_errors_train <- rep(0, numPcts)
bank_knn_plot_errors_val <- rep(0, numPcts)
bank_knn_plot_errors_test <- rep(0, numPcts)

crypto_nn_size_errors <- rep(0, numsizes)
bank_nn_size_errors <- rep(0, numsizes)

crypto_nn_iter_errors <- rep(0, numiter)
bank_nn_iter_errors <- rep(0, numiter)

iter <- 1
for(i in layers){
  cat("Running iteration ",iter, "\n")
  
  thissize <- i
  
  #Perform predictions
  crypto_size_out <- crypto_ann_predFunc(crypto_data, thissize, 1, 200)
  bank_size_out <- bank_ann_predFunc(bank_data, thissize, 1, 200)
  
  #grab test "final" error rates for the datasets
  crypto_nn_size_errors[iter] <- crypto_size_out$test_error
  
  bank_nn_size_errors[iter] <- bank_size_out$test_error
  
  iter <- iter + 1
}

iter <- 1
for(i in iterations){
  cat("Running iteration ",iter, "\n")
  
  thisiter <- i
  
  #Perform predictions
  crypto_iter_out <- crypto_ann_predFunc(crypto_data, 10, 1, thisiter)
  bank_iter_out <- bank_ann_predFunc(bank_data, 10, 1, thisiter)
  
  #grab test "final" error rates for the datasets
  crypto_nn_iter_errors[iter] <- crypto_iter_out$test_error
  
  bank_nn_iter_errors[iter] <- bank_iter_out$test_error
  
  iter <- iter + 1
}

iter <- 1
for(i in trainPcts){
  cat("Running iteration ",iter, "\n")

  thisTrainPct <- i
  
  #Perform predictions
  crypto_nn_out <- crypto_ann_predFunc(crypto_data, 10, thisTrainPct, 200)
  bank_nn_out <- bank_ann_predFunc(bank_data, 10, thisTrainPct, 200)
  
  crypto_knn_out <- crypto_knn_predFunc(crypto_data, thisTrainPct)
  bank_knn_out <- bank_knn_predFunc(bank_data, thisTrainPct)
  
  #grab train/test "final" error rates for the crypto dataset
  crypto_nn_plot_errors_train[iter] <- crypto_nn_out$train_error
  crypto_nn_plot_errors_val[iter] <- crypto_nn_out$val_error
  crypto_nn_plot_errors_test[iter] <- crypto_nn_out$test_error
  
  bank_nn_plot_errors_train[iter] <- bank_nn_out$train_error
  bank_nn_plot_errors_val[iter] <- bank_nn_out$val_error
  bank_nn_plot_errors_test[iter] <- bank_nn_out$test_error
  
  crypto_knn_plot_errors_train[iter] <- crypto_knn_out$train_error
  crypto_knn_plot_errors_val[iter] <- crypto_knn_out$val_error
  crypto_knn_plot_errors_test[iter] <- crypto_knn_out$test_error
  
  bank_knn_plot_errors_train[iter] <- bank_knn_out$train_error
  bank_knn_plot_errors_val[iter] <- bank_knn_out$val_error
  bank_knn_plot_errors_test[iter] <- bank_knn_out$test_error
  
  iter <- iter + 1
}

# Plot the errors

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

# Bank ANN
bank_plot_nndata <- as.data.table(cbind(trainPcts, bank_nn_plot_errors_train, bank_nn_plot_errors_val, bank_nn_plot_errors_test))

bank_plot_nndat <- melt(bank_plot_nndata, id = c("trainPcts"))

bank_plot_nnplot <- ggplot(data = bank_plot_nndat,
                             aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Bank ANN, N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Classification Error")

# Crypto KNN
crypto_plot_knndata <- as.data.table(cbind(trainPcts, crypto_knn_plot_errors_train, crypto_knn_plot_errors_val, crypto_knn_plot_errors_test))

crypto_plot_knndat <- melt(crypto_plot_knndata, id = c("trainPcts"))

crypto_plot_knnplot <- ggplot(data = crypto_plot_knndat,
                             aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Crypto KNN, N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Classification Error")

# Bank KNN
bank_plot_knndata <- as.data.table(cbind(trainPcts, bank_knn_plot_errors_train, bank_knn_plot_errors_val, bank_knn_plot_errors_test))

bank_plot_knndat <- melt(bank_plot_knndata, id = c("trainPcts"))

bank_plot_knnplot <- ggplot(data = bank_plot_knndat,
                           aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Bank KNN, N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Classification Error")

# Crypto ANN Size errors
crypto_plot_sizedata <- as.data.table(cbind(sizes, crypto_nn_size_errors))

crypto_plot_sizedat <- melt(crypto_plot_sizedata, id = c("sizes"))

crypto_plot_sizeplot <- ggplot(data = crypto_plot_sizedat,
                             aes(x = sizes, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Crypto ANN, # Layers vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("Size (layers)") +
  ylab ("Classification Error")

# Bank ANN Size errors
bank_plot_sizedata <- as.data.table(cbind(sizes, bank_nn_size_errors))

bank_plot_sizedat <- melt(bank_plot_sizedata, id = c("sizes"))

bank_plot_sizeplot <- ggplot(data = bank_plot_sizedat,
                               aes(x = sizes, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Bank ANN, # Layers vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("Size (layers)") +
  ylab ("Classification Error")

# Crypto ANN iter errors
crypto_plot_iterdata <- as.data.table(cbind(iterations, crypto_nn_iter_errors))

crypto_plot_iterdat <- melt(crypto_plot_iterdata, id = c("iterations"))

crypto_plot_iterplot <- ggplot(data = crypto_plot_iterdat,
                               aes(x = iterations, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Crypto ANN, # Iterations vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("Iterations") +
  ylab ("Classification Error")

# Bank ANN iter errors
bank_plot_iterdata <- as.data.table(cbind(iterations, bank_nn_iter_errors))

bank_plot_iterdat <- melt(bank_plot_iterdata, id = c("iterations"))

bank_plot_iterplot <- ggplot(data = bank_plot_iterdat,
                             aes(x = iterations, y = value, colour = variable)) +
  geom_line()+
  ggtitle("Bank ANN, # Iterations vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("Iterations") +
  ylab ("Classification Error")

# Optimization
crypto_opt <- crypto_ann_predFunc(crypto_data, 12, 1, 900) 
                                  
bank_opt <- bank_ann_predFunc(bank_data, 10, 1, 700)
