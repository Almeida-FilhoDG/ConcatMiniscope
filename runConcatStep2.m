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

%% Step 2: Alignment across sessions
load('concatInfo.mat')
load('animal.mat')
path=pwd;
Step2Dur = tic; 
disp('Step 2: Aligning between sessions');
[concatInfo.AllAlignment,concatInfo.AllCorrelation]=AlignAcrossSessions(animal);
[concatInfo.refAverCorr,concatInfo.refSession] = nanmax(nanmean(concatInfo.AllCorrelation));
concatInfo.FinalAlignment = concatInfo.AllAlignment(concatInfo.refSession,:);

concatInfo = excludeBadAlign(concatInfo);

disp('Step 2.1: Concatenating videos for final motion correction');
[~,concatInfo] = ConcatVideos(path,concatInfo);
save(strcat(path,separator,'concatInfo.mat'),'concatInfo','-v7.3')
disp(['Total duration of Step 2 = ' num2str(toc(Step2Dur)) ' seconds.'])