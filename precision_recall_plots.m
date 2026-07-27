% CMS 6/18/26

clear all

% claude code
% Plots precision-recall curves for each whale call type from model test evaluation
% Inputs:  none - data hardcoded from eval txt file
% Outputs: figure displaying precision-recall curves for all three call types

% ---- hardcoded data from eval txt file ----

% score thresholds evaluated during testing
scoreThresholds = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];

% precision values at each threshold for each call type
pulsePrecision     = [0.9091, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 0.0000];
hz40Precision      = [0.3267, 0.3295, 0.3537, 0.3529, 0.3500, 0.5000, 0.0000, 0.0000, 0.0000];
downsweepPrecision = [0.1978, 0.2136, 0.2394, 0.2548, 0.2613, 0.2784, 0.2986, 0.2989, 0.3133];

% recall values at each threshold for each call type
pulseRecall     = [0.5882, 0.5625, 0.5625, 0.5000, 0.4375, 0.3125, 0.2500, 0.1250, 0.0000];
hz40Recall      = [0.7333, 0.6304, 0.6042, 0.4528, 0.2593, 0.1207, 0.0000, 0.0000, 0.0000];
downsweepRecall = [0.9293, 0.8947, 0.8947, 0.8421, 0.7895, 0.7474, 0.6947, 0.5474, 0.2737];

% ---- plotting ----

figure;  
hold on; 

% plot precision-recall curve for Pulse_train with circle markers
plot(pulseRecall, pulsePrecision, '-o', 'DisplayName', 'Pulse\_train', 'LineWidth', 2);

% plot precision-recall curve for 40Hz with square markers
plot(hz40Recall, hz40Precision, '-s', 'DisplayName', '40Hz', 'LineWidth', 2);

% plot precision-recall curve for Downsweep with triangle markers
plot(downsweepRecall, downsweepPrecision, '-^', 'DisplayName', 'Downsweep', 'LineWidth', 2);

% label each point with its score threshold value
for i = 1:length(scoreThresholds)                                                    % loop over each threshold
    text(pulseRecall(i),     pulsePrecision(i),     num2str(scoreThresholds(i)), 'FontSize', 12, 'HorizontalAlignment','left', 'VerticalAlignment','top'); % label Pulse_train point
    text(hz40Recall(i),      hz40Precision(i),      num2str(scoreThresholds(i)), 'FontSize', 12, 'HorizontalAlignment','left', 'VerticalAlignment','top'); % label 40Hz point
    text(downsweepRecall(i), downsweepPrecision(i), num2str(scoreThresholds(i)), 'FontSize', 12, 'HorizontalAlignment','left', 'VerticalAlignment','top'); % label Downsweep point
end

xlabel('Recall');    % x-axis label
ylabel('Precision'); % y-axis label
title('Precision-Recall Curves by Call Type'); % figure title
legend('show', 'Location', 'best');            % display legend with call type names
xlim([0 1]); % set x-axis range from 0 to 1
ylim([0 1]); % set y-axis range from 0 to 1
grid on;     % add gridlines for readability
hold off;    % release hold on axes