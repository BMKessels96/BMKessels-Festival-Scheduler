% This script will allocate stages to artists for a festival, according to
% a list (input file) with fixed timeslots for each artist. This script
% gives the possibility to take turnover times (required on festivals to
% prepare the stage for a new artist, soundcheck, etc.) into account. Also,
% it provides two types of planning (with a dense main stage, or randomly
% allocated stages). 
% The outputs of the script are several figures, one of which is the time
% table. Also, a .txt file is created that lists each artist with their
% stage, and timeslot. 

% Code created in Matlab R2024a by B.M. Kessels, 18-8-2026

clear
close all
clc


%% USER INPUTS:
TurnoverTime = 2;  % optional (make 0 to toggle off): hours required for turnover (should be integer value!)
PlanningType = "DenseMainStage";  % Choose the Planning type: "Random" (randomly select available stages), "DenseMainStage" (Prefer a dense main stage in which a relatively large number of acts are planned)
FigPos = [100, 100, 1000, 400];  % define figure position for all figures
InputFile = "ShowList";  % input name of .txt file with show list
OutputFile = InputFile + "_withStages";  % define name of output file in which the stages are added to the list with artists and strarting/ending times


%% Check user input:
% Check if turnover time is integer:
if mod(TurnoverTime,1)~=0
    error("Please make sure that the variable 'TurnoverTime' is defined as an integer value (i.e., number of hours)")
end


%% General settings:
% Ensure that schedule is plotted red (not playing), green (playing):
Colormap_RedOrangeGreen = [1 0 0; 1 0.647 0; 0 1 0];
set(groot, 'DefaultFigureColormap', Colormap_RedOrangeGreen);


%% Load and process inputdata:
ShowList = readtable(sprintf("%s.txt", InputFile));  % load ShowList .txt document as table
ShowTimes = table2array(ShowList(:, 2:end));  % extract ShowTimes in matrix
n_artists = size(ShowTimes, 1);  % extract number of artists
n_timeslots = max(ShowTimes, [], 'all');  % extract number of timeslots
IsPlaying = f_CheckIfPlaying(ShowTimes, TurnoverTime);  % IsPlaying is a matrix with, for each artist (row) and timeslot (column), a binary value (0=not playing, 1=playing) 


%% Inspect inputdata:
plot_IsPlaying(IsPlaying, 1:n_artists, 'ShowTimes (raw inputdata)', FigPos)  % plot
SimultaneousShows = sum(IsPlaying~=0, 1);  % determine number of simultaneous shows
[n_stages, TimeSlot_mostSimultaneousShows] = max(SimultaneousShows);  % number of minimal stages equals highest number of simultaneous shows (including turnover) in one timeslot 


%% Order Artists on starting time (for similar starting times, first artist will be with earliest ending time):
[~, ArtistList_orderedOnEnd] = sort(ShowTimes(:, 2), 1, 'descend');  % first order artists on their ending time
[~, ArtistList_orderedOnStart_temp] = sort(ShowTimes(ArtistList_orderedOnEnd, 1), 1, 'ascend');  % second, order already ordered artists on their starting time
ArtistList_orderedOnStart = ArtistList_orderedOnEnd(ArtistList_orderedOnStart_temp);  % update ordering of artists 
ShowTimes_orderedOnStart = ShowTimes(ArtistList_orderedOnStart, :);  % update matrix with show times accordingly
IsPlaying_orderedOnStart = f_CheckIfPlaying(ShowTimes_orderedOnStart, TurnoverTime);  % use function to check for each time slot if an artist is playing

plot_IsPlaying(IsPlaying_orderedOnStart, ArtistList_orderedOnStart, 'ShowTimes (ordered on starting time)', FigPos)  % make plot


%% Make schedule:
% Use ordered list of artist and allocate them to available stages
StageBooking = zeros(n_stages, n_timeslots);  % initialize, will be filled with artistnumbers
StageIndication = zeros(n_stages, n_timeslots);  % initialize, will be filled with not-playing/turnover/playing
for ss = 1:n_artists             
    cur_artist = ArtistList_orderedOnStart(ss);  % pick earliest starting artist as current artist (which has not been picked
    StartTime_curArtist = ShowTimes(cur_artist, 1);
    EndTime_curArtist = ShowTimes(cur_artist, 2);
    AvailableStages = find(StageBooking(:, StartTime_curArtist)==0);  % find which stages are available
    switch PlanningType 
        case "DenseMainStage"
            cur_Stage = AvailableStages(1);  % pick available stage with lowest number
        case "Random"
            cur_Stage = AvailableStages(randi(length(AvailableStages)));  % randomly pick one of the available stages 
    end
    StageBooking(cur_Stage, StartTime_curArtist:EndTime_curArtist+TurnoverTime) = cur_artist;  % artist is allocated to current stage (lowest numbered available stage) 
    StageIndication(cur_Stage, StartTime_curArtist:EndTime_curArtist+TurnoverTime) = 2;  % stage is being played
    StageIndication(cur_Stage, EndTime_curArtist+1:EndTime_curArtist+TurnoverTime) = 1;  % stage is being 'turned over'
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
 

%% Plot festival timetable:
figure('Position',FigPos) 
imagesc(StageIndication)
hold on
for aa = 1:n_artists
    [row, col] = find(StageBooking==aa);  % find row (stage) and column (timeslot) corresponding to artist
    text(mean(col), row(1), num2str(aa), 'HorizontalAlignment','center', 'Color','k', 'FontWeight','bold')  % add number of artist in its timeslot
    % Include vertical bars to highlight start and end of timeslot:
    plot([col(1)-0.5, col(1)-0.5], [row(1)-0.5, row(1)+0.5], 'k', 'LineWidth',1.5)  
    plot([col(end)+0.5, col(end)+0.5], [row(1)-0.5, row(1)+0.5], 'k', 'LineWidth',1.5)
end
c = colorbar;
c.Ticks = [0, 1, 2];                  
c.TickLabels = {'Not playing', 'Turnover', 'Band is playing'}; 
xlabel('Timeslot')
ylabel('Stage')
xticks(1:n_timeslots)
yticks(1:n_stages)
yticklabels(string(1:n_stages))
axis equal tight
set(gca, 'YDir', 'normal');
title("Festival timetable")


%% Create output file with artist, stage, and timeslot:
file_out = fopen(sprintf("%s.txt", OutputFile), 'w');  % create output file
for aa = 1:n_artists
    [stageOfArtist, ~] = find(StageBooking==aa);  % find stage of artist 
    fprintf(file_out, 'Artist: %d, Stage:%d, Timeslot: %d-%d\n', aa, stageOfArtist(1), ShowTimes(aa, 1), ShowTimes(aa, 2));  % print information to output file
end
fclose(sprintf("%s.txt", OutputFile));


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