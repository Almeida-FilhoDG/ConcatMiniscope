function runConcatStep6(path)



%% Pipeline for the proper concatenation of miniscope data across sessions
% Developed by Daniel Almeida Filho July/2020 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Auto-detect operating system
if ispc
    separator = '\'; % For pc operating  syste  ms
else
    separator = '/'; % For unix (mac, linux) operating systems
end

cd(strcat(path,separator,'Concatenation'))
load('concatInfo.mat')
ConcatFolder = concatInfo.ConcatFolder;

%% Step 6: Project the calcium raw trace, get the deconvolved trace, 
% and the putative activity of all cells in different sessions

% Get raw and deconvolved calcium traces
getActivity(strcat(path,separator,ConcatFolder));

% Get the putative activity of cells (default is output convolv1D and 
% Foopsi Threshold methods)
dSFactor = 3; % Downsampling factor to improve computation of neuronal activity 
% default is 3 for a Frame Rate of 30fps. Results are outputs with the same
% dimensions as the raw traces (downsmapling is only for computation of
% activity and it is not applied to the final result).
deconvConcat(strcat(path,separator,ConcatFolder),concatInfo.FrameRate,dSFactor)
