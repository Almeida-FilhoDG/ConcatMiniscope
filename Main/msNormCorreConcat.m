function ms = msNormCorreConcat(ms,isnonrigid,ROIflag,plotFlag,checkMotCorr)
% Performs fast, rigid registration (option for non-rigid also available).
% Relies on NormCorre (Paninski lab). Rigid registration works fine for
% large lens (1-2mm) GRIN lenses, while non-rigid might work better for
% smaller lenses. Ideally you want to compare both on a small sample before
% choosing one method or the other.
% Original script by Eftychios Pnevmatikakis, edited by Guillaume Etter
% Edited by Daniel Almeida Filho Mar/2020 (SilvaLab - UCLA)
% Updated by Daniel Almeida Filho Aug/2020 (SilvaLab - UCLA)
% Updated by Daniel Almeida Filho Oct/2021 (SilvaLab - UCLA)
% Updated by Daniel Almeida Filho Apr/2022 (SilvaLab - UCLA)

warning off all
if nargin < 5
    checkMotCorr = false;
    if nargin<4
        plotFlag = false;
        if nargin<3
            ROIflag=false;
        end
    end
end

%% Filtering parameters
ds = ms.ds;
gSig = 7/ds;
gSiz = 17/ds;
psf = fspecial('gaussian', round(2*gSiz), gSig);
ind_nonzero = (psf(:)>=max(psf(:,1)));
psf = psf-mean(psf(ind_nonzero));
psf(~ind_nonzero) = 0;
bound = 4*gSiz;
gridSize = [128 128];

template = [];

writerObj = VideoWriter([ms.dirName filesep ms.analysis_time filesep 'msvideo.avi'],'Grayscale AVI');
if isfield(ms,'FrameRate')
    writerObj.FrameRate = ms.FrameRate;
end
open(writerObj);

ms.shifts = [];
ms.meanFrame = [];
for video_i = 1:ms.numFiles
    answer='No';
    tic
    name = [ms.vidObj{1, video_i}.Path filesep ms.vidObj{1, video_i}.Name];
    disp(['Registration on: ' name]);
    if ismember(ms.equipment,{'v4','V4'})
        gridSize = [164 164];
    end
    % read data and convert to single
    Yf = single(read_file(name));
    
    Yf = downsample_data(Yf,'space',1,ms.ds,1);
    
    Y = imfilter(Yf,psf,'symmetric');
    [d1,d2,~] = size(Y);
    % Setting registration parameters (rigid vs non-rigid)
    if isnonrigid
        disp('Non-rigid motion correction...');
        options = NoRMCorreSetParms('d1',d1-bound,'d2',d2-bound,'bin_width',50, ...
            'grid_size',gridSize*2,'mot_uf',4,'correct_bidir',false, ...
            'overlap_pre',32,'overlap_post',32,'max_shift',20);
    else
        disp('Rigid motion correction...');
        options = NoRMCorreSetParms('d1',d1-bound,'d2',d2-bound,'bin_width',200,...
            'max_shift',20,'iter',1,'correct_bidir',false);
    end
    
    while strcmp(answer,'No') % Testing if Motion Correction is good in the first video
        if video_i == 1
            if ROIflag
                [~,mask,~] = selectROI(Y,false);
                mask = single(mask);
            else
                mask = single(ones(size(Y,1),size(Y,2)));
            end
        else
            answer='Yes';
        end
        Y2 = Y.*repmat(mask,1,1,size(Y,3));
        
        if ~checkMotCorr
            answer='Yes';
        end
        
        %% register using the high pass filtered data and apply shifts to original data
        if isempty(template)
            [M1,shifts1,template] = normcorre(Y2(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:),options); % register filtered data
            % exclude boundaries due to high pass filtering effects
        else
            [M1,shifts1,template] = normcorre(Y2(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:),options,template); % register filtered data
        end
        
        Mr = apply_shifts(Yf,shifts1,options,bound/2,bound/2); % apply shifts to full dataset
        if strcmp(answer,'No')
            answer = checkMotionCorrection(Yf,Mr);
        end
    end
    % apply shifts on the whole movie
    if size(Mr,3)<4 % (1/2)workaround because the writeVideo function
        %gets confused when there is a video with only 3 frames.
        % It misunderstands it as an RGB 1-frame video.
        temp = Mr;
        Mr = reshape(Mr,size(Mr,1),size(Mr,2),1,size(Mr,3));
    end
    writeVideo(writerObj,uint8(Mr));
    
    if length(size(Mr))==4 % (2/2)workaround because the writeVideo function
        %gets confused when there is a video with only 3 frames.
        % It misunderstands it as an RGB 1-frame video.
        Mr=temp;
    end
    
    %% compute metrics
    [cY,~,~] = motion_metrics(Y(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:),options.max_shift);
    [cYf,~,~] = motion_metrics(Yf,options.max_shift);
    
    [cM1,~,~] = motion_metrics(M1,options.max_shift);
    [cM1f,mM1f,~] = motion_metrics(Mr,options.max_shift);
    
    %% plot rigid shifts and metrics
    shifts = squeeze(cat(3,shifts1(:).shifts));
    if plotFlag
        figure('units','normalized','outerposition',[0 0 1 1])
        subplot(311); plot(shifts);
        title('Rigid shifts','fontsize',14,'fontweight','bold');
        legend('y-shifts','x-shifts');
        subplot(312); plot(1:T,cY,1:T,cM1);
        title('Correlation coefficients on filtered movie','fontsize',14,'fontweight','bold');
        legend('raw','rigid');
        subplot(313); plot(1:T,cYf,1:T,cM1f);
        title('Correlation coefficients on full movie','fontsize',14,'fontweight','bold');
        legend('raw','rigid');
    end
    if video_i == 1
        ms.meanFrame = mM1f;
    else
        ms.meanFrame = (ms.meanFrame + mM1f)./2;
    end
    corr_gain = cYf./cM1f*100;
    
    ms.maskROI = mask;
    ms.shifts{video_i} = shifts1;
    ms.templateMotionCorr = template;
    ms.XYshifts{video_i} = shifts;
    ms.CorrFiltered{video_i} = [cY;cM1];
    ms.CorrFullMovie{video_i} = [cYf;cM1f];
    toc
end

close(writerObj);

end