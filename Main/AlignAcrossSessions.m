
function [Alignment,Correlation]=AlignAcrossSessions(animal)

figure('units','normalized','outerposition',[0 0 1 1])
colormap gray
hLarge = fspecial('average', 40);
hSmall = fspecial('average', 3);
[optimizer,metric] = imregconfig('multimodal');
optimizer.MaximumIterations=300;
optimizer.GrowthFactor=1.01;
optimizer.Epsilon=1.5e-8;
optimizer.InitialRadius=6.25e-4;

NSess = length(animal);
idx=1;
while isempty(animal{idx})
    idx=idx+1;
end
Height = size(animal{idx}.meanFrame,1);
Width = size(animal{idx}.meanFrame,2);

WinSx = floor(Width/2);
WinSy = floor(Height/2);

WinsX = [0 WinSx/2 Width-WinSx];
WinsY = [0 WinSy/2 Height-WinSy];
ThreshDispl = Height/100; %in pixels
ThreshCorr = .6;

for i = 1:NSess
    if ~isempty(animal{i})
        meanFrame1 = animal{i}.meanFrame;
        meanFrame1F = (filter2(hSmall,meanFrame1) - filter2(hLarge, meanFrame1));
        for j = i:NSess
            if ~isempty(animal{j})
                meanFrame2 = animal{j}.meanFrame;
                meanFrame2F = (filter2(hSmall,meanFrame2) - filter2(hLarge, meanFrame2));
                BufferDispl = [];
                CorrM = [];
                valM1=[];
                valM2=[];
                BufferPatches.p1 = [];
                BufferPatches.p2 = [];
                for x=1:3
                    parfor y=1:3
                        idxX = WinsX(x)+1:WinsX(x)+WinSx;
                        idxY = WinsY(y)+1:WinsY(y)+WinSy;
                        patchM1 = meanFrame1F(idxY,idxX);
                        val1(y) = nanmean(patchM1(:));
                        patchM2 = meanFrame2F(idxY,idxX);
                        val2(y) = nanmean(patchM2(:));
                        tform1 = imregtform(patchM2,patchM1,'translation',optimizer,metric);
                        dhM = tform1.T(3,1);
                        dwM = tform1.T(3,2);
                        FixedM2 = imwarp(patchM2,tform1,'OutputView',imref2d(size(patchM1)));
                        CorrT(y)=corr(patchM1(:),FixedM2(:));
                        BufferDisplT(y,:) = [dhM dwM];
                        patchM1 = patchM1 + abs(min(patchM1(:)));
                        FixedM2 = FixedM2 + abs(min(FixedM2(:)));
                        p1(:,:,y)=(patchM1/max(patchM1(:)))+1;
                        p2(:,:,y)=(FixedM2/max(FixedM2(:)))+1;
                        if y==3
                            temp{y}=tform1;
                        end
                    end
                    tform=temp{3};
                    valM1 = [valM1 val1];
                    valM2 = [valM2 val2];
                    CorrM = [CorrM CorrT];
                    BufferDispl = [BufferDispl;BufferDisplT];
                    BufferPatches.p1 = cat(3,BufferPatches.p1,p1);
                    BufferPatches.p2 = cat(3,BufferPatches.p2,p2);
                end
                clc
                [~,highers1] = sort(valM1,'descend');
                [~,highers2] = sort(valM2,'descend');
                chosen = unique([highers1(1:3) highers2(1:3)]);
                DisplacementDesv = std(BufferDispl(chosen,:));
                [~,chosen2] = max(CorrM(chosen));
                clf
                display(['Aligning sessions ' num2str(i) ' with ' num2str(j)])
                if ~isempty(find(abs(DisplacementDesv)>ThreshDispl,1)) || CorrM(chosen2)<ThreshCorr
                    userInput = 'N';
                    while (strcmp(userInput,'N'))
                        [tform,Corr]=ManualAlignSessions(meanFrame1,meanFrame2,i,j);
                        userInput = upper(input('Keep alignment? (Y/N)','s'));
                    end
                else
                    tform.T(3,1:2)=BufferDispl(chosen2,:);
                    Corr = CorrM(chosen2);
                    
                    subplot(2,3,1)
                    imagesc((squeeze(BufferPatches.p1(:,:,chosen2)).^1.5)-1);
                    caxis([0 1])
                    title(['Session ' num2str(i)])
                    subplot(2,3,2)
                    imagesc((squeeze(BufferPatches.p2(:,:,chosen2)).^1.5)-1)
                    caxis([0 1])
                    title(['Session ' num2str(j) ' displaced'])
                    subplot(2,3,4)
                    imagesc((squeeze(BufferPatches.p2(:,:,chosen2)).^1.5)-1)
                    caxis([0 1])
                    title(['Session ' num2str(j) ' displaced'])
                    subplot(2,3,3)
                    imshow(uint8(meanFrame1));
                    subplot(2,3,6)
                    imshow(uint8(meanFrame2));
                    title({['Correlation RefFrame x Frame = ' num2str(Corr)],['wShift: ' num2str(tform.T(3,1)) ' | hShift: ' num2str(tform.T(3,2))]});
                    [~,~]=ginput(1);
                    userInput = 'N';
                    while (strcmp(userInput,'N'))
                        userInput = upper(input('Type X to change to manual, or Y to keep alignment: ','s' ));
                        if (strcmp(userInput,'X'))
                            userInput = 'N';
                            while (strcmp(userInput,'N'))
                                [tform,Corr]=ManualAlignSessions(meanFrame1,meanFrame2,i,j);
                                userInput = upper(input('Keep alignment? (Y/N)','s'));
                            end
                        end
                    end
                end
                Alignment{i,j}=tform;
                Alignment{j,i}=tform;
                Alignment{j,i}.T(3,1:2)=-1*(Alignment{j,i}.T(3,1:2));
                Correlation(i,j)=Corr;
                Correlation(j,i)=Corr;
            end
        end
    end
end


end


