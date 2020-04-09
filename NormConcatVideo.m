function Total3d = NormConcatVideo(Matrix,concatInfo)
%%% Normalize the concatenated videos to enhance cell detection
if ispc
    separator = '\'; % For pc operating  syste  ms
else
    separator = '/'; % For unix (mac, linux) operating systems
end

Dims = size(Matrix);
Matrix = reshape(Matrix,prod(Dims(1:2)),Dims(3));
if isfield(concatInfo,'FrameRate')
    win = floor(concatInfo.FrameRate);
else
    win = 30;
end
HalthWin = ceil(win/2);
Sizes = concatInfo.NumberFramesSessions;
a=single(Matrix(:,1:Sizes(1)));
b=single(Matrix(:,Sizes(1)+1:sum(Sizes(1:2))));
c=single(Matrix(:,sum(Sizes(1:2))+1:sum(Sizes)));

nPix = size(Matrix,1);
parfor i=1:nPix
    actual = conv(a(i,:),rectwin(win)/win,'same');
    surrog = nanmedian(actual(HalthWin+1:end-HalthWin));
    actual([1:HalthWin length(actual)-HalthWin+1:length(actual)]) = surrog;
    a(i,:) = actual;
    actual = conv(b(i,:),rectwin(win)/win,'same');
    surrog = nanmedian(actual(HalthWin+1:end-HalthWin));
    actual([1:HalthWin length(actual)-HalthWin+1:length(actual)]) = surrog;
    b(i,:) = actual;
    actual = conv(c(i,:),rectwin(win)/win,'same');
    surrog = nanmedian(actual(HalthWin+1:end-HalthWin));
    actual([1:HalthWin length(actual)-HalthWin+1:length(actual)]) = surrog;
    c(i,:) = actual;
end


a2 = iqr(a')';
a2(a2<1)=1;
b2 = iqr(b')';
b2(b2<1)=1;
c2 = iqr(c')';
c2(c2<1)=1;

d=((a-repmat(median(a')',1,size(a,2)))./repmat(a2,1,size(a,2)));
e=((b-repmat(median(b')',1,size(b,2)))./repmat(b2,1,size(b,2)));
f=((c-repmat(median(c')',1,size(c,2)))./repmat(c2,1,size(c,2)));

Total = [d e f];
Total = ((Total-nanmin(Total(:)))./(nanmax(Total(:))-nanmin(Total(:)))).*255;
Total = uint8(Total);
Total3d = reshape(Total,Dims(1),Dims(2),Dims(3));


writerObj = VideoWriter([concatInfo.path separator concatInfo.ConcatFolder separator 'FinalConcatNorm1.avi'],'Grayscale AVI');
if isfield(concatInfo,'FrameRate')
    writerObj.FrameRate = concatInfo.FrameRate;
end
open(writerObj);
writeVideo(writerObj,Total3d);
close(writerObj);

clear a b c d e f  