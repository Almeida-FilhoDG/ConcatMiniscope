function getActivity(path)
% Function to project the raw and deconvolved activity of data acquired
% through the CNMF-E algorithm using the ConcatMiniscope pipeline.
%
% INPUT:
%   path: path of the folder containing the dataset to be treated. Outputs
%   will be saved to the folder as ".mat" files with the name
%   "neuronVid_X.mat", where X is the index of the video in the same
%   position as concatenated.
%
% Developed by Daniel Almeida Filho (Jun, 2020) almeidafilhodg@ucla.edu
% almeidafilhodg@ucla.edu
%% Auto-detect operating system
if ispc
    separator = '\'; % For pc operating systems
else
    separator = '/'; % For unix (mac, linux) operating systems
end
%%
load(strcat(path,separator,'concatInfo.mat'));


%%
NFramesSess = concatInfo.NumberFramesSessions;
NSessions = length(NFramesSess);
load(strcat(path,separator,'neuronFull.mat'),'neuron');

valid_roi = logical(ones(size(neuron.C,1),1));
if exist(strcat(path,separator,'validROIs.mat'))
    load(strcat(path,separator,'validROIs.mat'));
end
%% Create Video
Video = read_file(strcat(path,separator,'FinalConcatVideo.avi'));
%%
for vid = 1:NSessions
    newObj=VideoWriter(strcat(path,separator,['msvideo' num2str(vid) '.avi']),'Grayscale AVI');
    open(newObj);
    in = sum(NFramesSess(1:vid))-NFramesSess(vid)+1;
    out = sum(NFramesSess(1:vid));
    writeVideo(newObj,Video(:,:,in:out));
    close(newObj);
    
    
    %%%%%% Compute activity
    
    file_to_the_raw_data=strcat(path,separator,['msvideo' num2str(vid) '.avi']);
    load(strcat(path,separator,'neuronFull.mat'),'neuron');
    neuron.A = neuron.A + 1e-6;
    %%%%%%%%%%%% Parameters
    neuron.select_data(file_to_the_raw_data);  % neuron is the result from Y_new
    pars_envs = struct('memory_size_to_use', 50, ...   % GB, memory space you allow to use in MATLAB
        'memory_size_per_patch', 4.0, ...   % GB, space for loading data within one patch
        'patch_dims', [42, 42]);  %GB, patch size
    % -------------------------      SPATIAL      -------------------------  %
    include_residual = false; % If true, look for neurons in the residuals
    gSig = 3;           % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
    gSiz = 15;          % pixel, neuron diameter
    ssub = 2;          % spatial downsampling factor
    with_dendrites = false;   % with dendrites or not
    if with_dendrites
        % determine the search locations by dilating the current neuron shapes
        updateA_search_method = 'dilate';  %#ok<UNRCH>
        updateA_bSiz = 5;
        updateA_dist = neuron.options.dist;
    else
        % determine the search locations by selecting a round area
        updateA_search_method = 'ellipse'; %#ok<UNRCH>
        updateA_dist = 5;
        updateA_bSiz = neuron.options.dist;
    end
    spatial_constraints = struct('connected', true, 'circular', false);  % you can include following constraints: 'circular'
    spatial_algorithm = 'hals_thresh';
    
    % -------------------------      TEMPORAL     -------------------------  %
    Fs = 30;             % frame rate
    tsub = 5;           % temporal downsampling factor
    deconv_flag = false; % Perform deconvolution if it's true
    
    nk = 3;             % detrending the slow fluctuation. usually 1 is fine (no detrending)
    % when changed, try some integers smaller than total_frame/(Fs*30)
    detrend_method = 'spline';  % compute the local minimum as an estimation of trend.
    
    % -------------------------     BACKGROUND    -------------------------  %
    bg_model = 'ring';  % model of the background {'ring', 'svd'(default), 'nmf'}
    nb = 1;             % number of background sources for each patch (only be used in SVD and NMF model)
    ring_radius = 20;  % when the ring model used, it is the radius of the ring used in the background model.
    %otherwise, it's just the width of the overlapping area
    num_neighbors = []; % number of neighbors for each neuron
    
    % -------------------------      MERGING      -------------------------  %
    show_merge = false;  % if true, manually verify the merging step
    merge_thr = 0.65;     % thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
    method_dist = 'max';   % method for computing neuron distances {'mean', 'max'}
    dmin = 5;       % minimum distances between two neurons. it is used together with merge_thr
    dmin_only = 2;  % merge neurons if their distances are smaller than dmin_only.
    merge_thr_spatial = [0.8, 0.4, -inf];  % merge components with highly correlated spatial shapes (corr=0.8) and small temporal correlations (corr=0.1)
    
    % -------------------------  INITIALIZATION   -------------------------  %
    K = [];             % maximum number of neurons per patch. when K=[], take as many as possible.
    min_corr = 0.7;     % minimum local correlation for a seeding pixel, default 0.8
    min_pnr = 7;       % minimum peak-to-noise ratio for a seeding pixel
    min_pixel = gSig^2;      % minimum number of nonzero pixels for each neuron
    bd = 5;             % number of rows/columns to be ignored in the boundary (mainly for motion corrected data)
    frame_range = [];   % when [], uses all frames
    save_initialization = false;    % save the initialization procedure as a video.
    use_parallel = true;    % use parallel computation for parallel computing
    show_init = false;   % show initialization results
    choose_params = false; % manually choose parameters
    center_psf = true;  % set the value as true when the background fluctuation is large (usually 1p data)
    % set the value as false when the background fluctuation is small (2p)
    
    % -------------------------  Residual   -------------------------  %
    min_corr_res = 0.6; % Default 0.7
    min_pnr_res = 7;
    seed_method_res = 'auto';  % method for initializing neurons from the residual
    update_sn = true;
    
    % ----------------------  WITH MANUAL INTERVENTION  --------------------  %
    with_manual_intervention = false;
    
    % -------------------------    UPDATE ALL    -------------------------  %
    neuron.updateParams('gSig', gSig, ...       % -------- spatial --------
        'gSiz', gSiz, ...
        'ring_radius', ring_radius, ...
        'ssub', ssub, ...
        'search_method', updateA_search_method, ...
        'bSiz', updateA_bSiz, ...
        'dist', updateA_bSiz, ...
        'spatial_constraints', spatial_constraints, ...
        'spatial_algorithm', spatial_algorithm, ...
        'tsub', tsub, ...                       % -------- temporal --------
        'deconv_flag', deconv_flag, ...
        'nk', nk, ...
        'detrend_method', detrend_method, ...
        'background_model', bg_model, ...       % -------- background --------
        'nb', nb, ...
        'ring_radius', ring_radius, ...
        'num_neighbors', num_neighbors, ...
        'merge_thr', merge_thr, ...             % -------- merging ---------
        'dmin', dmin, ...
        'method_dist', method_dist, ...
        'min_corr', min_corr, ...               % ----- initialization -----
        'min_pnr', min_pnr, ...
        'min_pixel', min_pixel, ...
        'bd', bd, ...
        'center_psf', center_psf);
    neuron.Fs = Fs;
    
    neuron.getReady(pars_envs);
    neuron.initTemporal();
    
    delete(strcat(path,separator,'msvideo*'))
    [status, message, ~] = rmdir(strcat(path,separator,'msvideo*'),'s');
    
    
    %%%%% Get important variables (C and C_raw)
    
    tempNeuron.C = neuron.C(valid_roi,:);
    tempNeuron.C_raw = neuron.C_raw(valid_roi,:);
    clear neuron
    neuron = tempNeuron;
    save(strcat(path,separator,['neuronVid_' num2str(vid) '.mat']),'neuron')
    
end

