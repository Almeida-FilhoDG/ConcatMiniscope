%% Pipeline for the proper concatenation of miniscope data across sessions
% Developed by Daniel Almeida Filho Mar/2020 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parameters
%%%****************%%%
concatInfo.spatial_downsampling = 2; % (Recommended range: 2 - 4. Downsampling significantly increases computational speed, but verify it does not
path = pwd;
concatInfo.path = path;
%%%****************%%%
concatInfo.equipment = 'V4'; %equipment used for imaging.
%%%****************%%%
isnonrigid = true; % If true, performs non-rigid registration (slower). If false, rigid alignment (faster).
% non-rigid is preferred within sessions.
concatInfo.Sessions = dir(path);
concatInfo.Sessions = concatInfo.Sessions(3:end,:);
analysis_time ='SHtemp';
ConcatFolder = 'Concatenation';
concatInfo.ConcatFolder = ConcatFolder;
%%%****************%%%
concatInfo.order = [1 2 3]; % Order in which the files in "concatInfo.Sessions" 
% will be concatenated. 
nSessions = size(concatInfo.Sessions,1);
mkdir(strcat(path,filesep,ConcatFolder));
save(strcat(path,filesep,ConcatFolder,filesep,'concatInfo.mat'),'concatInfo','-v7.3')

%% Step 1: Motion correction of single sessions (NoRMCorre)
Step1Dur = tic; 
disp('Step 1: Applying motion correction on single sessions.');
plotFlag = false; %Plot the results of motion correction
ROIflag = false; %Choose true if you want to select a specific ROI in the 
% FOV for each separate session. Pixels outside of the FOV will be deemed
% zero.
replaceRGBVideo = false; %Choose true if you want to replace RGB videos by their gray scale version
for i = 1:nSessions
    cd(strcat(path,filesep,concatInfo.Sessions(i).name))
    ms = msGenerateVideoObjConcat(pwd, concatInfo.equipment, replaceRGBVideo,'msCam');
    ms.FrameRate = round(1/(nanmedian(diff(ms.time))/1000)); 
    ms.equipment = concatInfo.equipment;
    if i==1
       concatInfo.FrameRate = ms.FrameRate; 
    end
    ms.analysis_time = analysis_time;
    ms.ds = concatInfo.spatial_downsampling;
    mkdir(strcat(pwd,filesep,analysis_time));
    save([ms.dirName filesep 'ms.mat'],'ms');
    disp(['Working on Session: ' num2str(i) ' of ' num2str(nSessions)])
    ms = msNormCorreConcat(ms,isnonrigid,ROIflag,plotFlag);
    save([ms.dirName filesep 'ms.mat'],'ms');
    clear ms
end

%%% Place all the motion corrected videos in the same folder
disp('Step 1.1: Copying videos to concatenate to the same folder and in the correct order.');
mkdir(strcat(path,filesep,ConcatFolder));
animal={};
for i = 1:length(concatInfo.order)
    actualIdx = concatInfo.order(i);
    cd(strcat(path,filesep,concatInfo.Sessions(actualIdx).name,filesep))
    load('ms.mat')
    animal{i}=ms;
    cd(analysis_time)
    copyfile('msvideo.avi',...
        strcat(path,filesep,ConcatFolder,filesep,['msvideo' num2str(i) '.avi']))
    clear ms
end
save(strcat(path,filesep,ConcatFolder,filesep,'concatInfo.mat'),'concatInfo','-v7.3')
save(strcat(path,filesep,ConcatFolder,filesep,'animal.mat'),'animal','-v7.3')
disp(['Total duration of Step 1 = ' num2str(toc(Step1Dur)) ' seconds.'])
%% Step 2: Alignment across sessions
dsFOVflag = true; %Choose true if you want to downsample the FOV by 
% selecting an ROI from the concatenated video or if you want to downsample 
% the FOV of the concatenated video to the non-zero pixels (useful when an ROI was 
% selected from the FOV before motion correction)
Step2Dur = tic; 
disp('Step 2: Aligning between sessions');
[concatInfo.AllAlignment,concatInfo.AllCorrelation]=AlignAcrossSessions(animal);
[concatInfo.refAverCorr,concatInfo.refSession] = nanmax(nanmean(concatInfo.AllCorrelation));
concatInfo.FinalAlignment = concatInfo.AllAlignment(concatInfo.refSession,:);
concatInfo = excludeBadAlign(concatInfo);


disp('Step 2.1: Concatenating videos for final motion correction');
[CompleteVideo,concatInfo] = ConcatVideos(strcat(path,filesep,concatInfo.ConcatFolder),concatInfo,dsFOVflag);
save(strcat(path,filesep,ConcatFolder,filesep,'concatInfo.mat'),'concatInfo','-v7.3')
disp(['Total duration of Step 2 = ' num2str(toc(Step2Dur)) ' seconds.'])

%% Step 3: Normalizing the concatenated video for cell detection.
Step3Dur = tic; 
[~] = NormConcatVideo(CompleteVideo,concatInfo,[path filesep ConcatFolder]);
disp(['Total duration of Step 3 = ' num2str(toc(Step3Dur)) ' seconds.'])

%% Step 4: Perform cell detection (CNMF-E).
Step4Dur = tic; 
if ismember(concatInfo.equipment,{'v4','V4'})
    spatial_downsampling = 1.5;
else
    spatial_downsampling = 2;
end
script_start = tic;
mkdir(strcat(path,filesep,ConcatFolder,filesep,analysis_time));
copyfile(strcat(path,filesep,ConcatFolder,filesep,'FinalConcatNorm1.avi'),...
        strcat(path,filesep,ConcatFolder,filesep,analysis_time,filesep,'msvideo.avi'))

ms = msGenerateVideoObjConcat(strcat(path,filesep,ConcatFolder), concatInfo.equipment, replaceRGBVideo,'FinalConcatNorm');
ms.analysis_time = analysis_time;
concatInfo.downSamplingCNMF_E = spatial_downsampling;
ms.ds = spatial_downsampling;
ms.FrameRate = concatInfo.FrameRate;
save(strcat(path,filesep,ConcatFolder, filesep, 'msConcat.mat'),'ms');

[ms, neuron] = msRunCNMFE_Concat(ms);

analysis_duration = toc(script_start);
ms.analysis_duration = analysis_duration;
ms.time = (1:sum(concatInfo.NumberFramesSessions))*(1/concatInfo.FrameRate)*1000;

save(strcat(path,filesep,ConcatFolder, filesep, 'msConcat.mat'),'ms', '-v7.3');
save (strcat(path,filesep,ConcatFolder, filesep, 'neuronFull.mat'), 'neuron', '-v7.3');

disp('all msRun finally done!!!');
datetime
disp(['Total duration of Step 4 = ' num2str(toc(Step4Dur)) ' seconds.'])

%% Step 5 (optional): Deleting the bad neurons.
msDeleteROI
%% Step 6: Project the calcium raw trace, get the deconvolved trace, 
% and the putative activity of all cells in different sessions

% Get raw and deconvolved calcium traces
getActivity(strcat(path,filesep,ConcatFolder));

% Get the putative activity of cells (default is output convolv1D and 
% Foopsi Threshold methods)

%%%****************%%%
dSFactor = 3; % Downsampling factor to improve computation of neuronal activity 
% default is 3 for a Frame Rate of 30fps. Results are outputs with the same
% dimensions as the raw traces (downsmapling is only for computation of
% activity and it is not applied to the final result).
deconvConcat(strcat(path,filesep,ConcatFolder),concatInfo.FrameRate,dSFactor)

%% Step 7: Final check for noisy neurons

matlab.apputil.run('checkNoisyCells')

%% Step 8 (optional): Join all the activity in just one file

joinActivity(strcat(path,filesep,ConcatFolder))



