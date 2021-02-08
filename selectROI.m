function [ROIvideo,mask] = selectROI(Video,dsFlag)
% Function used to select an ROI of the FOV to improve motion correction,
% avoid border noise, and reduce the amount of false positive cell
% detection.
%
% Developed by Daniel Almeida Filho Feb/2021 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu

meanVideo = nanmean(Video,3);
figure('units','normalized','outerposition',[0 0 1 1])
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
        
        Xidx = sum(mask)~=0;
        Yidx = sum(mask,2)~=0;
        ROIvideo = Video.*uint8(repmat(mask,1,1,size(Video,3)));
        if dsFlag
            ROIvideo = ROIvideo(Yidx,Xidx,:);
            msgbox(['The video from this session will be downsampled to a ' num2str(sum(Yidx)) ' X ' num2str(sum(Xidx)) ' FOV!'],'','warn')
        end
    case 'No'
        mask = nan;
        ROIvideo=nan;
        msgbox('The whole field of view will be considered for motion correction!','','help')
end