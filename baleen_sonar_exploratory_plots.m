% CMS 4/15/26
% exploratory plots from the baleen and MFAS hourly bins 
% baleen whale effort: HAT02A-B_03_01
% MFAS effort: HAT01A-B_07_01

load('X:\Atlantic_Baleen_Sonar\HAT\Binned_data\Baleen_MFA_table_1hr_bins.mat'); % baleen whale data
MFAS = readtable('X:\MBARC_Reports\Atlantic Synthesis Reports\Anthropogenic\Final Tables\HAT\HAT_MFA_LoggerTable.xlsx'); % MFAS data

whale_sum = sum(full_table{:,2:end},2);
full_table.AllWhales = whale_sum;
mult_whales_idx = find(full_table.AllWhales>1);
mult_whales = full_table.AllWhales(mult_whales_idx);
mult_whales_unique = unique(mult_whales) % maximum we have 4 whale species detected in an hour

% subset for only sonar events:
sonar_table = full_table(full_table.MFA==1,:);

% subset for only whale presence:
whale_table = full_table(full_table.AllWhales==1,:);

% subset for sonar and whale presence:
both_table = full_table(full_table.AllWhales==1 & full_table.MFA==1,:);

% plotting
figure();
scatter(full_table.Time,(full_table.MFA.*full_table.AllWhales),'filled','o');
hold on
plot(full_table.Time,full_table.AllWhales)

figure();
scatter(sonar_table.Time,(sonar_table.AllWhales),'filled','o');
hold on
plot(sonar_table.Time,sonar_table.AllWhales)

%% === Diel Plot ===

% partial HAT effort
effort.Start = [datetime('15-Mar-2012 16:00:00'), datetime('09-Oct-2012 15:00:00'), datetime('29-May-2013 18:00:00'), datetime('09-May-2014 00:00:00'), datetime('07-Apr-2015 00:00:00'), datetime('29-Apr-2016 12:00:00'),...
    datetime('09-May-2017 12:02:54'), datetime('26-Oct-2017 12:00:00'), datetime('29-Oct-2020 11:04:59')];
effort.End   = [datetime('15-Mar-2012 16:00:01'), datetime('09-May-2013 20:00:06'), datetime('15-Mar-2014 00:35:00'), datetime('11-Dec-2014 22:53:45'), datetime('21-Jan-2016 11:54:16'), datetime('06-Feb-2017 08:56:03'),...
    datetime('25-Oct-2017 14:11:45'), datetime('01-Jun-2018 00:54:59'), datetime('29-Oct-2020 11:05:00')];
lat = 35+(20.432/60); lon = 360-(74+(51.457/60));

% Off-effort periods (if multi-interval)
if numel(effort.Start) > 1
    offEffort_start = effort.End(1:end-1) + seconds(1);
    offEffort_end   = effort.Start(2:end) - seconds(1);
    offEffort = [offEffort_start' offEffort_end'];
else
    offEffort = [];
end

% fprintf('Creating diel plot for %s...\n', SignalType);
q = dbInit('Server', 'breach.ucsd.edu', 'Port', 9779);
night = dbDiel(q, lat, lon, effort.Start(1), effort.End(end));
night(1,:) = []; night(end,:) = [];
night = datetime(night, 'ConvertFrom', 'datenum');

% nEncounters = height(full_table);
% if nEncounters < lowDataThreshold, dielLineStyle = '-'; else, dielLineStyle = 'none'; end

full_table.EndTime = full_table.Time+hours(1); % create "end times" for hour bins

% subset pres for each species:
pres_blue = horzcat(full_table.Time(full_table.Blue==1), full_table.EndTime(full_table.Blue==1));
pres_fin = horzcat(full_table.Time(full_table.Fin==1), full_table.EndTime(full_table.Fin==1));
pres_hump = horzcat(full_table.Time(full_table.Humpback==1), full_table.EndTime(full_table.Humpback==1));
pres_sei = horzcat(full_table.Time(full_table.Sei==1), full_table.EndTime(full_table.Sei==1));
pres_minke = horzcat(full_table.Time(full_table.Minke==1), full_table.EndTime(full_table.Minke==1));
pres_narw = horzcat(full_table.Time(full_table.NARW==1), full_table.EndTime(full_table.NARW==1));
pres_whale = horzcat(full_table.Time(full_table.AllWhales>0), full_table.EndTime(full_table.AllWhales>0));
pres_mfas = horzcat(full_table.Time(full_table.MFA==1), full_table.EndTime(full_table.MFA==1));

% pres = horzcat(full_table.Time, full_table.EndTime);
rgbcols = [0 0.4470 0.7410];

%% plotting
figure()
night = visPresence(sort(night), 'Color', 'black', 'LineStyle', 'none', 'Transparency', 0.1);
sonar = visPresence(sortrows(pres_mfas), 'Color', rgbcols, ...
    'DateRange', [effort.Start(1), effort.End(end)]);
% set(get(sonar(1), 'Children'), 'EdgeColor', rgbcols);
hold on
whale = visPresence(sortrows(pres_narw), 'Color', [0.75, 0, 0.75], ...
    'DateRange', [effort.Start(1), effort.End(end)]);

% plot all whales? zoomed in at HAT02A-03A
% night = visPresence(sort(night), 'Color', 'black', 'LineStyle', 'none', 'Transparency', 0.1, ...
%     'DateRange', [effort.Start(1), effort.End(3)]);
% whale = visPresence(sortrows(pres_narw), 'Color', [1,0,0],'Transparency', 0.4, ...
%     'DateRange', [effort.Start(1), effort.End(3)]);
% whale0 = visPresence(sortrows(pres_blue), 'Color', [0.75, 0, 0.75],'Transparency', 0.4, ...
%     'DateRange', [effort.Start(1), effort.End(3)]);
% whale1 = visPresence(sortrows(pres_fin), 'Color', [0.4660, 0.6740, 0.1880],'Transparency', 0.4, ...
%     'DateRange', [effort.Start(1), effort.End(3)]);
% whale2 = visPresence(sortrows(pres_hump), 'Color', [0.8500, 0.3250, 0.0980], 'Transparency', 0.4,...
%     'DateRange', [effort.Start(1), effort.End(3)]);
% whale3 = visPresence(sortrows(pres_sei), 'Color', 	[0, 0, 1],'Transparency', 0.4, ...
%     'DateRange', [effort.Start(1), effort.End(3)]);
% whale4 = visPresence(sortrows(pres_minke), 'Color', [0.4940, 0.1840, 0.5560], 'Transparency', 0.4,...
%     'DateRange', [effort.Start(1), effort.End(3)]);


if ~isempty(offEffort)
    offEffortPlot = visPresence(sort(offEffort), 'Color', [1 0.8 0.8], ...
        'DateRange', [effort.Start(1), effort.End(end)]);
    children = get(offEffortPlot(1), 'Children');
    if ~isempty(children), set(children, 'FaceAlpha', 0.3); end
end

set(gca, 'YDir','reverse');
ylimVals = ylim;
newYTicks = linspace(ylimVals(1), ylimVals(2), 10);
yticks(newYTicks);
yticklabels(datestr(newYTicks, 'dd-mmm-yyyy'));
set(gca,'FontSize',14,'YDir','reverse');
ylabel('Date','FontSize',16);
xlabel('Hour (UTC)','FontSize',16);
set(gcf, 'Position', [301,126,543,783]);

lineDate = datenum(datetime('07-May-2017'));
hold on; plot(xlim, [lineDate lineDate], 'k--', 'LineWidth', 1.5);
title("HAT - Sonar and Baleen Whale Plot")


% saveas(gcf, 'G:\My Drive\Atlantic Baleen and Sonar Impact\Exploratory Plots\Blue_diel.fig']));
% print(gcf, fullfile(saveDirFig, [SiteName,'_' SignalType '_diel.png']), '-dpng', '-r600');
%     close(gcf);


