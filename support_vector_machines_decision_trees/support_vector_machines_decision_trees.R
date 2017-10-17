
# Import libraries
library(lubridate)
library(e1071)
library(rpart)
library(pROC)
library(rpart.plot)
library(RColorBrewer)
library(ada)
library(maboost)
library(adabag)
library(ROCR)
library(data.table)
library(dplyr)

# Working directory
# setwd("")

set.seed(100)

# Load the data
crypto_data <- read.csv("Data/all_data.csv")
bank_data <- read.csv("Data/bank-additional-full.csv", header = TRUE, sep = ";")

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
  
  error = 1-sum(diag(conf_mat))/sum(conf_mat)
  
  return (error)
}

# Decision trees
tree_pruning <- function(data, trainPct, prune_val) {
  
  trainP <- trainPct * .6
  valP <- trainPct * .2
  testP <- trainPct * .2
  
  # Prune the bank tree
  trainObs <- sample(nrow(data), trainP * nrow(data), replace = FALSE)
  valObs <- sample(nrow(data), valP * nrow(data), replace = FALSE)
  testObs <- sample(nrow(data), testP * nrow(data), replace = FALSE)
  
  # Create the training/va/test datasets
  trainDS <- data[trainObs,]
  valDS <- data[valObs,]
  testDS <- data[testObs,]
  
  tree <- rpart(targetVar ~ ., data = trainDS, method = "class", cp = -1)

  prune_tree <- prune(tree, prune_val)
  
  predtree <- predict(prune_tree, select(trainDS, -targetVar), type = "class")
  valtree <- predict(prune_tree, select(valDS, -targetVar), type = "class")
  testtree <- predict(prune_tree, select(testDS, -targetVar), type = "class")
  
  # Tree confusion matrix
  treetrainConfusion <- table(true = trainDS[,c("targetVar")], pred = predtree)
  treevalConfusion <- table(true = valDS[,c("targetVar")], pred = valtree)
  treetestConfusion <- table(true = testDS[,c("targetVar")], pred = testtree)
  
  # Classification error
  treetrainClassificationError <- classification_error(treetrainConfusion)
  treevalClassificationError <- classification_error(treevalConfusion)
  treetestClassificationError <- classification_error(treetestConfusion)
  
  return(list(treetrainClassificationError = treetrainClassificationError,
              treevalClassificationError = treevalClassificationError,
              treetestClassificationError = treetestClassificationError))
}

# Iterate through different values of N
trainPcts <- seq(.1, 1, by = .05)
numPcts <- length(trainPcts)

# Function to make predictions
predFunc <- function(inData,trainPct){
  
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
  
  # SVM- linear kernel
  linearSVM <- svm(targetVar ~ ., data = trainDS, method = "C-classification", kernel = "linear")
  
  # SVM- radial kernel
  radialSVM<- svm(targetVar ~ ., data = trainDS, cost = 100, gamma = 1)
  
  # SVM- sigmoid kernel
  sigSVM <- svm(targetVar ~ ., data = trainDS, kernel = "sigmoid", cost = 100, gamma = 1)
  
  # Boosting
  adaboost <- boosting(targetVar ~ ., data = trainDS, boos = TRUE, mfinal = 6)

  # linear SVM Predictions
  predSVMlin <- predict(linearSVM, select(trainDS, -targetVar))
  valSVMlin <- predict(linearSVM, select(valDS, -targetVar))
  testSVMlin <- predict(linearSVM, select(testDS, -targetVar))
  
  # radial SVM predictions
  predSVMrad <- predict(radialSVM, select(trainDS, -targetVar))
  valSVMrad <- predict(radialSVM, select(valDS, -targetVar))
  testSVMrad <- predict(radialSVM, select(testDS, -targetVar))
  
  # sigmoid SVM predictions
  predSVMsig <- predict(sigSVM, select(trainDS, -targetVar))
  valSVMsig <- predict(sigSVM, select(valDS, -targetVar))
  testSVMsig <- predict(sigSVM, select(testDS, -targetVar))
  
  # boosting predictions
  predboost <- predict.bagging(adaboost, select(trainDS, -targetVar))
  valboost <- predict.bagging(adaboost, select(valDS, -targetVar))
  testboost <- predict.bagging(adaboost, select(testDS, -targetVar))
  
  # SVM Confusion matrix
  trainConfusion <- table(true = trainDS[,c("targetVar")], pred = predSVMlin)
  valConfusion <- table(true = valDS[,c("targetVar")], pred = valSVMlin)
  testConfusion <- table(true = testDS[,c("targetVar")], pred = testSVMlin)
  
  # SVM radial Confusion matrix
  radtrainConfusion <- table(true = trainDS[,c("targetVar")], pred = predSVMrad)
  radvalConfusion <- table(true = valDS[,c("targetVar")], pred = valSVMrad)
  radtestConfusion <- table(true = testDS[,c("targetVar")], pred = testSVMrad)
  
  # SVM sig confustion matrix
  sigtrainConfusion <- table(true = trainDS[,c("targetVar")], pred = predSVMsig)
  sigvalConfusion <- table(true = valDS[,c("targetVar")], pred = valSVMsig)
  sigtestConfusion <- table(true = testDS[,c("targetVar")], pred = testSVMsig)
  
  # Boosting confusion matrix
  boosttrainConfusion <- table(true = trainDS[,c("targetVar")], pred = predboost$class)
  boostvalConfusion <- table(true = valDS[,c("targetVar")], pred = valboost$class)
  boosttestConfusion <- table(true = testDS[,c("targetVar")], pred = testboost$class)
  
  # Linear SVM Classification error
  trainClassificationError <- classification_error(trainConfusion)
  valClassificationError <- classification_error(valConfusion)
  testClassificationError <- classification_error(testConfusion)
  
  # Radial SVM Classification error
  radtrainClassificationError <- classification_error(radtrainConfusion)
  radvalClassificationError <- classification_error(radvalConfusion)
  radtestClassificationError <- classification_error(radtestConfusion)
  
  # Sig SVM Classification error
  sigtrainClassificationError <- classification_error(sigtrainConfusion)
  sigvalClassificationError <- classification_error(sigvalConfusion)
  sigtestClassificationError <- classification_error(sigtestConfusion)
  
  # Boosting Error
  boosttrainClassificationError <- classification_error(boosttrainConfusion)
  boostvalClassificationError <- classification_error(boostvalConfusion)
  boosttestClassificationError <- classification_error(boosttestConfusion)
  
  return(list(trainClassificationError = trainClassificationError,
              valClassificationError = valClassificationError,
              testClassificationError = testClassificationError,
              radtrainClassificationError = radtrainClassificationError,
              radvalClassificationError = radvalClassificationError,
              radtestClassificationError = radtestClassificationError,
              sigtrainClassificationError = sigtrainClassificationError,
              sigvalClassificationError = sigvalClassificationError,
              sigtestClassificationError = sigtestClassificationError,
              boosttrainClassificationError = boosttrainClassificationError,
              boostvalClassificationError = boostvalClassificationError,
              boosttestClassificationError = boosttestClassificationError))
}

#Create empty vectors to store train/test error rates
crypto_linsvm_plot_errors_train <- rep(0, numPcts)
crypto_linsvm_plot_errors_val <- rep(0, numPcts)
crypto_linsvm_plot_errors_test <- rep(0, numPcts)

crypto_radsvm_plot_errors_train <- rep(0, numPcts)
crypto_radsvm_plot_errors_val <- rep(0, numPcts)
crypto_radsvm_plot_errors_test <- rep(0, numPcts)

crypto_sigsvm_plot_errors_train <- rep(0, numPcts)
crypto_sigsvm_plot_errors_val <- rep(0, numPcts)
crypto_sigsvm_plot_errors_test <- rep(0, numPcts)

crypto_tree_plot_errors_train <- rep(0, numPcts)
crypto_tree_plot_errors_val <- rep(0, numPcts)
crypto_tree_plot_errors_test <- rep(0, numPcts)

crypto_boost_plot_errors_train <- rep(0, numPcts)
crypto_boost_plot_errors_val <- rep(0, numPcts)
crypto_boost_plot_errors_test <- rep(0, numPcts)

bank_linsvm_plot_errors_train <- rep(0, numPcts)
bank_linsvm_plot_errors_val <- rep(0, numPcts)
bank_linsvm_plot_errors_test <- rep(0, numPcts)

bank_radsvm_plot_errors_train <- rep(0, numPcts)
bank_radsvm_plot_errors_val <- rep(0, numPcts)
bank_radsvm_plot_errors_test <- rep(0, numPcts)

bank_sigsvm_plot_errors_train <- rep(0, numPcts)
bank_sigsvm_plot_errors_val <- rep(0, numPcts)
bank_sigsvm_plot_errors_test <- rep(0, numPcts)

bank_tree_plot_errors_train <- rep(0, numPcts)
bank_tree_plot_errors_val <- rep(0, numPcts)
bank_tree_plot_errors_test <- rep(0, numPcts)

bank_boost_plot_errors_train <- rep(0, numPcts)
bank_boost_plot_errors_val <- rep(0, numPcts)
bank_boost_plot_errors_test <- rep(0, numPcts)

iter <- 1
for(i in trainPcts){
  cat("Running iteration ",iter, "\n")

  #Perform prediction
  thisTrainPct <- i
  crypto_out <- predFunc(crypto_data, thisTrainPct)
  bank_out <- predFunc(bank_data, thisTrainPct)
  
  tree1 <- tree_pruning(crypto_data, thisTrainPct, .02)
  tree2 <- tree_pruning(bank_data, thisTrainPct, .002)
  
  crypto_tree_plot_errors_train[iter] <- tree1$treetrainClassificationError
  crypto_tree_plot_errors_val[iter] <- tree1$treevalClassificationError
  crypto_tree_plot_errors_test[iter] <- tree1$treetestClassificationError
  
  bank_tree_plot_errors_train[iter] <- tree2$treetrainClassificationError
  bank_tree_plot_errors_val[iter] <- tree2$treevalClassificationError
  bank_tree_plot_errors_test[iter] <- tree2$treetestClassificationError
  
  #grab train/test "final" error rates for the crypto dataset
  crypto_linsvm_plot_errors_train[iter] <- crypto_out$trainClassificationError
  crypto_linsvm_plot_errors_val[iter] <- crypto_out$valClassificationError
  crypto_linsvm_plot_errors_test[iter] <- crypto_out$testClassificationError
  
  crypto_radsvm_plot_errors_train[iter] <- crypto_out$radtrainClassificationError
  crypto_radsvm_plot_errors_val[iter] <- crypto_out$radvalClassificationError
  crypto_radsvm_plot_errors_test[iter] <- crypto_out$radtestClassificationError
  
  crypto_sigsvm_plot_errors_train[iter] <- crypto_out$sigtrainClassificationError
  crypto_sigsvm_plot_errors_val[iter] <- crypto_out$sigvalClassificationError
  crypto_sigsvm_plot_errors_test[iter] <- crypto_out$sigtestClassificationError
  
  crypto_boost_plot_errors_train[iter] <- crypto_out$boosttrainClassificationError
  crypto_boost_plot_errors_val[iter] <- crypto_out$boostvalClassificationError
  crypto_boost_plot_errors_test[iter] <- crypto_out$boosttestClassificationError
  
  #grab train/test "final" error rates for the bank dataset
  bank_linsvm_plot_errors_train[iter] <- bank_out$trainClassificationError
  bank_linsvm_plot_errors_val[iter] <- bank_out$valClassificationError
  bank_linsvm_plot_errors_test[iter] <- bank_out$testClassificationError
  
  bank_radsvm_plot_errors_train[iter] <- bank_out$radtrainClassificationError
  bank_radsvm_plot_errors_val[iter] <- bank_out$radvalClassificationError
  bank_radsvm_plot_errors_test[iter] <- bank_out$radtestClassificationError
  
  bank_sigsvm_plot_errors_train[iter] <- bank_out$sigtrainClassificationError
  bank_sigsvm_plot_errors_val[iter] <- bank_out$sigvalClassificationError
  bank_sigsvm_plot_errors_test[iter] <- bank_out$sigtestClassificationError
  
  bank_boost_plot_errors_train[iter] <- bank_out$boosttrainClassificationError
  bank_boost_plot_errors_val[iter] <- bank_out$boostvalClassificationError
  bank_boost_plot_errors_test[iter] <- bank_out$boosttestClassificationError
  
  iter <- iter + 1
}

# Plot the errors
crypto_plot_linsvmdata <- as.data.table(cbind(trainPcts, crypto_linsvm_plot_errors_train, crypto_linsvm_plot_errors_val, crypto_linsvm_plot_errors_test))

crypto_plot_linsvmdat <- melt(crypto_plot_linsvmdata, id = c("trainPcts"))

crypto_plot_linsvmplot <- ggplot(data = crypto_plot_linsvmdat,
                    aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Crypto Linear SVM Classification Error")

# Plot the errors
crypto_plot_radsvmdata <- as.data.table(cbind(trainPcts, crypto_radsvm_plot_errors_train, crypto_radsvm_plot_errors_val, crypto_radsvm_plot_errors_test))

crypto_plot_radsvmdat <- melt(crypto_plot_radsvmdata, id = c("trainPcts"))

crypto_plot_radsvmplot <- ggplot(data = crypto_plot_radsvmdat,
                    aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Crypto Radial SVM Classification Error")

# Plot the errors
crypto_plot_sigsvmdata <- as.data.table(cbind(trainPcts, crypto_sigsvm_plot_errors_train, crypto_sigsvm_plot_errors_val, crypto_sigsvm_plot_errors_test))

crypto_plot_sigsvmdat <- melt(crypto_plot_sigsvmdata, id = c("trainPcts"))

crypto_plot_sigsvmplot <- ggplot(data = crypto_plot_sigsvmdat,
                          aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Crypto Sigmoid Classification Error")

# Plot the errors
crypto_plot_treedata <- as.data.table(cbind(trainPcts, crypto_tree_plot_errors_train, crypto_tree_plot_errors_val, crypto_tree_plot_errors_test))

crypto_plot_treedat <- melt(crypto_plot_treedata, id = c("trainPcts"))

crypto_plot_treeplot <- ggplot(data = crypto_plot_treedat,
                          aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Crypto Tree Classification Error")

# Plot the errors
crypto_plot_boostdata <- as.data.table(cbind(trainPcts, crypto_boost_plot_errors_train, crypto_boost_plot_errors_val, crypto_boost_plot_errors_test))

crypto_plot_boostdat <- melt(crypto_plot_boostdata, id = c("trainPcts"))

crypto_plot_boostplot <- ggplot(data = crypto_plot_boostdat,
                               aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Crypto Boosting Classification Error")

# Plot the errors
bank_plot_linsvmdata <- as.data.table(cbind(trainPcts, bank_linsvm_plot_errors_train, bank_linsvm_plot_errors_val, bank_linsvm_plot_errors_test))

bank_plot_linsvmdat <- melt(bank_plot_linsvmdata, id = c("trainPcts"))

bank_plot_linsvmplot <- ggplot(data = bank_plot_linsvmdat,
                                 aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Bank Linear SVM Classification Error")

# Plot the errors
bank_plot_radsvmdata <- as.data.table(cbind(trainPcts, bank_radsvm_plot_errors_train, bank_radsvm_plot_errors_val, bank_radsvm_plot_errors_test))

bank_plot_radsvmdat <- melt(bank_plot_radsvmdata, id = c("trainPcts"))

bank_plot_radsvmplot <- ggplot(data = bank_plot_radsvmdat,
                                 aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Bank Radial SVM Classification Error")

# Plot the errors
bank_plot_sigsvmdata <- as.data.table(cbind(trainPcts, bank_sigsvm_plot_errors_train, bank_sigsvm_plot_errors_val, bank_sigsvm_plot_errors_test))

bank_plot_sigsvmdat <- melt(bank_plot_sigsvmdata, id = c("trainPcts"))

bank_plot_sigsvmplot <- ggplot(data = bank_plot_sigsvmdat,
                                 aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Bank Sigmoid Classification Error")

# Plot the errors
bank_plot_treedata <- as.data.table(cbind(trainPcts, bank_tree_plot_errors_train, bank_tree_plot_errors_val, bank_tree_plot_errors_test))

bank_plot_treedat <- melt(bank_plot_treedata, id = c("trainPcts"))

bank_plot_treeplot <- ggplot(data = bank_plot_treedat,
                               aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Bank Tree Classification Error")

# Plot the errors
bank_plot_boostdata <- as.data.table(cbind(trainPcts, bank_boost_plot_errors_train, bank_boost_plot_errors_val, bank_boost_plot_errors_test))

bank_plot_boostdat <- melt(bank_plot_boostdata, id = c("trainPcts"))

bank_plot_boostplot <- ggplot(data = bank_plot_boostdat,
                                aes(x = trainPcts, y = value, colour = variable)) +
  geom_line()+
  ggtitle("N vs. Classification Error Rates") +
  theme(plot.title = element_text(hjust = 0.5)) +
  xlab ("N") +
  ylab ("Bank Boosting Classification Error")
