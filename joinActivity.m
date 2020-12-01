function joinActivity(path,order,flag)
% Function to join the raw trace and the calculated activity of each cell 
% across all the sessions concatenated.This function is part of the 
% pipeline ConcatMiniscope.
%
% INPUTS:
%   path: path of the folder containing the dataset to be treated. Outputs
%   will be loaded from and saved back to the folder.
%   order: Vector of positive integers with the same length as the number
%   of sessions. This indicates the order of sessions for the downstream
%   analysis. (Default is the same order as the neuronVid files).
%   flag: Scalar with the code to define the method of calculation of 
%   neuronal putative activity that will be used for the downstream analysis. 
%   0 => Use the Convolution first derivative method (convolve1D)); 
%   1 => Use the Foopsi Thresholded method (CalcFoopsiThresh); (Default = 0).
%  
% Developed by Daniel Almeida Filho (Jun, 2020) almeidafilhodg@ucla.edu



files = dir([path filesep 'neuronVid*']);
nFiles = length(files);
load(strcat(path,filesep,'NoisyCells.mat'),'NoisyCells')
if nargin < 3
    flag = 0;
    if nargin<2
        order = 1:nFiles;
    end
end

for i = 1:nFiles
    load([path filesep files(i).name],'neuron');
    nNeurs = size(neuron.C,1);
    idxValids = true(1,nNeurs);
    idxValids(NoisyCells) = false;
    concatResult.C_raw{order(i)} = neuron.C_raw(idxValids,:);
    if flag == 0
        concatResult.FR{order(i)} = neuron.convolve1D(idxValids,:);
    else
        concatResult.FR{order(i)} = neuron.FoopThresh(idxValids,:);
    end
end

save(strcat(path,filesep,'concatResult.mat'),'concatResult')