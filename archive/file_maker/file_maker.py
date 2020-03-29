#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun May  6 15:16:37 2018

@author: zansadiq
"""

import sys
import os
import zxs
import json
import pandas as pd

# System defined arguments

# Working directory
wd = str(sys.argv[1])

os.chdir(wd)

# In-file
fn = str(sys.argv[2])

# System arguments
kwargs = json.loads(sys.argv[3])

# Data Processing

# Load and parse the in-file
data = zxs.local_import(wd, fn)

# Transform to numeric
dat = zxs.transform(data, **kwargs)

# Out-file
dat.to_csv('numeric_file.csv')