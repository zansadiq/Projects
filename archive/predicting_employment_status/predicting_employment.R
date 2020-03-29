library(knitr)
library(readxl)
library(data.table)
library(ggplot2)
library(nnet)
library(randomForest)
library(caret)
library(MASS)
library(parallel)
library(doMC)
library(plyr)
library(nnet)
library(e1071)
library(caretEnsemble)

# Set the root directory for RMarkdown
setwd("/Users/zansadiq/Documents/Code/IAS Comp")

set.seed(100)

options(scipen = 3)

load("ias_res.RData")

# Set-up parallel processing
numCores <- detectCores()
registerDoMC(cores = numCores)

# Function to compute classification error
classification_error <- function(conf_mat) {
  conf_mat = as.matrix(conf_mat)
  
  error = 1 - sum(diag(conf_mat)) / sum(conf_mat)
  
  return (error)
}

# Load the data and create a data.table
data <- setDT(read_xlsx("Training Dataset.xlsx"))
test <- setDT(read_xlsx("Test Dataset.xlsx"))

# Remove the unwanted characters
names(data) <- gsub(" ", "", names(data))
names(test) <- gsub(" ", "", names(test))

names(data) <- gsub("&", "and", names(data))
names(test) <- gsub("&", "and", names(test))

# Lower-casing
setnames(data, names(data), tolower(names(data)))
setnames(test, names(test), tolower(names(test)))

# Fix the factor names
data$employmentstatus <- as.factor(make.names(data$employmentstatus))
test$employmentstatus <- as.factor(make.names(test$employmentstatus))

data$educationlevel <- as.factor(make.names(data$educationlevel))
test$educationlevel <- as.factor(make.names(test$educationlevel))

data$year <- as.factor(make.names(data$year))
test$year <- as.factor(make.names(test$year))

# Factor columns 
factors <- c("educationlevel", "agerange", "employmentstatus", "gender", "year")

train <- data[, (factors) := lapply(.SD, as.factor), .SDcols = factors]
test <- test[, (factors) := lapply(.SD, as.factor), .SDcols = factors]

# Create training and validation sets
trainObs <- sample(nrow(data), .8 * nrow(data), replace = FALSE)
valObs <- sample(nrow(data), .2 * nrow(data), replace = FALSE)

train <- data[trainObs,]
val <- data[valObs,]

# Create a new variable for workers
train$worker <- factor(ifelse(train$employmentstatus == "Not.in.labor.force", 0, 1))
val$worker <- factor(ifelse(val$employmentstatus == "Not.in.labor.force", 0, 1))

train$worker <- as.factor(make.names(train$worker))
val$worker <- as.factor(make.names(val$worker))

# Create empty vectors for test set
test$worker <- factor(0)
test$employmentstatus <- factor("Unemployed")

# Model to predict workers 
control <- trainControl(method = "repeatedcv", number = 10, repeats = 3, search = "grid", savePredictions = "final", index = createResample(train$worker, 10), summaryFunction = twoClassSummary, classProbs = TRUE, verboseIter = TRUE)

# List algorithms
alg_list <- c("rf", "glm", "gbm", "glmboost", "nnet", "treebag", "svmLinear")

multi_mod <- caretList(worker ~ . - employmentstatus, data = train, trControl = control, methodList = alg_list, metric = "ROC")

# Results
res <- resamples(multi_mod)
summary(res)

# Stack 
stackControl <- trainControl(method = "repeatedcv", number = 10, repeats = 3, savePredictions = TRUE, classProbs = TRUE, verboseIter = TRUE)

stack <- caretStack(multi_mod, method = "rf", metric = "Accuracy", trControl = stackControl)

# Save results 
# save.image("ias_res.RData")

# Predict
stack_val_preds <- data.frame(predict(stack, val, type = "prob"))
stack_test_preds <- data.frame(predict(stack, test, type = "prob"))

# Function to find threshold

# Values
thresholds <- seq(0, 1, .05)
num_thresh <- length(thresholds)

# Empty list to store results
errors <- rep(0, num_thresh)

iter <- 1

for (i in thresholds) {

  cat("Calculating error for threshold value-", i, "\n")
  
  threshold_value <- i
  
  val_work_pred <- ifelse(stack_val_preds > threshold_value, "Yes", "No")
  
  conf_mat <- table(true = val$worker, pred = val_work_pred)
  
  errors[iter]<- classification_error(conf_mat) 
  
  iter <- iter + 1
}

# Compute final threshold value
result <- data.table(cbind(thresholds, errors))

final_value <- result[which(result$error == min(result$errors))]

val_worker_pred <- ifelse(stack_val_preds >= final_value$thresholds, 1, 0)

# Report error rate
phase1_conf <- table(true = val$worker, pred = val_worker_pred)
cat("Classification Error for Worker Predictions:", classification_error(phase1_conf), "\n")

# Fill the predictions for the test set
test$worker <- factor(ifelse(stack_test_preds >= final_value$thresholds, "X1", "X0"))

# Model
rf <- randomForest(employmentstatus ~ ., data = train, importance = TRUE)

print(rf)

# Predictions
rf_val_pred <- predict(rf, val)
rf_test_pred <- predict(rf, test)

# Results
rf_conf_mat <- table(true = val$employmentstatus, pred = rf_val_pred)

cat("Random Forest Classification Error, Validation:", classification_error(rf_conf_mat), "\n")

# Fill the results for the test set
test$employmentstatus <- rf_test_pred

# Make the names comply with original labels
levels(test$employmentstatus)[levels(test$employmentstatus)=="Not.in.labor.force"] <- "Not in labor force"

# Remove extra column created for predictions 
test <- test[,  "worker" := NULL]

# Write the results to csv
write.csv(test, "ias3_final_preds.csv")
