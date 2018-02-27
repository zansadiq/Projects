#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug 26 13:54:30 2017

@author: 
"""

import json
import urllib.request
import pandas as pd
from threading import Timer

def refresh_btc():
    # Coindesk API
    with urllib.request.urlopen('https://api.coindesk.com/v1/bpi/currentprice.json') as url:
        data = json.loads(url.read().decode())

    # Convert data to Pandas
    df = pd.DataFrame(data)

    btc = df[['bpi','time']]

    x = btc.loc['USD', 'bpi']['rate']
    y = btc.loc['updated', 'time']

    pricing = pd.DataFrame({'btc_price_usd': [x], 'time' : [y]}) 

    pricing['time'] = pd.to_datetime(pricing['time'])

    pricing.set_index(['time'],inplace=True)

    with open('btc_price_data.csv', 'a') as f:
        pricing.to_csv(f, header = False)
   
    # Set the timer    
    t = Timer(60, refresh_btc)
    t.daemon = True
    t.start()

# Call the function
refresh_btc()

def refresh_eth():
    with urllib.request.urlopen('https://api.coinmarketcap.com/v1/ticker/') as url:
        eth_data = json.loads(url.read().decode())

    # Convert data to Pandas
    eth_df = pd.DataFrame(eth_data)

    a = eth_df.loc[1,'last_updated']
    b = eth_df.loc[1,'price_usd']

    eth_pricing = pd.DataFrame({'eth_price_usd': [b], 'time' : [a]}) 

    eth_pricing['time'] = pd.to_datetime(eth_pricing['time'], unit = 's')

    eth_pricing.set_index(['time'],inplace = True)

    with open('eth_price_data.csv', 'a') as f:
        eth_pricing.to_csv(f, header = False)
    
    # Set the timer    
    t1 = Timer(60, refresh_eth)
    t1.daemon = True
    t1.start()

# Call the function
refresh_eth()

# Create the block_dat csv
csv_header = '''time,block_size,difficulty,estimated_btc_sent,estimated_transaction_volume_usd,hash_rate,
                market_price_usd,miners_revenue_btc,miners_revenue_usd,minutes_between_blocks,n_blocks_mined,n_blocks_total,
                n_btc_mined,n_tx,nextretarget,total_btc_sent,total_fees_btc,totalbtc,trade_volume_btc,trade_volume_usd'''

file_name = 'block_data.csv'

with open(file_name, 'a') as f:
    print(csv_header, file = f)
    
def get_btc_dat():
    # Block Chain data
    with urllib.request.urlopen('https://api.blockchain.info/stats') as url:
        block_data = json.loads(url.read().decode())
        
    # Convert to Pandas
    block_df = pd.DataFrame([block_data]).set_index('timestamp')
    
    # Fix timestamp
    block_df.index = pd.to_datetime(block_df.index, unit = 'ms')
    
    with open('block_data.csv', 'a') as f:
        block_df.to_csv(f, header=False)
    
    # Set the timer
    t2 = Timer(60, get_btc_dat)
    t2.daemon = True
    t2.start()
    
get_btc_dat()

# Bitcoin charts api
with urllib.request.urlopen('http://api.bitcoincharts.com/v1/markets.json') as url:
    bitcoin_charts = json.loads(url.read().decode())
    
    crypto_info = pd.DataFrame(bitcoin_charts)


    
    
