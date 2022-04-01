function FR = CalcFoopsiThresh(Data,DownSampleFactor)
% Function to calculate the Foopsi Thresholded deconvolution of a dataset
% comprising recordings of calcium imaging data.
% Reference paper: Friedrich, J., Zhou, P. and Paninski, L., 2017. Fast 
% online deconvolution of calcium imaging data. PLoS computational biology, 
% 13(3), p.e1005423.
%
% INPUTS:
%   Data: m x n matrix, with "m" time series and with "n" datapoints
%   each. Usually the neuron.C_ray from the CNMF-E algorithm.
%   DownSampleFactor: positive scalar with the downsampling factor for improving
%   the activity definition.
% OUTPUT:
%   FR: m x n matrix, with "m" time series and with "n" datapoints
%   each. This represents the putative activity of each cell.
%
% Daniel Almeida Filho (Oct, 2019) almeidafilhodg@ucla.edu
% almeidafilhodg@ucla.edu

timevecDiff=DownSampleFactor/2:DownSampleFactor:size(Data,2)+DownSampleFactor/2;
FR = nan(size(Data));
for i = 1:size(Data,1)
    temp = Data(i,:)';
    temp = conv(temp,rectwin(DownSampleFactor)/DownSampleFactor,'same');
    temp = temp(1:DownSampleFactor:end);
    [~,temp2, ~] = deconvolveCa(temp, 'ar1', ...
        'thresholded', 'optimize_smin', true,'optimize_pars', true,'thresh_factor', 0.99);  %#ok<*ASGLU>
    temp2=interp1(timevecDiff(1:length(temp2)),temp2,0:size(Data,2)-1);
    temp2(isnan(temp2))=0;
    FR(i,:)=temp2;%./nanmax(temp2);
end