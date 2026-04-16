close all; clear; clc;

parentDir = 'L:\.shortcut-targets-by-id\1NHK8ZRtCbvo4cicsapyJzWLfPTWFfpQ0\NAVFAC_REPORT_FIGURES\HAT\data\01_DATA_INPUTS\HUMPBACK';
species   = 'HUMPBACK';
saveDir   = 'Z:\Atlantic_Baleen_Sonar\HAT\Concatenated_NOAA_Logs';

files = dir(fullfile(parentDir, '**', '*.csv'));

masterCell = cell(length(files),1);
validCount = 0;

total_missed_instances   = 0;
total_valid_instances    = 0;
total_detected_instances = 0;

for i = 1:length(files)

    filePath = fullfile(files(i).folder, files(i).name);
    fprintf('\nProcessing: %s\n', filePath);

    %% ================= READ =================
    try
        raw = readcell(filePath);
    catch
        warning('Could not read file, skipping');
        continue
    end

    %% ================= DETECT MINKE FIRST =================
    firstRow = lower(strtrim(string(raw(1,:))));

    isMinke = any(contains(firstRow,'date (utc')) && ...
              any(contains(firstRow,'detections')) && ...
              any(contains(firstRow,'manual'));

    if isMinke
        fprintf('Minke format detected\n');

        data = raw(2:end,:);

        % Remove empty rows
        nonEmpty = any(~cellfun(@isempty, data), 2);
        data = data(nonEmpty,:);

        % Extract columns (fixed structure)
        startStr = string(data(:,1));
        mrCol    = str2double(string(data(:,3)));

        % Datetime
        try
            StartDateTime = datetime(startStr,'InputFormat','MM/dd/yyyy HH:mm:ss');
        catch
            StartDateTime = datetime(startStr);
        end

        % Fix bad years
        bad = year(StartDateTime) < 1900;
        StartDateTime(bad) = StartDateTime(bad) + years(2000);

        % Clean MR
        mrCol(~ismember(mrCol,[0 1])) = NaN;

        % FINAL MINKE TABLE
        Tclean = table(StartDateTime, mrCol, ...
            'VariableNames', {'StartDateTime','Manual_Review'});

        validCount = validCount + 1;
        masterCell{validCount} = Tclean;

        continue
    end

    %% ================= FIND NOAA HEADER =================
    col1 = lower(strtrim(string(raw(:,1))));

    headerIdx = find(strcmp(col1,'start date'),1);

    if isempty(headerIdx)
        warning('NOAA header not found, skipping');
        continue
    end

    %% ================= CLEAN HEADER =================
    rawHeader = raw(headerIdx,:);
    cleanHeader = strings(size(rawHeader));

    for h = 1:length(rawHeader)
        sval = string(rawHeader{h});
        if all(strlength(sval)==0) || all(ismissing(sval))
            cleanHeader(h) = "Var" + h;
        else
            cleanHeader(h) = sval;
        end
    end

    headers = matlab.lang.makeValidName(cleanHeader);

    %% ================= DATA =================
    data = raw(headerIdx+1:end,:);

    nonEmpty = any(~cellfun(@isempty, data),2);
    data = data(nonEmpty,:);

    T = cell2table(data,'VariableNames',headers);

    %% ================= COLUMN INDEX =================
    varNames = lower(T.Properties.VariableNames);

    sumIdx = find(strcmp(varNames,"sum"),1);
    mrIdx  = find(contains(varNames,"manual"),1);

    if isempty(sumIdx) || isempty(mrIdx)
        warning('Missing Sum or Manual Review, skipping');
        continue
    end

    %% ================= NUMERIC =================
    mrCol = str2double(string(T{:,mrIdx}));
    mrCol(~ismember(mrCol,[0 1])) = NaN;

    sumCol = str2double(string(T{:,sumIdx}));

    %% ================= CALL TYPES =================
    if sumIdx > 4
        for k = 1:(sumIdx-4)
            T.Properties.VariableNames{4+k} = sprintf('CallType_%d',k);
        end
        callTypeCols = T(:,5:sumIdx);
    else
        callTypeCols = table();
    end

    %% ================= DATETIME =================
    startStr = string(T{:,1}) + " " + string(T{:,2});
    endStr   = string(T{:,3}) + " " + string(T{:,4});

    try
        StartDateTime = datetime(startStr,'InputFormat','MM/dd/yyyy HH:mm:ss');
        EndDateTime   = datetime(endStr,'InputFormat','MM/dd/yyyy HH:mm:ss');
    catch
        StartDateTime = datetime(startStr);
        EndDateTime   = datetime(endStr);
    end

    bad = year(StartDateTime) < 1900;
    StartDateTime(bad) = StartDateTime(bad) + years(2000);
    EndDateTime(bad)   = EndDateTime(bad)   + years(2000);

    %% ================= BUILD TABLE =================
    Tclean = [table(StartDateTime,EndDateTime), ...
              callTypeCols, ...
              table(sumCol,mrCol)];

    Tclean.Properties.VariableNames{end-1} = 'Sum';
    Tclean.Properties.VariableNames{end}   = 'Manual_Review';

    %% ================= DAILY ANALYSIS =================
    tempDate = datetime(year(StartDateTime),month(StartDateTime),day(StartDateTime));
    [~,~,idxDay] = unique(tempDate);

    for d = 1:max(idxDay)

        mask = (idxDay==d);
        daySum = sumCol(mask);
        dayMR  = mrCol(mask);

        idx = find(daySum>30,1);
        if isempty(idx), continue; end

        val = dayMR(idx);

        if ~isnan(val)
            total_valid_instances = total_valid_instances + 1;

            if val==0
                total_missed_instances = total_missed_instances + 1;
            else
                total_detected_instances = total_detected_instances + 1;
            end
        end
    end

    %% ================= STORE =================
    validCount = validCount + 1;
    masterCell{validCount} = Tclean;
end

%% ================= COMBINE =================
masterCell = masterCell(1:validCount);
masterTable = vertcat(masterCell{:});

%% ================= SAVE =================
if isempty(masterTable)
    error('Master table is EMPTY');
end

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

fileBase = sprintf('Master_Detections_Table_%s', species);

save(fullfile(saveDir,[fileBase '.mat']),'masterTable');
writetable(masterTable,fullfile(saveDir,[fileBase '.csv']));

fprintf('\nSaved master table for %s\n',species);

%% ================= STATS =================
fprintf('\nTotal valid instances: %d\n',total_valid_instances);
fprintf('Total missed instances: %d\n',total_missed_instances);
fprintf('Total detected instances: %d\n',total_detected_instances);

if total_valid_instances>0
    fprintf('Miss rate: %.2f%%\n', ...
        total_missed_instances/total_valid_instances*100);
end