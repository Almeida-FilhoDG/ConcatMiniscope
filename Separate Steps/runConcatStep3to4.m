function runConcatStep3to4(path)



%% Pipeline for the proper concatenation of miniscope data across sessions
% Developed by Daniel Almeida Filho Mar/2020 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(strcat(path,filesep,'Concatenation'))
%% Step 3: Normalizing the concatenated video for cell detection.
load('concatInfo.mat')
analysis_time ='SHtemp';
replaceRGBVideo = false;
% path = concatInfo.path;
ConcatFolder = concatInfo.ConcatFolder;
cd(strcat(path,filesep,ConcatFolder))
name = strcat(path,filesep,ConcatFolder,filesep,'ConcatenatedVideo.avi');
Step3Dur = tic;  
disp('Loading video...')
CompleteVideo = read_file(name);
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
FR = 30;
if isfield(concatInfo,'FrameRate')
    FR = concatInfo.FrameRate;
end
ms.time = (1:sum(concatInfo.NumberFramesSessions))*(1/FR)*1000;

save(strcat(path,filesep,ConcatFolder, filesep, 'msConcat.mat'),'ms', '-v7.3');
save (strcat(path,filesep,ConcatFolder, filesep, 'neuronFull.mat'), 'neuron', '-v7.3');

disp('all msRun finally done!!!');
datetime
disp(['Total duration of Step 4 = ' num2str(toc(Step4Dur)) ' seconds.'])
end