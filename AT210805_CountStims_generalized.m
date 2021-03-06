% read and count all sweeps for a given dataset 

% In the variable stimcounts, each row corresponds to a plate. 
% For 160 sweeps, there will be 160 columns in the row, showing the pulses
% counted for each sweep in that plate. This one is most useful for copying
% to spreadsheets if desired. 

% the channel that the electrical stimulus was recorded on may vary.
% For recent screens (2020 onwards) the channel is probably 1. 
% Prior years on Rig 1 (all GECIs): the channel is probably 4
% Prior years on Rig 2: the channel is probably ??? 
% A plot of the channel is generated by this script as a sanity check.
stimsync_channel = 1;

disp('Choose a FOLDER')
% datafolder = uigetdir('/Volumes/genie/GETIScreenData/RawImageData')
datafolder = uigetdir('/Users/tsanga/Documents/MATLAB/Count_Stims/iglusnfr_stimcount_test')

channel_msg = strcat('Reading channel ', " ", num2str(stimsync_channel), " ", 'for stim sync data');
disp(channel_msg)

cd(datafolder);
h5files = dir('*.h5');

numFiles = length(h5files);

% make a new structure 
stimcounts = [];

for i = 1:numFiles
    
    currentFile = h5files(i).name;

    % parse the filename to get the number of sweeps to read
    [sweeps1,sweeps2] = regexp(currentFile, '\d+.h5');
    sweep_str = currentFile(sweeps1:sweeps2);
    sweep_str = sweep_str(1:4);
    total_sweeps = str2num(sweep_str);
    
    userMsg = strcat('Processing file', " ", currentFile);
    disp(userMsg)
    
    % for the current h5 file, read the stim sync channel for each sweep
    for j = 1:total_sweeps
        
        % create the name of the dataset to read
        jstr = int2str(j);
        if j < 10
            sweepnum = strcat('000', jstr);
        elseif j > 9 && j < 100
            sweepnum = strcat('00', jstr);
        else
            sweepnum = strcat('0', jstr);
        end
            
        sweepname = strcat('/sweep_', sweepnum);
        
        dataname = strcat(sweepname, '/analogScans');
        
        % read stim sync and count stim pulses
        
        analogscans = h5read(currentFile, dataname);
        stimsync = analogscans(:,1);
        
        % take the absolute value of stimsync readout in case it's inverted
        stimsync = abs(stimsync);
        
%         pulsecount = 0;

        dstimsync = double(stimsync);

        % the first assignment returns values to pks.

        % the second findpeaks statement creates a plot with arrows
        % indicating the peaks detected by the function (useful for hand
        % checking single sweeps).

        [pks, lc] = findpeaks(dstimsync, 'MinPeakHeight', 200, 'MinPeakDistance',90);

        % MinPeakHeight: 200 (arbitrary signal units)
        % MinPeakProminence: 200 (aribtrary signal units)
        % MinPeakDistance: 100 samples (83Hz pulse train = 12 ms interval; at 10Khz.
        % Therefore, 0.012 sec * 10,000 samples/sec = 120 samples.
        % Shortened the window to 100 samples for margin to accomodate
        % timing errors. 
        
        stimcounts(i,j) = length(pks);
        
    end
    
end

% plot

% finding axes sizes for setting in plots later
stim_axes = size(stimcounts);
stim_axes_rows = stim_axes(1);
stim_axes_cols = stim_axes(2);

% colref = 2:2:160; % use this to reference even numbered columns (the 20 AP columns)
% barx = 1:80; % x axis for a bar graph of 20 AP sweeps per plate

% get only the 20 ap stim counts (even columns of stimcounts)
% stimcounts_20ap = stimcounts(:,2:2:160);
% stim_axes = size(stimcounts_20ap);
% stim_axes_rows = stim_axes(1);
% stim_axes_cols = stim_axes(2);


numpoints = stim_axes_rows * stim_axes_cols;
graphx = 1:numpoints; % make a general sequential x-axis for the graph

stimcounts_vect = reshape(stimcounts, [1,numpoints]);

maxval = max(stimcounts_vect);

figure
scatter(graphx, stimcounts_vect)
axis([0,inf,0,maxval])
title('Pulses counted in each sweep of this dataset')

figure
histogram(stimcounts_vect)
title('Histogram of pulses in this dataset')

figure
hold on
plot(dstimsync)
plot(lc, pks, 'o', 'MarkerSize',12)
title('Example plot of chosen channel')
hold off

% calculate and display a breakdown by plate

