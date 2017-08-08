#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jul  2 18:26:47 2017

@author: zan
"""
"""
    Flight Schedule-
        The purpose of this project is to create a flight schedule for travel between 3 airports for 6 aircraft.
"""

# Initial flight schedule-
flight_schedule = [['T1','AUS','DAL','0600','0650'],
                   ['T2','DAL','HOU','0600','0705'],
                   ['T3','DAL','HOU','0600','0705']]

flight_schedule.append(['T4','HOU','AUS','0600','0645'])
flight_schedule.append(['T5','HOU','DAL','0600','0705'])
flight_schedule.append(['T6','HOU','DAL','0600','0705'])

# Function for converting time (flights are initially recorded in "minutes past midnight" and then converted to 24-hour time)
def military_time(minutes):
    if minutes < 600:
        h = minutes // 60 
        m = minutes % 60
        return("{0:02d}{1:02d}".format(h, m))
    elif 600 < minutes < 720:
        h = minutes // 60
        m = minutes % 60
        return("{0:02d}{1:02d}".format(h, m))
    elif minutes == 720:
        h = 1200
        return("1200")
    else:
        h = ((minutes-720) // 60) + 12
        m = (minutes) % 60
        return("{0:02d}{1:02d}".format(h, m))

# Define the planes by tail number
planes = ['T1','T2','T3','T4','T5','T6']

# Create a function to record new flights
def flights(str):
    # Record the start time and end times of flights due to noise restrictions    
    start = 360
    end = 1320
    
    # Flight times
    aus_dal = 50
    aus_hou = 45
    dal_hou = 65

    # Ground times (Minimum wait time at each airport for plane after landinng, before departure.)
    aw = 25
    dw = 30
    hw = 35
    
    #Start times
    DepA = 360
    DepD = 360
    DepH = 360
    ArrA = 405
    T1ArrD = 410
    ArrH = 425
    
    #Initialize the list
    flights = []

    #T1 AUS to DAL and back
    while start < end:
                if str == 'T1':
                    
# Run the flights function on planes
for plane in planes:
    flights(plane)
        
# Sort the flight schedule according to tail number and departure time
flight_schedule = sorted(flights, key = lambda x: x[0] + x[3])

print(flight_schedule)

# Write the flight schedule to a CSV output file
csv_header = 'tail_number,origin,destination,departure_time,arrival_time' 
file_name = 'flight_schedule.csv'

def print_flight_schedule(file_name, csv_header, flight_schedule): 
    with open(file_name,'wt') as f:
        print(csv_header, file=f) 
        for s in flight_schedule:
            print(','.join(s), file=f)

print_flight_schedule(file_name, csv_header, flight_schedule)