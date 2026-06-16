% splitting the training and test data after we have made more examples in
% WMV

% CMS 6/16/26

clear all

% load in txt file:
opts2 = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Make_New_Examples\NFC01A_A_02_combined_verified.txt', 'Delimiter', '\t');
opts2 = setvartype(opts2, opts2.VariableNames, 'string');  % keep ALL columns as text
new_data = readtable("G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Make_New_Examples\NFC01A_A_02_combined_verified.txt", opts2);

opts1 = detectImportOptions('G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC01A_verified_Ba_NFC_A_02_spring', 'Delimiter', '\t');
opts1 = setvartype(opts1, opts1.VariableNames, 'string');  % keep ALL columns as text
input_data = readtable("G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Backup\NFC01A_verified_Ba_NFC_A_02_spring", opts1);

%% searching for calls that are sooo short (in duration) that the start and end pixels are the same pixel
cleaned_data = rmmissing(new_data);
starttime = str2double(cleaned_data.xmin);
endtime = str2double(cleaned_data.xmax);
diff_time = endtime-starttime;

short_dur_idx = find(diff_time==0); % all of the calls that share the same start and end time pixel are 40 Hz calls, we can remove them when we subset fin whale calls
short_data = cleaned_data(short_dur_idx,:);

%%
% investigate the new data:
unique(new_data.label);
length(find(new_data.label=="Downsweep"))
length(find(new_data.label=="Pulse_train"))
length(find(new_data.label=="40Hz"))

% split the data between train, validate, and test -> make sure you do this by label to make sure that all of your data is evenly distributed
Bb_data = new_data(new_data.label=="Downsweep",:);
Ba_data = new_data(new_data.label=="Pulse_train",:);

Bp_data = new_data(new_data.label=="40Hz",:);
starttime = str2double(Bp_data.xmin);
endtime = str2double(Bp_data.xmax);
diff_time = endtime-starttime;
short_dur_idx = find(diff_time==0); % all of the calls that share the same start and end time pixel are 40 Hz calls, we can remove them when we subset fin whale calls
short_data = Bp_data(short_dur_idx,:); % you can see all of the calls with a duration of 0 pixels here
Bp_data.xmax(short_dur_idx)= string(endtime(short_dur_idx)+1);

unlabeled_data = new_data(ismissing(new_data.label),:);

% making a 70/15/15 split with our data for train,validate,test
% test data:
Bb_idx = (1:height(Bb_data))'; % full list indices for the Bb calls
Bb_test_idx =  randsample(Bb_idx,floor(0.15*height(Bb_idx))); % we are randomly sampling indices that we will use to index actual calls from our Bb_data  

Ba_idx = (1:height(Ba_data))';
Ba_test_idx =  randsample(height(Ba_idx),floor(0.15*height(Ba_idx)));

Bp_idx = (1:height(Bp_data))';
Bp_test_idx =  randsample(Bp_idx,floor(0.15*height(Bp_idx)));

unlabeled_idx = (1:height(unlabeled_data))';
unlabeled_test_idx = randsample(unlabeled_idx,floor(0.15*height(unlabeled_idx)));

% compile all of the species
test_data = [Bb_data(Bb_test_idx,:); Ba_data(Ba_test_idx,:); Bp_data(Bp_test_idx,:); unlabeled_data(unlabeled_test_idx,:)];

% validate data:
Bb_idx_no_test = Bb_idx;% starting with the full dataset
Bb_idx_no_test(Bb_test_idx) = []; % remove the indices we have designated as our test data before resampling
Bb_val_idx = randsample(Bb_idx_no_test,floor(0.15*height(Bb_idx))); % resample indices now that we have removed the selected indices for test data (to avoid repeated selections)
any(intersect(Bb_val_idx,Bb_test_idx)); % checking to make sure that we are not getting the same samples between test and validation data

Ba_idx_no_test = Ba_idx;
Ba_idx_no_test(Ba_test_idx) = []; % remove already sampled data
Ba_val_idx = randsample(Ba_idx_no_test,floor(0.15*height(Ba_idx))); % sample for validation indices
any(intersect(Ba_val_idx,Ba_test_idx)) % sanity check

Bp_idx_no_test = Bp_idx;
Bp_idx_no_test(Bp_test_idx) = []; % remove already sampled data
Bp_val_idx = randsample(Bp_idx_no_test,floor(0.15*height(Bp_idx))); % sample for validation indices
any(intersect(Bp_val_idx,Bp_test_idx)) % sanity check

unlabeled_idx_no_test = unlabeled_idx;
unlabeled_idx_no_test(unlabeled_test_idx) = []; % remove already sampled data
unlabeled_val_idx = randsample(unlabeled_idx_no_test,floor(0.15*height(unlabeled_idx))); % sample for validation indices
any(intersect(unlabeled_val_idx,unlabeled_test_idx)) % sanity check

% compile all labels
validation_data = [Bb_data(Bb_val_idx,:); Ba_data(Ba_val_idx,:); Bp_data(Bp_val_idx,:); unlabeled_data(unlabeled_val_idx,:)];

% training data:
Bb_train_idx = Bb_idx; % you must start with the full dataset
Bb_train_idx([Bb_val_idx; Bb_test_idx]) = []; % remove the test and validation indices, the rest will be training data
any(intersect(intersect(Bb_val_idx,Bb_test_idx),Bb_train_idx)) % sanity check

Ba_train_idx = Ba_idx;
Ba_train_idx([Ba_val_idx; Ba_test_idx]) = []; % remove test and val indices
any(intersect(intersect(Ba_val_idx,Ba_test_idx),Ba_train_idx)) % sanity check

Bp_train_idx = Bp_idx;
Bp_train_idx([Bp_val_idx; Bp_test_idx]) = []; % remove test and val indices
any(intersect(intersect(Bp_val_idx,Bp_test_idx),Bp_train_idx)) % sanity check

unlabeled_train_idx = unlabeled_idx;
unlabeled_train_idx([unlabeled_test_idx; unlabeled_val_idx]) = [];
any(intersect(intersect(unlabeled_test_idx,unlabeled_val_idx),unlabeled_train_idx))

% compile everything together
train_data = [Bb_data(Bb_train_idx,:); Ba_data(Ba_train_idx,:); Bp_data(Bp_train_idx,:); unlabeled_data(unlabeled_train_idx,:)];


%% save all of the datasets
writetable(test_data, 'G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Make_New_Examples\NFC01A_A_02_combined_test_data.txt', ...
    'Delimiter', '\t', ...
    'FileType', 'text', ...
    'QuoteStrings', false);   % <-- critical: prevents "A N Atlantic" → "\"A N Atlantic\""

writetable(train_data, 'G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Make_New_Examples\NFC01A_A_02_combined_train_data.txt', ...
    'Delimiter', '\t', ...
    'FileType', 'text', ...
    'QuoteStrings', false);   % <-- critical: prevents "A N Atlantic" → "\"A N Atlantic\""

writetable(validation_data, 'G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz\Make_New_Examples\NFC01A_A_02_combined_validate_data.txt', ...
    'Delimiter', '\t', ...
    'FileType', 'text', ...
    'QuoteStrings', false);   % <-- critical: prevents "A N Atlantic" → "\"A N Atlantic\""


