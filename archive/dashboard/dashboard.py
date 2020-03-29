#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug 17 14:03:28 2018

@author: zxs107020
"""

# Import the required libraries
import os
import csv
import dash
from dash.dependencies import Input, Output
import dash_core_components as dcc
import dash_html_components as html
import plotly.figure_factory as ff
import plotly.graph_objs as go
import pandas as pd
import folium

# User-defined settings
wd = input('Enter the path for the working directory: ')

# Settings
os.chdir(wd)

##############################################################################
# Fetch the data / Model
##############################################################################
 
# Initialize a list to store the data
data = list() 
    
# Load the data
with open('chicago_crime.csv') as dat:
    csvReader = csv.reader(dat)
    for row in csvReader:
        data.append(row)
    
# Convert to Pandas
data = pd.DataFrame(data)

# Fix the headers
data.columns = data.iloc[0]
    
# Delete the initial header row
data = data.reindex(data.index.drop(0))

# Fix the casing and remove spaces
data.columns = [x.lower() for x in data.columns]

# Remove spaces
data.columns = [x.strip().replace(' ', '_') for x in data.columns]

# Parse the dates
data = data.drop(columns = 'year')
data['year'] = pd.DatetimeIndex(data['date']).year
data['month'] = pd.DatetimeIndex(data['date']).month

# Query for returning years
def get_years():
    years = sorted(data['year'].unique())
    
    return years

# Query for returning months
def get_months(year):
    months = data[(data.year == year)][['month']]
    
    return months

# Query to get crimes
def get_crimes(year, month):
    crimes = list(data['fbi_code'].unique.sort_values())
    
    return crimes

# Return compiled results
def get_match_results(year, month, crime):
    matches = data[(data.year == year) & (data.month == month) & (data.fbi_code == crime)][['id', 'case_number', 'date', 'arrest', 'latitude', 'longitude', 'fbi_code']]
    
    return matches

# Summarize the query
def comp_summ(df):
    crimes = df.groupby(by = ['arrest'])['fbi_code'].count()
    
    summ = pd.DataFrame(dat = {'Crimes': crimes['Yes'] + crimes['No'],
                               'Arrests': crimes['Yes']},
                               columns = ['Crimes', 'Arrests'],
                               index = df['fbi_code'].unique())
    return summ

# Mark the coordinates for the city
chi = [41.88, -87.62]

# Plot crimes
def plot_graphics(coords_ls, df):
    # Convert locations
    cols = ['latitude', 'longitude']
    
    df[cols] = data[cols].apply(pd.to_numeric, errors = 'coerce', axis = 1)
    
    # Drop missing values
    df = df.dropna(how = 'any', axis = 0)
    
    # Initialize map
    map_cc = folium.Map(location = coords_ls, zoom_start = 12)
    
    # Iterate through df
    for each in df.iterrows():
        map_cc.Marker([each[1]['longitude'], each[1]['latitude']], popup = 'Incident Location').add_to(map_cc)
    
    # Show results
    return(map_cc)
    
##############################################################################
# Dashboard layout / View
##############################################################################

# Setup dashboard and create layout
app = dash.Dash()

app.css.append_css({'external_url': ''})

app.layout = html.Div([
        
        # Page header
        html.Div([html.H1('Project Header')]), 
])
    
def generate_table(df, max_rows = 10):
    
    # Given dataframe, return template

    return html.Table(
        
        # Header
        [html.Tr([html.Th(col) for col in df.columns])] +

        # Body
        [html.Tr([html.Td(
                df.iloc[i][col]) for col in df.columns]) for i in range(min(len(df), max_rows))]
    )

def onLoad_division_options():
    
    # Initial actions
    year_options = ([{'label': year, 'value': year} for year in get_years()])
    
    return year_options

# Set up Dashboard and create layout
app = dash.Dash()
app.css.append_css({
    "external_url": "https://codepen.io/chriddyp/pen/bWLwgP.css"
})

app.layout = html.Div([

    # Page Header
    html.Div([
        html.H1('Chicago Crime Viewer')
    ]),

    # Dropdown Grid
    html.Div([
        html.Div([
            # Select Division Dropdown
            html.Div([
                html.Div('Select Year', className = 'three columns'),
                html.Div(dcc.Dropdown(id = 'year-selector',
                                      options = onLoad_division_options()),
                         className = 'nine columns')
            ]),

            # Select Season Dropdown
            html.Div([
                html.Div('Select Month', className =' three columns'),
                html.Div(dcc.Dropdown(id = 'month-selector'),
                         className = 'nine columns')
            ]),

            # Select Team Dropdown
            html.Div([
                html.Div('Select Crime', className = 'three columns'),
                html.Div(dcc.Dropdown(id = 'crime-selector'),
                         className = 'nine columns')
            ]),
        ], className = 'six columns'),

        # Empty
        html.Div(className = 'six columns'),
    ], className = 'twleve columns'),

    # Match Results Grid
    html.Div([

        # Match Results Table
        html.Div(
            html.Table(id = 'match-results'),
            className = 'six columns'
        ),

        # Season Summary Table and Graph
        html.Div([
            # summary table
            dcc.Graph(id = 'month-summary'),

            # graph
            dcc.Graph(id = 'month-graph')
            # style={},

        ], className = 'six columns')
    ]),
])
    
##############################################################################
# Interactions / Controller
##############################################################################
    
# Load months in dropdown
@app.callback(
    Output(component_id = 'month-selector', component_property = 'options'),
    [
        Input(component_id = 'year-selector', component_property = 'value')
    ]
)

def populate_month_selector(year):
    years = get_months(year)
    
    return [{'label': year, 'value': year} for year in years]
    
# Load crimes into dropdown
@app.callback(
    Output(component_id = 'crime-selector', component_property = 'options'),
    [
        Input(component_id = 'year-selector', component_property = 'value'),
        Input(component_id = 'month-selector', component_property = 'value')
    ]
)

def populate_crime_selector(year, month):
    crimes = get_crimes(year, month)
    return [
        {'label': crime, 'value': crime} for crime in crimes]
    
# Load match results
@app.callback(
    Output(component_id = 'match-results', component_property = 'children'),
    [
        Input(component_id = 'year-selector', component_property = 'value'),
        Input(component_id = 'month-selector', component_property = 'value'),
        Input(component_id = 'crime-selector', component_property = 'value')
    ]
)

def load_match_results(year, month, crime):
    results = get_match_results(year, month, crime)
    return generate_table(results, max_rows = 50)

# Update month summary table
@app.callback(
    Output(component_id = 'month-summary', component_property = 'figure'),
    [
        Input(component_id = 'year-selector', component_property = 'value'),
        Input(component_id = 'month-selector', component_property = 'value'),
        Input(component_id = 'crime-selector', component_property = 'value')
    ]
)

def load_month_summary(year, month, crime):
    results = get_match_results(year, month, crime)

    table = []
    if len(results) > 0:
        summary = comp_summ(results)
        table = ff.create_table(summary)

    return table


# Update Season Point Graph
@app.callback(
    Output(component_id = 'month-graph', component_property = 'figure'),
    [
        Input(component_id = 'year-selector', component_property = 'value'),
        Input(component_id = 'month-selector', component_property = 'value'),
        Input(component_id = 'crime-selector', component_property = 'value')
    ]
)

def load_months_points_graph(year, month, crime):
    results = get_match_results(year, month, crime)

    figure = []
    if len(results) > 0:
        figure = plot_graphics(chi, results)

    return figure

# start Flask server
if __name__ == '__main__':
    app.run_server(
        debug = True,
        host = '0.0.0.0',
        port = 8050)    
    
  