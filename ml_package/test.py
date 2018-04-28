#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Apr 28 09:04:58 2018

@author: zansadiq
"""

# Import the required libraries
import csv
import os
import random
import numpy as np
import pandas as pd
from sklearn.preprocessing import LabelEncoder

# Import custom module
import ml

# Set seed
random.seed(100)

# Create an empty list to store the data
data = list()

# Load the data from a local file using the csv module
with open('data.csv') as dat:
    csvReader = csv.reader(dat)
    for row in csvReader:
        data.append(row)

# Convert to Pandas
data = pd.DataFrame(data)

# Fix the headers
data.columns = data.iloc[0]

# Delete the row
data = data.reindex(data.index.drop(0))

# Convert target variable to factor
data['Won?'] = data['Won?'].astype('category')

# Fix the ratings
data.loc[data["Rate"] == "G", "Rate"] = 1
data.loc[data["Rate"] == "PG", "Rate"] = 2
data.loc[data["Rate"] == "PG-13", "Rate"] = 3
data.loc[data["Rate"] == "R", "Rate"] = 4

# Handle missing values
data.isnull().sum()

data = data.drop(columns = ['Opening Weekend'])

# Fix the genres
lb = LabelEncoder()

data['Genres'] = lb.fit_transform(data['Genres'])

# Fix the movie titles
data['Movie'] = lb.fit_transform(data['Movie'])

# Remove the IMDB id
data = data.drop(columns = 'IMdB id')

# Convert remaining object variables
cols = data.columns[data.dtypes.eq('object')]

data[cols] = data[cols].apply(pd.to_numeric)

# Split into training, validation, and testing- using ml
x_train, x_val, x_test, y_train, y_val, y_test = ml.separate(data, 'Won?', .3)

# Fill blank cells with 0's
x_train.fillna(0, inplace = True)
x_val.fillna(0, inplace = True)
x_test.fillna(0, inplace = True)

# Call ml function
preds, conf_mat, class_rep, acc = ml.machine_learning('from sklearn.tree import DecisionTreeClassifier', x_train, y_train, x_val, y_val, 'DecisionTreeClassifier()')

# Fix the output
codes = {'0': 0, '1': 1}
y_val = y_val.map(codes).astype('category', ordered = False, categories = [0, 1]).astype(int)
preds = pd.Series(preds)
preds = preds.map(codes).astype('category', ordered = False, categories = [0, 1]).astype(int)

# Call visualization function
out = ml.visualize(y_val, preds)