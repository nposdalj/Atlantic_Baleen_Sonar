% CMS 4/15/26
% exploratory plots from the baleen and MFAS hourly bins 
% baleen whale effort: HAT02A-B_03_01
% MFAS effort: HAT01A-B_07_01

clear all

load('X:\Atlantic_Baleen_Sonar\HAT\Binned_data\HAT_Baleen_MFA_table_1hr_bins.mat'); % baleen whale data
MFAS = readtable('X:\MBARC_Reports\Atlantic Synthesis Reports\Anthropogenic\Final Tables\HAT\HAT_MFA_LoggerTable.xlsx'); % MFAS data
saveDirFig = 'G:\My Drive\Atlantic Baleen and Sonar Impact\Exploratory Plots';
SiteName = 'HAT';

whale_sum = sum(full_table{:,2:end},2);
full_table.AllWhales = whale_sum;
mult_whales_idx = find(full_table.AllWhales>1);
mult_whales = full_table.AllWhales(mult_whales_idx);
mult_whales_unique = unique(mult_whales); % maximum we have 4 whale species detected in an hour

% subset for only sonar events:
sonar_table = full_table(full_table.MFA==1,:);

% subset for only whale presence:
whale_table = full_table(full_table.AllWhales==1,:);

% subset for multiple whales
many_whale_table = full_table(full_table.AllWhales>0,:);

% subset for sonar and whale presence:
both_table = full_table(full_table.AllWhales>0 & full_table.MFA==1,:);

% plotting
% figure();
% scatter(full_table.Time,(full_table.MFA.*full_table.AllWhales),'filled','o');
% hold on
% plot(full_table.Time,full_table.AllWhales)
% 
% figure();
% scatter(sonar_table.Time,(sonar_table.AllWhales),'filled','o');
% hold on
% plot(sonar_table.Time,sonar_table.AllWhales)

%% === Diel Plot ===

switch SiteName
% partial HAT effort
    case 'HAT'
        effort.Start = [datetime('15-Mar-2012 16:00:00'), datetime('09-Oct-2012 15:00:00'), datetime('29-May-2013 18:00:00'), datetime('09-May-2014 00:00:00'), datetime('07-Apr-2015 00:00:00'), datetime('29-Apr-2016 12:00:00'),...
            datetime('09-May-2017 12:02:54'), datetime('26-Oct-2017 12:00:00'), datetime('29-Oct-2020 11:04:59')];
        effort.End   = [datetime('15-Mar-2012 16:00:01'), datetime('09-May-2013 20:00:06'), datetime('15-Mar-2014 00:35:00'), datetime('11-Dec-2014 22:53:45'), datetime('21-Jan-2016 11:54:16'), datetime('06-Feb-2017 08:56:03'),...
            datetime('25-Oct-2017 14:11:45'), datetime('01-Jun-2018 00:54:59'), datetime('29-Oct-2020 11:05:00')];
        lat = 35+(20.432/60); lon = 360-(74+(51.457/60));
% partial NFC effort    
    case 'NFC'
        effort.Start = [datetime('19-Jun-2014 12:00:00'), datetime('30-Apr-2016 12:00:00'), datetime('30-Jun-2017 00:00:00'), datetime('17-May-2022 14:02:29')];
        effort.End   = [datetime('05-Apr-2015 02:25:48'), datetime('28-Jun-2017 18:38:51'), datetime('02-Jun-2018 06:15:06'), datetime('17-May-2022 14:02:30')];
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
SpCode = 'Humpback';

figure()

nightH = visPresence(sort(night),'LineStyle', 'none','Color', [0.5,0.5,0.5], 'Transparency', 0.15);
sonar = visPresence(sortrows(pres_mfas), 'Color', 'black', ...
    'DateRange', [effort.Start(1), effort.End(end)]);
% set(get(sonar(1), 'Children'), 'EdgeColor', rgbcols);
hold on
whale = visPresence(sortrows(pres_hump), 'Color', 'blue', ...
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

if SiteName == 'HAT'
lineDate = datenum(datetime('07-May-2017'));
hold on; plot(xlim, [lineDate lineDate], 'k--', 'LineWidth', 1.5);
end
title([SiteName,' Sonar and ', SpCode]);


saveas(gcf, fullfile(saveDirFig, [SiteName,'_',SpCode,'_manual_logs_diel.fig']));
print(gcf, fullfile(saveDirFig, [SiteName,'_' SpCode '_manual_logs_diel.png']), '-dpng', '-r600');
%     close(gcf);

%% investigate the overlap between sonar and whales
clear all

load('X:\Atlantic_Baleen_Sonar\HAT\Binned_data\HAT_Baleen_MFA_table_1hr_bins.mat'); % baleen whale data
hat_table = full_table;
hat_table.Site = repmat('HAT',size(hat_table,1),1);
whale_sum = sum(hat_table{:,2:7},2);
hat_table.AllWhales = whale_sum;
% sum(hat_table.Sei(hat_table.AllWhales>0 & hat_table.MFA==1))
% sum(hat_table.Blue(hat_table.AllWhales>0 & hat_table.MFA==1))
% sum(hat_table.Fin(hat_table.AllWhales>0 & hat_table.MFA==1))
% sum(hat_table.Minke(hat_table.AllWhales>0 & hat_table.MFA==1))
% sum(hat_table.NARW(hat_table.AllWhales>0 & hat_table.MFA==1))
% sum(hat_table.Humpback(hat_table.AllWhales>0 & hat_table.MFA==1))

load('X:\Atlantic_Baleen_Sonar\NFC\Binned_data\NFC_Baleen_MFA_table_1hr_bins.mat'); % baleen whale data
nfc_table = full_table;
nfc_table.Site = repmat('NFC',size(nfc_table,1),1);
whale_sum = sum(full_table{:,2:7},2);
nfc_table.AllWhales = whale_sum;
% sum(nfc_table.Sei(nfc_table.AllWhales>0 & nfc_table.MFA==1))
% sum(nfc_table.Blue(nfc_table.AllWhales>0 & nfc_table.MFA==1))
% sum(nfc_table.Fin(nfc_table.AllWhales>0 & nfc_table.MFA==1))
% sum(nfc_table.Minke(nfc_table.AllWhales>0 & nfc_table.MFA==1))
% sum(nfc_table.NARW(nfc_table.AllWhales>0 & nfc_table.MFA==1))
% sum(nfc_table.Humpback(nfc_table.AllWhales>0 & nfc_table.MFA==1))

full_table = [hat_table; nfc_table];

% whale_sum = sum(full_table{:,2:7},2);
% full_table.AllWhales = whale_sum;
mult_whales_idx = find(full_table.AllWhales>1);
mult_whales = full_table.AllWhales(mult_whales_idx);
mult_whales_unique = unique(mult_whales); % maximum we have 4 whale species detected in an hour

% subset for only sonar events:
sonar_table = full_table(full_table.MFA==1,:);

% subset for only whale presence:
whale_table = full_table(full_table.AllWhales==1,:);

% subset for multiple whales
many_whale_table = full_table(full_table.AllWhales>0,:);

% subset for sonar and whale presence:
both_table = full_table(full_table.AllWhales>0 & full_table.MFA==1,:);

% subset for before and after sonar events (when we have whale overlap):
before_idx = find(full_table.AllWhales>0 & full_table.MFA==1)-1; % get all of the hours before a sonar pos. hour (treating each sonar hour as an individual event)
sonar_idx = find(full_table.AllWhales>0 & full_table.MFA==1); % get all sonar event idx
true_before_idx = setdiff(before_idx,sonar_idx); % accounting for consecutive hours of presence and only including non-consecutive before hours
before_table = full_table(true_before_idx,:);
before_table.Relate_sonar = repmat(1,size(before_table,1),1); % mark 1 for before a sonar pos. hour

both_table.Relate_sonar = repmat(2,size(both_table,1),1); % mark 2 for during a sonar pos. hour

after_idx = find(full_table.AllWhales>0 & full_table.MFA==1)+1; % get all of the hours after a sonar pos. hour (treating each sonar hour as an individual event)
true_after_idx = setdiff(after_idx,sonar_idx);
after_table = full_table(true_after_idx,:);
after_table.Relate_sonar = repmat(3,size(after_table,1),1); % mark 3 for after a sonar pos. hour

sonar_event_table = [before_table; both_table; after_table];
sonar_event_table = sortrows(sonar_event_table); % gives before, during, and after for each sonar pos. hour for nfc and hat

hat_idx = sonar_event_table.Site=='HAT';
hat_mfa_table = sortrows(sonar_event_table(hat_idx(:,1),:));

nfc_idx = (sonar_event_table.Site=='NFC');
nfc_mfa_table = sortrows(sonar_event_table(nfc_idx(:,1),:));

% sum(both_table.Sei)
% sum(both_table.Blue)
% sum(both_table.Fin)
% sum(both_table.Minke)
% sum(both_table.NARW)
% sum(both_table.Humpback)

%% plot 


%%

mfa_colors = [
    0.80 0.95 0.80   % very light green
    0.98 0.80 0.80   % very light red (soft pink)
    0.75 0.88 0.98   % very light blue
];
speciesColors = [
    0.80 0.40 0.40   % red
    0.90 0.60 0.20   % orange
    0.40 0.70 0.40   % green
    0.90 0.80 0.30   % yellow
    0.40 0.60 0.85   % blue
    0.60 0.40 0.70   % purple
];

hours = nfc_mfa_table.Time;
mfa = nfc_mfa_table.Relate_sonar;
species = nfc_mfa_table{:,2:7};
species_name = ["Sei","Minke","Blue","NARW","Fin","Humpback"];

numSpecies = size(species,2);
numRows    = size(species,1);

img = ones(numRows, numSpecies, 3); % start white

for i = 1:numRows
    for j = 1:numSpecies
        
        if species(i,j) == 1
            % species color
            img(i,j,:) = speciesColors(j,:);
        else
            % blend rain tint for empty cells
            img(i,j,:) = mfa_colors(mfa(i),:);
        end
        
    end
end

figure
image(img)

set(gca, 'YDir','normal') % so time goes upward

xticks(1:numSpecies)
xticklabels(species_name)

yticks(1:numRows)
yticklabels(string(hours))

xlabel('Species')
ylabel('Hour')
title('NFC - Whale Presence with MFA Context')

hold on
for x = 0.5:1:numSpecies+0.5
    xline(x, 'k-', 'LineWidth', 0.5)
end

% for y = 0.5:1:numRows+0.5
%     yline(y, 'k-', 'LineWidth', 0.5)
% end