#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun 13 10:02:47 2017

@author: zan
"""

import csv

with open('battlefielddata.csv', newline='', encoding='utf-8') as file:
    cin = csv.reader(file)
    data = [row for row in cin]
        
print(data)

import pandas as pd

# Read the excel sheet to pandas dataframe
DataFrame = pd.read_csv("battlefielddata.csv")

print(DataFrame.columns)

maps=DataFrame['MAP']

outcomes=DataFrame['OUTCOME']

scores=DataFrame['SCORE ']

classes=DataFrame['TYPE']