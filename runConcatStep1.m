function runConcatStep1(path,equipment)


eval(['cd ' path])

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
concatInfo.spatial_downsampling = 2; % (Recommended range: 2 - 4. Downsampling significantly increases computational speed, but verify it does not
path = pwd;
concatInfo.path = path;
concatInfo.equipment = equipment;
isnonrigid = true; % If true, performs non-rigid registration (slower). If false, rigid alignment (faster).
% non-rigid is preferred within sessions.
concatInfo.Sessions = dir(path);
concatInfo.Sessions = concatInfo.Sessions(3:end,:);
script_start = tic;
analysis_time ='SHtemp';
ConcatFolder = 'Concatenation';
concatInfo.ConcatFolder = ConcatFolder;
concatInfo.order = [3 2 1]; % Order in which the files in "concatInfo.Sessions" 
% will be concatenated. 
nSessions = size(concatInfo.Sessions,1);
mkdir(strcat(path,separator,ConcatFolder));
save(strcat(path,separator,ConcatFolder,separator,'concatInfo.mat'),'concatInfo','-v7.3')

%% Step 1: Motion correction of single sessions (NoRMCorre)
Step1Dur = tic; 
disp('Step 1: Applying motion correction on single sessions.');
plotFlag = false;
replaceRGBVideo = true;
for i = 1:nSessions
    cd(strcat(path,separator,concatInfo.Sessions(i).name))
    ms = msGenerateVideoObjConcat(pwd, concatInfo.equipment, replaceRGBVideo);
    ms.FrameRate = round(1/(nanmedian(diff(ms.time))/1000)); 
    ms.equipment = concatInfo.equipment;
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
if ~isfield(concatInfo,'FrameRate')
    concatInfo.FrameRate = 30;
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
end