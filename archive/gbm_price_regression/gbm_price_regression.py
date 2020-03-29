#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Aug 12 12:24:21 2018

@author: zxs107020
"""

# Import the required libraries
import os
import zipfile
import pandas as pd
import numpy as np
from sklearn import model_selection
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.preprocessing import LabelBinarizer
from scipy.sparse import csr_matrix, hstack
import lightgbm as lgb
from sklearn.metrics import mean_squared_error
import matplotlib.pyplot as plt

# Set the URL for data and local destination
wd = '/Users/zansadiq/Documents/Code/local/Misc'
fn = 'mercari.zip'

# Change the working directory
os.chdir(wd)

# Access the Data and Unzip
with zipfile.ZipFile(fn, 'r') as zf:
    zf.extractall()

# Load the training set
training = pd.read_csv('train.tsv', sep = '\t')

# Load the testing set
testing = pd.read_csv('test.tsv', sep = '\t')

# List all of the column headers
train_vars = training.columns.values.tolist()
test_vars = testing.columns.values.tolist()

# Check for missing values
training.isnull().sum()
testing.isnull().sum()

# Handle nulls
training['category_name'].fillna(value = 'missing', inplace = True)
training['brand_name'].fillna(value = 'missing', inplace = True)
training['item_description'].fillna(value = 'missing', inplace = True)

testing['category_name'].fillna(value = 'missing', inplace = True)
testing['brand_name'].fillna(value = 'missing', inplace = True)
testing['item_description'].fillna(value = 'missing', inplace = True)

# Transform categorical variables
def to_cat(data, col):
    data[col] = data[col].astype('category')
    return data

cols = ['category_name', 'brand_name', 'item_condition_id']

for i in cols:
    to_cat(training, i)
    to_cat(testing, i)

# Drop 0 prices
training = training[training.price != 0].reset_index(drop = True)  

# Separate dependent variables
y_training = training['price']

training = training.drop('price', axis = 1)

# Split the training data for validation
train_x, val_x, train_y, val_y = model_selection.train_test_split(training, y_training, test_size = .3, random_state = 100)

# General settings
num_hotel = 879
num_cat = 1000
name_min_df = 10
max_ft = 50000

# Vectorize the products and categories
cv = CountVectorizer(min_df = name_min_df)

x_train_name = cv.fit_transform(train_x['name'])
x_test_name = cv.fit_transform(val_x['name'])

cv = CountVectorizer()

x_train_cat = cv.fit_transform(train_x['category_name'])
x_test_cat = cv.fit_transform(val_x['category_name'])

# TF-IDF
tv = TfidfVectorizer(max_features = max_ft, ngram_range = (1, 3), stop_words = 'english')

x_train_desc = tv.fit_transform(train_x['item_description'])
x_test_desc = tv.fit_transform(val_x['item_description'])

# Binarize labels
lb = LabelBinarizer(sparse_output = True)

x_train_brand = lb.fit_transform(train_x['brand_name'])
x_test_brand = lb.fit_transform(val_x['brand_name'])

# Dummy variables for item_condition_id and shipping
x_training_dummies = csr_matrix(pd.get_dummies(train_x[['item_condition_id', 'shipping']], sparse = True).values)
x_testing_dummies = csr_matrix(pd.get_dummies(val_x[['item_condition_id', 'shipping']], sparse = True).values)

# Merge
training_merged = hstack((x_training_dummies, x_train_desc, x_train_brand, x_train_cat, x_train_name)).tocsr()
testing_merged = hstack((x_testing_dummies, x_test_desc, x_test_brand, x_test_cat, x_test_name)).tocsr()

# Remove doc frequencies < 1
mask = np.array(np.clip(training_merged.getnnz(axis = 0) - 1, 0, 1), dtype = bool)
test_mask = np.array(np.clip(testing_merged.getnnz(axis = 0) - 1, 0, 1), dtype = bool)

training_merged = training_merged[:, mask]
testing_merged = testing_merged[:, test_mask]

# GBM
train_x = lgb.Dataset(training_merged, label = train_y)

# Parameters (these can be fine-tuned)
params = {'learning_rate': .75, 'application': 'regression', 'max_depth': 3, 'num_leaves': 100, 'verbosity': -1, 'metric': 'RMSE'}

# Train model
gbm = lgb.train(params, train_set = train_x, num_boost_round = 3200, verbose_eval = 100)

# Predictions
test_preds = gbm.predict(testing_merged, num_iteration = gbm.best_iteration)

# Evaluate 
print('The RMSE of the GBM Predictions is: ', mean_squared_error(val_y, test_preds))

# Visualize training data
plt.subplot(1, 2, 1)
(train_y).plot.hist(bins = 50, figsize = (12, 6), edgecolor = 'white', range = [0, 250])
plt.xlabel('price', fontsize = 12)
plt.title('Price Distribution', fontsize = 12)

# Compare training distribution to test results
fig, ax = plt.subplots(figsize = (18, 8))

ax.hist(train_y, color = '#8CB4E1', bins = 50, range = [0, 100], label = 'Training Prices')
ax.hist(val_y, color = '#007D00', bins = 50, range = [0, 100], label = 'Test Predictions')
        
plt.xlabel('price', fontsize = 12)
plt.ylabel('frequency', fontsize = 12)

plt.title('Price Distribution: Training Data and Test Predictions', fontsize = 15)

plt.tick_params(labelsize = 12)

plt.legend()

plt.show()