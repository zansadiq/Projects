#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 22 07:44:08 2018

@author: zxs107020
"""

# Import the required libraries
import os
import pandas as pd
import dash
import dash_html_components as html
from dash.dependencies import Input, Output
import dash_core_components as dcc
import plotly.graph_objs as go

##############################################################################
######################### Collect user-inputs ################################
##############################################################################

wd = input('Enter the path of the desired working directory: ')
fn = input('Enter the name of the input data file: ')

# Change the settings
os.chdir(wd)

# Load the data
data = pd.read_csv(fn)

##############################################################################
############################ Pre-Processing ##################################
##############################################################################

# Fix the casing
data.columns = map(str.lower, data.columns)
data.columns = data.columns.str.replace(" ", "_")

# Convert the date
data['date'] = pd.to_datetime(data['date'])
data['date'].apply(lambda x: x.strftime('%m/%d/%Y'))

# Filter out currencies with less than two data points
data = data.groupby('currency').filter(lambda x: len(x) > 3)

##############################################################################
############################# Interface ######################################
##############################################################################

# Function to select results of user input
def load_table(value):
    df = data[data['currency'] == value]
    
    return df

# Function to obtain results of user input
def gen_tab(df, max_rows = 10):
    return html.Table([html.Tr([html.Th(col) for col in df.columns])] +
                      [html.Tr([html.Td(df.iloc[i][col]) for col in df.columns]) for i in range(min(len(df), max_rows))])

# Function to draw graph
def draw_graph(df):
    x = df['date']
    y = df['close']

    fig = go.Figure(data = [go.Scatter(x = x, y = y, mode = 'lines+markers')],
                    layout = go.Layout(title = 'Price over Time for Selected Currency',
                                       showlegend = False))

    return fig
    
# Initialize Dashboard
app = dash.Dash()

# Format the layout
app.layout = html.Div([
        # Page header
        html.Div([html.H1('Cryptocurrency Price Viewer:')]),
        
        # Dropdown menu
        dcc.Dropdown(id = 'dropdown',
                     options = [{'label': i, 'value': i} for i in data['currency'].unique()],
                     value = 'a'),
        
        # Results table
        html.Div(id = 'match-results'),

        # Price graph
        html.Div([dcc.Graph(id = 'graph')]),
        
        # User input
        html.Div(id = 'user-input', style = {'display': 'none'})])

# Callback to store user value    
@app.callback(
        Output(component_id = 'match-results', component_property = 'children'),
        [Input(component_id = 'dropdown', component_property = 'value')])

# Function to populate table based on user value
def disp_tab(value):
    dff = load_table(value)
    
    return gen_tab(dff)

# Callback to draw graph
@app.callback(
        Output(component_id = 'graph', component_property = 'figure'),
        [Input(component_id = 'dropdown', component_property = 'value')]
        )

# Function to populate graph based on user value
def disp_graph(value):
    dff = load_table(value)
    
    fig = []
    
    if len(dff) > 0:
        fig = draw_graph(dff)
        
    return fig

##############################################################################
################################ Run #########################################
##############################################################################

# Start the instance
if __name__ == '__main__':
    app.run_server(
        debug = False,
        host = '0.0.0.0',
        port = 8050)   