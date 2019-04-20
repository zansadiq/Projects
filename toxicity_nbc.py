#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr 17 15:50:12 2019

@author: zxs
"""

# Import the required libraries
import os
import numpy as np
import pandas as pd
import string
import nltk
from nltk.corpus import stopwords
from nltk.stem import PorterStemmer
from nltk.tokenize import word_tokenize
import pickle
import operator
from tqdm import tqdm
import gc
tqdm.pandas()
from sklearn.model_selection import train_test_split
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, Activation
from keras.preprocessing.sequence import pad_sequences
import matplotlib.pyplot as plt
from gensim.models import KeyedVectors
import nltk.classify.util
from nltk.classify import NaiveBayesClassifier

# Set the working directory
wd = '/Users/zxs/Documents/code/kaggle/sentiment/'
os.chdir(wd)

# Load the data
train_df = pd.read_csv('train.csv.zip', compression = 'zip')
test_df = pd.read_csv('test.csv.zip', compression = 'zip')

# Load the pickled data
with open('sentiment.pickle', mode = 'rb') as f:

    train_text = pickle.load(f)

f.close() 

with open('train_words.pickle', mode = 'rb') as f:

    train_words = pickle.load(f)

f.close() 

# Rejoin the data
train_df['processed_text'] = train_words

# Split the data based on toxicity
train_df['toxicity'] = train_df['target'].progress_apply(lambda x: 'positive' if x >= .5 else 'negative')

# Arrange list of words and labels
train_df['processed_text'] = train_df['processed_text'].progress_apply(lambda x: ' '.join(x))

# Separate
text = train_df[['processed_text', 'toxicity']].values.tolist()

# Function to process features
def word_fts(words):
    
    return dict([(word, True) for word in words])

# Split the data for training and testing
train, test = train_test_split(text, test_size = .2, random_state = 100)    

# Iterate the tokenized data to extract features
toxic_train = []
nontoxic_train = []

for i in train:
    
    if i[1] == 'positive':
        
        toxic_train.append(word for word in word_tokenize(i[0]))

    else:
        
        nontoxic_train.append(word for word in word_tokenize(i[0]))

toxic_val = []
nontoxic_val = []

for i in test:
    
    if i[1] == 'positive':
        
        toxic_val.append(word for word in word_tokenize(i[0]))

    else:
        
        nontoxic_val.append(word for word in word_tokenize(i[0]))
        
# Remove duplicates        
toxic_train = set(toxic_train)
nontoxic_train = set(nontoxic_train)

toxic_val = set(toxic_val)
nontoxic_val = set(nontoxic_val)

# ID features
toxicft = [(word_fts(tox), 'positive') for tox in toxic_train]
nontoxicft = [(word_fts(nontox), 'negative') for nontox in nontoxic_train]

valtoxicft = [(word_fts(tox), 'positive') for tox in toxic_val]
valnontoxicft = [(word_fts(nontox), 'negative') for nontox in nontoxic_val]

# Recombine features
train = toxicft + nontoxicft
val = valtoxicft + valnontoxicft

# Model
nbc = NaiveBayesClassifier.train(train)

# Evaluate
print ('Accuracy:', nltk.classify.util.accuracy(nbc, val))
nbc.show_most_informative_features()

