% compiling the txt files from WhaleMoanViz
% CMS 5/12/26
opts1 = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_disk01-06_WMVZ_verified.txt', 'Delimiter', '\t');
opts1 = setvartype(opts1, opts1.VariableNames, 'string');  % keep ALL columns as text
whales1 = readtable("G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_disk01-06_WMVZ_verified.txt",opts1);

opts2 = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_disk06-07_WMVZ_verified.txt', 'Delimiter', '\t');
opts2 = setvartype(opts2, opts2.VariableNames, 'string');  % keep ALL columns as text
whales2 = readtable("G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_disk06-07_WMVZ_verified.txt", opts2);

opts3 = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_disk07_WMVZ_verified.txt', 'Delimiter', '\t');
opts3 = setvartype(opts3, opts3.VariableNames, 'string');  % keep ALL columns as text
whales3 = readtable("G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_disk07_WMVZ_verified.txt",opts3);

% get the edited sections from each table:
whales1_edits = whales1(1:521,:);
whale2_edits = whales2(276:529,:); % getting only the rows with annotated eits
whales3_edits = whales3(331:end,:);

% combine whale table:
edits_only = [whales1_edits; whale2_edits; whales3_edits];

% correction: no gaps in the data
% whales1_missing = whales1(1:576,:);
% full_table = [whales1_missing; whale2_edits];

% make D calls Downsweeps
edits_only.label(edits_only.label=='D')='Downsweep';
edits_only.label(edits_only.label=='B')='Pulse_train';

% full_table.label = string(full_table.label);
% full_table.label(full_table.label=='D')='Downsweep';

% save
% writetable(edits_only, "G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_all_verified.txt");
writetable(edits_only, 'G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_spring_verified.txt', ...
    'Delimiter', '\t', ...
    'FileType', 'text', ...
    'QuoteStrings', false);
% writetable(full_table, "G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_all_missing_verified.txt");
% writetable(full_table, 'G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_all_missing_verified.txt', ...
%     'Delimiter', '\t', ...
%     'FileType', 'text', ...
%     'QuoteStrings', false);

%% edit labels only:

% --- READ ---
opts = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\NFC01A_WMVZ_verified.txt', 'Delimiter', '\t');
opts = setvartype(opts, opts.VariableNames, 'string');  % keep ALL columns as text
T = readtable('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\NFC01A_WMVZ_verified.txt', opts);

% --- EDIT labels ---
T.label(T.label=='D')='Downsweep';
T.label(T.label=='A')='Up-call';
T.label(T.label=='B')='Pulse_train';

% --- SAVE ---
writetable(T, 'G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC01A_verified_Ba_NARW.txt', ...
    'Delimiter', '\t', ...
    'FileType', 'text', ...
    'QuoteStrings', false);   % <-- critical: prevents "A N Atlantic" → "\"A N Atlantic\""

%% create a compiled NFC verified txt file
% NFC_A_02 -  on effort during the springtime, with a +/- 5 minute window
% around all logged calls

% --- READ ---
opts1 = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_spring_verified.txt', 'Delimiter', '\t');
opts1 = setvartype(opts1, opts1.VariableNames, 'string');  % keep ALL columns as text
whales1 = readtable("G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC_A_02_spring_verified.txt",opts1);
whales1_edits = whales1;
whales1_edits.start_date = datetime(whales1_edits.start_time);
whales1_edits.months = month(whales1_edits.start_date);

% want to subset feb-april
spring_idx = find(whales1_edits.months==2 | whales1_edits.months==3 | whales1_edits.months==4);
spring_whales = whales1(spring_idx,:);

% get call totals:
unique(spring_whales.label)
length(find(spring_whales.label=="40Hz")) % 419
length(find(spring_whales.label=="Downsweep")) % 666
length(find(spring_whales.label=="Pulse_train")) %4

% NFC01A -  on effort for all rarer whale calls
opts2 = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC01A_verified_Ba_NARW', 'Delimiter', '\t');
opts2 = setvartype(opts2, opts2.VariableNames, 'string');  % keep ALL columns as text
whales2 = readtable("G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC01A_verified_Ba_NARW", opts2);

% get call totals:
unique(whales2.label)
length(find(whales2.label=="A N Atlantic")) % 3
length(find(whales2.label=="Up-call")) % 2
length(find(whales2.label=="Pulse_train")) % 60

% subset the rarer calls:
rare_whale_idx = find(whales2.label=="A N Atlantic" | whales2.label=="Up-call" | whales2.label=="Pulse_train");
rare_whales = whales2(rare_whale_idx,:);

% subset pulse-trains:
ba_idx = find(whales2.label=="Pulse_train");
ba_whales = whales2(ba_idx,:);

T = [spring_whales; ba_whales];

% --- SAVE ---
writetable(T, 'G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC01A_verified_Ba_NFC_A_02_spring.txt', ...
    'Delimiter', '\t', ...
    'FileType', 'text', ...
    'QuoteStrings', false);   % <-- critical: prevents "A N Atlantic" → "\"A N Atlantic\""

%%
opts = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Data_Backup\NFC01A_verified_Ba_NFC_A_02_spring.txt', 'Delimiter', '\t');
opts = setvartype(opts, opts.VariableNames, 'string');  % keep ALL columns as text
T = readtable('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Data_Backup\NFC01A_verified_Ba_NFC_A_02_spring.txt', opts);

get_xwavs = unique(T.wav_file_path);




