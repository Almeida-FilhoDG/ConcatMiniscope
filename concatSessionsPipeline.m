%% Pipeline for the proper concatenation of miniscope data across sessions
% Developed by Daniel Almeida Filho Mar/2020 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Auto-detect operating system
if ispc
    separator = '\'; % For pc operating  syste  ms
else
    separator = '/'; % For unix (mac, linux) operating systems
end

%% Parameters
%%%****************%%%
concatInfo.spatial_downsampling = 2; % (Recommended range: 2 - 4. Downsampling significantly increases computational speed, but verify it does not
path = pwd;
concatInfo.path = path;
%%%****************%%%
isnonrigid = true; % If true, performs non-rigid registration (slower). If false, rigid alignment (faster).
% non-rigid is preferred within sessions.
concatInfo.Sessions = dir(path);
concatInfo.Sessions = concatInfo.Sessions(3:end,:);
script_start = tic;
analysis_time ='SHtemp';
ConcatFolder = 'Concatenation';
concatInfo.ConcatFolder = ConcatFolder;
%%%****************%%%
concatInfo.order = [1 4 5 6 2 3]; % Order in which the files in "concatInfo.Sessions" 
% will be concatenated. 
nSessions = size(concatInfo.Sessions,1);
mkdir(strcat(path,separator,ConcatFolder));
save(strcat(path,separator,ConcatFolder,separator,'concatInfo.mat'),'concatInfo','-v7.3')

%% Step 1: Motion correction of single sessions (NoRMCorre)
Step1Dur = tic; 
disp('Step 1: Applying motion correction on single sessions.');
plotFlag = false;
for i = 1:nSessions
    cd(strcat(path,separator,concatInfo.Sessions(i).name))
    ms = msGenerateVideoObj(pwd,'msCam');
    ms.FrameRate = round(1/(nanmedian(diff(ms.time))/1000)); 
    if i==1
       concatInfo.FrameRate = ms.FrameRate; 
    end
    ms.analysis_time = analysis_time;
    ms.ds = concatInfo.spatial_downsampling;
    mkdir(strcat(pwd,separator,analysis_time));
    save([ms.dirName separator 'ms.mat'],'ms');
    disp(['Working on Session: ' num2str(i) ' of ' num2str(nSessions)])
    ms = msNormCorreConcat(ms,isnonrigid,plotFlag);
    save([ms.dirName separator 'ms.mat'],'ms');
    clear ms
end

%%% Place all the motion corrected videos in the same folder
disp('Step 1.1: Copying videos to concatenate to the same folder and in the correct order.');
mkdir(strcat(path,separator,ConcatFolder));
animal={};
for i = 1:nSessions
    actualIdx = concatInfo.order(i);
    cd(strcat(path,separator,concatInfo.Sessions(actualIdx).name,separator))
    load('ms.mat')
    animal{i}=ms;
    cd(analysis_time)
    copyfile('msvideo.avi',...
        strcat(path,separator,ConcatFolder,separator,['msvideo' num2str(i) '.avi']))
end
save(strcat(path,separator,ConcatFolder,separator,'animal.mat'),'animal','-v7.3')
disp(['Total duration of Step 1 = ' num2str(toc(Step1Dur)) ' seconds.'])
%% Step 2: Alignment across sessions
Step2Dur = tic; 
disp('Step 2: Aligning between sessions');
[concatInfo.AllAlignment,concatInfo.AllCorrelation]=AlignAcrossSessions(animal);
[concatInfo.refAverCorr,concatInfo.refSession] = nanmax(nanmean(concatInfo.AllCorrelation));
concatInfo.FinalAlignment = concatInfo.AllAlignment(concatInfo.refSession,:);
concatInfo = excludeBadAlign(concatInfo);


disp('Step 2.1: Concatenating videos for final motion correction');
[CompleteVideo,concatInfo] = ConcatVideos(strcat(path,separator,concatInfo.ConcatFolder),concatInfo);
save(strcat(path,separator,ConcatFolder,separator,'concatInfo.mat'),'concatInfo','-v7.3')
disp(['Total duration of Step 2 = ' num2str(toc(Step2Dur)) ' seconds.'])

%% Step 3: Normalizing the concatenated video for cell detection.
Step3Dur = tic; 
[~] = NormConcatVideo(CompleteVideo,concatInfo);
disp(['Total duration of Step 3 = ' num2str(toc(Step3Dur)) ' seconds.'])

%% Step 4: Perform cell detection (CNMF-E).
Step4Dur = tic; 
spatial_downsampling = 1;
analyse_behavior = true;
script_start = tic;
mkdir(strcat(path,separator,ConcatFolder,separator,analysis_time));
copyfile(strcat(path,separator,ConcatFolder,separator,'FinalConcatNorm1.avi'),...
        strcat(path,separator,ConcatFolder,separator,analysis_time,separator,'msvideo.avi'))

ms = msGenerateVideoObj(strcat(path,separator,ConcatFolder),'FinalConcatNorm');
ms.analysis_time = analysis_time;
ms.ds = spatial_downsampling;
save(strcat(path,separator,ConcatFolder, separator, 'msConcat.mat'),'ms');

[ms, neuron] = msRunCNMFE_large(ms);

analysis_duration = toc(script_start);
ms.analysis_duration = analysis_duration;
ms.time = (1:sum(concatInfo.NumberFramesSessions))*(1/concatInfo.FrameRate)*1000;

save(strcat(path,separator,ConcatFolder, separator, 'msConcat.mat'),'ms', '-v7.3');
save (strcat(path,separator,ConcatFolder, separator, 'neuronFull.mat'), 'neuron', '-v7.3');

disp('all msRun2018 finally done!!!');
datetime
disp(['Total duration of Step 4 = ' num2str(toc(Step4Dur)) ' seconds.'])

%% Step 5: Deleting the bad neurons.
msDeleteROI
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

%% Step 7: Final check for noisy neurons
checkNoisyCells;

%% Step 8 (optional): Join all the activity in just one file

joinActivity(strcat(path,separator,ConcatFolder))



