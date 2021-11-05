function [FR,HighNoiseIDX] = convolve1D(rawFluor,fps,dSFactor)
% Function to calculate the putatiuve activity of neurons recorded through
% calcium imaging algorithm.
% 
% INPUTS:
%   rawFluor: m x n matrix, with "m" time series and with "n" datapoints
%   each. Usually the neuron.C_ray from the CNMF-E algorithm.
%   fps: positive scalar with sampling rate of the recordings in frames per second.
%   dSFactor: positive scalar with the downsampling factor for improving
%   the activity definition.
% OUTPUT:
%   FR: m x n matrix, with "m" time series and with "n" datapoints
%   each. This represents the putative activity of each cell.
%   HighNoiseIDX: Vector of scalar with the indexes of the neurons that may 
%   present too much noise and should be analyzed closer. 
% Developed by Daniel Almeida Filho (Oct, 2019) almeidafilhodg@ucla.edu
% Calculating with temporal downsample - Daniel Almeida Filho (Nov, 2019). 
% Adding one more criteria (Bumps after peaks) in June/2020 
% Adding the putative noise detection in June 2020.
% almeidafilhodg@ucla.edu

win = dSFactor*(1/fps);
Std1=fps*(win/2);
Std2=Std1*2;
Std3=fps*(win/4);
nPts = round(win*fps);
dt = 1/fps;

FR=nan(size(rawFluor));
kernel1=gaussmf(1:199,[Std1 100]);
kernel1=kernel1/sum(kernel1);

kernel2=gaussmf(1:199,[Std2 100]);
kernel2=kernel2/sum(kernel2);

kernel3=gaussmf(1:199,[Std3 100]);
kernel3=kernel3/sum(kernel3);

%%%%% Parameters
Stringency1 = 1.5; %how many IQRs summed with 3rd quartile
Stringency2 = 1.5; %how many IQRs summed with 3rd quartile
StringencyNoise = 1.5; %how many IQRs summed with 3rd quartile

winBumpLength = 1; %in seconds

%%%% Threshold for detecting neurons with putative high noise level. 
%%%% Look closer! %%%%
highNoisePercLim = 2; % 200% difference between Q1 and Q3 quartiles (triple)
threshPNR = 20; %max peak is 20 times the noise
%%%%%%%%

winNoisePts = round(winBumpLength/dt); %in data points
winBumpPts = floor(winNoisePts/nPts); %in data points
if winBumpPts < 3
    winBumpPts = 3;
end

winNoise = zeros(1,2*winNoisePts+1);
winNoise(end-winNoisePts+1:end) = rectwin(winNoisePts);
winNoise = winNoise/sum(winNoise);


winBump = zeros(1,2*winBumpPts+1);
winBump(end-winBumpPts+1:end) = rectwin(winBumpPts);
winBump = winBump/(sum(winBump)*2);
winBump(end-winBumpPts)=-.5;


winHighAmpNoisePts = floor(winBumpLength/2*fps);
if mod(winHighAmpNoisePts,2) == 0
    winHighAmpNoisePts = winHighAmpNoisePts + 1;
end
highAmpNoiseKernel = rectwin(winHighAmpNoisePts)/winHighAmpNoisePts;
HighNoiseIDX = zeros(1,size(rawFluor,1));

%%%%
timevecDiff=nPts/2:nPts:size(rawFluor,2)+nPts/2;
%%%%
for i = 1:size(rawFluor,1)
    actual = rawFluor(i,:);
    actual = detrend(actual);
    actual = actual - quantile(actual,.25);
    
    temp=conv(actual,kernel1,'same');
    
    %%%%%
    temp = temp(1:nPts:end);
    %%%%%
   
    Diff1=[0 diff(temp)];
    Diff1(Diff1<0)=0;
    thresh1 = quantile(Diff1,.75)+Stringency1*iqr(Diff1);
    
    indexes1 = Diff1>thresh1;
    
    temp=conv(actual,kernel2,'same');
    
    %%%%% Noise threshold and IQR
    noise = actual - temp;
    highAmpNoise = conv(abs(noise),highAmpNoiseKernel,'same');
    threshHighAmpNoise = quantile(highAmpNoise,.75)/quantile(highAmpNoise,.25);
    if threshHighAmpNoise >= (1 + highNoisePercLim)
        HighNoiseIDX(i) = true;
    end
    
    tempNoise = noise(1:nPts:end);
    tempNoise = conv(tempNoise,fliplr(winNoise),'same');
    threshNoise = quantile(tempNoise,.75)+StringencyNoise*iqr(tempNoise);
    %%%%%%
    
    %%%%%
    temp = temp(1:nPts:end);
    %%%%%
    Diff2=[0 diff(temp)];
    Diff2(Diff2<0)=0;
    thresh2 = quantile(Diff2,.75)+Stringency2*iqr(Diff2);
    
    indexes2 = ~([false (temp(1:end-1) < 0)]);
    
    indexes3 = Diff2>thresh2;
    
    %%% Condition for positive Bump
    positiveBump = conv(temp,fliplr(winBump),'same');
    indexes4 = positiveBump>threshNoise;
    %%%
    
    
    indexesFinal = indexes1 & indexes2 & indexes3 & indexes4;
    
    temp=conv(actual,kernel3,'same');
    
    %%%%%
    temp = temp(1:nPts:end);
    %%%%%
    
    DiffFinal=[0 diff(temp)];
    DiffFinal(DiffFinal<0)=0;
    DiffFinal(~indexesFinal)=0;
    
    temp=interp1(timevecDiff(1:length(DiffFinal)),DiffFinal,0:size(rawFluor,2)-1);
    temp(isnan(temp))=0;
    %%%% 
    maxVar = max(actual(temp>0));
    if isempty(maxVar)
        maxVar=0;
    end
    if maxVar/iqr(highAmpNoise) < threshPNR
        HighNoiseIDX(i) = true;
    end
    FR(i,:)=temp;%/nanmax(temp);
end
HighNoiseIDX = find(HighNoiseIDX);
