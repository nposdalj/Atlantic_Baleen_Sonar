% CMS 4/14/26

% plotting species presence with sonar for all baleen whales we have manual
% logs for
% created with a combination of
% plot_Zc_timeseries_from_ID_files_CMS_edits.m and
% logger_timeseries_plotting_v3.m scripts

clear all
% close all


%% User-Defined Settings
SiteName = 'HAT'; % Options: 'HAT', 'NFC', 'JAX_A' - 'JAX_D', 'USWTR_A' - 'USWTR_E'
MFApath = ['X:\MBARC_Reports\Atlantic Synthesis Reports\Anthropogenic\Final Tables\',SiteName];

% % --- Processing Parameters ---
p.gth = 0.5;         % Gap time in hours
p.minBout = 0;       % Minimum bout duration in seconds
% p.ltsaMax = 6;       % Maximum LTSA session duration
p.binDur = 60;       % Bin size in minutes

% % --- File Paths and Save Names ---
filePrefix = SiteName; % to load in logger files, match these to stay consistent with naming

% % --- Load in MFAS Encounters ---
MFAS = readtable([MFApath,'\',SiteName,'_MFA_LoggerTable.xlsx']);
sb = datenum(MFAS.StartTime);
eb = datenum(MFAS.EndTime);


%% Site-Specific Effort Selection
% from IDfiles_to_plots_Odonts_BW.m
switch SiteName
%     case 'HAT'  % for hat02a-hatb03
%         effort.Start = [datetime('15-Mar-2012 16:00:00'), datetime('09-Oct-2012 15:00:00'), datetime('29-May-2013 18:00:00'), datetime('09-May-2014 00:00:00'), datetime('07-Apr-2015 00:00:00'), datetime('29-Apr-2016 12:00:00'),...
%             datetime('09-May-2017 12:02:54'), datetime('26-Oct-2017 12:00:00'), datetime('29-Oct-2020 11:04:59')];
%         effort.End   = [datetime('15-Mar-2012 16:00:01'), datetime('09-May-2013 20:00:06'), datetime('15-Mar-2014 00:35:00'), datetime('11-Dec-2014 22:53:45'), datetime('21-Jan-2016 11:54:16'), datetime('06-Feb-2017 08:56:03'),...
%             datetime('25-Oct-2017 14:11:45'), datetime('01-Jun-2018 00:54:59'), datetime('29-Oct-2020 11:05:00')];
%         lat = 35+(20.432/60); lon = 360-(74+(51.457/60));
    case 'HAT'  % for the full HAT deployment
        effort.Start = [datetime('15-Mar-2012 16:00:00'), datetime('09-Oct-2012 15:00:00'), datetime('29-May-2013 18:00:00'), datetime('09-May-2014 00:00:00'), datetime('07-Apr-2015 00:00:00'), datetime('29-Apr-2016 12:00:00'),...
            datetime('09-May-2017 12:02:54'), datetime('26-Oct-2017 12:00:00'), datetime('01-Jun-2018 04:00:00'), datetime('14-Dec-2018 00:00:00'), datetime('17-May-2019 15:00:00'), datetime('25-Oct-2019 00:00:00')];
        effort.End   = [datetime('11-Apr-2012 04:42:30'), datetime('09-May-2013 20:00:06'), datetime('15-Mar-2014 00:35:00'), datetime('11-Dec-2014 22:53:45'), datetime('21-Jan-2016 11:54:16'), datetime('06-Feb-2017 08:56:03'),...
            datetime('25-Oct-2017 14:11:45'), datetime('01-Jun-2018 00:54:59'), datetime('14-Dec-2018 14:42:36'), datetime('17-May-2019 18:17:30'), datetime('21-Sep-2019 02:02:47'), datetime('29-Oct-2020 11:05:00')];
        lat = 35+(20.432/60); lon = 360-(74+(51.457/60));
    case 'NFC'
        effort.Start = [datetime('19-Jun-2014 12:00:00'), datetime('30-Apr-2016 12:00:00'), datetime('30-Jun-2017 00:00:00'), datetime('02-Jun-2018 12:00:00'), datetime('19-May-2019 00:00:00'), datetime('29-Jun-2021 08:00:00'), datetime('17-May-2022 14:02:29')];
        effort.End   = [datetime('05-Apr-2015 02:25:48'), datetime('28-Jun-2017 18:38:51'), datetime('02-Jun-2018 06:15:06'), datetime('18-May-2019 17:46:40'), datetime('08-May-2020 21:11:15'), datetime('19-Sep-2021 00:21:30'), datetime('17-May-2022 14:02:30')];
        lat = 37+(9.871/60); lon = 360-(74+(27.951/60));
    otherwise
        error('Unknown site specified. Please check the SiteName.');
end

% BINNING MFAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Off-effort periods (if multi-interval)
if numel(effort.Start) > 1
    offEffort_start = effort.End(1:end-1) + seconds(1);
    offEffort_end   = effort.Start(2:end) - seconds(1);
    offEffort = [offEffort_start' offEffort_end'];
else
    offEffort = [];
end

% Small manual cleanups
if strcmp(SiteName,'JAX_D'), offEffort(3,:) = []; end
if strcmp(SiteName,'HAT')
    if size(offEffort,1) >= 10
        offEffort(10,:) = [];
        offEffort(9,:)  = [];
    end
end

% group effort in bins
effort.diffSec = seconds(effort.End-effort.Start) ;
effort.bins = effort.diffSec/(60*p.binDur);
effort.roundbin = round(effort.diffSec/(60*p.binDur));

% convert intervals in bins
binEffort = intervalToBinTimetable_LMB(effort.Start,effort.End,p);  % set to 1 min bins
binEffort.Properties.VariableNames{1} = 'bin';
binEffort.Properties.VariableNames{2} = 'sec';

% group logs in bins
binData = zeros(size(binEffort.tbin,1),1); % preallocate
numtbins = datenum(binEffort.tbin);

for i = 1:size(sb,1)

    % start times
    stTime = sb(i); % grab this starting datetime
    [~, closeStIdx] = min(abs(numtbins-stTime)); % find the closest time bin
    if numtbins(closeStIdx) > stTime % if the time bin starts after the log start
        closeStIdx = closeStIdx - 1; % move back 1 bin
        if closeStIdx == 0
            closeStIdx = 1;
        end
    end

    % end times
    edTime = eb(i); % grab this ending datetime
    [~, closeEdIdx] = min(abs(numtbins-edTime)); % find the closest time bin
    if numtbins(closeEdIdx) > edTime % if the time bin starts after the log end
        closeEdIdx = closeEdIdx + 1; % move up 1 bin
    end

    % log bin durations
    if closeStIdx == closeEdIdx % if log occurs within one time bin
        logIdx = closeStIdx;
    else % if log occurs within multiple time bins
        logIdx = closeStIdx:1:closeEdIdx;
    end

    binData(logIdx) = 1; % plug these values in

end

binData = timetable(binEffort.tbin,binData); % marking in 1 min bins (selected bin)
binData = renamevars(binData,"Var1","MFA");


%% Load Logger Data - FOR THE BALEEN WHALE CALLS

SiteName = 'HAT'; % Options: 'HAT', 'NFC', 'JAX_A' - 'JAX_D', 'USWTR_A' - 'USWTR_E'
SpName = 'Humpback'; % Options: Sei, Minke, Blue, NARW, Fin, Humpback
keyWord1 = 'Mn'; % Options: Bb, Ba, Bm, Eg, Bp, Mn
IDpath = 'X:\Atlantic_Baleen_Sonar\HAT\Cleaned_Logs';
% saveDir = fullfile('X:\Atlantic_Baleen_Sonar\HAT\Binned_data', 'EncounterTables_Logs'); % don't need this, not saving hourly logs?
saveDirFig = ['X:\Atlantic_Baleen_Sonar\HAT\Binned_data'];

% % --- File Paths and Save Names ---
filePrefix = SiteName; % to load in logger files, match these to stay consistent with naming
SaveName = [SiteName,'_',SpName]; %File/figure save name
SaveDataPath = ['X:\Atlantic_Baleen_Sonar\HAT\Binned_data'];

disp('Loading logger files...');
fileList = cellstr(ls(IDpath));
fileMatchIdx = find(~cellfun(@isempty, regexp(fileList, filePrefix))); % for all other baleen whales
% fileMatchIdx = find(~cellfun(@isempty, regexp(fileList, keyWord1))); % for humpbacks
matchingFile = fileList(fileMatchIdx);

logger_table = [];

for f = 1:length(matchingFile)
    fprintf('Loading file: %s\n', matchingFile{f});
    this_log = readtable(fullfile(IDpath, matchingFile{f}));
    if ~isempty(this_log)
        idx = strcmp(this_log.SpeciesCode, keyWord1);
        this_log_times = table(this_log.StartTime(idx), this_log.EndTime(idx));
    end
    % Fix Excel serial dates if necessary
    if ~isempty(this_log_times) % only add this if this_log_times are full, this can be empty if you are reading general LF or MF logs that have baleen whale detections (so the log is full) but there aren't any key word detectoins
        for col = 1:2
            if isnumeric(this_log_times{:,col})
                fixed_dates = datetime(this_log_times{:,col}, 'ConvertFrom', 'excel');
                this_log_times(:,col) = []; % remove the excel column of doubles - you need this extra step when only one of the columns is in the excel number format :/
                this_log_times.Var2 = fixed_dates; % add in the datetimes to the table (will get renamed)
            end
        end

        % compile into one large table
        this_log_times.Properties.VariableNames = {'StartTime', 'EndTime'};
        logger_table = [logger_table; this_log_times];
    end
end
% end

% create an end time for logs with just a start time
if iscell(logger_table.EndTime) % make the end times a date instead of a cell
    logger_table.EndTime = datetime(logger_table.EndTime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
end
no_end_idx = find(isnat(logger_table.EndTime));
logger_table.EndTime(no_end_idx)=logger_table.StartTime(no_end_idx)+seconds(1); % add one second to the start time, assuming that only start times are on the call level

if ~isempty(logger_table)
    logger_table.Properties.VariableNames = {'StartTime', 'EndTime'};
else
    disp("Logger table empty.");
end



%%
% Save logger table
loggerMatFileName = fullfile(SaveDataPath, [SaveName '_LoggerTable.mat']);
loggerXlsxFileName = fullfile(SaveDataPath, [SaveName '_LoggerTable.xlsx']);

save(loggerMatFileName, 'logger_table');
writetable(logger_table, loggerXlsxFileName);

disp(['Saving Compiled Logger Table for ',SpName]);

% get whale data into bins
sb = datenum(logger_table.StartTime);
eb = datenum(logger_table.EndTime);

% group logs in bins
whaleBinData = zeros(size(binEffort.tbin,1),1); % preallocate
numtbins = datenum(binEffort.tbin);

for i = 1:size(sb,1)

    % start times
    stTime = sb(i); % grab this starting datetime
    [~, closeStIdx] = min(abs(numtbins-stTime)); % find the closest time bin
    if numtbins(closeStIdx) > stTime % if the time bin starts after the log start
        closeStIdx = closeStIdx - 1; % move back 1 bin
        if closeStIdx == 0
            closeStIdx = 1;
        end
    end

    % end times
    edTime = eb(i); % grab this ending datetime
    [~, closeEdIdx] = min(abs(numtbins-edTime)); % find the closest time bin
    if numtbins(closeEdIdx) > edTime % if the time bin starts after the log end
        closeEdIdx = closeEdIdx + 1; % move up 1 bin
    end

    % log bin durations
    if closeStIdx == closeEdIdx % if log occurs within one time bin
        logIdx = closeStIdx;
    else % if log occurs within multiple time bins
        logIdx = closeStIdx:1:closeEdIdx;
    end

    whaleBinData(logIdx) = 1; % plug these values in

end

whaleBinData = timetable(binEffort.tbin,whaleBinData); % marking in 1 min bins (selected bin)
whaleBinData = renamevars(whaleBinData,"Var1",SpName);

% compile the whales
% full_table = [binData, whaleBinData]; % to make the first table
full_table = [full_table, whaleBinData];

disp([SpName,' added to full table']);

%% save large table
loggerMatFileName = fullfile(SaveDataPath, [SiteName,'_Baleen_MFA_table_1hr_bins.mat']);
save(loggerMatFileName, 'full_table');

% explore sums of each baleen whale hour bins:
sum(full_table.Sei)
sum(full_table.Blue)
sum(full_table.Fin)
sum(full_table.Minke)
sum(full_table.Humpback)
sum(full_table.NARW)





