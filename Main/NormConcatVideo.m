function Matrix = NormConcatVideo(Matrix,concatInfo,savingPath)
%%% Normalize the concatenated videos to enhance cell detection

Dims = size(Matrix);
Matrix = single(reshape(Matrix,prod(Dims(1:2)),Dims(3)));
win = floor(concatInfo.FrameRate);
HalthWin = ceil(win/2);
Sizes = concatInfo.NumberFramesSessions;

nPix = size(Matrix,1);
if prod(Dims) <= 2e6
    subSample = single(1:prod(Dims));
else
    subSample = randperm(prod(Dims),2e6);
end
IQR = iqr(Matrix(subSample));

in = 1;
for sess = 1:length(Sizes)
    idxs = in:sum(Sizes(1:sess));
    actual = Matrix(:,idxs);
    disp(['Normalizing session ' concatInfo.Sessions(concatInfo.order(sess)).name])
    parfor i=1:nPix
        if mod(i,round(nPix/20))==0
            disp(['Smoothing at ' num2str((i/nPix)*100) '%'])
        end
        actual2 = (actual(i,:)-median(actual(i,:)))/IQR;
        actual2 = conv(actual2,rectwin(win)/win,'same');        
        surrog = nanmedian(actual2(HalthWin+1:end-HalthWin));
        actual2([1:HalthWin length(actual2)-HalthWin+1:length(actual2)]) = surrog;
        actual(i,:)=actual2;
    end

    Matrix(:,idxs) = actual;
    in=sum(Sizes(1:sess))+1;
end

Matrix = ((Matrix-nanmin(Matrix(:)))./(nanmax(Matrix(:))-nanmin(Matrix(:)))).*255;
Matrix = uint8(Matrix);
Matrix = reshape(Matrix,Dims(1),Dims(2),Dims(3));



writerObj = VideoWriter([savingPath filesep 'FinalConcatNorm1.avi'],'Grayscale AVI');
writerObj.FrameRate = concatInfo.FrameRate;
open(writerObj);
writeVideo(writerObj,Matrix);
close(writerObj);

