% alldatainone.m
% Saves the data of all raw-data files stored in the directory 
% '../../results/allinonefile' together in a single file: 
% '../../results/allinonefile/alldata.csv'
% use this function to save all data files of either experiment 1 or 2 in
% a single file
% Parameters: 
% Experiment: 1 for files of the first experiment, 2 for files of the 2nd
%             experiment
% Two columns are added compared to the original raw-data file: 
% distflakers: number of distorted flankers (0,2,4)
% experiment: 1: unflanked/flanked letter distortion detection task
%             3: follow-up experiments with distorted flankers

clear all;
close all;
clc;
 
% Number of repitions of the same amplitude/frequency pair used
reps = 10;

% Directory in which data files (to be saved in one file) can be found 
files = dir ( '../../results/allinonefile/*.csv' );

% Data of experiment 1 or 3 (different number of raw-data rows)
ex = input('Experiment (1/3):', 's');

numberOfFiles= size(files);
file = files(1);

% Split the first filename found and determine wether 0,2 or 4 distorted
% flankers were used
splitted_filename = textscan(file.name,'%s','delimiter','_');
splitted_filename = splitted_filename{:};

if strcmp(splitted_filename{1},'2distflanker') 
    distflankers = 2;
    exp = 0;
elseif strcmp(splitted_filename{1}, '4distflanker')
    distflankers = 4;
    exp = 0;
elseif strcmp(splitted_filename{1}, '4exp3b')
    distflankers = 4; 
    exp = 1;
elseif strcmp(splitted_filename{1}, '4exp3c')
    distflankers = 4; 
    exp = 2;
else
    distflankers = 0;
    exp = 0;
end

%% Bex frequencies and amplitudes
bexfreq = [2,4,6,8,16,32];
bexamp = [0.5, 1, 1.5, 2,3,4,5];

% RF frequencies and amplitudes
rfamp = [0.01, 0.0617, 0.1133, 0.165, 0.2167, 0.2683 ,0.32];
rffreq = [2,3,4,5,8,12];

%%  Number of trials in the corresponding file
if strcmp(ex,'1')
    numberOfStims = 6*7*10; %length(freq)*length(amp)*reps;
elseif strcmp(ex,'3')
    numberOfStims = 1*7*10*3; %length(freq)*length(amp)*reps;
else
    fclose('all');
    error('exp not known');
end

% Initialize variables, skip headerline
[subj, session, trial, flanked, distortion, frequency, amplitude, spacing, im_name, targ_letter, targ_pos, response, em, rt] = textread(['rdata/', file.name], ...
    '%s %d %d %s %s %d %f %f %s %s %s %s %s %f', 'headerlines', 1); 

% Save number of distorted flankers and experiment in the resulting file 
distflanks = distflankers * ones(length(subj),1);
experiment = exp * ones(length(subj),1);

% Loop through all files in the directory
for i=2:numberOfFiles(1)
    file = files(i);
    
    splitted_filename = textscan(file.name,'%s','delimiter','_');
    splitted_filename = splitted_filename{:};

    if strcmp(splitted_filename{1},'2distflanker')
        distflankers = 2;
        exp = 0;
    elseif strcmp(splitted_filename{1}, '4distflanker')
        distflankers = 4;
        exp = 0;
    elseif strcmp(splitted_filename{1}, '4exp3b')
        distflankers = 4;
        exp = 1; 
    elseif strcmp(splitted_filename{1}, '4exp3c')
        distflankers = 4; 
        exp = 2; 
    else
        distflankers = 0;
    end
    
    distflanks = [distflanks, distflankers * ones(length(subj),1)];
    experiment = [experiment, exp * ones(length(subj),1)];
    
    % Save parameters to data structure
    [subji, sessioni, triali, flankedi, distortioni, frequencyi, amplitudei, spacingi, im_namei, targ_letteri, targ_posi, responsei, emi, rti] = textread(['rdata/', files(i).name], '%s %d %d %s %s %d %f %f %s %s %s %s %s %f', 'headerlines', 1); 
    subj = [subj, subji];
    session = [session, sessioni]; 
    trial = [trial, triali]; 
    flanked = [flanked, flankedi]; 
    distortion = [distortion, distortioni]; 
    frequency = [frequency, frequencyi]; 
    amplitude = [amplitude, amplitudei]; 
    spacing = [spacing, spacingi];  
    im_name = [im_name, im_namei];  
    targ_letter = [targ_letter, targ_letteri]; 
    targ_pos = [targ_pos, targ_posi]; 
    response = [response, responsei]; 
    em = [em, emi]; 
    rt = [rt, rti];
end
idxrt = find(rt < 0.15 | isnan(rt))

%% Write results to file:

PathName = '../../results/allinonefile/';
datafilename = fullfile(PathName, char('alldata.csv')) % name of data file to write to
% Check for existing result file to prevent accidentally overwriting files
while fopen(datafilename, 'rt')~=-1
    fclose('all');
    error('File already exists.');
end
datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing

% Header
fprintf (datafilepointer,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n', 'subject', 'session','trial','flanked','distortion','freq','amplitude', 'spacing', 'im_name', 'targ_letter', 'targ_pos','response','eyemovement','RT', 'distflanks', 'exp3');

% Write all data to result file 
for i = 1:numberOfFiles(1)
    for j = 1 : numberOfStims                
        fprintf(datafilepointer,'%s\t %i\t %i\t %s\t %s\t %i\t %f\t %f\t %s\t %s\t %s\t %s\t %s\t %i\t %i\t %i\n', ...   
            char(subj(j,i)), ...
            session(j,i), ...
            trial(j,i),...
            char(flanked(j,i)),...
            char(distortion(j,i)),...
            frequency(j,i),...
            amplitude(j,i),...
            spacing(j,i),...
            char(im_name(j,i)),...
            char(targ_letter(j,i)),...
            char(targ_pos(j,i)),...
            char(response(j,i)),...
            char(em(j,i)),...
            rt(j,i),...
            distflanks(j,i),...
            experiment(j,i));
    end
end

fclose('all');