% Set parent directory (can contain multiple folders)
parentDir = 'L:\.shortcut-targets-by-id\1NHK8ZRtCbvo4cicsapyJzWLfPTWFfpQ0\NAVFAC_REPORT_FIGURES\HAT\data\01_DATA_INPUTS\HUMPBACK';  % <-- change this

% Get all CSV files recursively
files = dir(fullfile(parentDir, '**', '*.csv'));

total_missed_instances = 0;
total_valid_instances = 0;   % counts where MR is 0 or 1
total_detected_instances = 0; % optional: counts where MR == 1

for i = 1:length(files)
    
    filePath = fullfile(files(i).folder, files(i).name);
    fprintf('Processing: %s\n', filePath);
    
    % Read table
    T = readtable(filePath);
    T(1:21,:) = [];
    T.Properties.VariableNames(1) = "StartDate";
    T.Properties.VariableNames(2) = "StartTime";
    T.Properties.VariableNames(3) = "EndDate";
    T.Properties.VariableNames(4) = "EndTime";
    T.Properties.VariableNames(5) = "call type 1";
    T.Properties.VariableNames(6) = "Sum";
    T.Properties.VariableNames(7) = "Manual_Review";
    T = removevars(T, ["Var8","Var9"]);

    % --- Clean Manual_Review column ---
if iscell(T.Manual_Review) || isstring(T.Manual_Review)
    T.Manual_Review = str2double(string(T.Manual_Review));
end

% Any values that are NOT 0 or 1 → set to NaN
T.Manual_Review(~ismember(T.Manual_Review, [0 1])) = NaN;

% Convert StartDate + StartTime into one datetime
T.StartDate = string(T.StartDate);
T.StartTime = string(T.StartTime);

T.DateTime = datetime(T.StartDate + " " + T.StartTime, ...
    'InputFormat','MM/dd/yyyy HH:mm:ss'); % <-- adjust if needed
    
T.Date = dateshift(T.DateTime, 'start', 'day');

    % Get unique days
    uniqueDays = unique(T.Date);

    for d = 1:length(uniqueDays)
        
        dayMask = T.Date == uniqueDays(d);
        dayData = T(dayMask, :);
        
        % Find rows where Sum > 30
        idx = find(dayData.Sum > 30);
        
        if isempty(idx)
            continue
        end
        
        % First occurrence in that day
        firstIdx = idx(1);
        
val = dayData.Manual_Review(firstIdx);

if ~isnan(val)
    total_valid_instances = total_valid_instances + 1;
    
    if val == 0
        total_missed_instances = total_missed_instances + 1;
    elseif val == 1
        total_detected_instances = total_detected_instances + 1;
    end
end
        
    end
end

fprintf('\nTotal valid instances (Sum > 30 with MR = 0 or 1): %d\n', total_valid_instances);
fprintf('Total missed instances (MR = 0): %d\n', total_missed_instances);
fprintf('Total detected instances (MR = 1): %d\n', total_detected_instances);

if total_valid_instances > 0
    miss_rate = total_missed_instances / total_valid_instances * 100;
    fprintf('Miss rate: %.2f%%\n', miss_rate);
end