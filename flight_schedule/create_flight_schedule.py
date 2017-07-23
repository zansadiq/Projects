#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jul  2 18:26:47 2017

@author: zan
"""

# function for converting time

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

start = 360
end = 1320

# Flight times
AD = 50
AH = 45
DH = 65

#Ground times
AW = 25
DW = 30
HW = 35

#Start times
DepA = 360
DepD = 360
DepH = 360
ArrA = 360
ArrD = 360
ArrH = 360

#Initialize the list
flights = []

#T1 AUS to DAL and back
while start < end:
    ArrD = DepA + AD 
    flights.append(['T1', 'AUS', 'DAL', military_time(DepA), military_time(ArrD)])
    DepD = ArrD + DW + 20
    ArrA = DepD + AD 
    flights.append(['T1', 'DAL', 'AUS', military_time(DepD), military_time(ArrA)])
    DepA = ArrA + AW + 20 
    start = DepA + AD + DW + 20 + AD    

#T2 DAL to HOU and back
start = 360
end = 1320

# Flight times
AD = 50
AH = 45
DH = 65

#Ground times
AW = 25
DW = 30
HW = 35

#Start times
DepA = 360
DepD = 360
DepH = 360
ArrA = 360
ArrD = 360
ArrH = 360

while start < end:
    ArrH = DepD + DH
    flights.append(['T2', 'DAL', 'HOU', military_time(DepD), military_time(ArrH)])
    DepH = ArrH + HW
    ArrD= DepH + DH
    flights.append(['T2', 'HOU', 'DAL', military_time(DepH), military_time(ArrD)])
    DepD = ArrD + DW
    start = DepD + DH + HW + DH

#T3 HOU to AUS and back
start = 360
end = 1320

# Flight times
AD = 50
AH = 45
DH = 65

#Ground times
AW = 25
DW = 30
HW = 35

#Start times
DepA = 360
DepD = 360
DepH = 360
ArrA = 360
ArrD = 360
ArrH = 360

while start < end:
    ArrA = DepH + AH 
    flights.append(['T3', 'HOU', 'AUS', military_time(DepH), military_time(ArrA)])
    DepA = ArrA + AW + 30
    ArrH= DepA + AH  
    flights.append(['T3', 'AUS', 'HOU', military_time(DepA), military_time(ArrH)])
    DepH = ArrH + HW + 15
    start = DepH + AH + HW + AH

#T4
start = 360
end = 1320

# Flight times
AD = 50
AH = 45
DH = 65

#Ground times
AW = 25
DW = 30
HW = 35

#Start times
DepA = 360
DepD = 360
DepH = 360
ArrA = 360
ArrD = 360
ArrH = 360

for i in range(10):
    if start < end:
        ArrH = DepD + DH
        flights.append(['T4', 'DAL', 'HOU', military_time(DepD), military_time(ArrH)])
        DepH = ArrH + HW + 90
        start = DepH + DH + DW
    if start < end:
        ArrD = DepH + DH
        flights.append(['T4', 'HOU', 'DAL', military_time(DepH), military_time(ArrD)])
        DepD = ArrD + DW
        start = DepD + DH + HW

#T5
start = 360
end = 1320

# Flight times
AD = 50
AH = 45
DH = 65

#Ground times
AW = 25
DW = 30
HW = 35

#Start times
DepA = 360
DepD = 360
DepH = 360
ArrA = 360
ArrD = 360
ArrH = 360

for i in range(10):
    if start < end:
        ArrD = DepH + DH
        flights.append(['T5', 'HOU', 'DAL', military_time(DepH), military_time(ArrD)])
        DepD = ArrD + DW
        start = DepD + DH + HW
    if start < end:
        ArrH = DepD + DH
        flights.append(['T5', 'DAL', 'HOU', military_time(DepD), military_time(ArrH)])
        DepH = ArrH + HW + 90
        start = DepH + DH + DW

#T6
start = 360
end = 1320

# Flight times
AD = 50
AH = 45
DH = 65

#Ground times
AW = 25
DW = 30
HW = 35

#Start times
DepA = 360
DepD = 360
DepH = 360
ArrA = 360
ArrD = 360
ArrH = 360
T6DH = 455

for i in range(10):
    if start < end:
        ArrD = T6DH + DH
        flights.append(['T6', 'HOU', 'DAL', military_time(T6DH), military_time(ArrD)])
        DepD = ArrD + DW
        start = DepD + DH+ HW
    if start < end:
        ArrH = DepD + DH
        flights.append(['T6', 'DAL', 'HOU', military_time(DepD), military_time(ArrH)])
        T6DH = ArrH + HW + 90
        start = T6DH + DH + DW
        
#sort the flight schedule according to tail number and departure time
flight_schedule = sorted(flights, key = lambda x: x[0] + x[3])

print(flight_schedule)

csv_header = 'tail_number,origin,destination,departure_time,arrival_time' 
file_name = 'flight_schedule.csv'

def print_flight_schedule(file_name, csv_header, flight_schedule): 
    with open(file_name,'wt') as f:
        print(csv_header, file=f) 
        for s in flight_schedule:
            print(','.join(s), file=f)

print_flight_schedule(file_name, csv_header, flight_schedule)