function runConcatStep3to4(path)



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

cd(strcat(path,separator,'Concatenation'))
%% Step 3: Normalizing the concatenated video for cell detection.
load('concatInfo.mat')
analysis_time ='SHtemp';
path = concatInfo.path;
ConcatFolder = concatInfo.ConcatFolder;
cd(strcat(concatInfo.path,separator,concatInfo.ConcatFolder))
name = strcat(concatInfo.path,separator,concatInfo.ConcatFolder,separator,'ConcatenatedVideo.avi');
Step3Dur = tic;  
CompleteVideo = read_file(name);
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
FR = 30;
if isfield(concatInfo,'FrameRate')
    FR = concatInfo.FrameRate;
end
ms.time = (1:sum(concatInfo.NumberFramesSessions))*(1/FR)*1000;

save(strcat(path,separator,ConcatFolder, separator, 'msConcat.mat'),'ms', '-v7.3');
save (strcat(path,separator,ConcatFolder, separator, 'neuronFull.mat'), 'neuron', '-v7.3');

disp('all msRun2018 finally done!!!');
datetime
disp(['Total duration of Step 4 = ' num2str(toc(Step4Dur)) ' seconds.'])
end