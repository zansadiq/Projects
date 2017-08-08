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
    
# Grab the data from the internet
training_url = 'http://kevincrook.com/utd/market_basket_training.txt'

r_training = requests.get(training_url)

# Open the data
training_data = r_training.text
training_set = training_data.splitlines()

# Split the transaction_id from the product_id's
training_set1 = [re.split(r',', line, maxsplit=1) for line in training_set]

# Create an array
train_array = np.asarray(training_set1)

# Use the arrays to create a dataframe
training_df = pd.DataFrame(train_array,columns=['transaction_id','product_id'])

# Split the product_id's for the training data
training_df.set_index(['transaction_id'],inplace=True)

training_df['product_id'] = training_df['product_id'].apply(lambda row: row.split(','))

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
              
"""
    Testing data: processing
"""

# Grab the data from the internet
test_url = 'http://kevincrook.com/utd/market_basket_test.txt'

r_test = requests.get(test_url)
                                                                          
# Open the data
testing_data = r_test.text
testing_set = testing_data.splitlines()

# Split the transaction_id from the product_id's
testing_set1 = [re.split(r',', line, maxsplit=1) for line in testing_set]

# Create an array based on the split value
test_array = np.asarray(testing_set1)

# Use the arrays to create a dataframe
testing_df =pd.DataFrame(test_array,columns=['transaction_id','product_id'])

# Split the product_id's for the testing data
testing_df.set_index(['transaction_id'],inplace=True)

testing_df['product_id'] = testing_df['product_id'].apply(lambda row: row.split(','))

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
        
    