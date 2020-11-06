function runConcatStep8(path)



%% Pipeline for the proper concatenation of miniscope data across sessions
% Developed by Daniel Almeida Filho July/2020 (SilvaLab - UCLA)
% If you have any questions, please send an email to
% almeidafilhodg@ucla.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Auto-detect operating system
if ispc
    separator = '\'; % For pc operating  syste  ms
else
    separator = '/'; % For unix (mac, linux) operating systems
end


%% Step 8 (optional): Join all the activity in just one file

joinActivity(strcat(path,separator,'Concatenation'))
