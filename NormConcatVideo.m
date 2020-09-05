function Total3d = NormConcatVideo(Matrix,concatInfo)
%%% Normalize the concatenated videos to enhance cell detection
if ispc
    separator = '\'; % For pc operating  syste  ms
else
    separator = '/'; % For unix (mac, linux) operating systems
end

Dims = size(Matrix);
Matrix = single(reshape(Matrix,prod(Dims(1:2)),Dims(3)));
win = floor(concatInfo.FrameRate);
HalthWin = ceil(win/2);
Sizes = concatInfo.NumberFramesSessions;

nPix = size(Matrix,1);
parfor i=1:nPix
    actual = conv(Matrix(i,:),rectwin(win)/win,'same');
    in=1;
    temp = [];
%     if mod(i,round(nPix/20))==0
%         disp(['Smoothing at ' num2str((i/nPix)*100) '%'])
%     end
    for sess = 1:length(Sizes)
        idxs = in:sum(Sizes(1:sess));
        actual2 = actual(idxs);
        surrog = nanmedian(actual2(HalthWin+1:end-HalthWin));
        actual2([1:HalthWin length(actual2)-HalthWin+1:length(actual2)]) = surrog;
        temp = [temp actual2];
        in=sum(Sizes(1:sess))+1;
    end
    Matrix(i,:) = temp;
end

in=1;
Total = [];
for sess = 1:length(Sizes)
    tic
    idxs = in:sum(Sizes(1:sess));
    actual = Matrix(:,idxs);
    actual2 = iqr(actual')';
    actual2(actual2<1)=1;
    
    actual3 = ((actual-repmat(median(actual')',1,size(actual,2)))./repmat(actual2,1,size(actual,2)));
    Total = [Total actual3];
    in=sum(Sizes(1:sess))+1;
    toc
end

Total = ((Total-nanmin(Total(:)))./(nanmax(Total(:))-nanmin(Total(:)))).*255;
Total = uint8(Total);
Total3d = reshape(Total,Dims(1),Dims(2),Dims(3));


writerObj = VideoWriter([concatInfo.path separator concatInfo.ConcatFolder separator 'FinalConcatNorm1.avi'],'Grayscale AVI');
writerObj.FrameRate = concatInfo.FrameRate;
open(writerObj);
writeVideo(writerObj,Total3d);
close(writerObj);

