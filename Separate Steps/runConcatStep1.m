function runConcatStep1(path,equipment)



%% Pipeline for the proper concatenation of miniscope data across sessions
% Developed by Daniel Almeida Filho Mar/2020 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parameters
concatInfo.spatial_downsampling = 2; % (Recommended range: 2 - 4. Downsampling significantly increases computational speed, but verify it does not
concatInfo.path = path;
concatInfo.equipment = equipment;
isnonrigid = true; % If true, performs non-rigid registration (slower). If false, rigid alignment (faster).
% non-rigid is preferred within sessions.
concatInfo.Sessions = dir(path);
% concatInfo.Sessions = concatInfo.Sessions(3:end,:);
concatInfo.Sessions = concatInfo.Sessions(3:end,:);

analysis_time ='SHtemp';
ConcatFolder = 'Concatenation';
concatInfo.ConcatFolder = ConcatFolder;
% concatInfo.order = [1 2 3]; % Order in which the files in "concatInfo.Sessions" 
% % will be concatenated.  
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
checkMotCorr = false; %Manually check the first video of motion correction 
% to see if the algoirthm is capable of correcting motion properly for that specific dataset.
for i = 1:nSessions
    cd(strcat(path,filesep,concatInfo.Sessions(i).name))
    ms = msGenerateVideoObjConcat(pwd, concatInfo.equipment, replaceRGBVideo, 'msCam');
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
    ms = msNormCorreConcat(ms,isnonrigid,ROIflag,plotFlag,checkMotCorr);
    save([ms.dirName filesep 'ms.mat'],'ms');
    clear ms
end

%%% Place all the motion corrected videos in the same folder
disp('Step 1.1: Copying videos to concatenate to the same folder and in the correct order.');
animal={};
for i = 1:nSessions
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
end