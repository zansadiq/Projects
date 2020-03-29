#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Feb 17 15:34:14 2019

@author: zxs
"""

# Import the required libraries
import os
import pandas as pd
import lightgbm as lgb
from sklearn.model_selection import StratifiedKFold
from sklearn import metrics

# Set the working directory
wd = '/Users/zxs/Documents/local/personal/code/santander_customer_transactions/data'
os.chdir(wd)

# Load the data
train = pd.read_csv('train.csv')
test = pd.read_csv('test.csv')

# Separate the independent and dependent variables
x = train.drop(['ID_code', 'target'], axis = 1)
y = train['target']


# Stratified K-Fold Cross Validation
skf = StratifiedKFold(n_splits = 10, shuffle = True, random_state = 100)
predictors = [i for i in x.columns]

param = {'seed': 100,
         'feature_fraction_seed': 100,
         'bagging_seed': 100,
         'drop_seed': 100,
         'data_random_seed': 100,
         'objective': 'binary',
         'boosting_type': 'gbdt',
         'verbose': 1,
         'metric': 'auc',
         'is_unbalance': True,
         'boost_from_average': False,
         'learning_rate': .01,
         'num_leaves': 50,
         'max_depth': 5, # shallower trees reduce overfitting.
         'min_split_gain': 0, # minimal loss gain to perform a split.
         'min_child_samples': 21, # specifies the minimum samples per leaf node.
         'min_child_weight': 5, # minimal sum hessian in one leaf.
    
        'lambda_l1': 0.5, # L1 regularization.
        'lambda_l2': 0.5, # L2 regularization.
    
        # LightGBM can subsample the data for training (improves speed):
        'feature_fraction': 0.5, # randomly select a fraction of the features.
        'bagging_fraction': 0.5, # randomly bag or subsample training data.
        'bagging_freq': 0, # perform bagging every Kth iteration, disabled if 0.
    
        'scale_pos_weight': 99, # add a weight to the positive class examples.
        # this can account for highly skewed data.
    
        'subsample_for_bin': 200000, # sample size to determine histogram bins.
        'max_bin': 1000, # maximum number of bins to bucket feature values in.
    
        'nthread': 4}

# Iterate the K-folds
for train_index, val_index in skf.split(x, y):
    
    # Training model
    xg_train = lgb.Dataset(x.iloc[train_index][predictors].values,
                           label = y[train_index].values,
                           feature_name = predictors,
                           free_raw_data = False)
    
    # Validation model
    xg_val = lgb.Dataset(x.iloc[val_index][predictors].values,
                         label = y[val_index].values,
                         feature_name = predictors,
                         free_raw_data = False)

    # Fit
    clf = lgb.train(param, xg_train, valid_sets = [xg_val])    

    # Predict
    preds = clf.predict(x.iloc[val_index][predictors].values, num_iteration = clf.best_iteration) 
    
    # Score
    auc = metrics.roc_auc_score(y.iloc[val_index].values, preds)

    print('The AUC for this iteration is: ', auc)
    
# Output predictions
out = pd.DataFrame(test['ID_code'], columns = ['ID_code'])
out['target'] = clf.predict(test[predictors].values, num_iteration = clf.best_iteration) 

# Write file
out.to_csv('zxs_santander_preds.csv', index = False)
    