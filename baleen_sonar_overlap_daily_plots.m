% CMS 3/10/26

% plotting for HAT and NFC
% plotting baleen whale presence overlap with MFAS overlap
% created with a combination of
% plot_Zc_timeseries_from_ID_files_CMS_edits.m and
% logger_timeseries_plotting_v3.m scripts

clear all
close all


%% User-Defined Settings
SiteName = 'NFC'; % Options: 'HAT', 'NFC', 'JAX_A' - 'JAX_D', 'USWTR_A' - 'USWTR_E'
% SignalType = 'MFAS'; % Options: MFA, LFA, HFA/Echosounder
IDpath = ['X:\MBARC_Reports\Atlantic Synthesis Reports\Anthropogenic\Final Tables\',SiteName]; 

% % --- Processing Parameters ---
p.gth = 0.5;         % Gap time in hours
p.minBout = 0;       % Minimum bout duration in seconds
% p.ltsaMax = 6;       % Maximum LTSA session duration
p.binDur = 1;       % Bin size in minutes

% % --- File Paths and Save Names ---
filePrefix = SiteName; % to load in logger files, match these to stay consistent with naming

% % --- Load in MFAS Encounters ---
MFAS = readtable(['X:\MBARC_Reports\Atlantic Synthesis Reports\Anthropogenic\Final Tables\',SiteName,'\',SiteName,'_MFA_LoggerTable.xlsx']);
sb = datenum(MFAS.StartTime);
eb = datenum(MFAS.EndTime);

% % --- Load in the Baleen Whale Daily Bins ---
data = readtable('G:\My Drive\Atlantic Baleen and Sonar Impact\Data\BALEEN_DAILYPRESENCE_ALLSPECIES_NAVFAC_NFC_090925.csv'); % for NFC
% data = readtable('G:\My Drive\Atlantic Baleen and Sonar Impact\Data\BALEEN_DAILYPRESENCE_ALLSPECIES_NAVFAC_FINAL_080125.csv');
baleen = data(:, ["date", "month","year","SITE","SEWH_occur","HUWH_occur","MIWH_occur","BLWH_occur","FIWH_occur","NARW_occur"]);


%% Site-Specific Effort Selection
% from IDfiles_to_plots_Odonts_BW.m
switch SiteName
    case 'HAT'
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

%% group effort in bins

effort.diffSec = seconds(effort.End-effort.Start) ;
effort.bins = effort.diffSec/(60*p.binDur);
effort.roundbin = round(effort.diffSec/(60*p.binDur));

% convert intervals in bins
binEffort = intervalToBinTimetable_LMB(effort.Start,effort.End,p);  % set to 1 min bins
binEffort.Properties.VariableNames{1} = 'bin';
binEffort.Properties.VariableNames{2} = 'sec';

%% group logs in bins

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

%% group data by days and weeks and hours
% clearvars -except binData % to help with out of memory errors
Click = retime(binData(:,1),'daily','sum'); % # mean click per day
Bin = retime(binData(:,1),'daily','count'); % #bin per day

Click_hr = retime(binData(:,1),'hourly','sum');
Bin_hr = retime(binData(:,1),'hourly','count'); % number of bins per hour

hourData = synchronize(Click_hr,Bin_hr);
hourEffort = retime(binEffort,'hourly','sum');
hourTable = synchronize(hourData, hourEffort); % get data table with hour sums instead
hourTable.Properties.VariableNames{'bin'} = 'Effort_Bin';
hourTable.Properties.VariableNames{'sec'} = 'Effort_Sec';

dayData = synchronize(Click,Bin); % matching up the mean number of clicks and number of bins per day (with 1 min bins a full day = 1440 bins) by time stamp
dayEffort = retime(binEffort,'daily','sum'); % sum our effort bins (binDur in  60 sec)
dayTable = synchronize(dayData,dayEffort); % match up our number of clicks/bins per day with our effort for each day
dayTable.Properties.VariableNames{'bin'} = 'Effort_Bin';
dayTable.Properties.VariableNames{'sec'} = 'Effort_Sec';

% combine the MFAS and baleen whale daily presence
baleen.match_date = datetime(baleen.date,"Format","dd-MMM-yyyy"); % get date formats to match dayTable timetable
baleen.date = [];
baleen = table2timetable(baleen); % convert to timetable
dayTable.datenum = datenum(dayTable.tbin);
dayTable= renamevars(dayTable,["Var1_Bin","Var1_Click"],["Effort_min_day","MFAS_min_day"]);

combined_table = synchronize(baleen,dayTable); % creat a combined table
combined_table = removevars(combined_table, 'Effort_min_day');
cleaned_table = rmmissing(combined_table);

%% plotting
offEffort = dayData(find(dayData.Var1_Bin==0),:);

% daily presence
top_of_plot =  max(cleaned_table.MFAS_min_day);
max_eff_bin = ((24*60)/p.binDur) % how many bins would we have per day?
figure()
colororder({'[0 0.4470 0.7410]','k'})
yyaxis left
bh = bar(cleaned_table.match_date,cleaned_table.MFAS_min_day,'stacked','barwidth',1,'edgecolor','none') % change hard coded conversion here!!! for min, divide by 60
hold on

% plot the baleen whale occurance here
% scatter(cleaned_table.match_date(cleaned_table.MIWH_occur==1),(cleaned_table.MIWH_occur(cleaned_table.MIWH_occur==1).*cleaned_table.MFAS_min_day(cleaned_table.MIWH_occur==1)),35,'r*')
bar(offEffort.Time,repelem(top_of_plot,size(offEffort,1)),'barwidth',1,'facecolor', [0.8 0.8 0.8],'edgecolor','none')
xlim([cleaned_table.match_date(1), cleaned_table.match_date(end)])

hold on % plot off effort
bar(cleaned_table.match_date(cleaned_table.NARW_occur==1),repelem(top_of_plot,size(cleaned_table.match_date(cleaned_table.NARW_occur==1),1)),'barwidth',1,'facecolor', [0.8500, 0.3250, 0.0980]	,'edgecolor','none','FaceAlpha',0.5)
hold on
y=ylim
if SiteName == 'HAT'
plot([datetime('07-May-2017') datetime('07-May-2017')], y, 'k--', 'LineWidth', 1.5); % Dashed vertical line at the start day of HAT B
hold on
end


hold on
ylabel('MFAS Positive Minutes/Day') % when switching to hour bins fix ylabel - Click Positive Hours/Week
ylim([0 top_of_plot])
yyaxis right % plot partial effort
scatter(cleaned_table.match_date(cleaned_table.Effort_Bin>0&cleaned_table.Effort_Bin<max_eff_bin),(cleaned_table.Effort_Bin(cleaned_table.Effort_Bin>0&cleaned_table.Effort_Bin<max_eff_bin)/max_eff_bin)*100,10,'o','filled')
ylim([0 100])
ylabel("% of Effort/Week")
xlabel('Date')
title("North Atlantic Right Whale and MFAS Daily Overlap - NFC")
grid on
% fontsize(16,"points")
set(gca,'fontname','Times New Roman','FontSize',16)  % Set font

%% calculate some summary stats
sum(cleaned_table.SEWH_occur)
sum(cleaned_table.MIWH_occur)
sum(cleaned_table.HUWH_occur)
sum(cleaned_table.BLWH_occur)
sum(cleaned_table.FIWH_occur)
sum(cleaned_table.NARW_occur)

sum(cleaned_table.SEWH_occur(cleaned_table.MFAS_min_day>0))
sum(cleaned_table.MIWH_occur(cleaned_table.MFAS_min_day>0))
sum(cleaned_table.HUWH_occur(cleaned_table.MFAS_min_day>0))
sum(cleaned_table.BLWH_occur(cleaned_table.MFAS_min_day>0))
sum(cleaned_table.FIWH_occur(cleaned_table.MFAS_min_day>0))
sum(cleaned_table.NARW_occur(cleaned_table.MFAS_min_day>0))

sum(cleaned_table.SEWH_occur(cleaned_table.MFAS_min_day>0))/sum(cleaned_table.SEWH_occur)
sum(cleaned_table.MIWH_occur(cleaned_table.MFAS_min_day>0))/sum(cleaned_table.MIWH_occur)
sum(cleaned_table.HUWH_occur(cleaned_table.MFAS_min_day>0))/sum(cleaned_table.HUWH_occur)
sum(cleaned_table.BLWH_occur(cleaned_table.MFAS_min_day>0))/sum(cleaned_table.BLWH_occur)
sum(cleaned_table.FIWH_occur(cleaned_table.MFAS_min_day>0))/sum(cleaned_table.FIWH_occur)
sum(cleaned_table.NARW_occur(cleaned_table.MFAS_min_day>0))/sum(cleaned_table.NARW_occur)

sum(cleaned_table.MFAS_min_day>0)
