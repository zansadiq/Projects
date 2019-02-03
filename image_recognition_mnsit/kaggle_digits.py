#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Feb  3 08:21:21 2019

@author: zxs
"""

# Import the required libraries
import os
import pandas as pd
from keras.utils.np_utils import to_categorical
from sklearn.model_selection import train_test_split
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten, Conv2D, MaxPool2D
from keras.optimizers import RMSprop
from keras.callbacks import ReduceLROnPlateau
import time

# Set the working directory
wd = 'Users/zxs/Documents/local/personal/code/kaggle_digits/'
os.chdir(wd)

# Create a folder for the data
try:
    data_dir = 'data'
    os.mkdir(data_dir)
    
    # Use the command line w/Kaggle API to download data
    os.system('kaggle competitions download -c digit-recognizer')

except:
    pass

# Read the files
os.chdir(data_dir)

train = pd.read_csv('train.csv')
test = pd.read_csv('test.csv')

# Separate the dependent and independent variables
y = train['label']
x = train.drop('label', axis = 1)

# Normalize the data
x_norm = x / 255

# Reshape the image in 3D based on vector size
x_3d = x_norm.values.reshape(-1, 28, 28, 1)

# One-hot encoding of image labels
y_oh = to_categorical(y)

# Create a validation set for comparing different models
seed = 100

x_train, x_val, y_train, y_val = train_test_split(x_3d, y_oh, test_size = .3, random_state = seed)

'''
    CNN: Convoluted Neural Network
    
    [[Conv2D->relu]*2 -> MaxPool2D -> Dropout]*2 -> Flatten -> Dense -> Dropout -> Out
'''

# Initialize the CNN
cnn = Sequential()

# Add the layers
cnn.add(Conv2D(filters = 32, 
               kernel_size = (5,5),
               padding = 'Same', 
               activation ='relu', 
               input_shape = (28,28,1)))

cnn.add(Conv2D(filters = 32, 
                kernel_size = (5,5),
                padding = 'Same', 
                activation ='relu'))

cnn.add(MaxPool2D(pool_size = (2,2)))

cnn.add(Dropout(0.25))

cnn.add(Conv2D(filters = 64, 
               kernel_size = (3,3),
               padding = 'Same', 
               activation ='relu'))

cnn.add(Conv2D(filters = 64, 
               kernel_size = (3,3),
               padding = 'Same', 
               activation ='relu'))

cnn.add(MaxPool2D(pool_size = (2,2), strides = (2,2)))

cnn.add(Dropout(0.25))

cnn.add(Flatten())
cnn.add(Dense(256, activation = "relu"))
cnn.add(Dropout(0.5))
cnn.add(Dense(10, activation = "softmax"))

# Initialize a function to conduct optimization of the networkj
optimizer = RMSprop(lr = 0.001, rho = 0.9, epsilon = 1e-08, decay = 0.0)

# Compile the layers of the network
cnn.compile(optimizer = optimizer , loss = "categorical_crossentropy", metrics=["accuracy"])

# Define a step value for the learning rate to be used in finding the global minima of loss
learning_rate_reduction = ReduceLROnPlateau(monitor='val_acc', 
                                            patience = 3, 
                                            verbose = 1, 
                                            factor = 0.5, 
                                            min_lr = 0.00001)

%%time

# Run the model
result = cnn.fit(x_train, 
                 y_train, 
                 batch_size = 100, 
                 epochs = 5, 
                 validation_data = (x_val, y_val), 
                 verbose = 2)