function Matrix = NormConcatVideo(Matrix,concatInfo)
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
in = 1;
for sess = 1:length(Sizes)
    idxs = in:sum(Sizes(1:sess));
    actual = Matrix(:,idxs);
    disp(['Normalizing session ' concatInfo.Sessions(concatInfo.order(sess)).name])
    parfor i=1:nPix
        if mod(i,round(nPix/20))==0
            disp(['Smoothing at ' num2str((i/nPix)*100) '%'])
        end
        actual2 = conv(actual(i,:),rectwin(win)/win,'same');
        surrog = nanmedian(actual2(HalthWin+1:end-HalthWin));
        actual2([1:HalthWin length(actual2)-HalthWin+1:length(actual2)]) = surrog;
        actual(i,:)=actual2;
    end
    actual2 = iqr(actual')';
    actual2(actual2<1)=1;
    actual3 = ((actual-repmat(nanmedian(actual')',1,size(actual,2)))./repmat(actual2,1,size(actual,2)));
    
    Matrix(:,idxs) = actual3;
    in=sum(Sizes(1:sess))+1;
end

Matrix = ((Matrix-nanmin(Matrix(:)))./(nanmax(Matrix(:))-nanmin(Matrix(:)))).*255;
Matrix = uint8(Matrix);
Matrix = reshape(Matrix,Dims(1),Dims(2),Dims(3));



writerObj = VideoWriter([concatInfo.path separator concatInfo.ConcatFolder separator 'FinalConcatNorm1.avi'],'Grayscale AVI');
writerObj.FrameRate = concatInfo.FrameRate;
open(writerObj);
writeVideo(writerObj,Matrix);
close(writerObj);

