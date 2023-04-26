%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Secondary Analysis - detecting quick switches and returns %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% Loads timestamps from primary analysis and uses interlick intervals
%%%%% to detect times when licks occurred at one bottle and then the other
%%%%% in less than 30 seconds and to detect which bottle exhibited the
%%%%% first lick after more than 5 minutes of no licks. Outputs data in
%%%%% excel file for the whole night (sheet1), first 30 mins of recording
%%%%% (sheet4), first 2 hours of recording (sheet5), and last 2 hours of
%%%%% recording (sheet6). Also outputs the switch time for all quick
%%%%% switches from water to sucrose (sheet2) and from sucrose to water
%%%%% (sheet3), as well as overall order of licks at the sucrose bottle
%%%%% 'S' and water bottle 'W' (sheet7).

%%%%% Requires sheets of primary analysis to be organized to the sheet from
%%%%% the first bottle for each cage is in order followed by the sheet from
%%%%% the second bottle for each cage in order i.e., cage 1 bottle 1, cage
%%%%% 2 bottle 1, cage 1 bottle 2, cage 2 bottle 2.


clear

%%%%% Defines columns for output of data in excel. Each column corresponds
%%%%% to a cage
cols = {'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'};

%%%%% Prompt to choose excel file to analyze
file = uigetfile('.xlsx');

%%%%% Prompt to define number of cages in data sheet
prompt = {'How many cages in data sheet?'};
dlgtitle = 'Number of Cages';
dims = [1 35];
definput = {'8'};
NumCages = inputdlg(prompt, dlgtitle, dims, definput);
NumCages = str2double(NumCages);

%%%%% Prompt to input whether bottle 1 or bottle 2 contains sucrose
prompt = {'Is the Sucrose bottle in location 2 or 1 (choose for each cage, comma separated)'};
dlgtitle = 'Sucrose Position';
dims = [1 35];
SucroseLoc = inputdlg(prompt, dlgtitle, dims);
SucroseLoc = cell2mat(SucroseLoc);
SucroseLoc = str2num(SucroseLoc);


%%%%% Loop to load the sheet containing timestamps from water bottle and
%%%%% sucrose bottle and organize timestamps from entire span of recording
%%%%% with identifiers as to which bottle the lick was detected at
for j = 1:NumCages;
    
    if SucroseLoc(j) == 1;
        Water = NumCages + j;
        Sucrose = j;
    elseif SucroseLoc(j) == 2;
        Water = j;
        Sucrose = NumCages + j;
    end
    
    %load Water Events
    opts = detectImportOptions(file);
    opts.Sheet = Water;
    opts.PreserveVariableNames = true;
    opts = setvartype(opts, 'double');
    WaterEvents = table2array(readtable(file, opts));

    %load Sucrose Events
    opts = detectImportOptions(file);
    opts.Sheet = Sucrose;
    opts.PreserveVariableNames = true;
    opts = setvartype(opts, 'double');
    SucroseEvents = table2array(readtable(file, opts));

    %%%%% adjusts timestamps to reflect total time since start of recording
    %%%%% (rather than start of file) and concatenate time stamps into one
    %%%%% string
    for i = 1:size(WaterEvents, 2);
        WaterEvents(:, i) = WaterEvents(:, i)+(i-1)*1800000;
        SucroseEvents(:, i) = SucroseEvents(:, i) + (i-1)*1800000;
   
        if i == 1;
            WaterArray = WaterEvents(:, i);
            SucroseArray = SucroseEvents(:, i);
        else
            WaterArray = vertcat(WaterArray, WaterEvents(:, i));
            SucroseArray = vertcat(SucroseArray, SucroseEvents(:,i));
        end
    end
    
    %%%%% cleans time stamp arrays and combines water and sucrose time
    %%%%% stamps. Makes a ledger identifying each lick as belonging to the
    %%%%% water bottle or sucrose bottle.
    WaterArray = WaterArray(~isnan(WaterArray));
    SucroseArray = SucroseArray(~isnan(SucroseArray));

    W = size(WaterArray);
    S = size(SucroseArray);

    CombArray = vertcat(WaterArray, SucroseArray);
    [CombArray, I] = sort(CombArray);
    index = char(zeros(size(I)));
    index(I <= W) = 'W';
    index(I > W) = 'S';

    %%%%% Calculates interlick intervals and removes licks happening with
    %%%%% an interlick interval less than 50 ms. These are artifacts of one
    %%%%% peak being detected twice.
    ILIArray = diff(CombArray);

    ILIi = find(ILIArray <= 50);
    ILIArray(ILIi) = [];
    CombArrayi = ILIi +1;
    CombArray(CombArrayi) = [];
    index(CombArrayi) = [];

    %%%%% makes arrays to store switch times between water and sucrose and
    %%%%% between sucrose and water
    WSArray = [];
    SWArray = [];
    WSArray30m = [];
    SWArray30m = [];
    WSArray2h = [];
    SWArray2h = [];
    WSArrayL2h = [];
    SWArrayL2h = [];


    %%%%% loop detecting switches between licking water and sucrose and
    %%%%% storing the switch times. Performed for the entirety of the
    %%%%% recording session, for the first 30 mins, for the first 2 hours,
    %%%%% and for the last 2 hours
    for i = 2:size(CombArray);
        if index(i) == 'S' & index(i-1) == 'W';
            WSArray(end+1) = ILIArray(i-1);
            if CombArray(i) < 30*60000;
                WSArray30m(end+1) = ILIArray(i-1);
            end
            if CombArray(i) < 120*60000;
                WSArray2h(end+1) = ILIArray(i-1);
            end
            if CombArray(i) > 12*60*60000;
                WSArrayL2h(end+1) = ILIArray(i-1);
            end
        elseif index(i) == 'W' & index(i-1) == 'S';
            SWArray(end+1) = ILIArray(i-1);
            if CombArray(i) < 30*60000;
                SWArray30m(end+1) = ILIArray(i-1);
            end
            if CombArray(i) < 120*60000;
                SWArray2h(end+1) = ILIArray(i-1);
            end
            if CombArray(i) > 12*60*60000;
                SWArrayL2h(end+1) = ILIArray(i-1);
            end
        end
    end

    WSArray = WSArray';
    SWArray = SWArray';
    WSArray30m = WSArray30m';
    SWArray30m = SWArray30m';
    WSArray2h = WSArray2h';
    SWArray2h = SWArray2h';
    WSArrayL2h = WSArrayL2h';
    SWArrayL2h = SWArrayL2h';

    %%%%% calculate average switch time from water to sucrose and from
    %%%%% sucrose to water
    avgWStime = mean(WSArray);
    avgSWtime = mean(SWArray);
    avgWStime30m = mean(WSArray30m);
    avgSWtime30m = mean(SWArray30m);
    avgWStime2h = mean(WSArray2h);
    avgSWtime2h = mean(SWArray2h);
    avgWStimeL2h = mean(WSArrayL2h);
    avgSWtimeL2h = mean(SWArrayL2h);

    
    %%%%% detect switch times greater than 60 seconds and removes them from
    %%%%% the switch arrays
    WSi = find(WSArray > 60000);
    SWi = find(SWArray > 60000);
    WSi30m = find(WSArray30m > 60000);
    SWi30m = find(SWArray30m > 60000);
    WSi2h = find(WSArray2h > 60000);
    SWi2h = find(SWArray2h > 60000);
    WSiL2h = find(WSArrayL2h > 60000);
    SWiL2h = find(SWArrayL2h > 60000);

    WSArray(WSi) = [];
    SWArray(SWi) = [];
    WSArray30m(WSi30m) = [];
    SWArray30m(SWi30m) = [];
    WSArray2h(WSi2h) = [];
    SWArray2h(SWi2h) = [];
    WSArrayL2h(WSiL2h) = [];
    SWArrayL2h(SWiL2h) = [];

    %%%%% counts number of switches with switch times less than 60 seconds
    WScounts = size(WSArray, 1);
    SWcounts =  size(SWArray, 1);
    WScounts30m = size(WSArray30m, 1);
    SWcounts30m = size(SWArray30m, 1);
    WScounts2h = size(WSArray2h, 1);
    SWcounts2h = size(SWArray2h, 1);
    WScountsL2h = size(WSArrayL2h, 1);
    SWcountsL2h = size(SWArrayL2h, 1);

    %%%%% prepares counter for number of times licks are observed first at
    %%%%% a bottle after at least 5 mins of no licks detected i.e.,
    %%%%% Interlick interval is greater than 5 mins
    nW = 0;
    nS = 0;
    nW30m = 0;
    nS30m = 0;
    nW2h = 0;
    nS2h = 0;
    nWL2h = 0;
    nSL2h = 0;

    %%%%% Loop that detects if a lick happened with an interlick interval
    %%%%% greater than 5 mins, identifies if the lick happened at the water
    %%%%% bottle or the sucrose bottle, and increases the count of the
    %%%%% appropriate counter. Performed for the entire recording, for the
    %%%%% first 30 mins, for the first 2 hours, and for the last 2 hours.
    for i = 1:size(ILIArray);
        if ILIArray(i) > 300000;
            if index(i+1) == 'W';
                nW = nW+1;
                if CombArray(i+1) < 30*60000;
                    nW30m = nW30m+1;
                end
                if CombArray(i+1) < 120*60000;
                    nW2h = nW2h+1;
                end
                if CombArray(i+1) > 12*60*60000;
                    nWL2h = nWL2h+1;
                end
            elseif index(i+1) == 'S';
                nS = nS+1;
                if CombArray(i+1) < 30*60000;
                    nS30m = nS30m+1;
                end
                if CombArray(i+1) < 120*60000;
                    nS2h = nS2h+1;
                end
                if CombArray(i+1) > 12*60*60000;
                    nSL2h = nSL2h+1;
                end
            end
        end
    end
    
    %%%%% Calculates the percent of switches happening in either direction
    switchCounts = WScounts + SWcounts;
    pWS = WScounts / switchCounts * 100;
    pSW = SWcounts / switchCounts * 100;

    switchCounts30m = WScounts30m + SWcounts30m;
    pWS30m = WScounts30m / switchCounts30m * 100;
    pSW30m = SWcounts30m / switchCounts30m * 100;

    switchCounts2h = WScounts2h + SWcounts2h;
    pWS2h = WScounts2h / switchCounts2h * 100;
    pSW2h = SWcounts2h / switchCounts2h * 100;

    switchCountsL2h = WScountsL2h + SWcountsL2h;
    pWSL2h = WScountsL2h / switchCountsL2h *100;
    pSWL2h = SWcountsL2h / switchCountsL2h *100;

    %%%%% calculates the percent of returns happening at either bottle
    nCounts = nW + nS;
    pnW = nW/nCounts*100;
    pnS = nS/nCounts*100;

    nCounts30m = nW30m + nS30m;
    pnW30m = nW30m/nCounts30m*100;
    pnS30m = nS30m/nCounts30m*100;

    nCounts2h = nW2h + nS2h;
    pnW2h = nW2h/nCounts2h*100;
    pnS2h = nS2h/nCounts2h*100;

    nCountsL2h = nWL2h + nSL2h;
    pnWL2h = nWL2h/nCountsL2h*100;
    pnSL2h = nSL2h/nCountsL2h*100;


    %%%%% Writing the data into an excel file. Organization of data
    %%%%% described above.
    col = cols(j);
    col = char(col);
    
    writecell({'WS switch'; 'SW switch';'';'';'pct WS switch';'pct SW switch';'';'';'Water return';'Sucrose return';'';'';'pct Water return';'pct Sucrose return';'';'';'WS switch time';'SW switch time'}, [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 1, 'Range', 'A4');
    writecell({'WS switch'; 'SW switch';'';'';'pct WS switch';'pct SW switch';'';'';'Water return';'Sucrose return';'';'';'pct Water return';'pct Sucrose return';'';'';'WS switch time';'SW switch time'}, [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 4, 'Range', 'A4');
    writecell({'WS switch'; 'SW switch';'';'';'pct WS switch';'pct SW switch';'';'';'Water return';'Sucrose return';'';'';'pct Water return';'pct Sucrose return';'';'';'WS switch time';'SW switch time'}, [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 5, 'Range', 'A4');
    writecell({'WS switch'; 'SW switch';'';'';'pct WS switch';'pct SW switch';'';'';'Water return';'Sucrose return';'';'';'pct Water return';'pct Sucrose return';'';'';'WS switch time';'SW switch time'}, [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 6, 'Range', 'A4');
    
    writematrix([WScounts; SWcounts], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 1, 'Range', [col, '4']);
    writematrix([pWS; pSW], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 1, 'Range', [col, '8']);
    writematrix([nW; nS], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 1, 'Range', [col, '12']);
    writematrix([pnW; pnS], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 1, 'Range', [col, '16']);
    writematrix([avgWStime; avgSWtime], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 1, 'Range', [col, '20']);
    writematrix(WSArray, [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 2, 'Range', [col, '2']);
    writematrix(SWArray, [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 3, 'Range', [col, '2']);
    writematrix([WScounts30m; SWcounts30m], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 4, 'Range', [col, '4']);
    writematrix([pWS30m; pSW30m], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 4, 'Range', [col, '8']);
    writematrix([nW30m; nS30m], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 4, 'Range', [col, '12']);
    writematrix([pnW30m; pnS30m], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 4, 'Range', [col, '16']);
    writematrix([avgWStime30m; avgSWtime30m], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 4, 'Range', [col, '20']);
    writematrix([WScounts2h; SWcounts2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 5, 'Range', [col, '4']);
    writematrix([pWS2h; pSW2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 5, 'Range', [col, '8']);
    writematrix([nW2h; nS2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 5, 'Range', [col, '12']);
    writematrix([pnW2h; pnS2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 5, 'Range', [col, '16']);
    writematrix([avgWStime2h; avgSWtime2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 5, 'Range', [col, '20']);
    writematrix([WScountsL2h; SWcountsL2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 6, 'Range', [col, '4']);
    writematrix([pWSL2h; pSWL2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 6, 'Range', [col, '8']);
    writematrix([nWL2h; nSL2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 6, 'Range', [col, '12']);
    writematrix([pnWL2h; pnSL2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 6, 'Range', [col, '16']);
    writematrix([avgWStimeL2h; avgSWtimeL2h], [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 6, 'Range', [col, '20']);
    if size(index, 1) > 500;
        writematrix(index(1:500), [file(1:strfind(file,'.')-1), '_ILI', '.xlsx'], 'Sheet', 7, 'Range', [col, '2']);
    end
end