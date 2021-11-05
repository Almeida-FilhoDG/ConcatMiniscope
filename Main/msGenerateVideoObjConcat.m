function ms = msGenerateVideoObjConcat(dirName, equipment, replaceRGBVideo, filePrefix)
%MSGENERATEMS Summary of this function goes here
%   Detailed explanation goes here

ms.dirName = dirName; % Added by GE to keep track of where the files were initially

MAXFRAMESPERFILE = 1000; %This is set in the miniscope control software
if nargin <3
        replaceRGBVideo= false;
    if nargin < 2 || ~ismember(equipment,{'v3','V3','v4','V4'})
        error('Please inform the equipment used for the recordings. (Options: ''V3'' or ''V4'')');
    end
end
if strcmp(equipment,'v3')
    equipment='V3';
elseif strcmp(equipment,'v4')
    equipment='V4';
end
% find avi and dat files
aviFiles = dir([dirName filesep '*.avi']);
if strcmp(equipment,'V3')
    datFiles = dir([dirName filesep '*.dat']);
    ms.numFiles = 0;
    ms.numFrames = 0;
    ms.vidNum = [];
    ms.frameNum = [];
    ms.maxFramesPerFile = MAXFRAMESPERFILE;
    
    %find the total number of relevant video files

    for i=1:length(aviFiles)
        endIndex = strfind(aviFiles(i).name,'.avi');
        if (~isempty(strfind(aviFiles(i).name,filePrefix)))
            ms.numFiles = max([ms.numFiles str2double(aviFiles(i).name((length(filePrefix)+1):endIndex))]);
        end
    end
    %generate a vidObj for each video file. Also calculate total frames
    for i=1:ms.numFiles
        %         [folder filesep num2str(filePrefix) num2str(i) '.avi']
        ms.vidObj{i} = VideoReader([dirName filesep num2str(filePrefix) num2str(i) '.avi']);
        ms.vidNum = [ms.vidNum i*ones(1,ms.vidObj{i}.NumberOfFrames)];
        ms.frameNum = [ms.frameNum 1:ms.vidObj{i}.NumberOfFrames];
        ms.numFrames = ms.numFrames + ms.vidObj{i}.NumberOfFrames;
    end
    ms.height = ms.vidObj{1}.Height;
    ms.width = ms.vidObj{1}.Width;
    
    %read timestamp information
    cameraMatched=0;
    for i=1:length(datFiles)
        if strcmp(datFiles(i).name,'timestamp.dat')
            fileID = fopen([dirName filesep datFiles(i).name],'r');
            dataArray = textscan(fileID, '%f%f%f%f%[^\n\r]', 'Delimiter', '\t', 'EmptyValue' ,NaN,'HeaderLines' ,1, 'ReturnOnError', false);
            camNum = dataArray{:, 1};
            frameNum = dataArray{:, 2};
            sysClock = dataArray{:, 3};
            buffer1 = dataArray{:, 4};
            clearvars dataArray;
            fclose(fileID);
            cameraMatched = 0;
            for j=0:max(camNum)
                %                 (frameNum(find(camNum==j,1,'last')) == ms.numFrames)
                %                 (sum(camNum==j) == ms.numFrames)
                if (sum(camNum==j)~=0)
                    if ((frameNum(find(camNum==j,1,'last')) == ms.numFrames) && (sum(camNum==j) == ms.numFrames))
                        ms.camNumber = j;
                        ms.time = sysClock(camNum == j);
                        ms.time(1) = 0;
                        ms.maxBufferUsed = max(buffer1(camNum==j));
                        cameraMatched = 1;
                    end
                end
            end
            if ~cameraMatched
                display(['Problem matching up timestamps for ' dirName]);
            end
        elseif strcmp(datFiles(i).name, 'settings_and_notes.dat') %read in and store animal name
            fileID = fopen([dirName filesep datFiles(i).name],'r');
            textscan(fileID, '%[^\n\r]', 1, 'ReturnOnError', false);
            dataArray = textscan(fileID, '%s%s%s%s%[^\n\r]', 1, 'Delimiter', '\t', 'ReturnOnError', false);
            ms.Experiment = dataArray(:,1);
            ms.Experiment = string(ms.Experiment{1});
        end
    end
    if ~cameraMatched && ~isempty(datFiles)
        error('No timestamp file!'); %included by Daniel Almeida Aug/2019
    end
    %
    %     %figure out date and time of recording if that information if available
    %     %in folder path
    idx = strfind(dirName, '_');
    idx2 = strfind(dirName, filesep);
    if (length(idx) >= 4)
        ms.dateNum = datenum(str2double(dirName((idx(end-2)+1):(idx2(end)-1))), ... %year
            str2double(dirName((idx2(end-1)+1):(idx(end-3)-1))), ... %month
            str2double(dirName((idx(end-3)+1):(idx(end-2)-1))), ... %day
            str2double(dirName((idx2(end)+2):(idx(end-1)-1))), ...%hour
            str2double(dirName((idx(end-1)+2):(idx(end)-1))), ...%minute
            str2double(dirName((idx(end)+2):end)));%second
    end
elseif strcmp(equipment,'V4')
    datFiles = dir([dirName filesep '*.csv']);
    
    ms.numFiles = 0;
    ms.numFrames = 0;
    ms.vidNum = [];
    ms.frameNum = [];
    ms.maxFramesPerFile = MAXFRAMESPERFILE;
    
    %find the total number of relevant video files
    for i=1:length(aviFiles)
        endIndex = strfind(aviFiles(i).name,'.avi');
        fname = aviFiles(i).name(1:endIndex-1);
        if strcmp(fname(1:end-1),filePrefix)
            ms.numFiles = 0;
            break
        end
        ms.numFiles = max([ms.numFiles str2double(fname)]);
    end
    ms.numFiles = ms.numFiles + 1;
    %generate a vidObj for each video file. Also calculate total frames
    for i=1:ms.numFiles
        if ms.numFiles == 1 && strcmp(fname(1:end-1),filePrefix)
            ms.vidObj{i} = VideoReader([dirName filesep fname '.avi']);
        else
            ms.vidObj{i} = VideoReader([dirName filesep num2str(i-1) '.avi']);
        end
        if strcmp(ms.vidObj{i}.VideoFormat,'RGB24')
            convertToGray(ms.vidObj{i},replaceRGBVideo)
            ms.vidObj{i} = VideoReader([dirName filesep 'gray' num2str(i-1) '.avi']);
        end
        ms.vidNum = [ms.vidNum (i-1)*ones(1,ms.vidObj{i}.NumberOfFrames)];
        ms.frameNum = [ms.frameNum 1:ms.vidObj{i}.NumberOfFrames];
        ms.numFrames = ms.numFrames + ms.vidObj{i}.NumberOfFrames;
    end
    ms.height = ms.vidObj{1}.Height;
    ms.width = ms.vidObj{1}.Width;
    
    %read timestamp information
    for i=1:length(datFiles)
        if strcmp(datFiles(i).name,'timeStamps.csv')
            dataArray = table2array(readtable([dirName filesep 'timeStamps.csv']));
            ms.time = dataArray(:, 2);
            buffer1 = dataArray(:, 3);
            ms.time(1) = 0;
            ms.maxBufferUsed = max(buffer1);
            clearvars dataArray;
        end
    end
    
    idx = strfind(dirName, '_');
    idx2 = strfind(dirName, filesep);
    if (length(idx) >= 4)
        ms.dateNum = datenum(str2double(dirName((idx(end-3)-4):(idx(end-3)-1))), ... %year
            str2double(dirName((idx(end-2)-2):(idx(end-2)-1))), ... %month
            str2double(dirName((idx2(end-1)-2):(idx2(end-1)-1))), ... %day
            str2double(dirName((idx(end-1)-2):(idx(end-1)-1))), ...%hour
            str2double(dirName((idx(end)-2):(idx(end)-1))), ...%minute
            str2double(dirName((idx2(end)-2):(idx2(end)-1))));%second
    end
end
    function convertToGray(videoObj,replace)
        writerObj = VideoWriter([videoObj.Path filesep 'gray' videoObj.Name],'Grayscale AVI');
        NumFrames = videoObj.NumberOfFrames;
        BuffVideo = nan(videoObj.Width,videoObj.Height,NumFrames);

        for ii = 1:NumFrames
            BuffVideo(:,:,ii) = rgb2gray(read(videoObj,ii));
        end
        
        if size(BuffVideo,3)<4 %workaround because the writeVideo function 
            %gets confused when there is a videa with only 3 frames. 
            % It misunderstands it as an RGB 1-frame video.
            BuffVideo = reshape(BuffVideo,size(BuffVideo,1),size(BuffVideo,2),...
                1,size(BuffVideo,3));
        end
        open(writerObj);
        writeVideo(writerObj,uint8(BuffVideo));
        close(writerObj);
        if replace
            delete([videoObj.Path filesep videoObj.Name])
        end
    end
end

