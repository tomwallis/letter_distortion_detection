%% Clutter analysis
%
% The following script will load images from the letter distortions
% experiments of Wallis et al, and apply the "visual clutter metrics"
% proposed by Rosenholtz et al 2007.

% depends on the clutter code available from
% https://dspace.mit.edu/handle/1721.1/37593

% TSAW wrote it.

this_dir = pwd;
top_dir = this_dir(1:end-13);

expt_1_ims = [top_dir, 'code/stimuli/images/distorted/'];
expt_3_0_dist_flanks = [top_dir, 'code/stimuli/exp3img0flankersdistorted/distorted/'];
expt_3_2_dist_flanks = [top_dir, 'code/stimuli/exp3img2flankersdistorted/distorted/'];
expt_3_4_dist_flanks = [top_dir, 'code/stimuli/exp3img4flankersdistorted/distorted/'];

out_path = [top_dir, 'results/clutter_analysis/'];

if ~exist(out_path, 'dir')
    mkdir(out_path);
end

%% Experiment 1
letters = {'N', 'K', 'D', 'H'};
distortion_types = {'rf', 'bex'};
flanker_conds = {'flanked', 'unflanked'};

bex_freqs = [2, 4, 6, 8, 16, 32];
rf_freqs = [2, 3, 4, 5, 8, 12];
bex_amps = [0.25, 0.5, 1, 1.5, 2, 2.5, 3, 5];
rf_amps = [0.0075, 0.01, 0.165, 0.0617, 0.1133, 0.2167, 0.2683, 0.32];

% bex_freqs = 2;
% rf_freqs = 2;
% approximately flanked thresholds:
% bex_amps = 2;  
% rf_amps = 0.2167;

reps = 0:9;

target_locs = {'t', 'b', 'l', 'r'};

data = [];  % empty table

for i = 1 : length(letters)
    for j = 1 : length(flanker_conds)
        for k = 1 : length(distortion_types)
            
            if strcmp(distortion_types{k}, 'rf')
                freqs = rf_freqs;
                amps = rf_amps;
            elseif strcmp (distortion_types{k}, 'bex')
                freqs = bex_freqs;
                amps = bex_amps;
            end
            
            for l = 1 : length(freqs)
                for m = 1 : length(amps)
                    for n = 1 : length(reps)
                        for z  = 1 : length(target_locs)
                            
                            if strcmp(flanker_conds{j}, 'flanked')
                                
                                fname = sprintf('%s_%s_freq_%s_amplitude_%s_rep_%d_%s_%s_2.0.png',...
                                    flanker_conds{j}, distortion_types{k}, num2str(freqs(l)), num2str(amps(m)), ...
                                    reps(n), target_locs{z}, letters{i});
                                
                            else
                                fname = sprintf('%s_%s_freq_%s_amplitude_%s_rep_%d_%s_%s.png',...
                                    flanker_conds{j}, distortion_types{k}, num2str(freqs(l)), num2str(amps(m)), ...
                                    reps(n), target_locs{z}, letters{i});
                            end
                            
                            fname = [expt_1_ims, fname];
                            
                            if exist(fname, 'file')
                                im = imread(fname);
                                tmp_out = [out_path, 'tmp.png'];
                                rgb = [];
                                rgb(:, :, 1) = im;
                                rgb(:, :, 2) = im;
                                rgb(:, :, 3) = im;
                                imwrite(rgb, tmp_out);
                                % feature congestion:
                                [clutter_scalar_fc, clutter_map_fc] = getClutter_FC(tmp_out);
                                % subband entropy:
                                clutter_se = getClutter_SE(tmp_out);
                                
                                s = [];
                                s.letter = letters(i);
                                s.flanked = flanker_conds(j);
                                s.distortion = distortion_types(k);
                                s.freq = freqs(l);
                                s.amplitude = amps(m);
                                s.rep = reps(n);
                                s.FC = clutter_scalar_fc;
                                s.SE= clutter_se;
                                data = [data; struct2table(s)];
                            end
                        end
                    end
                end
            end
        end
    end
end

writetable(data, [out_path, 'expt_1_clutter_results.csv']);


%% Experiment 2
letters = {'N', 'K', 'D', 'H'};
distortion_types = {'rf', 'bex'};

bex_freqs = 4;
rf_freqs = 4;

bex_amps = [1, 2, 3, 4, 5, 6, 7];
rf_amps = [0.05, 0.125, 0.2, 0.275, 0.35, 0.425, 0.5];

% bex_amps = 7;
% rf_amps = 0.5;

num_distorted = [0, 2, 4];

reps = 0:9;

target_locs = {'t', 'b', 'l', 'r'};

data = [];  % empty table

for i = 1 : length(letters)
    for j = 1 : length(num_distorted)
        
        for k = 1 : length(distortion_types)
            
            if strcmp(distortion_types{k}, 'rf')
                freqs = rf_freqs;
                amps = rf_amps;
            elseif strcmp (distortion_types{k}, 'bex')
                freqs = bex_freqs;
                amps = bex_amps;
            end
            
            for l = 1 : length(freqs)
                for m = 1 : length(amps)
                    for n = 1 : length(reps)
                        for z  = 1 : length(target_locs)
                            fname = sprintf('flanked_%s_freq_%s_amplitude_%s_rep_%d_%s_%s_2.0.png',...
                                distortion_types{k}, num2str(freqs(l)), num2str(amps(m)), ...
                                reps(n), target_locs{z}, letters{i});
                            
                            if num_distorted(j) == 0
                                this_dir = expt_3_0_dist_flanks;
                            elseif num_distorted(j) == 2
                                this_dir = expt_3_2_dist_flanks;
                            elseif num_distorted(j) == 4
                                this_dir = expt_3_4_dist_flanks;
                            else
                                error('number of distorted flankers not known');
                            end
                            
                            fname = [this_dir, fname];
                            
                            if exist(fname, 'file')
                                im = imread(fname);
                                tmp_out = [out_path, 'tmp.png'];
                                rgb = [];
                                rgb(:, :, 1) = im;
                                rgb(:, :, 2) = im;
                                rgb(:, :, 3) = im;
                                imwrite(rgb, tmp_out);
                                % feature congestion:
                                [clutter_scalar_fc, clutter_map_fc] = getClutter_FC(tmp_out);
                                % subband entropy:
                                clutter_se = getClutter_SE(tmp_out);
                                
                                s = [];
                                s.letter = letters(i);
                                s.distortion = distortion_types(k);
                                s.freq = freqs(l);
                                s.amplitude = amps(m);
                                s.rep = reps(n);
                                s.n_dist_flanks = num_distorted(j);
                                s.FC = clutter_scalar_fc;
                                s.SE= clutter_se;
                                data = [data; struct2table(s)];
                            end
                        end
                    end
                end
            end
        end
    end
end

writetable(data, [out_path, 'expt_2_clutter_results.csv']);
