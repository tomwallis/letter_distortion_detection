% Function to run a flanked/unflanked letter distortion detection experiment. 
% Six frequencies and 7 amplitude levels are tested. 
% 
% params: 
% - subject code:   identification of the observer 
% - flanked type: 
%   - unflanked: Stimuli consisting of 4 Sloan letters (D,H,K,N)
%   - flanked: Each letter is additionally flanked by 4 other letters (C,O,R,Z)
% - distortiontype: 
%   - bex: A spatial distortion method based on a method by Peter Bex
%     (Bex, P. J. (2010). (In) sensitivity to spatial distortion in natural
%      scenes. Journal of Vision, 10(2), 23:1-15.9
%   - rf: radial frequency modulation method based on a method by Dickinson
%     (Dickinson, J. E., Almeida, R. A., Bell, J. & Badcock, D. R. (2010). 
%      Global shape aftereffects have a local substrate: 
%      A tilt aftereffect field. Journal of Vision,10 (13), 2.)

function distortionexp1and2()
%% Parameters
session = 1;
% Run in the lab (true) or on a PC (false)
lab = true; 
forcedbreak = 70;

% Pause after "forcedbreak" trials for "breaksecs" seconds
breaksecs = 60;

% Trial durations in ms
ms_stim = 150;
ms_resp = 2000;
ms_iti = 100;
ms_fixation = 500;

img_size = [1024 1024];
bg_color = 0.5;
aud_volume = 0.5;

dist_monitor=600; % mm

% Degrees of visual angle of the stimulus
%LCD
deg_pic=2*atan(.5*img_size(1)*.252/dist_monitor)/pi*180;

%% Start the hardware
if lab 
    % LCD-initialization 
    win = window('lcd_gray', 'bg_color', bg_color);
    aud = dpixx_audio_port('volume', aud_volume);
    list_wait = listener_buttonbox('names', {'Red', 'Yellow', 'Green', 'Blue'});
    list_stop = listener_buttonbox('does_interrupt', true);
end

%% Calculate framecount per trial
if lab 
    n_frames_stim = ms_stim * win.framerate / 1000;
    n_frames_resp = ms_resp * win.framerate / 1000;
    n_frames_iti = ms_iti * win.framerate / 1000;
    n_frames_fixate = ms_fixation * win.framerate / 1000;
end

%% Generate sounds
if lab
    aud.create_beep('short_low', 'low', .15, 0.25);
    aud.create_beep('short_high', 'high', .15, 0.25);
end

%% Set file paths and open file to write to
filepathToHere=pwd;
dataPath = fullfile(filepathToHere, '../../raw-data');
imPath = fullfile(filepathToHere, '../stimuli/images/distorted');

%% Generate Fixationcross texture
if lab 
    filename = fullfile(filepathToHere, '../stimuli/fixationcross.png');
    imdata = im2double(imread(filename));
    fixationcross = win.make_texture(imdata);
end

% Ask for parameters:
subj = input('Enter subject code:','s');
flankedtype = input('Enter flanktype ("flanked" or "unflanked"):' ,'s');
if strcmp(flankedtype, 'unflanked')
    flanked = 0;
elseif strcmp(flankedtype, 'flanked')
    flanked = 1;
else
    fclose('all')
    error('No valid flanktype, please use "flanked" or "unflanked"');
end 
distortiontype = input('Enter distortiontype ("bex" or "rf"):', 's');
newamps = input('Use new amplitudes? (y/n):','s');

%% Set amplitudes and frequencies depending on the distortiontype
if strcmp(distortiontype, 'bex')
    distortion = 0; 
    if strcmp(newamps, 'y') | strcmp(newamps, 'yes') | strcmp(newamps, 'Y') | strcmp(newamps, 'Yes')
        amp = [0.25, 0.5, 1, 1.5, 2, 2.5, 3];
    else
        amp = [0.5, 1, 1.5, 2, 2.5, 3, 5];
    end
    freq = [2, 4, 6, 8, 16, 32];
elseif strcmp(distortiontype, 'rf')
    distortion = 1;
    if strcmp(newamps, 'y') | strcmp(newamps, 'yes') | strcmp(newamps, 'Y') | strcmp(newamps, 'Yes')
        amp = [0.0075, 0.01, 0.0617, 0.1133, 0.1650, 0.2167, 0.2683];
    else
        amp = [0.01, 0.0617, 0.1133, 0.1650, 0.2167, 0.2683, 0.3200];
    end
    freq = [2, 3, 4, 5, 8, 12];
else
    fclose('all')
    error('Distortiontype not known');
end

images = 0:9; %number of images with same frequency and amplitude

%number of repititions of the same stimuli 
%reps = input('Enter number of repititions:'); 
reps = 1; 

amplitudes = length(amp);
n_trials = amplitudes*length(images)*reps*length(freq); % number of trials

datafilename = fullfile(dataPath, strcat('distortionData_', flankedtype, '_', distortiontype, '_sub_',subj,'_session_',num2str(session),'.csv')); % name of data file to write to
% Check for existing result file to prevent accidentally overwriting files
% from a previous session
while fopen(datafilename, 'rt')~=-1
    fclose('all');
    warning('File already exists. Using next session number.');
    session = session +1;
    datafilename = fullfile(dataPath, strcat('distortionData_', flankedtype, '_', distortiontype, '_sub_',subj,'_session_',num2str(session),'.csv')); % name of data file to write to
end
datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing

%% PC properties (only tested on Windows) 
if lab == false
    screens=Screen('Screens');
    screenNumber=max(screens);
    HideCursor;
    % Get the mean gray value of screen:
    white=WhiteIndex(screenNumber);
    gray=GrayIndex(screenNumber);
    [w, wRect]=Screen('OpenWindow',screenNumber, white);
    Screen('TextSize',w, 15);
    
    % Keys for responding: arrow keys 
    KbName('UnifyKeyNames');
    left = KbName('LeftArrow');
    bottom = KbName('DownArrow');
    right = KbName('RightArrow');
    top = KbName('UpArrow');
    
    %% Create fixationcross texture
    filename = fullfile(filepathToHere, '../stimuli/fixationcross.png');
    imdata = imread(filename);
    fixationcross = Screen('MakeTexture', w, imdata);
    
    % Red/green fixation cross for feedback
    filename = fullfile(filepathToHere, '../stimuli/fixationcross_red.png');
    imdata = imread(filename);
    fixationcross_red = Screen('MakeTexture', w, imdata);
    
    filename = fullfile(filepathToHere, '../stimuli/fixationcross_green.png');
    imdata = imread(filename);
    fixationcross_green = Screen('MakeTexture', w, imdata);
end
%% Create random trial order
[dist, f, a, im_number] = BalanceFactors(reps, 1, distortion, freq, amp, images);

%% Trials
try
    for trial=1:n_trials
        % Save properties in data structure 
        data(trial).subj = str2num(subj);
        data(trial).session = session;
        data(trial).distortion = distortiontype;
        data(trial).trial = trial;
        data(trial).flanked = flankedtype;
        data(trial).freq = f(trial);
        data(trial).amplitude = a(trial);
        
        % Find images with given flankedtype, distortiontype, freq and amplitude
        flst = dir([fullfile(imPath, '*.png')]);
        flst={flst.name};
        this_imfile = strcat('^',flankedtype, '_', distortiontype, '_freq_', num2str(f(trial)), '_amplitude_', num2str(a(trial)), '_rep_', num2str(im_number(trial)));
        
        fl = regexp(flst,this_imfile);
        fl = ~cellfun('isempty',fl);
        files = flst(fl);
        
        if isempty(files)==false
            splitted_filename = textscan(char(files),'%s','delimiter','_');
            splitted_filename = splitted_filename{:};
        elseif length(files) > 1
            Screen('CloseAll');
            fclose('all');
            error('More than one filename starts with %s', this_imfile);
        else
            Screen('CloseAll');
            fclose('all');
            error('No file starting with %s', this_imfile);
        end
        
        % Save properties in data structure 
        data(trial).im_name = char(files);
        data(trial).targ_pos = splitted_filename{9};
        data(trial).response = 'n.a.';
        data(trial).em = 'n.a.';
        data(trial).RT= 0;
        
        if flanked == 1 % flanked filenames differ from unflanked in "spacing"
            data(trial).targ_letter = splitted_filename{10};
            splitted_filename = textscan(splitted_filename{11},'%s','delimiter','.');
            splitted_filename = splitted_filename{:};
            data(trial).spacing = str2num(splitted_filename{1});
        else
            splitted_filename = textscan(splitted_filename{10},'%s','delimiter','.');
            splitted_filename = splitted_filename{:};
            data(trial).targ_letter = splitted_filename{1};    
            data(trial).spacing = 0;
        end
        
        %% Show trial 
        if lab
            if trial == 1
                win.pause_trial(list_stop, ['Press any button to start!']); 
                for itic = 1 : n_frames_fixate
                    win.draw(fixationcross);
                    win.flip();
                end
            end
            
            % Inter trial interval
            for itic = 1 : n_frames_iti
                win.draw(fixationcross);
                win.flip();
            end
            
            % Stimulus interval
            filename = char(fullfile(imPath, files));
            imdata = im2double(imread(filename));
            texture = win.make_texture(imdata);
            for itic = 1 : n_frames_stim
                    win.draw(texture);
                    win.flip();
            end
            
            % Response interval
            list_wait.start();
            for itic = 1 : n_frames_resp
                win.draw(fixationcross);
                win.flip();
            end
            response = list_wait.stop();
         
            % Save the responses
            [press, rt] = response.get_presses('first');
            switch press
                case 1 
                    res = 'r'; 
                case 2
                    res = 't';
                case 3
                    res = 'l';
                case 4
                    res = 'b';  
                otherwise
                    res ='n.a.';
            end
                    
            data(trial).response = res; 
            data(trial).RT = rt;
            
            % Auditory feedback
            if data(trial).response == data(trial).targ_pos  
                aud.play('short_high');
            else
                aud.play('short_low');
            end
            
            % Forced break          
            if mod(trial,forcedbreak)==0 && trial~=n_trials
                sum = 0; 
                for icorr=(trial-(forcedbreak-1)):trial
                   if strcmp(data(icorr).response, data(icorr).targ_pos)
                        sum = sum+1;
                   end
                end
                perc_corr = (sum/forcedbreak)*100;
       
                for i=1:breaksecs 
                    win.draw_text(sprintf('%d out of %d trials correct. That corresponds to %.2f %% correct. \nYou should take a short break now! \n %d seconds left', sum,forcedbreak,perc_corr,breaksecs-i));
                    win.flip;
                    pause(1);
                end
                win.pause_trial(list_stop, sprintf('Block %d out of %d\n Press any button to continue', (trial/forcedbreak)+1, round(n_trials/forcedbreak)));   
                for itic = 1 : n_frames_fixate
                    win.draw(fixationcross);
                    win.flip();
                end
            end
            
            % Responded to last trial  
            if trial == n_trials
                win.pause_trial(list_stop, ['You are done! \nPress any button to end']);
            end
            Screen('Close', texture);
        
        % On a PC (only tested on Windows) 
        else
            if trial == 1
                [KeyIsDown, time, KeyCode]=KbCheck;
                spacebar = KbName('space');
                while(KeyCode(spacebar)==0)
                    message = 'Press the spacebar to start the experiment.';
                    DrawFormattedText(w, message, 'center', 'center', gray);
                    % Update the display to show the instruction text:
                    Screen('Flip', w);
                    [KeyIsDown, time, KeyCode]=KbCheck;
                    WaitSecs(0.001);
                end       
            end
            
            % Initialize variables
            [KeyIsDown, time, KeyCode]=KbCheck;
            if trial > 1
                if strcmp(data(trial-1).targ_pos, data(trial-1).response)
                    Screen('DrawTexture', w, fixationcross_green);
                else
                    Screen('DrawTexture', w, fixationcross_red);
                end
            else 
                Screen('DrawTexture', w, fixationcross);
            end
            
            [VBLTimestamp time]=Screen('Flip', w);
            
            % Show fixationcross 
            while (GetSecs - time)<=ms_iti/1000 
            end
            
            % Stimulus interval
            filename = char(fullfile(imPath, files));
            imdata = imread(filename);
            texture = Screen('MakeTexture', w, imdata);
            Screen('DrawTexture', w, texture);            
            [VBLTimestamp time]=Screen('Flip', w);
            % Show stimulus 
            while (GetSecs - time)<=ms_stim/1000 % change to seconds
            end
            
            % Response interval
            [KeyIsDown, startrt, KeyCode]=KbCheck;
            Screen('DrawTexture', w, fixationcross);
            [VBLTimestamp startrt]=Screen('Flip', w);            
            % Show fixationcross until a response is given or time is
            % elapsed
            while (GetSecs - startrt) <= (ms_resp/1000)
                while (KeyCode(left)==0 && KeyCode(bottom)==0 && KeyCode(right)==0 && KeyCode(top)==0)
                    [KeyIsDown, endrt, KeyCode]=KbCheck;
                    WaitSecs(0.001);
                end
            end
                               
            % Compute response time
            data(trial).RT=round(1000*(endrt-startrt));
            
            % Save response in data structure
            if KeyCode(left) == 1
                data(trial).response = 'l';
            elseif KeyCode(bottom) == 1
                data(trial).response = 'b';
            elseif KeyCode(right) == 1
                data(trial).response = 'r';
            elseif KeyCode(top) == 1
                data(trial).response = 't';
            else
                response = 'none';
            end
            
            % Forced break
            if mod(trial,forcedbreak)==0 && trial~=n_trials
                sum = 0; 
                for icorr=(trial-(forcedbreak-1)):trial
                   if strcmp(data(icorr).response, data(icorr).targ_pos)
                        sum = sum+1;
                   end
                end  
                perc_corr = (sum/forcedbreak)*100;
                for i=1:breaksecs 
                    message = sprintf('%d out of %d trials correct. That corresponds to %.2f %% correct. \nYou should take a short break now! \n %d seconds left',sum,forcedbreak,perc_corr,breaksecs-i);
                    DrawFormattedText(w, message, 'center', 'center', gray);
                    Screen('Flip', w);
                    WaitSecs(1.00);
                end
                
                while(KeyCode(spacebar)==0)
                    message = sprintf('Block %d out of %d.\n Press the spacebar to continue',(trial/forcedbreak)+1, round(n_trials/forcedbreak));
                    DrawFormattedText(w, message, 'center', 'center', gray);
                    Screen('Flip', w);
                    [KeyIsDown, time, KeyCode]=KbCheck;
                    WaitSecs(0.001);
                end
            end            
            
            % Last trial finished
            if trial == n_trials
                WaitSecs(0.50);
                message = 'You are done! \n This window will close automatically.';
                DrawFormattedText(w, message, 'center', 'center', gray);
                Screen('Flip', w);
                WaitSecs(2.00);
            end 
            Screen('Close', texture);
        end
    end
    if lab == false
        Screen('CloseAll');
    end
catch e
    fclose('all');
    Screen('CloseAll');
    rethrow(e);
end

%% Write results to file:

% Header
fprintf (datafilepointer,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n', 'subject', 'session','trial','flanked','distortion','freq','amplitude', 'spacing', 'im_name', 'targ_letter', 'targ_pos','response','eyemovement','RT');

% Size of data in structure
datasize = size(data);
datasize = datasize(2);

for i = 1 : datasize
    fprintf(datafilepointer,'%i\t %i\t %i\t %s\t %s\t %i\t %f\t %f\t %s\t %s\t %s\t %s\t %s\t %i\n', ...
        data(i).subj, ...
        data(i).session, ...
        data(i).trial,...
        data(i).flanked,...
        data(i).distortion,...
        data(i).freq,...
        data(i).amplitude,...
        data(i).spacing,...
        data(i).im_name,...
        data(i).targ_letter,...
        data(i).targ_pos,...
        data(i).response,...
        data(i).em,...
        data(i).RT);
end
%Screen('CloseAll'); 
fclose('all');
