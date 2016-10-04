%% Analyse data of experiment 1/2 using psignifit: Estimate psychometric 
% functions, thresholds, sensitivities and 95% confidence intervals for a certain
% datapsignifit.csv file (for a certain subjcect, distortiontype,
% flankedtype and experiment) and save the analysis under 
% '../../results/sensitivitydata/disttype_analysis_subj.csv'
%
% Parameters: 
% Select the unflanked datapsignifit.csv data file
% Select the flanked datapsignifit.csv data file
% distortiontype: bex / rf
% subject: observer identification 

function analysis()
clear all;

% Directory to save data file to 
filepathToHere=pwd;
pathname = fullfile(filepathToHere, '../../results/sensitivitydata');

[filenameuf, pathnameuf] = uigetfile('*.csv', 'Select the unflanked datapsignifit.csv data file');
[filenamef, pathnamef] = uigetfile('*.csv', 'Select the flanked datapsignifit.csv data file');

distortiontype = input('Enter distortiontype ("Bex" or "RF"):', 's');
subj = input('Enter subject:', 's');

% Set amplitudes and frequencies depending on the distortion type 
if strcmp(distortiontype, 'Bex') | strcmp(distortiontype, 'bex')
    frequency = [1.3, 2.6, 4, 5.3, 10.6, 21.3];
    xlab = 'Distortion frequency (c/deg)';
    location = 'SouthEast';
elseif strcmp(distortiontype, 'RF') | strcmp(distortiontype, 'rf')
    frequency = [2,3,4,5,8,12];
    xlab = 'modulation frequency (cycles in 2 \pi)';
    location = 'NorthEast';
else
    close('all');
    error('distortiontype not known');
end

% Estimate confidence intervals and thresholds for the unflanked and
% flanked condition using psignifit
[confiuf, thresholduf] = GetThreshConfi(filenameuf, pathnameuf, false);
[confif, thresholdf] = GetThreshConfi(filenamef, pathnamef, true);

% Calculate sensitivity as the inverse of the threshold 
sensitivityuf = 1./thresholduf;
sensitivityf = 1./thresholdf;
sensconfiuf = 1./confiuf;
sensconfif = 1./confif;

%% Plots
% Plot thresholds as function of distortion frequencies
figure('NumberTitle','off','Name',['Threshold of distortion frequencies - ', distortiontype]);
hold on;
xlabel(xlab, 'FontSize',12);
ylabel('Modulation amplitude', 'FontSize',12);
title([subj, ' ', distortiontype, ' distortion'], 'FontSize', 12);
h1 = errorbar(frequency, thresholduf, thresholduf' - confiuf(:,1), confiuf(:,2)-thresholduf', 'og');
h2 = errorbar(frequency, thresholdf, thresholdf' - confif(:,1), confif(:,2)-thresholdf', 'xr');
hleg = legend([h1,h2], 'threshold unflanked', 'threshold flanked');
set(hleg,'Location',location)
grid on
hold off;

% Plot sensitivities as function of distortion frequencies
figure('NumberTitle','off','Name',['Sensitivity to distortion frequencies - ', distortiontype]);
hold on;
xlabel(xlab, 'FontSize',12);
ylabel('Sensitivity', 'FontSize',12);
title([subj, ' ', distortiontype, ' distortion'], 'FontSize', 12);
axis([0 23 0 75]);
s1 = errorbar(frequency, sensitivityuf, sensitivityuf' - sensconfiuf(:,2), sensconfiuf(:,1)-sensitivityuf', 'og');
s2 = errorbar(frequency, sensitivityf, sensitivityf' - sensconfif(:,2), sensconfif(:,1)-sensitivityf', 'xr');
sleg = legend([s1,s2], 'unflanked', 'flanked');
grid on

if strcmp(distortiontype,'RF') | strcmp(distortiontype,'rf')
    axis([1, 13, 1, 30]);
    set(sleg,'Location','South')
else
    set(sleg,'Location','NorthEast')
end

grid on
hold off;

% Name of the datafile to write to 
datafilename = fullfile(pathname, strcat(distortiontype, '_analysis_subj_', subj, '.csv')); 
% Check for existing result file to prevent accidentally overwriting files
% from a previous session
while fopen(datafilename, 'rt')~=-1
    fclose('all');
    error('File already exists.');
end
datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing

% Header
fprintf (datafilepointer,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n', 'subject', 'distortiontype','flanked','freq','sens', 'sensconfi_low', 'sensconfi_high', 'threshold', 'threshconfi_low','threshconfi_high');

% Write thresholds, sensitivities, confidence intervals to datafile 
sens = sensitivityuf;
sensconfi_low = sensitivityuf' - sensconfiuf(:,2);
sensconfi_high = sensconfiuf(:,1)-sensitivityuf';
threshold = thresholduf;
threshconfi_low = thresholduf' - confiuf(:,1);
threshconfi_high = confiuf(:,2)-thresholduf';
flanked = 'unflanked';

for i = 1:2
    if i == 2
        sens = sensitivityf;
        sensconfi_low = sensitivityf' - sensconfif(:,2);
        sensconfi_high = sensconfif(:,1)-sensitivityf';
        threshold = thresholdf;
        threshconfi_low = thresholdf' - confif(:,1);
        threshconfi_high = confif(:,2)-thresholdf';
        flanked = 'flanked';
    end
    for j = 1:length(frequency)
        fprintf(datafilepointer,'%s\t %s\t %s\t %f\t %f\t %f\t %f\t %f\t %f\t %f\n', ...
            subj,...
            distortiontype,...
            flanked,...
            frequency(j),...
            sens(j),...
            sensconfi_low(j),...
            sensconfi_high(j),...
            threshold(j),...
            threshconfi_low(j),...
            threshconfi_high(j));
    end
end
fclose(datafilepointer);
end


%% Fit data for all frequencies and return confidence interval and threshold
%
% Parameters: 
% filename: name of the datapsignifit.csv file 
% pathname: path where the respective datapsignifit.csv file can be found 
% flanked: true/false (datapsignifit.csv file containing flanked/unflanked
%          data)
%
% Return: 
% cinfi: 95% confidence interval of the thresholds
% threshold: thresholds for the different frequencies 
%
function [ confi, threshold ] = GetThreshConfi(filename, pathname, flanked)
% Initialize variables, skip headerline
[amp, nCorrect, total] = textread(fullfile(pathname, filename), '%f %d %d', 'headerlines', 1);

% Get all 7 amplitude levels for all 6 frequencies
for freqidx = 1: 6
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
    options.expN    = 4;            % this sets the guessing rate to .25    
    
    %% Run psignifit
    res = psignifit(data,options);
    
    %% Return results (thresholds and confidence intervals)
    threshold(freqidx) = res.Fit(1);
    [conf_int, conf_region] = getConfRegion(res);
    confi(freqidx,:) = conf_int(1,:);
    
    % Plot results using the plotPsych function 
    if freqidx == 3 & flanked
        plotOpts = struct;
        plotOpts.dataColor = [27/255,158/255,119/255]; %green, flanked condition exp2
        plotOpts.xLabel= 'Amplitude';
        plotOpts.lineColor = [27/255,158/255,119/255];
        plotPsych(res,gca,plotOpts);
        %plotOpts.tufteAxis = false;
    elseif freqidx == 3 & ~flanked
        plotOpts2 = struct;
        plotOpts2.dataColor = [217/255,95/255,2/255]; %orange, unflanked condition exp1 
        plotOpts2.lineColor = [217/255,95/255,2/255];
        plotPsych(res,gca,plotOpts2);
        %plotOpts.tufteAxis = false;
    end
    
    % calculates the correlation matrix
    %cor = getCor(res);
    
    %% remark for insufficient memory issues
    result = rmfield(res,{'Posterior','weight'});
end
end
