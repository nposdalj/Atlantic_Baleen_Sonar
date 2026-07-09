%% Add InputFile column based on xwav start times

clear; clc;

% -------------------------
% User settings
% -------------------------
inFile = 'L:\.shortcut-targets-by-id\16p-9IwPMhrAXrlYgpF4IEGZJrjjsaTQs\Atlantic_Baleen_Summer_2026\Manual logs\HAT06A_allLF_cleaned_CMS.xlsx';
outFile = 'L:\.shortcut-targets-by-id\16p-9IwPMhrAXrlYgpF4IEGZJrjjsaTQs\Atlantic_Baleen_Summer_2026\Manual logs\HAT06A_allLF_cleaned_CMS_with_InputFile.xlsx';

xwavRoot = 'V:\HAT_A_06';

% -------------------------
% Read detections table
% -------------------------
T = readtable(inFile, 'VariableNamingRule', 'preserve');

% Get detection start times
detTimes = T.("Start time");

% Convert to datetime if needed
if ~isdatetime(detTimes)
    detTimes = datetime(detTimes);
end

% -------------------------
% Find all xwavs in df100 folders
% -------------------------
xwavFiles = dir(fullfile(xwavRoot, '**', '*.x.wav'));

% Keep only files inside folders ending with df100
isDf100 = endsWith(string({xwavFiles.folder}'), "df100");
xwavFiles = xwavFiles(isDf100);

% -------------------------
% Extract xwav timestamps
% -------------------------
xwavPaths = fullfile({xwavFiles.folder}', {xwavFiles.name}');
xwavTimes = NaT(numel(xwavFiles), 1);

for i = 1:numel(xwavFiles)

    % Example filename:
    % HAT_B_03_01_180302_060614_df100.x.wav
    tok = regexp(xwavFiles(i).name, ...
        '_(\d{6})_(\d{6})_df100\.x\.wav$', ...
        'tokens', 'once');

    if ~isempty(tok)
        datePart = tok{1};   % e.g., 180302
        timePart = tok{2};   % e.g., 060614

        xwavTimes(i) = datetime([datePart timePart], ...
            'InputFormat', 'yyMMddHHmmss');
    end
end

% Remove files where timestamp could not be read
valid = ~isnat(xwavTimes);
xwavTimes = xwavTimes(valid);
xwavPaths = xwavPaths(valid);

% Sort xwavs by start time
[xwavTimes, idx] = sort(xwavTimes);
xwavPaths = xwavPaths(idx);

% -------------------------
% Match detections to xwavs
% -------------------------
InputFile = strings(height(T), 1);

for i = 1:height(T)

    % Find the most recent xwav that started before the detection
    k = find(xwavTimes <= detTimes(i), 1, 'last');

    if ~isempty(k)
        InputFile(i) = string(xwavPaths{k});
    else
        InputFile(i) = "";
    end
end

% -------------------------
% Add column and save
% -------------------------
T.InputFile = InputFile;

writetable(T, outFile);

disp("Done! Saved file:");
disp(outFile);