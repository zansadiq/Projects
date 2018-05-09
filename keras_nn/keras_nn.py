#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May  9 14:48:47 2018

@author: zansadiq
"""

import zxs
import numpy as np
import pandas as pd
from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.wrappers.scikit_learn import KerasClassifier
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline

# Set seed
np.random.seed(100)

# Define workspace
wd = '/Users/zansadiq/Documents/Code/local/keras_nn'
fn = 'numeric_file.csv'

# Import data
data = zxs.local_import(wd, fn)

# Drop index
data.drop(data.columns[0, 1], axis = 1, inplace = True)

data.dtypes

# Convert to numeric
data.loc[:, data.columns!= 'Date'].apply(pd.to_numeric)

# Fill missing Values
data.fillna({'X Coordinate': 0, 'Y Coordinate': 0}, inplace = True)

# Split the data for training/validation/testing
x_train, x_val, x_test, y_train, y_val, y_test = zxs.separate(data, 'Arrest', .3)

# Create a model
def model():
    model = Sequential()
    model.add(Dense(14, input_dim = 14, kernel_initializer = 'normal', activation = 'relu'))
    model.add(Dense(1, kernel_initializer = 'normal', activation = 'sigmoid'))
    model.add(Dropout(.25))	
    
    # Compile model
    model.compile(loss = 'binary_crossentropy', optimizer = 'adam', metrics = ['accuracy'])
    
    return model

# Create a pipeline
estimators = []
estimators.append(('standardize', StandardScaler()))
estimators.append(('mlp', KerasClassifier(build_fn = model, epochs = 100, batch_size = 5, verbose = 1)))
pipeline = Pipeline(estimators)

# Run the model
pipeline.fit(x_train, y_train)

# Evaluate the validation set
score = pipeline.evaluate(x_val, y_val, verbose = 1)

# Predictions
preds = pipeline.predict(np.array(y_test))

# Create ROC
zxs.visualize(y_test, preds)
