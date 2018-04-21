#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Apr 20 16:11:17 2018

@author: zansadiq
"""

# Load the required libraries
import os
import pandas as pd
from sklearn.cross_validation import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.metrics import roc_curve, auc
import matplotlib.pyplot as plt
import numpy as np

# Set the working directory
os.chdir('/Users/zansadiq/Documents/Work/takehome')

# Open the files
training = pd.read_csv('training.tsv', sep = '\t', header = None, names = ('user_id', 'activity_date', 'activity_type'))

testing = pd.read_csv('test.tsv', sep = '\t', header = None, names = ('user_id', 'activity_date', 'activity_type'))

# Fix the dates
training['activity_date'] = pd.to_datetime(training['activity_date'])

testing['activity_date'] = pd.to_datetime(testing['activity_date'])

# Convert activities to factor 
training['activity_type'] = training['activity_type'].astype('category')
testing['activity_type'] = testing['activity_type'].astype('category')

# Create dummy variables for activity types
dummies = pd.get_dummies(training, columns = ['activity_type'], drop_first = True)
test_dummies = pd.get_dummies(testing, columns = ['activity_type'], drop_first = True)

# Fill missing columns in test data
test_dummies = test_dummies.assign(activity_type_EmailClickThrough = 0, activity_type_Purchase = 0)

# List all of the column headers
dat_vars = dummies.columns.values.tolist()
test_vars = test_dummies.columns.values.tolist() 

# Select the dependent variable
y = ['activity_type_Purchase']

# Select independent variables
x = [i for i in dat_vars if i not in ['user_id', 'activity_type_Purchase', 'activity_date']]
x_test = [i for i in test_vars if i not in ['user_id', 'activity_type_Purchase', 'activity_date']]

# Fill the values
x = dummies[x]
y = dummies['activity_type_Purchase']

x_test = test_dummies[x_test]
y_test = test_dummies['activity_type_Purchase']

# Split the training data for training and validation
x_train, x_val, y_train, y_val = train_test_split(x, y, test_size = 0.3, random_state = 100)

# Logistic Regression
log_reg = LogisticRegression()

log_reg.fit(x_train, y_train)

# Predictions
train_preds = log_reg.predict(x_train)
val_preds = log_reg.predict(x_val)
test_preds = log_reg.predict(x_test)

# Print results
print(accuracy_score(y_val, log_reg.predict(x_val)))

# Examine the probabilities
train_probs = log_reg.predict_proba(x_train)
val_probs = log_reg.predict_proba(x_val)
test_probs = log_reg.predict_proba(x_test)
 
# ROC Curve
fpr, tpr, _ = roc_curve(y_train, train_preds)
roc_auc= auc(fpr, tpr)

# Plot ROC
plt.figure()
plt.plot(fpr, tpr, color = 'darkorange', label = 'ROC Curve (area = %0.2f)' % roc_auc)
plt.plot([0, 1], [0, 1], color='navy', linestyle = '--')
plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('Receiver operating characteristic example')
plt.legend(loc="lower right")
plt.show()

# Combine probabilities with test set
test_dummies['activity_type_Purchase'] = test_preds
test_dummies['prob_no_purchase'] = test_probs[:,0]
test_dummies['prob_purchase'] = test_probs[:,1]

# Sort probabilities and select top 1000
sort = test_dummies.sort_values(['prob_purchase'], ascending = [False])

out = sort.head(n = 1000)

# Variable importance
coefs = log_reg.coef_[0]

top_three = np.argpartition(coefs, -4)[-4:]

print(test_dummies.columns[top_three])

