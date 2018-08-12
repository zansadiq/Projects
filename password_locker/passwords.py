#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug 10 08:54:51 2018

@author: zxs107020
"""

# Import the required libraries
import datetime as dt
import os
import random
import dropbox as db

# Get information on current date/time
now = dt.datetime.now()
now = now.strftime('%Y/%m/%d')

# Define Variables
wd = input('Enter the Path of the Working Directory:')
key = input('Enter Your Storage Key:')
site = input('Enter Site Name:')
username = input('Enter Site Username:')
length = input('Enter Password Length:')
access_token = input('Enter Your Dropbox Access Token:')

# Set the working directory where the password file will be stored
os.chdir(wd)

# Define input characters
chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*'
    
# Initialize password
pswd = ''
    
pswd = random.choice(chars)
    
# Generate
for c in range(int(length)):
    pswd += random.choice(chars)

# Print for confirmation
print ('Your New Password is: ', pswd, '\n')
    
# Create CSV file, or update is already exists

# Check to see if file exists
check_file = os.path.isfile('pswds.csv')

# Create csv if not exists
header = ['Date', 'Site', 'Username', 'Password']
dat = [now, site, username, pswd]

# Write or append file based on existence
if not check_file:
    with open('pswds.csv', 'wt') as f:
        print(header, file = f)
        print(','.join(dat), file = f)
else:
    with open('pswds.csv', 'a') as f:
        print(','.join(dat), file = f)

# Interface with dropbox 
dbx = db.Dropbox(access_token)
print('Linked User is: ', dbx.users_get_current_account(), '\n')

# Upload the password file
with open('pswds.csv', 'rb') as f:
    dbx.files_upload(f.read(), '/pswds.csv', mode = db.files.WriteMode.overwrite)

print('Password file updated...program complete', '\n')