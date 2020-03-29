#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar 23 11:18:46 2018

@author: zxs107020
"""

import random
import pandas as pd
import numpy as np
import fbprophet
import matplotlib.pyplot as plt
import math

# Set seed
random.seed(100)

# Load the data
data = pd.read_csv("consolidated_coin_data.csv")

# Fix the casing
data.columns = map(str.lower, data.columns)
data.columns = data.columns.str.replace(" ", "_")

# Remove missing values
data2 = data[data.volume != "-"]
data2 = data2[data2.market_cap != "-"]

# Remove commas
data2['volume'] = pd.to_numeric(data2['volume'].str.replace(',', ''))
data2['market_cap'] = pd.to_numeric(data2['market_cap'].str.replace(',', ''))

# Convert the date
data2['date'] = pd.to_datetime(data2['date'])
data2['date'].apply(lambda x: x.strftime('%m/%d/%Y'))

# Filter out currencies with less than two data points
data2 = data2.groupby('currency').filter(lambda x: len(x) > 3)

# List unique currency values
currencies = set(data2['currency'])
currencies = list(currencies)

# Dictionary to store all outputs
preds_dict = {}

# Build a function to predict the price of a given currency
def currency_pred(currency, scale):
    
    # Select the data
    info = data2.loc[data2['currency'] == currency]
    
    # Fix the date and target
    info = info.rename(columns = {'date': 'ds', 'close': 'y'})
    
    # Model
    fit = fbprophet.Prophet(changepoint_prior_scale = scale)
    fit.fit(info)
    
    # Empty df to store results
    preds = fit.make_future_dataframe(periods = 31, freq = 'D')
    
    # Predict
    preds = fit.predict(preds)
    
    # Label the predictions
    preds['currency'] = currency

    # Plot
    img = fit.plot(preds, xlabel = 'Date', ylabel = 'Closing Price')
    plt.title('Predicted Closing Prices:{0}'.format(currency));
    
    # Store all outputs in dict
    preds_dict[currency] = {}
    preds_dict[currency]['preds'] = preds
    preds_dict[currency]['img'] = img
    
    return preds, img

# List for results
results = []
imgs = []

# Iterate through currencies and build predictions
for x in currencies:
        out = currency_pred(x, .15)
        results.append(out[0])
        imgs.append(out[1])

# Flatten the results
results1 = pd.concat(results)

# Reset index values
data2.set_index('date', inplace = True)
results1.set_index('ds', inplace = True)

# Create investment portfolio
investments = data2.loc['2017-12-27', ['currency', 'close']]
investments.rename(columns = {'close': 'start_price'}, inplace = True)

# Extract date and max value during investment period 
max_values = results1.groupby(['currency'])['yhat'].transform(max) == results1['yhat']
exit_points = results1[max_values]
exit_points.rename(columns = {'yhat': 'exit_price'}, inplace = True)

# Merge
investments['start_date'] = investments.index
exit_points['exit_date'] = exit_points.index
investments1 = pd.merge(investments, exit_points[['currency', 'exit_date', 'exit_price']], on = ['currency'])

# Calculate change in $
investments1['price_change'] = investments1['exit_price'] - investments1['start_price']

# Calculate the % change
investments1['pct_change'] = investments1['exit_price'] / investments1['start_price']

# Compile a list of top performing currencies
top_dollar = investments1.sort_values('price_change', ascending = False).head(5)

top_pct = investments1.sort_values('pct_change', ascending = False).head(5)

# Calculate predicted ROI
roi = {}

for index, row in top_dollar.iterrows():
    currency = row['currency']
    num_shares = math.floor(1000000 / row['start_price'])
    profit = num_shares * row['price_change']
    
    roi[currency] = {}
    roi[currency]['num_shares'] = num_shares
    roi[currency]['profit'] = profit

for index, row in top_pct.iterrows():
    currency = row['currency']
    num_shares = math.floor(1000000 / row['start_price'])
    profit = num_shares * row['price_change'] 
    
    roi[currency] = {}
    roi[currency]['num_shares'] = num_shares
    roi[currency]['profit'] = profit

# Return top 3 investments
recommendations = dict(sorted(roi.items(), key = lambda x: x[1]['profit'], reverse = True)[:5])

# Access the graphs for top 3
tron = preds_dict['tron']['img']
decentraland = preds_dict['decentraland']['img']
time_new_bank = preds_dict['time-new-bank']['img']



