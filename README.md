# BMKessels-Festival-Scheduler
A script to allocate artists to stages following an input file that lists fixed timeslots for a multitude of artists.

The script "FestivalScheduler_BMKessels.m" will allocate stages to artists 
for a festival, according to a list (.txt input file, of which the name is 
defined in user input variable "InputFile") with fixed timeslots for each 
artist. This script gives the possibility to take turnover times (required 
on festivals to prepare the stage for a new artist, soundcheck, etc.) into 
account using the variable "TurnoverTime". Also, it provides two types of 
planning (with a densely booked main stage, or randomly allocated stages), 
via the variable "PlanningType". 
The outputs of the script are several figures, one of which is the time
table. Also, a .txt file (of which the name can be defined by the user in 
variable "OutputFile" is created that lists each artist with their stage, 
and timeslot. 

To run the code, just make sure that the input file is located in the same 
directory as the script. And make sure that all user inputs (including the 
name of the input file) are correct, see first section starting at line 18.


To allocate stages to the artists, first the artists are sorted based on 
their starting time (for artists with the same starting time, the artist 
that plays the longest is put on the top). Then, artists are allocated to
available stages via two options:
 - Prefer to allocate artists to stage 1, then 2, then 3, etc. (when 
   available. This results in a densely booked 'main stage' (stage 1).
 - Book artists to random (available) stages. This results in a random 
   schedule without preference for one particular stage.  
