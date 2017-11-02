# Packages
library(bnlearn)
library(dplyr)
library(broom)
library(MASS)

# Working directory
setwd("")

options(scipen=6)

# Load the data
load("medical_history.Rimg")

data <- as.data.frame(medical_history)

set.seed(1)

# Bayesian Network
struct_hc <- hc(data)
plot(struct_hc)	

# Default model
fit <- bn.fit(struct_hc, data)

# Boostrap
b <- 1000

# Initialize empty data frames
pH_Fy_Cy	<-	rep(-1, b)
pH_Fy_Cn	<-	rep(-1, b)
pH_Fn_Cy	<-	rep(-1, b)
pH_Fn_Cn	<-	rep(-1, b)
pH_Fy	<-	rep(-1, b)
pH_Fn	<-	rep(-1, b)

# Boot
for(i in 1:b) {
  pH_Fy_Cy[i] <- cpquery(fit, (H == "Y"), (F == "Y" & C == "Y"))
  pH_Fy_Cn[i] <- cpquery(fit, (H == "Y"), (F =="Y" & C == "N"))
  pH_Fn_Cy[i] <- cpquery(fit, (H == "Y"), (F == "N" & C == "Y"))
  pH_Fn_Cn[i] <- cpquery(fit, (H == "Y"), (F == "N" & C == "N"))
  pH_Fy[i] <- cpquery(fit, (H == "Y"), (F == "Y"))
  pH_Fn[i] <- cpquery(fit, (H == "Y"), (F == "N"))
}

results <- data.frame(pH_Fy_Cy, pH_Fy_Cn, pH_Fn_Cy, pH_Fn_Cn, pH_Fy, pH_Fn)

summary(results)

alpha	<-	0.05

results %>% summarize(low	=	quantile(pH_Fy_Cy, alpha/2), high = quantile(pH_Fy_Cy, 1-alpha/2))
results %>% summarize(low	=	quantile(pH_Fy_Cn, alpha/2), high = quantile(pH_Fy_Cn, 1-alpha/2))
results %>% summarize(low	=	quantile(pH_Fn_Cy, alpha/2), high = quantile(pH_Fn_Cy, 1-alpha/2))
results %>% summarize(low	=	quantile(pH_Fn_Cn, alpha/2), high = quantile(pH_Fn_Cn, 1-alpha/2))
results %>% summarize(low	=	quantile(pH_Fy, alpha/2), high = quantile(pH_Fy, 1-alpha/2))
results %>% summarize(low	=	quantile(pH_Fn, alpha/2), high = quantile(pH_Fn, 1-alpha/2))
