function runSeparateSessions(parentFolder)
%%% Function to run CNMFe on sessions separatelly
%%% Requirements: Step 1 of Concatenation Pipeline.
% Input: 
%   parentFolder: Folder with data of one single subject. Should contain
%   child folders from single sessions each.
% Developed by Daniel Almeida Filho (Apr, 2021) almeidafilhodg@ucla.edu

Sessions = dir(parentFolder);
Sessions = Sessions(3:end);
cd(parentFolder)

for s = 1:length(Sessions)
    if isdir([parentFolder filesep Sessions(s).name])
        cd([parentFolder filesep Sessions(s).name])
    else
        continue
    end
    try load('ms.mat')
    catch 
        continue
    end
    if ismember(ms.equipment,{'v4','V4'})
        ms.ds = 1.5;
    else
        ms.ds = 2;
    end
    ms.dirName = pwd;
    [ms, neuron] = msRunCNMFE_Concat(ms);
    ms.ds=2;
    save('ms.mat','ms', '-v7.3');
    save ('neuronFull.mat', 'neuron', '-v7.3');
end


