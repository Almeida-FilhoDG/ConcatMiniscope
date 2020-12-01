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

%%
load(strcat(path,filesep,'concatInfo.mat'));


%%
NFramesSess = concatInfo.NumberFramesSessions;
NSessions = length(NFramesSess);
load(strcat(path,filesep,'neuronFull.mat'),'neuron');
load(strcat(path,filesep,'msConcat.mat'),'ms');

valid_roi = logical(ones(size(neuron.C,1),1));
if exist(strcat(path,filesep,'validROIs.mat'))
    load(strcat(path,filesep,'validROIs.mat'));
end
%% Create Video
Video = read_file(strcat(path,filesep,'ConcatenatedVideo.avi'));
%%
for vid = 1:NSessions
    newObj=VideoWriter(strcat(path,filesep,['msvideo' num2str(vid) '.avi']),'Grayscale AVI');
    open(newObj);
    in = sum(NFramesSess(1:vid))-NFramesSess(vid)+1;
    out = sum(NFramesSess(1:vid));
    writeVideo(newObj,Video(:,:,in:out));
    close(newObj);
    
    
    %%%%%% Compute activity
    
    file_to_the_raw_data=strcat(path,filesep,['msvideo' num2str(vid) '.avi']);
    load(strcat(path,filesep,'neuronFull.mat'),'neuron');
    neuron.A = neuron.A + 1e-6;
    %%%%%%%%%%%% Parameters
    neuron.select_data(file_to_the_raw_data);  % neuron is the result from Y_new
    if isfield(ms,'pars_envs')
        pars_envs = ms.pars_envs;
    else
        pars_envs = struct('memory_size_to_use', 50, ...   % GB, memory space you allow to use in MATLAB
            'memory_size_per_patch', 4.0, ...   % GB, space for loading data within one patch
            'patch_dims', [42, 42]);  %GB, patch size
    end

    neuron.getReady(pars_envs);
    neuron.initTemporal();
    
    delete(strcat(path,filesep,'msvideo*'))
    [status, message, ~] = rmdir(strcat(path,filesep,'msvideo*'),'s');
    
    
    %%%%% Get important variables (C and C_raw)
    
    tempNeuron.C = neuron.C(valid_roi,:);
    tempNeuron.C_raw = neuron.C_raw(valid_roi,:);
    clear neuron
    neuron = tempNeuron;
    save(strcat(path,filesep,['neuronVid_' num2str(vid) '.mat']),'neuron')
    
end

