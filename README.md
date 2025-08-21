This script is my submission to the Demcon coding challenge: 'Festival 
schedule generator' 
https://careersatdemcon.com/decode-demcon/challenge-festival-schedule-generator

The script will allocate stages to artists for a festival, according to a 
list (input file) with fixed timeslots for each artist. This script gives 
the possibility to take turnover times (required on festivals to prepare 
the stage for a new artist, soundcheck, etc.) into account. Also, it 
provides three types of planning (with a dense main stage, randomly 
allocated stages, or by taking into account the artist's popularity and 
allocating more popular artists to 'bigger stages', i.e., stages with a 
lower number). Each planning strategy tries to minimize the number of used 
stages. The outputs of the script are several figures, one of which is the 
time table. Also, a .txt file is created that lists each artist with their 
popularity (high popularity-score indicates popular 
artist), allocated stage, and timeslot.

To run the code, just make sure that the input file is located in the same 
directory as the script. And make sure that all user inputs (including the 
name of the input file) are correct, see first section starting at line 21.

With respect to the Popularity-score, there are two options:
 -  Predefine the Popularity-score in the input file by including the score 
    directly after the artist description, i.e., "show_1 2 14 18", 
    indicates that artist 1, has a popularity score of 2, and plays from 
    timeslot 14 till timeslot 18.
 -  If the Popularity score is not included in the input file, the script 
    will automatically allocate popularity-scores to each artist by 
    sampling from a (normal distribution). 

To allocate stages to the artists, first the artists are sorted based on 
their starting time (for artists with the same starting time, the artist 
that plays the longest is put on the top). Then, artists are allocated to
available stages via three options:
 1. Prefer to allocate artists to stage 1, then 2, then 3, etc. (when 
    available. This results in a densely booked 'main stage' (stage 1).
 2. Book artists to random (available) stages. This results in a random 
    schedule without preference for one particular stage.  
 3. Book artists based on their popularity. Popular artists will be booked 
    on 'bigger' stages, i.e., stage with low number. Artists with the same 
    popularity-score are handled as described above in Option 1. Note, in 
    this case, a higher number of stages might be required than when using 
    Option 1 or 2.
