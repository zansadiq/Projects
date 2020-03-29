#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Apr 26 14:03:12 2018

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
from sklearn.preprocessing import LabelEncoder

# Set seed
random.seed(100)

# Load the data
data = pd.read_excel("ibm_employee_attrition.xlsx")

data = data.drop(columns = 'Over18', axis = 1)

# One-hot encoding dummy variables
dummies = pd.get_dummies(data, columns = ['Attrition', 'BusinessTravel', 'EducationField', 'Department', 'Gender', 'JobRole', 'MaritalStatus', 'OverTime', 'Education', 'EnvironmentSatisfaction', 'JobInvolvement', 'JobLevel', 'JobSatisfaction', 'PerformanceRating', 'RelationshipSatisfaction', 'StockOptionLevel', 'WorkLifeBalance'], 
                               prefix = ['Attrition', 'BusinessTravel', 'EducationField', 'Department', 'Gender', 'JobRole', 'MaritalStatus', 'OverTime', 'Education', 'EnvironmentSatisfaction', 'JobInvolvement', 'JobLevel', 'JobSatisfaction', 'PerformanceRating', 'RelationshipSatisfaction', 'StockOptionLevel', 'WorkLifeBalance'], 
                               drop_first = True)

# List all of the column headers
dat_vars = dummies.columns.values.tolist()

# Select independent variables
x = [i for i in dat_vars if i not in ['Attrition_Yes']]

# Fill the values
x = dummies[x]
y = dummies['Attrition_Yes']

# Convert everything to numbers
x = x.apply(pd.to_numeric)
y = y.apply(pd.to_numeric)

# Create a model for running the RFE
log_mod = LogisticRegression()

# Run the feature selection
rfe = RFE(log_mod, 34)
rfe = rfe.fit(x, y)

# Columns to convert
strings = data.select_dtypes(include = 'object')

# Initialize the encoder
le = LabelEncoder()

# Encode the factors
for i in strings:
    data[i] = le.fit_transform(data[i])
    
# Redefine the x and y variables
variables = data.columns.values.tolist()

# Independent variables
x = [i for i in variables if i not in ['Attrition']]

# Fill the values
x = data[x]
y = data['Attrition']

# Split the data
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size = 0.3)
x_val, x_test, y_val, y_test = train_test_split(x_test, y_test, test_size=0.5)