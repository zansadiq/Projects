#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jul 28 18:10:53 2017

@author: zansadiq
"""

"""
    Assignment #3: Market Basket Analysis:
        The purpose of this assignment is to create a recommendation system for a company's customers based upon past purchasing history. 
        The data is broken into a training set of 1,000,000 records and a test set of 100. The output is a text file with 10 lines and no headers. 
        Each line will contain a product recommendation based upon the corresponding purchase history in the test set. 
"""

# Import the required libraries
import requests
import re
import numpy as np
import pandas as pd
import io

"""
    Training data: processing
"""

# Function to grab and process data
def get_data(url):
    r = requests.get(url)
    data = r.text
    data_set = data.splitlines()
    data_set1 = [re.split(r',', line, maxsplit=1) for line in data_set]
    data_array = np.asarray(data_set1)
    data_df = pd.DataFrame(data_array,columns=['transaction_id','product_id'])
    data_df['product_id'] = data_df['product_id'].apply(lambda row: row.split(','))
    data_df.set_index(['transaction_id'],inplace=True)
    return data_df

# Training set
training_df = get_data('http://kevincrook.com/utd/market_basket_training.txt')

# Testing set
testing_df = get_data('http://kevincrook.com/utd/market_basket_test.txt')

# Calculate the frequency for each unique combination of products
product_combos = dict()
for i in training_df['product_id']:
    key = tuple(i)
    if key in product_combos:
        product_combos[key] += 1
    else:
        product_combos[key] = 1

# Convert the product_combos dict to a dataframe
product_combos1 = pd.DataFrame(list(product_combos.items()))

# Rename the columns
product_combos1 = product_combos1.rename(columns={0: "product_id", 1: "count"})

# Store P04 and P08 in a list to be removed 
remove = ['P04','P08']

# Iterate through the dataframe to find P04 or P08 and extract it
for k in range(len(testing_df['product_id'])):
    for r in remove:
        if r in testing_df['product_id'][k]:
            testing_df['product_id'][k].remove(r)

# Convert the lists to tuples
testing_df['product_id'] = testing_df['product_id'].apply(tuple)

"""
    Predictions
"""

# Initialize a dictionary to store the matches
matches = {}

# Return the product combos values that are of the appropriate length and the strings match
for i, entry in enumerate (testing_df.product_id):
   
    # Initialize the recommendations
    recommendation = None
    recommended_count = 0
   
    # Iterate through the product_combos based on frequency
    for k, count in product_combos.items():
        k = list(k)
        # compare the length of test_df to product_combos
        if len(entry)+1 == len(k) and count >= recommended_count:
            for product in entry:
                if product in k: 
                    k.remove(product)
            if len(k) == 1:
                recommendation = k[0]
                recommended_count = count
    # Return a dictionary with the product recommendations as values
    transaction_id = testing_df.index[i]
    matches[transaction_id] = recommendation
        
"""
    Output: txt file containing a single product recommendation for each transaction in the test set
"""

# Create a text file with the recommendations output
"UTF-8 encoding"

with io.open("market_basket_recommendations.txt","w",encoding='utf8') as recommendations:    
    for k,v in matches.items():
        print("{},{}".format(k,v), file=recommendations)
    recommendations.close()
        
    