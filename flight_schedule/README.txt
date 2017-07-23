The problem for this project was to create a flight schedule for an airline company. 

There are 6 planes(T1-T6).

3 airports(AUS,DAL,HOU). 

The airports have 1,2,3 gates respectively. 

Each airport has a minimum ground time of 25,30,35 minutes respectively.
Each plane must wait for the minimum ground time after arrival before departing again. 

The planes can only fly between 0600 and 2200(military time) due to noise restrictions. 

The number of flights landing at any given airport at one time is constrained by the number of gates. 

My solution for this project was to create a dedicated route for each plane, and then create loops in python to record 
the arrival and departure times for each aircraft in a list of flights. 

The list of flights was then output in the form of a csv with (Tail Number, Origin, Destination, Departure Time, Arrival Time).
The CSV was then sorted according to tail number and departure time. 

