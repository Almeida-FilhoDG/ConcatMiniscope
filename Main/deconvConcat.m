function deconvConcat(path,fps,dSFactor,flag)
% Function to calculate the putative activity of neurons from raw calcium
% traces. This function is part of the pipeline ConcatMiniscope.
%
% INPUTS:
%   path: path of the folder containing the dataset to be treated. Outputs
%   will be loaded from and saved back to the folder.
%   fps: positive scalar with sampling rate of the recordings in frames per second.
%   dSFactor: positive scalar with the downsampling factor for improving
%   the activity definition.
%   flag: Scalar with the code to define the method to be used for
%   acquiring neuronal putative activity. 0 => Use the Convolution first
%   derivative method (convolve1D)); 1 => Use the Foopsi Thresholded method
%   (CalcFoopsiThresh); 2 => Use ans save both methods. (Default = 2).
%
% Developed by Daniel Almeida Filho (Jun, 2020) almeidafilhodg@ucla.edu

if nargin<4
    flag = 2;
end


files = dir([path filesep 'neuronVid*']);
nFiles = length(files);


for i = 1:nFiles
    load([path filesep files(i).name],'neuron');
    if isempty(neuron)
        continue
    end
    actual = neuron.C_raw;
    if flag == 0 || flag == 2
        [neuron.convolve1D,neuron.HighNoiseNeurons] = convolve1D(actual,fps,dSFactor);
    end
    if flag == 1 || flag == 2
        neuron.FoopThresh = CalcFoopsiThresh(actual,dSFactor);
    end
    save([path filesep files(i).name],'neuron');
end


%%% Checking if there are files ran by the Proj method
files = dir([path filesep 'neuronProj*']);

if ~isempty(files)
    nFiles = length(files);
    
    
    for i = 1:nFiles
        load([path filesep files(i).name],'neuron');
        if isempty(neuron)
            continue
        end
        actual = neuron.C_raw;
        if flag == 0 || flag == 2
            [neuron.convolve1D,neuron.HighNoiseNeurons] = convolve1D(actual,fps,dSFactor);
        end
        if flag == 1 || flag == 2
            neuron.FoopThresh = CalcFoopsiThresh(actual,dSFactor);
        end
        save([path filesep files(i).name],'neuron');
    end
end