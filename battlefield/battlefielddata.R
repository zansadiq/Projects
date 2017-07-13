setwd("~/Documents/Code/Battlefield")

library(timeDate)

data<-read.csv(file="battlefielddata.csv")

head(data)
summary(data)

names(data)
sapply(data, class)

data$DATE <- as.Date(data$DATE, format = "%m/%d/%Y")

write.csv(file="battlefielddata.csv",data)

library(rpart)
library(caret)

plot(data$OUTCOME,main=c("Outcome"))

library(rattle)
library(sqldf)

#subset the data

Assault <- subset(data,data$TYPE == 'Assault')

Medic <- subset(data,data$TYPE == 'Medic')

Scout <- subset(data,data$TYPE == 'Scout')

Wins <- subset(data,data$OUTCOME == 'Victory')

Losses <- subset(data,data$OUTCOME == 'Defeat')

(Wins/Losses) <- "Win/Loss ratio"

summary(Assault)
summary(Medic)
summary(Scout)
summary(Wins)
summary(Losses)

#scatter plots
library(lattice)

xyplot(SCORE ~ DATE, data = Scout,
       xlab = "Date",
       ylab = "Score",
       main = "Scatter Plot of Scout Scores"
)

xyplot(SCORE ~ DATE, data = Assault,
       xlab = "Date",
       ylab = "Score",
       main = "Scatter Plot of Assault Scores"
)

xyplot(SCORE ~ DATE, data = Medic,
       xlab = "Date",
       ylab = "Score",
       main = "Scatter Plot of Medic Scores"
)
#split into training/test data
set.seed(100)
trainingObs<-sample(nrow(data),0.75*nrow(data),replace=FALSE)
trainingDS<-data[trainingObs,]
testDS<-data[-trainingObs,]

# Create a simple decision tree model
treeModel<-rpart(OUTCOME ~ MAP + TYPE + SCORE, method="class", data=trainingDS)

# Do the predictions on the test dataset (output CLASS not PROBABILITIES)
predictions1<-predict(treeModel,testDS,type=c("class"))

# Create a confusion matrix
confMat1<-confusionMatrix(testDS$OUTCOME,predictions1)
print(confMat1$table)

# Association Analysis
library(arules)

# Min the associations
rules <- apriori(data[,2:4],parameter = list(supp = 0.15, conf = 0.3, target = "rules"))

#rules <- subset(rules, subset=lift>2.0)
srules <- subset(rules, subset = rhs %pin% c("OUTCOME=Victory"))

# Look at the rules- 20
inspect(rules)
inspect(srules)


