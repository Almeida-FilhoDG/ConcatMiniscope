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
%   1 => Use the Foopsi Thresholded method (CalcFoopsiThresh); (Default = 1).
%
% Developed by Daniel Almeida Filho (Jun, 2020) almeidafilhodg@ucla.edu
% Updated by by Daniel Almeida Filho (Aug, 2021) to account for discarded
% sessions.


files = dir([path filesep 'neuronVid*']);
files2 = struct2cell(files);
files2 = files2(1,:);
[~,filesOrder] = natsort(files2);
files = files(filesOrder);


nFiles = length(files);
load(strcat(path,filesep,'NoisyCells.mat'),'NoisyCells')
if nargin < 3
    flag = 1;
    if nargin<2
        order = 1:nFiles;
    end
end

for i = 1:nFiles
    load([path filesep files(i).name],'neuron');
    if isempty(neuron)
        continue
    else
        nNeurs = size(neuron.C_raw,1);
        break
    end
end

for i = 1:nFiles
    load([path filesep files(i).name],'neuron');
    %     nNeurs = size(neuron.C_raw,1);
    if isempty(neuron)
        concatResult.C_raw{order(i)} = [];
        concatResult.FR{order(i)} = [];
        continue
    else
        idxValids = true(1,nNeurs);
        idxValids(NoisyCells) = false;
        concatResult.C_raw{order(i)} = neuron.C_raw(idxValids,:);
        if flag == 0
            concatResult.FR{order(i)} = neuron.convolve1D(idxValids,:);
        else
            concatResult.FR{order(i)} = neuron.FoopThresh(idxValids,:);
        end
    end
end

%%% Checking if there are files ran by the Proj method
files = dir([path filesep 'neuronProj*']);

if ~isempty(files)
    files2 = struct2cell(files);
    files2 = files2(1,:);
    [~,filesOrder] = natsort(files2);
    files = files(filesOrder);
    nFiles = length(files);
    load(strcat(path,filesep,'NoisyCellsProj.mat'),'NoisyCells')
    for i = 1:nFiles
        load([path filesep files(i).name],'neuron');
        if isempty(neuron)
            continue
        else
            nNeurs = size(neuron.C_raw,1);
            break
        end
    end
    for i = 1:nFiles
        load([path filesep files(i).name],'neuron');
        %         nNeurs = size(neuron.C_raw,1);
        if isempty(neuron)
            concatResult.Proj.C_raw{order(i)} = [];
            concatResult.Proj.FR{order(i)} = [];
            continue
        else
            idxValids = true(1,nNeurs);
            idxValids(NoisyCells) = false;
            concatResult.Proj.C_raw{order(i)} = neuron.C_raw(idxValids,:);
            if flag == 0
                concatResult.Proj.FR{order(i)} = neuron.convolve1D(idxValids,:);
            else
                concatResult.Proj.FR{order(i)} = neuron.FoopThresh(idxValids,:);
            end
        end
    end
end

save(strcat(path,filesep,'concatResult.mat'),'concatResult')