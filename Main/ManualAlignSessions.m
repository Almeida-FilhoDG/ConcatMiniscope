function [tform,Corr] = ManualAlignSessions(refFrame, frame,i,j )
%ManualAlignSessions Summary of this function goes here
%
%
hLarge = fspecial('average', 40);
hSmall = fspecial('average', 3);

refFrame1 = refFrame;
frame1 = frame;
clf
set(gcf,'units','normalized','outerposition',[0 0 1 1])
subplot(2,3,1)
imagesc(refFrame)% pcolor (refFrame)
shading flat
daspect([1 1 1])
colormap gray
title(['Session ' num2str(i)])

subplot(2,3,4)
imagesc(frame)
shading flat
daspect([1 1 1])
colormap gray
title(['Session ' num2str(j)])

%----------------
subplot(2,3,[2 3 5 6])
imagesc(refFrame)
shading flat
daspect([1 1 1])
colormap gray
title('Select landmark')
[curserW(1), curserH(1), ~] = ginput(1);
imagesc(frame)
shading flat
daspect([1 1 1])
colormap gray
title('Select landmark')
[curserW(2), curserH(2), ~] = ginput(1);
dw = curserW(2) - curserW(1);
dh = curserH(2) - curserH(1);
title('Select ROI')
rect = getrect();
ROI = uint16([rect(1) rect(1)+rect(3) rect(2) rect(2)+rect(4)]);

refRect = rect - [dw dh 0 0];
refROI = uint16([refRect(1) refRect(1)+refRect(3) refRect(2) refRect(2)+refRect(4)]);

refFrame = (filter2(hSmall,refFrame) - filter2(hLarge, refFrame));

SizeRef = size(refFrame);
if refROI(3)<1 || refROI(4)> SizeRef(1) || refROI(1)<1 || refROI(2)> SizeRef(2)
    while refROI(3)<1 || refROI(4)> SizeRef(1) || refROI(1)<1 || refROI(2)> SizeRef(2)
        disp('Window out of bounds. Please, select again.')
        rect = getrect();
        ROI = uint16([rect(1) rect(1)+rect(3) rect(2) rect(2)+rect(4)]);
        
        refRect = rect - [dw dh 0 0];
        refROI = uint16([refRect(1) refRect(1)+refRect(3) refRect(2) refRect(2)+refRect(4)]);
        
        refFrame = (filter2(hSmall,refFrame1) - filter2(hLarge, refFrame1));
        
        SizeRef = size(refFrame);
    end
end
refFrame = refFrame(refROI(3):refROI(4),refROI(1):refROI(2));




refFrame = (refFrame-min(min(refFrame)))/max(max(refFrame-min(min(refFrame))));

frame = (filter2(hSmall,frame) - filter2(hLarge, frame));
frame = frame(ROI(3):ROI(4),ROI(1):ROI(2));
frame = (frame-min(min(frame)))/max(max(frame-min(min(frame))));


[optimizer,metric] = imregconfig('multimodal');
tform = imregtform(frame,refFrame,'translation',optimizer,metric); %rigid, similarity
movingRegistered = imwarp(frame,tform,'OutputView',imref2d(size(refFrame)));
tform.T = tform.T - [0,0,0;0,0,0;dw,dh,0];



subplot(2,3,1)
imshow(((refFrame+1).^1.5)-1);
caxis([0 1])
title(['Session ' num2str(i)])
subplot(2,3,2)
imshow(((movingRegistered+1).^1.5)-1);
caxis([0 1])
title(['Session ' num2str(j) ' displaced'])
subplot(2,3,4)
imshow(((movingRegistered+1).^1.5)-1);
caxis([0 1])
title(['Session ' num2str(j) ' displaced'])
subplot(2,3,3)
imshow(uint8(refFrame1));
hold on
plot(curserW(1),curserH(1),'+r','markersize',40);
hold off
subplot(2,3,6)
imshow(uint8(frame1));
hold on
plot(curserW(1)-tform.T(3,1),curserH(1)-tform.T(3,2),'+r','markersize',40);
hold off

Corr = corr(movingRegistered(:),refFrame(:));
%     subplot(2,3,[ 3  6])
title({['Correlation RefFrame x Frame = ' num2str(Corr)],['wShift: ' num2str(tform.T(3,1)) ' | hShift: ' num2str(tform.T(3,2))]});
[~,~]=ginput(1);


end

