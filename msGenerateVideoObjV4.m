
function ms = msGenerateVideoObjV4(dirName)
%MSGENERATEMS Summary of this function goes here
%   Detailed explanation goes here

ms.dirName = dirName; % Added by GE to keep track of where the files were initially

MAXFRAMESPERFILE = 1000; %This is set in the miniscope control software

% find avi and dat files
aviFiles = dir([dirName filesep '*.avi']);
datFiles = dir([dirName filesep '*.csv']);

ms.numFiles = 0;
ms.numFrames = 0;
ms.vidNum = [];
ms.frameNum = [];
ms.maxFramesPerFile = MAXFRAMESPERFILE;

%find the total number of relevant video files
for i=1:length(aviFiles)
    endIndex = strfind(aviFiles(i).name,'.avi');
    ms.numFiles = max([ms.numFiles str2double(aviFiles(i).name(1:endIndex))]);
end
ms.numFiles = ms.numFiles +1;
%generate a vidObj for each video file. Also calculate total frames
for i=1:ms.numFiles
    ms.vidObj{i} = VideoReader([dirName filesep num2str(i-1) '.avi']);
    if strcmp(ms.vidObj{i}.VideoFormat,'RGB24')
        convertToGray(ms.vidObj{i})
        ms.vidObj{i} = VideoReader([dirName filesep 'gray' num2str(i-1) '.avi']);
    end
    ms.vidNum = [ms.vidNum (i-1)*ones(1,ms.vidObj{i}.NumberOfFrames)];
    ms.frameNum = [ms.frameNum 1:ms.vidObj{i}.NumberOfFrames];
    ms.numFrames = ms.numFrames + ms.vidObj{i}.NumberOfFrames;
end
ms.height = ms.vidObj{1}.Height;
ms.width = ms.vidObj{1}.Width;

%read timestamp information
cameraMatched=0;
for i=1:length(datFiles)
    if strcmp(datFiles(i).name,'timeStamps.csv')
        dataArray = readmatrix([dirName filesep 'timeStamps.csv']);
        ms.time = dataArray(:, 2);
        buffer1 = dataArray(:, 3);
        ms.time(1) = 0;
        ms.maxBufferUsed = max(buffer1);
        clearvars dataArray;
        %     elseif strcmp(datFiles(i).name, 'settings_and_notes.dat') %read in and store animal name
        %         fileID = fopen([dirName filesep datFiles(i).name],'r');
        %         textscan(fileID, '%[^\n\r]', 1, 'ReturnOnError', false);
        %         dataArray = textscan(fileID, '%s%s%s%s%[^\n\r]', 1, 'Delimiter', '\t', 'ReturnOnError', false);
        %         ms.Experiment = dataArray(:,1);
        %         ms.Experiment = string(ms.Experiment{1});
    end
end
% if ~cameraMatched && ~isempty(datFiles)
%     error('No timestamp file!'); %included by Daniel Almeida Aug/2019
% end
%
%     %figure out date and time of recording if that information if available
%     %in folder path
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

    function convertToGray(videoObj)
        writerObj = VideoWriter([videoObj.Path filesep 'gray' videoObj.Name],'Grayscale AVI');
        BuffVideo = nan(videoObj.Width,videoObj.Height,videoObj.NumberOfFrames);
        ii = 1;
        while hasFrame(videoObj)
            BuffVideo(:,:,ii) = rgb2gray(readFrame(videoObj));
            ii = ii+1;
        end
        open(writerObj);
        writeVideo(writerObj,uint8(BuffVideo));
        close(writerObj);
    end
end

