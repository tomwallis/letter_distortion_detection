%% Analyse data of experiment 3 using psignifit: Estimate psychometric 
% functions, thresholds, sensitivities and 95% confidence intervals for a certain
% datapsignifit.csv file (for a certain subjcect, distortiontype,
% flankedtype and experiment) and save the analysis under 
% '../../results/sensitivitydata/Experiment3x_disttype_analysis_subj.csv'
%
% Parameters: 
% Select the datapsignifit.csv data file of experiment 3a
% distortiontype: bex / rf
% subject: observer identification 
% exp: a: 0,2,4 distorted flankers + distorted target
%      b: all letters distorted except the target
%      c: same as a, but flankers amplitude was fixed at a high level
%
function analysisexp3()
clear all; 

% Directory to save data file to 
filepathToHere = pwd;
pathsave = fullfile(filepathToHere, '../../results/sensitivitydata');

[filename, pathname] = uigetfile('*.csv', 'Select the 3a datapsignifit.csv file');

% Ask for parameters
distortiontype = input('Enter distortiontype ("Bex" or "RF"):', 's');
subj = input('Enter subject:', 's');
exp = input('Enter Experiment (a/b/c):', 's');

% Estimate confidence intervals and thresholds for each experimental 
% condition 
if strcmp(exp,'a')
    [confi, threshold] = GetThreshConfi(filename, pathname, 3); 
    xlab = 'Number of distorted Flankers';
    xt = [0,2,4];
    x = [0,2,4];
elseif strcmp(exp,'b')
    [filename3b, pathname3b] = uigetfile('*.csv', 'Select the 3b datapsig csv data file');
    [confi, threshold] = GetThreshConfi(filename, pathname, 3); 
    [confi3b, threshold3b] = GetThreshConfi(filename3b, pathname3b, 1); 
    xlab = 'Number of distorted Flankers'
    xt = [0,2,4];
    x = [0,2,4];
else
    [filename3b, pathname3b] = uigetfile('*.csv', 'Select the 3b datapsig csv data file');
    [filename3c, pathname3c] = uigetfile('*.csv', 'Select the 3c datapsig csv data file');
    [confi, threshold] = GetThreshConfi(filename, pathname, 3); 
    [confi3b, threshold3b] = GetThreshConfi(filename3b, pathname3b, 1); 
    [confi3c, threshold3c] = GetThreshConfi(filename3c, pathname3c, 1); 
    xlab = 'Number of distorted Flankers'
    xt = [0,2,4];
    x = [0,2,4];   
end

% calculate sensitivity for exp. 3a as the inverse of the threshold
sensitivity = 1./threshold
sensconfi = 1./confi

% calculate sensitivity for exp. 3b as the inverse of the threshold
if strcmp(exp, 'b')|strcmp(exp, 'c')
    sensitivity3b = 1./threshold3b
    sensconfi3b = 1./confi3b
end

% calculate sensitivity for exp. 3c as the inverse of the threshold
if strcmp(exp, 'c')
    sensitivity3c = 1./threshold3c
    sensconfi3c = 1./confi3c
end


%% Plots
% Plot thresholds as function of distortion frequencies
figure('NumberTitle','off','Name',['Threshold of distortion frequencies - ', distortiontype]); 
hold on;
xlabel('Number of distorted flankers', 'FontSize',12);
ylabel('Modulation amplitude', 'FontSize',12);
title([subj, ' ', distortiontype, ' distortion'], 'FontSize', 12);
XTick = [0,2,4];
h1 = errorbar([0,2,4], threshold, threshold' - confi(:,1), confi(:,2)-threshold', 'og');
if strcmp(exp, 'b')
    h2 = errorbar([4], threshold3b, threshold3b' - confi3b(:,1), confi3b(:,2)-threshold3b', 'xr');
    hleg = legend([h1,h2], 'exp3a', 'exp3b');
    set(hleg,'Location','NorthWest')
end
set(gca,'XTick',XTick,'FontSize',12);
hold off;

% Plot sensitivities as function of distortion frequencies
figure('NumberTitle','off','Name',['Sensitivity to distortion frequencies - ', distortiontype]); 
hold on;
xlabel('Number of distorted flankers', 'FontSize',12);
ylabel('Sensitivity', 'FontSize',12);
title([subj, ' ', distortiontype, ' distortion'], 'FontSize', 12);
XTick = [0,2,4];
s1 = errorbar([0,2,4], sensitivity, sensitivity' - sensconfi(:,2), sensconfi(:,1)-sensitivity', 'og');
if strcmp(exp, 'b')
    s2 = errorbar([4], sensitivity3b, sensitivity3b' - sensconfi3b(:,2), sensconfi3b(:,1)-sensitivity3b', 'xr');
    sleg = legend([s1,s2], 'exp3a', 'exp3b');
    set(sleg,'Location','NorthEast')
end
set(gca,'XTick',XTick,'FontSize',12);
hold off;

% Name of the datafile to write to 
datafilename = fullfile(pathsave, strcat('Experiment3', exp, '_', distortiontype, '_analysis_subj_', subj, '.csv')); 
% Check for existing result file to prevent accidentally overwriting files
% from a previous session
while fopen(datafilename, 'rt')~=-1
    fclose('all');
    error('File already exists.');
end
datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing

% Header
fprintf (datafilepointer,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n', 'subject', 'distortiontype','exp3','sens', 'sensconfi_low', 'sensconfi_high', 'threshold', 'threshconfi_low','threshconfi_high', 'distflanker');

% Write thresholds, sensitivities, confidence intervals to datafile
sensconfi_low = sensitivity' - sensconfi(:,2);
sensconfi_high = sensconfi(:,1)-sensitivity';
threshconfi_low = threshold' - confi(:,1);
threshconfi_high = confi(:,2)-threshold';

for j = 1:3 %0,2,4 flankers distorted
    fprintf(datafilepointer,'%s\t %s\t %s\t %f\t %f\t %f\t %f\t %f\t %f\t %d\n', ...
        subj,...
        distortiontype,...
        'a',...
        sensitivity(j),...
        sensconfi_low(j),...
        sensconfi_high(j),...
        threshold(j),...
        threshconfi_low(j),...
        threshconfi_high(j),...
        (j-1)*2);
end

% Write thresholds, sensitivites and cinfidence interval of Experiment 3b
% to the file
if strcmp(exp,'b')|strcmp(exp,'c')
    sensconfi3b_low = sensitivity3b' - sensconfi3b(:,2);
    sensconfi3b_high = sensconfi3b(:,1)-sensitivity3b';
    threshconfi3b_low = threshold3b' - confi3b(:,1);
    threshconfi3b_high = confi3b(:,2)-threshold3b';
    
    for j=1:1 %4 flankers + all lettters distorted except target
        fprintf(datafilepointer,'%s\t %s\t %s\t %f\t %f\t %f\t %f\t %f\t %f\t %d\n', ...
            subj,...
            distortiontype,...
            'b',...
            sensitivity3b(j),...
            sensconfi3b_low(j),...
            sensconfi3b_high(j),...
            threshold3b(j),...
            threshconfi3b_low(j),...
            threshconfi3b_high(j),...
            4);
    end
end

% Write thresholds, sensitivites and cinfidence interval of Experiment 3c
% to the file
if strcmp(exp,'c')
    sensconfi3c_low = sensitivity3c' - sensconfi3c(:,2);
    sensconfi3c_high = sensconfi3c(:,1)-sensitivity3c';
    threshconfi3c_low = threshold3c' - confi3c(:,1);
    threshconfi3c_high = confi3c(:,2)-threshold3c';
   
    for j=1:1 %4 flankers distorted at high amplitude + 1 letter distorted with varying amplitude
        fprintf(datafilepointer,'%s\t %s\t %s\t %f\t %f\t %f\t %f\t %f\t %f\t %d\n', ...
            subj,...
            distortiontype,...
            'c',...
            sensitivity3c(j),...
            sensconfi3c_low(j),...
            sensconfi3c_high(j),...
            threshold3c(j),...
            threshconfi3c_low(j),...
            threshconfi3c_high(j),...
            4);
    end
end

fclose(datafilepointer);

end

%% Fit data for all frequencies and return confidence interval and threshold
%
% Parameters: 
% filename: name of the datapsignifit.csv file 
% pathname: path where the respective datapsignifit.csv file can be found 
% freqidxlen: for experiment 3a: 3 (0,2, 4 distorted flanker conditions)    
%             for experiment 3b/c: 1 (4 distorted flanker condition)    
% Return: 
% cinfi: 95% confidence interval of the thresholds
% threshold: thresholds for the different frequencies 
%

function [ confi, threshold ] = GetThreshConfi(filename, pathname, freqidxlen)
    % initialize variables, skip headerline
    [amp, nCorrect, total] = textread(fullfile(pathname, filename), '%f %d %d', 'headerlines', 1);  

    % Get all 6 amplitude levels
    for freqidx = 1: freqidxlen
        freq = (freqidx-1)*7+1;
        data = [...
            amp(freq), nCorrect(freq), total(freq);...
            amp(freq+1), nCorrect(freq+1), total(freq+1);...
            amp(freq+2), nCorrect(freq+2), total(freq+2);...
            amp(freq+3), nCorrect(freq+3), total(freq+3);...
            amp(freq+4), nCorrect(freq+4), total(freq+4);...
            amp(freq+5), nCorrect(freq+5), total(freq+5);...
            amp(freq+6), nCorrect(freq+6), total(freq+6)];

        %% Construct an options struct
        options             = struct;   % initialize as an empty struct

        % Set the different options 
        options.sigmoidName = 'norm';   % choose a cumulative Gauss as the sigmoid
        options.expType     = 'nAFC';   % choose 4-AFC as the paradigm of the experiment
        options.expN    = 4;            % this sets the guessing rate to .25 and

        %% Run psignifit
        res = psignifit(data,options);
        
        %% Return results (thresholds and confidence intervals)
        threshold(freqidx) = res.Fit(1);
        [conf_int, conf_region] = getConfRegion(res);
        confi(freqidx,:) = conf_int(1,:);

        % calculates the correlation matrix 
        %cor = getCor(res);

        %% remark for insufficient memory issues
        result = rmfield(res,{'Posterior','weight'});
    end
end
