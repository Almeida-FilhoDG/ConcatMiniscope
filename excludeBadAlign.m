function concatInfo = excludeBadAlign(concatInfo)

CorrValues = concatInfo.AllCorrelation;
ff = figure;
imagesc(CorrValues),caxis([0 1])
title('Correlation Matrix'),colormap(jet),colorbar
xlabel('Sessions'),ylabel('Sessions')
set(gca,'ticklength',[0 0],'fontsize',12,'fontweight','bold')
nSessions = length(concatInfo.Sessions);
for i=1:nSessions
    for j=1:nSessions
        text(i,j,num2str(round(CorrValues(i,j)*100)/100),'color','k','fontweight','bold','HorizontalAlignment','Center')
    end
end
answer = questdlg('Would you like to exclude any session due to bad alignment?', ...
	'Session Deletion', ...
	'Yes','No','No');
% Handle response
switch answer
    case 'Yes'
        list={};
        iidx=[];
        for ii=1:nSessions
            if ii ~= concatInfo.refSession
                iidx=[iidx ii];
            end
            list{ii} = num2str(ii);
        end
        list = list(iidx);
        [indx,~] = listdlg('PromptString',{['Ref Session = ' num2str(concatInfo.refSession)],'Select bad alignment sessions.'},...
            'ListString',list);
        acc=[];
        for ii = 1:length(indx)
            act = str2double(list{indx(ii)});
            concatInfo.FinalAlignment{1,str2double(list{indx(ii)})}=[];
            acc = [acc act];
        end
        msgbox(['Session(s) ' num2str(acc) ' excluded. Proceeding to concatenation!'],'','warn')
    
    case 'No'
        msgbox('No alignment issues. Proceeding to concatenation!','','help')
end
close(ff)