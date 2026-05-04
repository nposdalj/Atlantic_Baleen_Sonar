% CMS 5/4/26
% code that takes logger files and reformats them into generic bounding
% boxes compatible with WhaleMoanViz

% modified LMB code for reformatting gray whale detections to be compatible
% with WhaleMoanViz

clear all

% load in data:
data = readtable('X:\Atlantic_Baleen_Sonar\NFC\Cleaned_Logs\NFC_A_02_allLF_cleaned_NP.xlsx');

%%
% df = dir('M:\Mysticetes\gray_M3_regina\*.mat');
saveDir = 'G:\My Drive\Atlantic_Baleen_Summer_2026\Test_Whale_Moan_Viz';
my_species = ["Bb","Bm","Bp","Ba","Eg"]; % sei, blue, fin, minke, narw
my_calls = ["Downsweep","blueyyyyyy","40Hz","Pulse_train","Up-call"]; % calls associated with the baleen whale order, special case for blue whales with multiple call types
min_freq = [30, 999, 35, 150, 50 ];
max_freq = [100, 999, 80, 175, 150 ];
call_dur = [2, 999, 1, 60, 2];

blue_calls = ["A N Atlantic","Arch Sound"];
blue_min_freq = [16,35];
blue_max_freq = [20,70];
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

            st = [blue_call_data.EventNumber];
            ed = [blue_call_data.EventNumber+seconds(blue_call_dur(n))];
            out.start_time = (st);
            out.end_time = (ed);
            out.start_time.Format = 'yyyy-MM-dd HH:mm:ss';
            out.end_time.Format = 'yyyy-MM-dd HH:mm:ss';
            out.score = repmat(1,height(out),1);
            out.label = repmat(blue_calls(n),height(out),1);
            out.min_frequency = repmat(blue_min_freq(n),height(out),1);
            out.max_frequency = repmat(blue_max_freq(n),height(out),1);

            wmv_data = [wmv_data; out];
        end

    elseif ~isempty(this_sp_data)

        st = [this_sp_data.EventNumber];
        ed = [this_sp_data.EventNumber+seconds(call_dur(j))];
        out.start_time = (st);
        out.end_time = (ed);
        out.start_time.Format = 'yyyy-MM-dd HH:mm:ss';
        out.end_time.Format = 'yyyy-MM-dd HH:mm:ss';
        out.score = repmat(1,height(out),1);
        out.label = repmat(my_calls(j),height(out),1);
        out.min_frequency = repmat(min_freq(j),height(out),1);
        out.max_frequency = repmat(max_freq(j),height(out),1);

        wmv_data = [wmv_data; out];
    end

end


%% save data
outname = [saveDir,'\NFC_A_02_WMVZ.txt'];
writetable(wmv_data,[outname],'delimiter','\t')


