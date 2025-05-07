% filepath: d:\Codes\Projects\RACH-performance-Analysis\analyzeRACHConfigurations.m
% Analyze the impact of different PRACH configurations
clc;
clear all;

% Base configuration
baseConfig = struct();
baseConfig.numPreambles = 54;
baseConfig.maxRetransmissions = 10;
baseConfig.backoffTime = 20;
baseConfig.simulationTime = 1000;

% Different PRACH periodicities to test (in ms)
prachPeriodicities = [2, 5, 10, 20];

% Device count
numDevices = 500;

% Results structure
configResults = struct();

% Run simulations for different periodicities
for p = 1:length(prachPeriodicities)
    config = baseConfig;
    config.prachPeriodicity = prachPeriodicities(p);
    
    fprintf('Simulating PRACH periodicity = %d ms with %d devices...\n', ...
        config.prachPeriodicity, numDevices);
    
    % Run simulation with random traffic
    [~, metrics] = fullRACHStateMachine(config, numDevices, 'random');
    
    % Store results
    configResults(p).periodicity = config.prachPeriodicity;
    configResults(p).successRate = metrics.successRate;
    configResults(p).avgDelay = metrics.avgDelay;
    configResults(p).avgRetransmissions = metrics.avgRetransmissions;
    configResults(p).energyEfficiency = metrics.energyEfficiency;
end

% Plot results
figure;
subplot(2, 2, 1);
plot([configResults.periodicity], [configResults.successRate], 'o-', 'LineWidth', 2);
title('Success Rate vs PRACH Periodicity');
xlabel('PRACH Periodicity (ms)');
ylabel('Success Rate');
grid on;

subplot(2, 2, 2);
plot([configResults.periodicity], [configResults.avgDelay], 'o-', 'LineWidth', 2);
title('Average Delay vs PRACH Periodicity');
xlabel('PRACH Periodicity (ms)');
ylabel('Average Delay (ms)');
grid on;

subplot(2, 2, 3);
plot([configResults.periodicity], [configResults.avgRetransmissions], 'o-', 'LineWidth', 2);
title('Retransmissions vs PRACH Periodicity');
xlabel('PRACH Periodicity (ms)');
ylabel('Avg Retransmissions');
grid on;

subplot(2, 2, 4);
plot([configResults.periodicity], [configResults.energyEfficiency], 'o-', 'LineWidth', 2);
title('Energy Efficiency vs PRACH Periodicity');
xlabel('PRACH Periodicity (ms)');
ylabel('Tx per Success');
grid on;

saveas(gcf, 'PRACH_Configuration_Analysis.png');