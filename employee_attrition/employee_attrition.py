#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Apr 16 09:10:48 2018

@author: zansadiq
"""

# Load the required libraries
import random
import os
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.feature_selection import RFE
from sklearn.linear_model import LogisticRegression
from sklearn.cross_validation import train_test_split
from sklearn.metrics import accuracy_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC

# Set seed
random.seed(100)

# Set directory
path = "/Users/zansadiq/Documents/Code/employee_attrition"

os.chdir(path)

# Load the data
data = pd.read_excel("ibm_employee_attrition.xlsx")

# Check for missing values
data.isnull().any()

# All are over 18, so we can drop this column
data = data.drop(['Over18'], axis = 1)

# Fix column types, string factors
for col in ['Attrition', 'BusinessTravel', 'EducationField', 'Department', 'Gender', 'JobRole', 'MaritalStatus', 'OverTime']:
    data[col] = data[col].astype('category')


# Fix column types, numeric factors
for col in ['Education', 'EnvironmentSatisfaction', 'JobInvolvement', 'JobLevel', 'JobSatisfaction', 'PerformanceRating', 'RelationshipSatisfaction', 'StockOptionLevel', 'WorkLifeBalance']:
    data[col] = data[col].astype('category')


dummies = pd.get_dummies(data, columns = ['Attrition', 'BusinessTravel', 'EducationField', 'Department', 'Gender', 'JobRole', 'MaritalStatus', 'OverTime', 'Education', 'EnvironmentSatisfaction', 'JobInvolvement', 'JobLevel', 'JobSatisfaction', 'PerformanceRating', 'RelationshipSatisfaction', 'StockOptionLevel', 'WorkLifeBalance'], 
                               prefix = ['Attrition', 'BusinessTravel', 'EducationField', 'Department', 'Gender', 'JobRole', 'MaritalStatus', 'OverTime', 'Education', 'EnvironmentSatisfaction', 'JobInvolvement', 'JobLevel', 'JobSatisfaction', 'PerformanceRating', 'RelationshipSatisfaction', 'StockOptionLevel', 'WorkLifeBalance'], 
                               drop_first = True)

# Select the dependent variable
y = ['Attrition_Yes']

# List all of the column headers
dat_vars = dummies.columns.values.tolist()

# Select independent variables
x = [i for i in dat_vars if i not in y]

# Fill the values
x = dummies[x]
y = dummies['Attrition_Yes']

# RFE
log_reg = LogisticRegression()

rfe_model = RFE(log_reg, 35)

rfe = rfe_model.fit(dummies[x], dummies[y])

print(rfe.support_)

# Split data for training and testing
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size = 0.3, random_state = 100)

# Logistic Regression
log_reg.fit(x_train, y_train)

# Print results
log_acc = accuracy_score(y_test, log_reg.predict(x_test))

# Random Forest
rf = RandomForestClassifier()

rf.fit(x_train, y_train)

rf_acc = accuracy_score(y_test, rf.predict(x_test))

# SVM
svc = SVC()

svc.fit(x_train, y_train)

svc_acc = accuracy_score(y_test, svc.predict(x_test))