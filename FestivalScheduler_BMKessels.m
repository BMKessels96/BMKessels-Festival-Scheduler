% This script will allocate stages to artists for a festival, according to
% a list (input file) with fixed timeslots for each artist. This script
% gives the possibility to take turnover times (required on festivals to
% prepare the stage for a new artist, soundcheck, etc.) into account. Also,
% it provides three types of planning (with a dense main stage, randomly
% allocated stages, or by taking into account the artist's popularity and 
% allocating more popular artists to 'bigger stages', i.e., stages with a 
% lower number). Each planning strategy tries to minimize the number of 
% used stages. The outputs of the script are several figures, one of which 
% is the time table. Also, a .txt file is created that lists each artist 
% with their popularity (high popularity-score (range: [1, 10]) indicates 
% popular artist), allocated stage, and timeslot. 

% Script created in Matlab R2024a by B.M. Kessels, 20-8-2026

clear
close all
clc


%% USER INPUTS:
TurnoverTime = 1;  % optional (make 0 to toggle off): hours required for turnover (should be integer value!)
PlanningType = "Popularity"; % choose the Planning type: "Random" (randomly select available stages), 
                             % "DenseMainStage" (Prefer a dense main stage in which a relatively large number of acts are planned),
                             % "Popularity" (Make sure that as many artists with high popularity score are booked to the prime stages, i.e., stages with low stage-numbers). This might result in additional stages to be used.
FigPos = [100, 100, 1400, 600];  % define figure position for all figures
InputFile = "ShowList";  % input name of .txt file with show list
OutputFile = InputFile + "_withStages";  % define name of output file in which the stages are added to the list with artists and strarting/ending times
PopularityRange = [1, 10];  % range of (integer) popularity scores. Only used when input file does not already have indicated popularity-scores


%% Check user input:
% Check if turnover time is integer:
if mod(TurnoverTime,1)~=0
    error("Please make sure that the variable 'TurnoverTime' is defined as an integer value (i.e., number of hours)")
end
PlanningTypeOptions = ["Random", "DenseMainStage", "Popularity"];
if ~any(PlanningType == PlanningTypeOptions)
    error("Please make sure that the variable 'PlanningType' is defined as one of the viable options (%s)", strjoin(PlanningTypeOptions, ', '))
end


%% General settings:
% Ensure that schedule is plotted red (not playing), green (playing):
Colormap_RedOrangeGreen = [1 0 0; 1 0.647 0; 0 1 0];
set(groot, 'DefaultFigureColormap', Colormap_RedOrangeGreen);


%% Load and process inputdata:
ShowList = readmatrix(sprintf("%s.txt", InputFile), 'OutputType','string');  % load ShowList .txt document as table
ShowTimes = double(ShowList(:, end-1:end));  % extract ShowTimes in matrix
n_artists = size(ShowTimes, 1);  % extract number of artists
n_timeslots = max(ShowTimes, [], 'all');  % extract number of timeslots
IsPlaying = f_CheckIfPlaying(ShowTimes, TurnoverTime);  % IsPlaying is a matrix with, for each artist (row) and timeslot (column), a binary value (0=not playing, 1=playing) 


%% Inspect inputdata:
plot_IsPlaying(IsPlaying, 1:n_artists, 'ShowTimes (raw inputdata)', FigPos)  % plot when artist is playing
SimultaneousShows = sum(IsPlaying~=0, 1);  % determine number of simultaneous shows
[n_stages, TimeSlot_mostSimultaneousShows] = max(SimultaneousShows);  % number of minimal stages equals highest number of simultaneous shows (including turnover) in one timeslot 
if size(ShowList, 2)==4
    InputHasPopularity = true;
    Popularity = round(double(ShowList(:, 2)));  % make sure that the Popularity-score is an integer
else
    InputHasPopularity = false;
end


%% Include popularity score (if, orignally, it did not have popularity score):
if ~InputHasPopularity
    Popularity = round(normrnd(mean(PopularityRange), diff(PopularityRange)/4, [n_artists, 1]));  % create an integer popularity score by sampling from a normal distribution centered around mean of popularity-score range
    Popularity(Popularity<PopularityRange(1)) = PopularityRange(1);  % limit to minimum of range of popularity-score
    Popularity(Popularity>PopularityRange(2)) = PopularityRange(2);  % limit to maximum of range of popularity-score
end


%% Order Artists on starting time (for similar starting times, first artist will be with earliest ending time):
[~, ArtistList_orderedOnEnd] = sort(ShowTimes(:, 2), 1, 'descend');  % first order artists on their ending time
[~, ArtistList_orderedOnStart_temp] = sort(ShowTimes(ArtistList_orderedOnEnd, 1), 1, 'ascend');  % second, order already ordered artists on their starting time
ArtistList_orderedOnStart = ArtistList_orderedOnEnd(ArtistList_orderedOnStart_temp);  % update ordering of artists 
ShowTimes_orderedOnStart = ShowTimes(ArtistList_orderedOnStart, :);  % update matrix with show times accordingly
IsPlaying_orderedOnStart = f_CheckIfPlaying(ShowTimes_orderedOnStart, TurnoverTime);  % use function to check for each time slot if an artist is playing

plot_IsPlaying(IsPlaying_orderedOnStart, ArtistList_orderedOnStart, 'ShowTimes (ordered on starting time)', FigPos)  % make plot


%% Make schedule:
% Define variable 'Pop' to be the popularity per artist. In contrast to 
% 'Popularity', 'Pop' takes into account that the Popularity-score is 
% irrelevant when Planning does not take into account popularity of 
% artists. Consequently, for these PlanningTypes, 'Pop' is set to '1' for 
% all artists:
if PlanningType == "Popularity"
    Pop = Popularity;
else
    Pop = ones(size(Popularity));
end
PopLevels = sort(unique(Pop), 'descend');  % sort the different Pop-levels from high to low

% Use ordered list of artist and allocate them to available stages (taking
% into account 'Pop-score':
AllArtistsBooked = false;
while AllArtistsBooked==false  % as long as not all artists are given a stage, the planning algorithm is repeated (for increasing number of stages)
    flag_break = false;  % initalize flag to break through multiple for-loops
    StageBooking = zeros(n_stages, n_timeslots);  % initialize, will be filled with artistnumbers
    StageIndication = zeros(n_stages, n_timeslots);  % initialize, will be filled with not-playing/turnover/playing
    for pp = PopLevels.'  % start with most popular artists
        Artists_curPopScore = find(Pop==pp);  % find artists with the currently evaluated Pop-score
        ArtistList_orderedOnStart_curPopScore = intersect(ArtistList_orderedOnStart, Artists_curPopScore, 'stable');  % only keep artists (in ordered order) with same popularity score
        for cur_artist = ArtistList_orderedOnStart_curPopScore.'  % pick earliest starting artist (with same Pop-score) as current artist             
            StartTime_curArtist = ShowTimes(cur_artist, 1);
            EndTime_curArtist = ShowTimes(cur_artist, 2);
            AvailableStages = find(all(StageBooking(:, StartTime_curArtist:min(EndTime_curArtist+TurnoverTime, n_timeslots))==0, 2));  % find which stages are available during the entire performance + turnover of current artist 
            AvailableStages = sort(AvailableStages, 'ascend');  % ensure that the available stages are sorted from low to high
            if ~isempty(AvailableStages)
                switch PlanningType 
                    case {"DenseMainStage", "Popularity"}
                        cur_Stage = AvailableStages(1);  % pick available stage with lowest number
                    case "Random"
                        cur_Stage = AvailableStages(randi(length(AvailableStages)));  % randomly pick one of the available stages 
                end
                StageBooking(cur_Stage, StartTime_curArtist:EndTime_curArtist+TurnoverTime) = cur_artist;  % artist is allocated to current stage (lowest numbered available stage) 
                StageIndication(cur_Stage, StartTime_curArtist:EndTime_curArtist+TurnoverTime) = 2;  % stage is being played
                StageIndication(cur_Stage, EndTime_curArtist+1:EndTime_curArtist+TurnoverTime) = 1;  % stage is being 'turned over'
            else  % no available stage for current artist, so an additional stage has to be used.
                n_stages = n_stages + 1;  
                flag_break = true;
                fprintf("There is no available stage, so an additional stage is used. Total number of stages now is: %d.\n", n_stages)
                break
            end
            % plot_FestivalTimetable(StageIndication, StageBooking, Popularity, FigPos)  % may be uncommented for debugging
        end
        % plot_FestivalTimetable(StageIndication, StageBooking, Popularity, FigPos)  % may be uncommented for debugging 
        if flag_break
            break
        end
    end
    if ~flag_break
        AllArtistsBooked = true;
    end
end

% Turnovers after last performance on each stage are irrelevant and thus pruned from matrices:
StageIndication = StageIndication(:, 1:n_timeslots);  % prune after last (original) timeslot, i.e., end of festival
for rr = 1:n_stages  
    idx = find(StageIndication(rr,:) == 2, 1, 'last');  % find index of last occurrence of 2 in each row
    if ~isempty(idx) && idx < n_timeslots
        StageIndication(rr, idx+1:end) = 0;  % set values after last occurence of 2 (i.e., possible turnover moments) to zero
    end
end
StageBooking = StageBooking(:, 1:n_timeslots);  % prune after last (original) timeslot, i.e., end of festival
StageBooking = StageBooking.*(StageIndication==2);  % Make sure that artists is only indicated when artist is playing (not during turnover)
 

%% Plot Final Festival Timetable:
plot_FestivalTimetable(StageIndication, StageBooking, Popularity, FigPos)


%% Create output file with artist, stage, and timeslot:
file_out = fopen(sprintf("%s.txt", OutputFile), 'w');  % create output file
for aa = 1:n_artists
    [stageOfArtist, ~] = find(StageBooking==aa);  % find stage of artist 
    fprintf(file_out, 'Artist: %d, Popularity: %d, Stage:%d, Timeslot: %d-%d\n', aa, Popularity(aa), stageOfArtist(1), ShowTimes(aa, 1), ShowTimes(aa, 2));  % print information to output file
end
fclose(file_out);



%% %%%% FUNCTIONS: %%%% %%
function IsPlaying = f_CheckIfPlaying(ShowTimes, TurnoverTime)
    % This function determines when each artist is playing and (if toggled)
    % when and how long the turnover after their show is.

    IsPlaying = zeros(size(ShowTimes, 1), max(ShowTimes, [], 'all'));  % initialize as if all artists are never playing (timeslot=0 for not playing)
    for aa = 1:size(ShowTimes, 1)  % iterate over artists    
        IsPlaying(aa, ShowTimes(aa, 1):ShowTimes(aa, 2)) = 2;  % from start show, band is playing (timeslot=2)
        IsPlaying(aa, ShowTimes(aa, 2)+1: ShowTimes(aa, 2)+TurnoverTime) = 1;  % include turnover time if present (timeslot=1)
    end
    IsPlaying = IsPlaying(:, 1:max(ShowTimes, [], 'all'));  % turnover after end of festival is irrelevant and thus pruned
end

function plot_IsPlaying(IsPlaying, ArtistList, Title, FigPos)
    % This function plots the availability of artists and (if toggled)
    % required turnover times after their performance.

    figure('Position',FigPos) 
    imagesc(IsPlaying)
    xticks(1:size(IsPlaying, 2))
    yticks(1:length(ArtistList))
    yticklabels(string(ArtistList))
    set(gca, 'YDir', 'normal');
    xlabel('TimeSlot')
    ylabel('Artist')
    title(Title)
    c = colorbar;
    c.Ticks = [0, 1, 2];                  
    c.TickLabels = {'Not playing', 'Turnover', 'Playing'}; 
end

function plot_FestivalTimetable(StageIndication, StageBooking, Popularity, FigPos)
    % This function plots the festival Timetable.  

    figure('Position',FigPos) 
    imagesc(StageIndication)
    hold on
    BookedArtists = setdiff(unique(StageBooking), 0).';
    for aa = BookedArtists  % iterate over all Booked artists
        [row, col] = find(StageBooking==aa);  % find row (stage) and column (timeslot) corresponding to artist
        text(mean(col), row(1), sprintf("A:%d, P:%d", aa, Popularity(aa)), 'HorizontalAlignment','center', 'Color','k', 'FontWeight','bold')  % add number of artist in its timeslot
        % Include vertical bars to highlight start and end of timeslot:
        plot([col(1)-0.5, col(1)-0.5], [row(1)-0.5, row(1)+0.5], 'k', 'LineWidth',1.5)  
        plot([col(end)+0.5, col(end)+0.5], [row(1)-0.5, row(1)+0.5], 'k', 'LineWidth',1.5)
    end
    c = colorbar;
    c.Ticks = [0, 1, 2];                  
    c.TickLabels = {'Not playing', 'Turnover', 'Band is playing'}; 
    xlabel('Timeslot')
    ylabel('Stage')
    xticks(1:size(StageBooking, 2))
    yticks(1:size(StageBooking, 1))
    yticklabels(string(1:size(StageBooking, 1)))
    axis equal tight
    set(gca, 'YDir', 'normal');
    title("Festival timetable (with indicated '(A)rtist, (P)opularity-score')")
end