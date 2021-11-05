function [ROIvideo,mask,excluded] = selectROI(Video,dsFlag)
% Function used to select an ROI of the FOV to improve motion correction,
% avoid border noise, and reduce the amount of false positive cell
% detection.
%
% Developed by Daniel Almeida Filho Feb/2021 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu

meanVideo = nanmean(Video,3);
ff = figure('units','normalized','outerposition',[0 0 1 1]);
subplot(1,2,1)
imagesc(meanVideo)
daspect([1 1 1])
colormap gray
set(gca,'xticklabel',[],'yticklabel',[])
answer = questdlg('Would you like to select a ROI?', ...
    'ROI selection', ...
    'Yes','No','No');
switch answer
    case 'Yes'
        
        answer2 = 'No';
        while (strcmp(answer2,'No'))
            roi = imfreehand();
            mask=createMask(roi);
            subplot(1,2,2)
            imagesc(meanVideo.*mask)
            daspect([1 1 1])
            set(gca,'xticklabel',[],'yticklabel',[])
            title('ROI Selected','fontsize',20)
            answer2 = questdlg('Do you confirm ROI?','ROI check', ...
                'Yes','No','No');
        end
    case 'No'
        mask = Video>0;
        mask = uint8(sum(mask,3)>(size(mask,3)*.95));
end
MultFactor = repmat(mask,1,1,size(Video,3));
Class = class(Video);
ROIvideo = Video.*cast(MultFactor,Class);

if dsFlag
    Xidx = sum(mask)~=0;
    Yidx = sum(mask,2)~=0;
    ROIvideo = ROIvideo(Yidx,Xidx,:);
    tempXidx = diff(Xidx);
    tempYidx = diff(Yidx);
    beforeX = find(tempXidx==1,1); if isempty(beforeX);beforeX=0;end
    beforeY = find(tempYidx==1,1); if isempty(beforeY);beforeY=0;end
    afterX = length(tempXidx)+1 - find(tempXidx==-1,1); if isempty(afterX);afterX=0;end
    afterY = length(tempYidx)+1 - find(tempYidx==-1,1); if isempty(afterY);afterY=0;end
    excluded = [beforeX beforeY afterX afterY];
    msgbox(['The video from this session will be downsampled to a ' num2str(sum(Yidx)) ' X ' num2str(sum(Xidx)) ' FOV!'],'','warn')
else
    excluded = zeros(1,4);
%     msgbox('The whole field of view will be considered for motion correction!','','help')
end
close(ff);
end