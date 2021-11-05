function answer = checkMotionCorrection(BeforeCorrection,AfterCorrection)

global ff
% global answer
ff=figure('units','normalized','outerposition',[0 0 1 1]);
set(ff,'KeyPressFcn',@myfun);
%
colormap gray

prompt1 = {['Frame # (from ' num2str(size(BeforeCorrection,3)) '):']};
dlgtitle1 = 'Start from...';
dims1 = [1 55];
definput1 = {'1'};
i = str2double(inputdlg(prompt1,dlgtitle1,dims1,definput1));


%i=1;
actFrame = squeeze(BeforeCorrection(:,:,i));
subplot(20,2,3:2:40)
imagesc(actFrame)
set(gca,'yticklabel',[],'xticklabel',[],'Yminorgrid','on','Xminorgrid','on',...
    'gridcolor',[1 0 0],'linewidth',1.5,'minorgridcolor',[1 0 0])
daspect([1 1 1])
title(['Before Motion Correction (Frame Number = ' num2str(i) '/' num2str(size(BeforeCorrection,3)) ')'],'fontsize',16)

actCorrFrame = squeeze(AfterCorrection(:,:,i));
subplot(20,2,4:2:40)
imagesc(actCorrFrame)
set(gca,'yticklabel',[],'xticklabel',[],'Yminorgrid','on','Xminorgrid','on',...
    'gridcolor',[1 0 0],'linewidth',1.5,'minorgridcolor',[1 0 0])
daspect([1 1 1])
title(['After Motion Correction (Frame Number = ' num2str(i) '/' num2str(size(BeforeCorrection,3)) ')'],'fontsize',16);
subplot(20,2,1:2)
text(0.5,0.5,{'Use arrows (<-- or -->) to change frames.','Press ESC when finish checking!'},'fontweight','bold','fontsize',20,...
    'horizontalalignment','center','verticalalignment','bottom','color',[1 0 0])
set(gca,'xtick',[],'ytick',[],'box','off')
uiwait(ff);
    function myfun(~,event)
        a=event.Key;
        %         disp(a);
        switch a
            case 'rightarrow'
                i=i+1;
            case 'leftarrow'
                i=i-1;
            case 'escape'
                answer = getAnswer();
                close(ff);
                return
        end
        actFrame = squeeze(BeforeCorrection(:,:,i));
        clf
        subplot(20,2,3:2:40)
        imagesc(actFrame)
        set(gca,'yticklabel',[],'xticklabel',[],'Yminorgrid','on','Xminorgrid','on',...
            'gridcolor',[1 0 0],'linewidth',1.5,'minorgridcolor',[1 0 0])
        daspect([1 1 1])
        title(['Before Motion Correction (Frame Number = ' num2str(i) '/' num2str(size(BeforeCorrection,3)) ')'],'fontsize',16)
        
        actCorrFrame = squeeze(AfterCorrection(:,:,i));
        subplot(20,2,4:2:40)
        imagesc(actCorrFrame)
        set(gca,'yticklabel',[],'xticklabel',[],'Yminorgrid','on','Xminorgrid','on',...
            'gridcolor',[1 0 0],'linewidth',1.5,'minorgridcolor',[1 0 0])
        daspect([1 1 1])
        title(['After Motion Correction (Frame Number = ' num2str(i) '/' num2str(size(BeforeCorrection,3)) ')'],'fontsize',16)
        subplot(20,2,1:2)
        text(0.5,0.5,{'Use arrows (<-- or -->) to change frames.','Press ESC when finish checking!'},'fontweight','bold','fontsize',20,...
            'horizontalalignment','center','verticalalignment','bottom','color',[1 0 0])
        set(gca,'xtick',[],'ytick',[],'box','off')
    end

    function temp = getAnswer()
        temp = questdlg('Is motion correction good?', ...
            'Check options', ...
            'Yes','No','Yes');
    end
end