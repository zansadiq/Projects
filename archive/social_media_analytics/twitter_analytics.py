#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  4 18:39:37 2017

@author: zansadiq
"""

# Import the required libraries
import io
import urllib.request
import json 
import pandas as pd

# Grab the data from internet
with urllib.request.urlopen('http://kevincrook.com/utd/tweets.json') as url:
    data = json.loads(url.read().decode())

# Convert the data into a pandas data frame
df = pd.DataFrame(data)

# Select the pertinent information
df1 = df[['text','lang']]

# Drop the rows that have missing tweets
tweets = df1.dropna()

# Calculate the frequency of each language
lang_freq = tweets.groupby('lang').count()

# Rename the column
lang_freq.columns = ['frequency']

# Sort the frequencies
lang_sorted = lang_freq.sort_values(by='frequency', ascending = False)

# Print the individual tweets
tweets1 = tweets['text'].str.replace('\n', '')

"""
    Analytics file:
        # of events
        # of tweets
        # frequency of tweets for each language (sorted by highest first)
"""
        
# Create the twitter analytics text file
with io.open("twitter_analytics.txt","w",encoding='utf8') as twitter_analytics:    
    # Number of events
    print(len(data), file = twitter_analytics)
    # Number of tweets
    print(len(tweets), file = twitter_analytics)
    # Frequency of tweets by language
    print(lang_sorted.to_csv(header = False), file = twitter_analytics)
    twitter_analytics.close()

"""
    Tweets file:
        1 tweet text per line
"""

# Create the tweets file
with io.open("tweets.txt","w", encoding = 'utf-8') as twitter_feed:    
    print('\n'.join(tweets1), file = twitter_feed)
    twitter_feed.close


