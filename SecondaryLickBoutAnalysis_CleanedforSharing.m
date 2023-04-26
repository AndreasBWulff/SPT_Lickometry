%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Secondary analysis - detecting and analyzing lick bouts %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% Analysis loads excel sheet created during primary analysis, cleans
%%%%% it, and detects lick bouts as defined. Outputs a table containing
%%%%% number of licks and lick bouts detected, the average number of licks
%%%%% per bout, and the overall lick frequency and intrabout lick frequency
%%%%% for each column in excel sheet (corresponding to each file analyzed
%%%%% in primary analysis). table can be copy-pasted into excel sheet.

%%%%% Requires a header for each column to be analyzed in the first row of
%%%%% the excel sheet for analysis to be performed properly. If not, empty
%%%%% columns will be skipped and resulting output will be temporally
%%%%% wrong.

clear

%%%%% Prompt to choose excel file and sheet to be analyzed. Each sheet in
%%%%% excel file correspond to each signal input in .abf file analyzed in
%%%%% primary analysis.
file = uigetfile('.xlsx');
prompt = {'Enter sheet to be loaded'};
dlgtitle = 'Load Sheet';
dims = [1 35];
definput = {'1'};
Sheet = inputdlg(prompt,dlgtitle,dims,definput);
Sheet = str2double(Sheet);
opts = detectImportOptions(file);
opts.Sheet = Sheet;
opts.PreserveVariableNames = true;
opts = setvartype(opts, 'double');

%%%%% loads file
LickingEvents = readtable(file, opts);

%%%%% Creates empty output table
Summary_table = array2table(zeros(5, size(LickingEvents, 2)), 'VariableNames', LickingEvents.Properties.VariableNames, 'RowNames', {'Total Licks', 'Bouts', 'Licks Per Bout', 'overall lick freq', 'intra-bout lick freq'});

%%%%% Creates Table with Inter-lick Intervals
LE = table2array(LickingEvents);
ILI = diff(LE, 1, 1);
ILI_table = array2table(ILI, 'VariableNames', LickingEvents.Properties.VariableNames);

%%%%% clean data. removes events with an interlick interval <= 50. These are not
%%%%% real licks. Then recreates the ILI table.
for i = 1:size(ILI_table, 2);
    for c = 1:size(ILI_table, 1);
        ILI_number = table2array(ILI_table(c, i));
        if ILI_number <= 50;
            LE(c+1, i) = nan;
        end
    end
    LE_Nan = LE(:,i);
    LE_c = LE_Nan(~isnan(LE_Nan));
    if i == 1;
        LE_clean = LE_c;
    else
        n = max(size(LE_clean, 1), numel(LE_c));
        LE_c(end+1:n, :) = nan;
        LE_clean(end+1:n, :) = nan;
        LE_clean = [LE_clean, LE_c];
    end       
end

ILI = diff(LE_clean, 1, 1);
ILI_table = array2table(ILI, 'VariableNames', LickingEvents.Properties.VariableNames);
freq_m = 1000 ./ ILI;

%%%%% Prompt to define Lick Bouts (max interlick interval and minimum
%%%%% number of licks.
prompt = {'Enter Max ILI criteria (ms):','Enter Min LPB:'};
dlgtitle = 'Bout Criteria';
dims = [1 35];
definput = {'1000', '4'};
BoutCrit = inputdlg(prompt,dlgtitle,dims,definput)
BoutCrit = str2double(BoutCrit)

%%%%% Uses table of interlick interval to group licks in bouts.
for i = 1:size(ILI_table, 2);
 ['Analyzing ' char(LickingEvents.Properties.VariableNames(i))]
 Bouts = [];
 Bout_freq = [];
 j  = 1;
 boutsize = 1;
 for c = 1:size(ILI_table, 1);
     ILI_number = table2array(ILI_table(c, i));
     %%%%% Determines if interlick interval is less than defined
     %%%%% requirement for lick bout
     if ILI_number < BoutCrit(1);
         %%%%% Adds lick to current bout when interlick interval is less
         %%%%% than defined for lick bout
         if boutsize > 1;
             boutsize = boutsize + 1;
         else
             boutsize = 2;
         end
         %%%%% determines if current lick bout is larger than defined
         %%%%% required size
     elseif boutsize >= BoutCrit(2);
         %%%%% Stores size of bout and intrabout lick frequency
         Bouts(j) = boutsize;
         Bout_freq(j) = mean(freq_m(c-(boutsize-1):(c-1), i));
         j = j+1;
         %%%%% resets bout size
         boutsize = 1;
     else
         boutsize = 1;
     end
 end
 %%%%% Determines if the last lick in column belongs to a bout and stores
 %%%%% licks per bout and intrabout lick frequency for last bout of file if
 %%%%% so.
 if boutsize >= BoutCrit(2);
     Bouts(j) = boutsize;
     Bout_freq(j) = mean(freq_m(c-(boutsize-2):c, i));
 end
 
 %%%%% counts number of licks in column and calculates lick frequency
 Licks = LE_clean(:,i);
 Licks = Licks(~isnan(Licks));
 freq = freq_m(:, i);
 freq = freq(~isnan(freq));
 
 %%%%% stores number of licks, number of bouts, average licks per bout,
 %%%%% average overall lick frequency, and average intrabout lick frequency
 %%%%% in output table.
 Summary_table(1, i) = {size(Licks, 1)};
 Summary_table(2, i) = {size(Bouts, 2)};
 Summary_table(3, i) = {mean(Bouts)};
 Summary_table(4, i) = {mean(freq)};
 Summary_table(5, i) = {mean(Bout_freq)};
end

%%%%% Creates "Raster" Plot. Not necessary for analysis.
raster = [0 0];
for c = 1:size(LickingEvents, 2);
    t = table2array(LickingEvents(:, c));
    t = t(~isnan(t));
    t = t / 60000;
    y = repelem(c, size(t, 1)).';
    ty = [t y];
    raster = [raster; ty];
end
scatter(raster(:, 1), raster(:, 2), '.', 'k')
axis([0 30 0 size(LickingEvents, 2)+1]);
xlabel('Time (min)');
ax = gca;
ax.YTick = [1:size(LickingEvents, 2)];
ax.YTickLabel = LickingEvents.Properties.VariableNames;