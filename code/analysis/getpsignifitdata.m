% Choose a alldata.csv file (created with the alldatainone function) and 
% save the data for a certain experiment (1/3), subject, distortiontype, 
% flankedtype in the format needed for psignifit under: 
% '../../results/psignifitdata/datapsignifit.csv'
% in the format: (amplitude | nCorrect | total) where nCorrect describes
% the number of correct trials and total the number of all trials 
%
% Parameters:
% alldata.csv:      Choose an alldata.csv file from wich you would like to 
%                   get the data in an appropriate format for psinifit 
% distortiontype:   bex/rf
% flankedtype:      unflanked / flanked   
% experiment:       1 (unflanked/flanked) or 3 (distorted flankers)
% subject:          identification of observer 


function getpsignifitdata()
clear all;
close all;
clc;

% Number of repitions with the same frequency and amplitude
reps = 10;
% Select alldata.csv file
[filename, pathname] = uigetfile('*.csv', 'Select the csv data file');

% Ask for parameters
distortiontype = input('Enter distortiontype ("bex" or "rf"):', 's');
flankedtype = input('Enter flankedtype ("unflanked" or "flanked"):', 's');
exp = input('Enter Experiment (1/3):', 's');
subject = input('Enter subj (2,5,7,8,9):', 's');

% Set amplitudes and frequencies according to chosen distortion type
% Bex distortion type
if strcmp(distortiontype, 'bex')
        if strcmp(exp, '1')
            amp = [0.25, 0.5, 1, 1.5, 2, 2.5, 3, 5];
            freq = [2, 4, 6, 8, 16, 32];
            files = input('Enter number of blocks (420 trials each) with old amps:', 's');
            newamps = input('Enter number of blocks (420 trials each) with new amps:', 's');
        else 
            amp = [1,2,3,4,5,6,7];
            freq = [4]; 
            files = input('Enter number of blocks (70 trials each):', 's');
            newamps = input('Enter number of blocks (70 trials each) with new amps:', 's');
        end
% RF distortion type        
elseif strcmp(distortiontype, 'rf')
        if strcmp(exp, '1')
            amp = [0.0075, 0.01, 0.0617, 0.1133, 0.1650, 0.2167, 0.2683, 0.3200];
            freq = [2, 3, 4, 5, 8, 12];
            files = input('Enter number of blocks (420 trials each)with old amps:', 's');
            newamps = input('Enter number of blocks (420 trials each) with new amps:', 's');
        else 
            amp = [0.05, 0.125, 0.2, 0.275, 0.35, 0.425, 0.5];
            freq = [4];
            files = input('Enter number of blocks (70 trials each):', 's');
            newamps = input('Enter number of blocks (70 trials each) with new amps:', 's');
        end
else
    fclose('all')
    error('Distortiontype not known');
end

% Number of files contained in the alldata.csv file
files = str2num(files);
newamps = str2num(newamps);

% Initialize variables, skip headerline
[subj, session, trial, flanked, distortion, frequency, amplitude, spacing, im_name, targ_letter, targ_pos, response, em, rt, distflanks, exp3b] = textread(fullfile(pathname, filename), ...
    '%s %d %d %s %s %d %f %f %s %s %s %s %s %f %d %d', 'headerlines', 1); 

% Find all indices of correct responses
for freqidx =1:length(freq) 
    for ampidx = 1:length(amp) 
        idx_freq_amp = find(frequency == freq(freqidx) & amplitude == amp(ampidx) & strcmp(subject, subj) &strcmp(distortion, distortiontype) & strcmp(flankedtype, flanked));
        idx_corr_freq_amp = find(frequency == freq(freqidx) & amplitude == amp(ampidx) & strcmp(targ_pos,response) & strcmp(subject, subj) & strcmp(distortion, distortiontype)& strcmp(flankedtype, flanked));
        idx_corr_freq_amp_distflanks0 = find(frequency == freq(freqidx) & amplitude == amp(ampidx) & strcmp(targ_pos,response) & strcmp(subject, subj) & distflanks==0 & strcmp(distortion, distortiontype)& strcmp(flankedtype, flanked));
        idx_corr_freq_amp_distflanks2 = find(frequency == freq(freqidx) & amplitude == amp(ampidx) & strcmp(targ_pos,response) & strcmp(subject, subj) & distflanks==2& strcmp(distortion, distortiontype)& strcmp(flankedtype, flanked));
        idx_corr_freq_amp_distflanks4 = find(frequency == freq(freqidx) & amplitude == amp(ampidx) & strcmp(targ_pos,response) & strcmp(subject, subj) & distflanks==4&strcmp(distortion, distortiontype)& strcmp(flankedtype, flanked));
        %freqampcorrect(freqidx, ampidx) = length(idx_corr_freq_amp)/length(idx_freq_amp);
        numbercorrect(freqidx, ampidx) = length(idx_corr_freq_amp);
        if strcmp(exp, '3')
            numbercorrectdistflanks0(freqidx, ampidx) = length(idx_corr_freq_amp_distflanks0);
            numbercorrectdistflanks2(freqidx, ampidx) = length(idx_corr_freq_amp_distflanks2);
            numbercorrectdistflanks4(freqidx, ampidx) = length(idx_corr_freq_amp_distflanks4);
        end
    end
end

% Find trials with a reaction time less than 0.15 s (might want to discard)
idx_disc = find(rt < 0.15); 

%% Write results to file:
rpathname = '../../results/psignifitdata';
datafilename = fullfile(rpathname, ['datapsignifit.csv']); % name of data file to write to
% Check for existing result file to prevent accidentally overwriting files
while fopen(datafilename, 'rt')~=-1
    fclose('all');
    error('File already exists.');
end
datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing

% Change amplitude from positional shifts in pixel to positional shifts in 
% degrees 
if strcmp(distortiontype, 'bex')
    amp = amp/41.5;
end

totalnumberamp1 = reps*newamps; % number of trials on lowest amplitude
totalnumberamp8 = reps*files;   % number of trials in highest amplitude
totalnumber = reps*files + reps*newamps; % number of trials on all other amplitudes 

% Header
fprintf (datafilepointer,'%s\t %s\t %s\n', 'amplitude', 'nCorrect','ntrials');

% Save amplitude, number of correct responses and total number of trials
% tested at this amplitude in datapsignifit.csv file
if strcmp(exp, '1')
    for i = 1 : size(numbercorrect,1)
        for j = 1:size(numbercorrect,2)
            if j == 1
                num = totalnumberamp1;
            elseif j==8 
                num = totalnumberamp8;
            else 
                num = totalnumber; 
            end 
            fprintf(datafilepointer,'%f\t %i\t %i\n', ...
                amp(j),...
                numbercorrect(i,j),...
                num);
        end
    end
else
    % So far only the same amplitudes were used in experiment 3, thus every
    % amplitude is used in the same number of trials 
    numbercorrect = numbercorrectdistflanks0; 
    for i = 1 : 3 % 0,2,4 distorted flankers
        for j = 1:size(numbercorrect,2)
%             if j == 1
%                 num = totalnumberamp1;
%             elseif j==8 
%                 num = totalnumberamp8;
%             else 
%                 num = totalnumber; 
%             end 
            fprintf(datafilepointer,'%f\t %i\t %i\n', ...
                amp(j),...
                numbercorrect(1,j),...
                totalnumber);
        end
        if i == 1 
            numbercorrect = numbercorrectdistflanks2;
        else
            numbercorrect = numbercorrectdistflanks4;
        end
    end   
end
fclose('all');