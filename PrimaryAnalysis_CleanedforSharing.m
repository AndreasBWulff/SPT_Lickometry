%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Primary analysis of lickometry data recorded with clampex %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% loads abf files and detects peaks. timestamps of peaks are written
%%%%% into an excel sheet.


%%%%% Requires abfload (fcollman/abfload v1.13)

%%%%% analysis was perfored using 80 mV peak prominence - rarely captured
%%%%% noise but sometimes missed licks. Reanalysis were performed with peak
%%%%% prominence of 10 mV in cases where data did not fit align with
%%%%% overall correlation - rarely missed licks but sometimes captured
%%%%% noise.

clear

%%%%% prompt to select folder containing files with lickometry recordings.
%%%%% Up to 32 .abf files in this folder will be analyzed in alphabetical
%%%%% order(?)
folder = uigetdir;
cd(folder);
files = dir('*.abf');

%%%%% cell array of excel sheet locations for writing time stamps. 
%%%%% Each cell in the array defines the location of the first time stamp
%%%%% from each .abf file in selected folder. time stamps from each file
%%%%% will be organized in columns from the defined start location.
cell = {'A2', 'B2', 'C2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2', 'J2', 'K2', 'L2', 'M2', 'N2', 'O2', 'P2', 'Q2', 'R2', 'S2', 'T2', 'U2', 'V2', 'W2', 'X2', 'Y2', 'Z2', 'AA2', 'AB2', 'AC2', 'AD2', 'AE2', 'AF2'};

%%%%% Defines filter that removes 60 Hz noise from recordings.
des = designfilt('bandstopiir','FilterOrder',20, ...
'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
'DesignMethod','butter','SampleRate',1000);

%%%%% commented code was used to make plots of each analyzed file. This
%%%%% required a lot of storage and has been foregone in subsequent analyses.

% plotfolder = [folder, '_plots'];
% mkdir(plotfolder);

%%%%% loop that opens each file in designated folder for analysis
for i = 1:length(files);
    filename = files(i).name;
    %%%%% signal data from .abf file is extracted
    [d,si,h] = abfload(filename);
    %%%%% number of recorded inputs is defined
    Chanl = size(d, 2);
    %%%%% length of files is defined in ms
    x = 1:size(d,1);
    x = x';
%     Anmls = Chanl / 2;

    %%%%% loop that analyses each recorded input for the opened file
    for j = 1:Chanl;
        signal = d(:, j);
        %%%%% signal is filtered to remove 60 Hz noise
        signal = filtfilt(des, signal);
        %%%%% local maxima are detected in the signal
%         [pks, locs] = findpeaks(signal, x, 'MinPeakHeight', 10, 'MinPeakWidth', 15, 'MaxPeakWidth', 80, 'MinPeakProminence', 10); %REANALYSIS
        [pks, locs] = findpeaks(signal, x, 'MinPeakHeight', 10, 'MinPeakWidth', 15, 'MaxPeakWidth', 80, 'MinPeakProminence', 80); %ANALYSIS
        %%%%% timestamps are written into excel sheet
        writematrix(locs, [folder, '.xlsx'], 'Sheet', j, 'Range', char(cell(i)));
        
%         locations{j} = locs;
%         peaks{j} = pks;

    end
    %%%% saving plots requires too much storage %%%%
    
%    for k = 1:Anmls;
%         subplot(2, 4, k)
%         plot(x, d(:, k), locations{k}, peaks{k}, 'o', x, d(:, k+Anmls), locations{k+Anmls}, peaks{k+Anmls}, 'o');
%         title([group, num2str(k)]);
%     end
% %     savefig([plotfolder, '/', group, num2str(animalnumber(k))]);
%     %plot(x, d(:, 1), locations{1}, peaks{1}, 'o', x, d(:, 2), locations{2}, peaks{2}, 'o');
%     sgtitle([folder, ': ', filename(1:strfind(filename,'.')-1)], 'Interpreter', 'none');
%     savefig([plotfolder, '/', filename(1:strfind(filename,'.')-1)]);
   
end