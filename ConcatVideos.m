function [CompleteVideo,concatInfo] = ConcatVideos(path,concatInfo)


% INPUT:
% Path: String with the path for the videos to be concatenated. The videos
% should be already motion corrected and named in the right order (e.g.:
% "msvideo1.avi", "msvideo2.avi", etc). The Alignment file should also be
% placed on the same folder as a 1xN cell, in which N is the number of
% videos to be concatenated in the same order as the "msvideo" files.

videos = dir([path '\msvideo*.avi']);
nVideos = length(videos);
Alignment = concatInfo.FinalAlignment;
ref = concatInfo.refSession;

Lims=nan(1,nVideos);
positions = 1:nVideos;
actual=[];
for pos = 1:length(positions)
    actPos = positions(pos);
    if isempty(Alignment{actPos})
        continue
    end
    actual = [actual;Alignment{actPos}.T(3,1:2)];
end
if ~isempty(actual)
    Lims=round([min(actual) max(actual)]);
end

% if nargin<2
%     ref = 3;
% end

NumberOfFrames = nan(size(positions));
emptyFlag = [];
for pos = 1:length(positions)
    actPos = positions(pos);
    if ~isempty(Alignment{actPos})
        videoObj = VideoReader([path '\' videos(pos).name]);
        NFrames = videoObj.NumFrames;
        Width = videoObj.Width;
        Height = videoObj.Height;
        LimsW = 1 + Lims(3):Width + Lims(1);
        LimsH = 1 + Lims(4):Height + Lims(2);
        tic
        Temp=[];
        parfor i = 1:NFrames
            if mod(i,1000)==0
                disp(i)
            end
            actual = read(videoObj,i);
            actual2 = imwarp(actual,Alignment{actPos},'OutputView',imref2d(size(actual)));
            Temp(:,:,i)=actual2(LimsH,LimsW);
        end
        toc
        ConcatVideo{pos}=uint8(Temp);
        NumberOfFrames(pos)=size(Temp,3);
        clear Temp
    else
        emptyFlag = [emptyFlag pos];
    end
end

if ~isempty(emptyFlag)
    for ii=1:length(emptyFlag)
        ConcatVideo{emptyFlag(ii)} = ConcatVideo{ref};
        NumberOfFrames(emptyFlag(ii))=size(ConcatVideo{ref},3);
    end
end

concatInfo.AbsentSessionsReplacedByRef = emptyFlag;
CompleteVideo = [];
for i = 1:length(positions)
    CompleteVideo = cat(3,CompleteVideo,ConcatVideo{i});
end
concatInfo.NumberFramesSessions = NumberOfFrames;
concatInfo.CutFromBorders = Lims;

% Saving Concatenated Videos
newVideoObj = VideoWriter([path '\ConcatenatedVideo.avi'],'Grayscale AVI');
newVideoObj.FrameRate = videoObj.FrameRate;
tic

open(newVideoObj)
writeVideo(newVideoObj,uint8(CompleteVideo))

toc
close(newVideoObj)