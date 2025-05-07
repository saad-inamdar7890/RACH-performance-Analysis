% filepath: d:\Codes\Projects\RACH-performance-Analysis\plotResults.m
function plotResults(results, deviceCounts, trafficPatterns)
% PLOTRESULTS Visualizes the RACH simulation results
%   results: Simulation results structure
%   deviceCounts: Array of device counts
%   trafficPatterns: Cell array of traffic patterns

% Create a figure for each metric
metrics = {'accessSuccess', 'accessDelay', 'collisionProb', 'numRetransmissions', 'energyEfficiency', 'resourceUtilization'};
metricTitles = {'Access Success Probability', 'Average Access Delay (ms)', 'Collision Probability', ...
    'Average Retransmissions', 'Energy Efficiency (Tx per Success)', 'Resource Utilization'};

% Plot each metric vs number of devices
for m = 1:length(metrics)
    figure('Position', [100, 100, 800, 600]);
    hold on;
    
    for t = 1:length(trafficPatterns)
        metricValues = zeros(1, length(deviceCounts));
        
        for d = 1:length(deviceCounts)
            metricValues(d) = results(t,d).(metrics{m});
        end
        
        plot(deviceCounts, metricValues, 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 8);
    end
    
    title(metricTitles{m}, 'FontSize', 14);
    xlabel('Number of Devices', 'FontSize', 12);
    ylabel(metricTitles{m}, 'FontSize', 12);
    legend(trafficPatterns, 'Location', 'best', 'FontSize', 10);
    grid on;
    
    % Save figure
    saveas(gcf, ['RACH_' metrics{m} '_vs_Devices.png']);
end

% Additional analysis - Heatmap of success probability vs devices and backoff
figure('Position', [100, 100, 800, 600]);
backoffValues = [5, 10, 20, 40, 80];
successMatrix = zeros(length(backoffValues), length(deviceCounts));

% Run additional simulations for different backoff values
config = struct();
config.numPreambles = 54;
config.maxRetransmissions = 10;
config.simulationTime = 1000;
config.prachPeriodicity = 5;

for b = 1:length(backoffValues)
    config.backoffTime = backoffValues(b);
    
    for d = 1:length(deviceCounts)
        [accessSuccess, ~, ~, ~, ~, ~] = simulateRACH(config, deviceCounts(d), 'random');
        successMatrix(b, d) = accessSuccess;
    end
end

% Plot heatmap
imagesc(successMatrix);
colorbar;
title('Access Success Probability vs Backoff and Device Count', 'FontSize', 14);
xlabel('Number of Devices', 'FontSize', 12);
ylabel('Backoff Window (ms)', 'FontSize', 12);
set(gca, 'XTick', 1:length(deviceCounts), 'XTickLabel', deviceCounts);
set(gca, 'YTick', 1:length(backoffValues), 'YTickLabel', backoffValues);
saveas(gcf, 'RACH_Backoff_Analysis.png');

end