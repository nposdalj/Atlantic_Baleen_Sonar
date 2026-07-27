% CMS 5/4/26
% code that takes logger files and reformats them into generic bounding
% boxes compatible with WhaleMoanViz

% modified LMB code for reformatting gray whale detections to be compatible
% with WhaleMoanViz

clear all

% load in data:
% data = readtable('X:\Atlantic_Baleen_Sonar\NFC\Cleaned_Logs\NFC01A_allLF_cleaned_NP.xlsx');
data = readtable('G:\My Drive\Atlantic_Baleen_Summer_2026\Azores Data\AZORES_B_01_LF_LMB.xls');

%%
% df = dir('M:\Mysticetes\gray_M3_regina\*.mat');
saveDir = 'G:\My Drive\Atlantic_Baleen_Summer_2026\Azores Data';
my_species = ["Bb","Bm","Bp","Ba","Eg"]; % sei, blue, fin, minke, narw
my_calls = ["Downsweep","blueyyyyyy","40Hz","Pulse_train","Up-call"]; % calls associated with the baleen whale order, special case for blue whales with multiple call types
min_freq = [30, 999, 35, 160, 50 ];
max_freq = [100, 999, 80, 180, 300 ];
call_dur = [2, 999, 1, 60, 2];

% these call parameters were set from the examples and notes in the
% training ppt: Frosty:\MBARC_ALL\Training\Logging

% for the blue whale call types
blue_calls = ["A N Atlantic","Arch Sound"];
blue_min_freq = [16,35];
blue_max_freq = [30,70];
blue_call_dur = [19,7]; 

wmv_data = [];

for j = 1:length(my_species)

    out = table(); % preallocate
    % make generic bounding boxes per species
    this_sp_data = data(data.SpeciesCode==my_species(j),:);

    % special case for blue whales because there are 2 call types:
    if my_species(j) =="Bm" && ~isempty(this_sp_data)
        for n=1:length(blue_calls)
            out = table(); % preallocate
            blue_call_data = this_sp_data(this_sp_data.Call==blue_calls(n),:);

            if ~isempty(blue_call_data)
                st = [blue_call_data.StartTime];
                if isnat(blue_call_data.EndTime)
                    ed = [blue_call_data.StartTime+seconds(blue_call_dur(n))];
                else
                    ed = [blue_call_data.EndTime];
                end
                out.start_time = (st);
                out.end_time = (ed);
                out.start_time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                out.end_time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                out.score = repmat(1,height(out),1);
                out.label = repmat(blue_calls(n),height(out),1);
                out.min_frequency = repmat(blue_min_freq(n),height(out),1);
                out.max_frequency = repmat(blue_max_freq(n),height(out),1);
                out.wav_file_path = this_sp_data.InputFile;
                out.start_time_sec = posixtime(st);
                out.end_time_sec = posixtime(ed);

                wmv_data = [wmv_data; out];
            end
        end

    elseif ~isempty(this_sp_data)

        st = [this_sp_data.StartTime];
        if isnat(this_sp_data.EndTime)
            ed = [this_sp_data.StartTime+seconds(call_dur(j))]; % create end times
        else
            ed = [this_sp_data.EndTime];
        end
        out.start_time = (st);
        out.end_time = (ed);
        out.start_time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
        out.end_time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
        out.score = repmat(1,height(out),1);
        out.label = repmat(my_calls(j),height(out),1);
        out.min_frequency = repmat(min_freq(j),height(out),1);
        out.max_frequency = repmat(max_freq(j),height(out),1);
        out.wav_file_path = this_sp_data.InputFile; % add these columns so that current detections match the column numbers of new detections
        out.start_time_sec = posixtime(st);
        out.end_time_sec = posixtime(ed);

        wmv_data = [wmv_data; out];
    end

end


%% save data
outname = [saveDir,'\Azores_B_01_WMV.txt'];
writetable(wmv_data,[outname],'delimiter','\t')


