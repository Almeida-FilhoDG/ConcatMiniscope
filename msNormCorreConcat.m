function [concatInfo,Mr] = msNormCorreConcat(Yf,concatInfo,plotFlag)
% Performs fast, rigid registration (option for non-rigid also available).
% Relies on NormCorre (Paninski lab). Rigid registration works fine for
% large lens (1-2mm) GRIN lenses, while non-rigid might work better for
% smaller lenses. Ideally you want to compare both on a small sample before
% choosing one method or the other.
% Original script by Eftychios Pnevmatikakis, edited by Guillaume Etter
% Edited by Daniel Almeida Filho Mar/2020 (SilvaLab - UCLA)
warning off all
%% Auto-detect operating system
if ispc
    separator = '\'; % For pc operating systems
else
    separator = '/'; % For unix (mac, linux) operating systems
end

%% Filtering parameters
ds = concatInfo.spatial_downsampling;
gSig = 7/ds;
gSiz = 17/ds;
psf = fspecial('gaussian', round(2*gSiz), gSig);
ind_nonzero = (psf(:)>=max(psf(:,1)));
psf = psf-mean(psf(ind_nonzero));
psf(~ind_nonzero) = 0;
bound = 4*gSiz;

template = concatInfo.template;
Lims = concatInfo.CutFromBorders;

writerObj = VideoWriter([concatInfo.path separator concatInfo.ConcatFolder separator 'FinalConcatVideo.avi'],'Grayscale AVI');
writerObj.FrameRate = concatInfo.FrameRate;
open(writerObj);

concatInfo.shifts = [];

tic
name = strcat(concatInfo.path,separator,concatInfo.ConcatFolder,separator,'ConcatenatedVideo.avi');

% read data and convert to single
Yf = single(Yf);

Y = imfilter(Yf,psf,'symmetric');
[d1,d2,T] = size(Y);

[d3,d4] = size(template);

LimsW = 1 + Lims(3):d4 + Lims(1);
LimsH = 1 + Lims(4):d3 + Lims(2);
template=template(LimsH,LimsW);

disp('Rigid motion correction...');
options = NoRMCorreSetParms('d1',d1-bound,'d2',d2-bound,'bin_width',200,...
    'max_shift',20,'iter',1,'correct_bidir',false,'upd_template',false);

%% register using the high pass filtered data and apply shifts to original data

[M1,shifts1,~] = normcorre_batch(Y(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:),options,template); % register filtered data

Mr = apply_shifts(Yf,shifts1,options,bound/2,bound/2); % apply shifts to full dataset
% apply shifts on the whole movie

writeVideo(writerObj,uint8(Mr));

close(writerObj);

%% compute metrics
[cY,~,~] = motion_metrics(Y(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:),options.max_shift);
[cYf,~,~] = motion_metrics(Yf,options.max_shift);

[cM1,~,~] = motion_metrics(M1,options.max_shift);
[cM1f,~,~] = motion_metrics(Mr,options.max_shift);

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
concatInfo.shifts = shifts1;
concatInfo.XYshifts = shifts;
concatInfo.CorrFiltered = [cY;cM1];
concatInfo.CorrFullMovie = [cYf;cM1f];

toc



end