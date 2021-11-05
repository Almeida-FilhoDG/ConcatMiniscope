%% Pipeline for the proper concatenation of miniscope data across sessions
% Developed by Daniel Almeida Filho Mar/2020 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Step 2: Alignment across sessions
load('concatInfo.mat')
load('animal.mat')
dsFOVflag = false; %Choose true if you want to downsample the FOV by 
% selecting an ROI from the concatenated video or if you want to downsample 
% the FOV of the concatenated video to the non-zero pixels (useful when an ROI was 
% selected from the FOV before motion correction)

path=pwd;
Step2Dur = tic; 
disp('Step 2: Aligning between sessions');
[concatInfo.AllAlignment,concatInfo.AllCorrelation]=AlignAcrossSessions(animal);
[concatInfo.refAverCorr,concatInfo.refSession] = nanmax(nanmean(concatInfo.AllCorrelation));
concatInfo.FinalAlignment = concatInfo.AllAlignment(concatInfo.refSession,:);

concatInfo = excludeBadAlign(concatInfo);
save(strcat(path,filesep,'concatInfo.mat'),'concatInfo','-v7.3')

disp('Step 2.1: Concatenating videos for final motion correction');
[~,concatInfo] = ConcatVideos(path,concatInfo,dsFOVflag);
save(strcat(path,filesep,'concatInfo.mat'),'concatInfo','-v7.3')
disp(['Total duration of Step 2 = ' num2str(toc(Step2Dur)) ' seconds.'])