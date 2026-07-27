% CMS 7/27/26
% code that takes MFA (mid-frequency active sonar) ping-level measurement
% files and reformats them into generic bounding boxes compatible with
% WhaleMoanViz

% modified from convert_logger_to_wmv_txt.m

clear all

% -------------------------
% User settings
% -------------------------
inFile = 'Z:\MBARC_Reports\Atlantic Synthesis Reports\Anthropogenic\MFA\NFC\NFC_A_03_MFA ping-level metrics\NFC_A_03_Measurements_300.csv';
saveDir = 'L:\.shortcut-targets-by-id\16p-9IwPMhrAXrlYgpF4IEGZJrjjsaTQs\Atlantic_Baleen_Summer_2026\Manual logs';
xwavRoot = 'S:\NFC\NFC_A_03';

my_call = "MFA";
mfa_freq = 200; % single frequency (Hz) -> plots as a line, not a box; well clear of sei (30-100 Hz) and fin (35-80 Hz) whale call bands

% -------------------------
% Read MFA measurements
% -------------------------
data = readtable(inFile);

st = data.StartUTC;
ed = data.EndUTC;

if ~isdatetime(st)
    st = datetime(st, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS');
end
if ~isdatetime(ed)
    ed = datetime(ed, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS');
end

% -------------------------
% Find all xwavs in df100 folders
% -------------------------
xwavFiles = dir(fullfile(xwavRoot, '**', '*.x.wav'));

% Keep only files inside folders ending with df100
isDf100 = endsWith(string({xwavFiles.folder}'), "df100");
xwavFiles = xwavFiles(isDf100);

% Extract xwav timestamps
xwavPaths = fullfile({xwavFiles.folder}', {xwavFiles.name}');
xwavTimes = NaT(numel(xwavFiles), 1);

for i = 1:numel(xwavFiles)

    % Example filename:
    % NFC_A_03_170627_200500_df100.x.wav
    tok = regexp(xwavFiles(i).name, ...
        '_(\d{6})_(\d{6})_df100\.x\.wav$', ...
        'tokens', 'once');

    if ~isempty(tok)
        datePart = tok{1};   % e.g., 170627
        timePart = tok{2};   % e.g., 200500

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
% Match each detection to the xwav it falls in
% -------------------------
wav_file_path = strings(height(data), 1);

for i = 1:height(data)

    % Find the most recent xwav that started before the detection
    k = find(xwavTimes <= st(i), 1, 'last');

    if ~isempty(k)
        wav_file_path(i) = string(xwavPaths{k});
    else
        wav_file_path(i) = "";
    end
end

% -------------------------
% Build WhaleMoanViz table
% -------------------------
wmv_data = table();
wmv_data.start_time = st;
wmv_data.end_time = ed;
wmv_data.start_time.Format = 'yyyy-MM-dd HH:mm:ss';
wmv_data.end_time.Format = 'yyyy-MM-dd HH:mm:ss';
wmv_data.score = repmat(1, height(data), 1);
wmv_data.label = repmat(my_call, height(data), 1);
wmv_data.min_frequency = repmat(mfa_freq, height(data), 1);
wmv_data.max_frequency = repmat(mfa_freq, height(data), 1);
wmv_data.wav_file_path = wav_file_path;
wmv_data.start_time_sec = posixtime(st);
wmv_data.end_time_sec = posixtime(ed);

%% save data
outname = fullfile(saveDir, 'NFC_A_03_MFA_WMVZ.txt');
writetable(wmv_data, outname, 'delimiter', '\t')
