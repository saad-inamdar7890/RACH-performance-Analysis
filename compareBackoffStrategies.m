% filepath: d:\Codes\Projects\RACH-performance-Analysis\compareBackoffStrategies.m
% Compare different backoff strategies in RACH
clc;
clear all;

% Base configuration
baseConfig = struct();
baseConfig.numPreambles = 54;
baseConfig.maxRetransmissions = 10;
baseConfig.simulationTime = 1000;
baseConfig.prachPeriodicity = 5;

% Define backoff strategies
strategies = {'fixed', 'linear', 'exponential', 'random'};
numDevices = 500;

% Results structure
backoffResults = struct();

% Run simulations for different backoff strategies
for s = 1:length(strategies)
    strategy = strategies{s};
    config = baseConfig;
    
    % Configure backoff strategy
    switch strategy
        case 'fixed'
            config.backoffTime = 20;
            config.backoffStrategy = 'fixed';
        case 'linear'
            config.backoffTime = 10; % Base value
            config.backoffStrategy = 'linear';
        case 'exponential'
            config.backoffTime = 10; % Base value
            config.backoffStrategy = 'exponential';
        case 'random'
            config.backoffTime = 40; % Max random value
            config.backoffStrategy = 'random';
    end
    
    fprintf('Simulating backoff strategy: %s with %d devices...\n', strategy, numDevices);
    
    % Implement custom backoff logic in the simulation
    [~, ~, collisionProb, numRetransmissions, energyEfficiency, successRate, avgDelay] = ...
        simulateWithBackoffStrategy(config, numDevices);
    
    % Store results
    backoffResults(s).strategy = strategy;
    backoffResults(s).collisionProb = collisionProb;
    backoffResults(s).numRetransmissions = numRetransmissions;
    backoffResults(s).energyEfficiency = energyEfficiency;
    backoffResults(s).successRate = successRate;
    backoffResults(s).avgDelay = avgDelay;
end

% Plot results
figure('Position', [100, 100, 1000, 800]);

subplot(2, 3, 1);
bar([backoffResults.collisionProb]);
set(gca, 'XTickLabel', strategies);
title('Collision Probability');
grid on;

subplot(2, 3, 2);
bar([backoffResults.numRetransmissions]);
set(gca, 'XTickLabel', strategies);
title('Average Retransmissions');
grid on;

subplot(2, 3, 3);
bar([backoffResults.energyEfficiency]);
set(gca, 'XTickLabel', strategies);
title('Energy Efficiency (Tx per Success)');
grid on;

subplot(2, 3, 4);
bar([backoffResults.successRate]);
set(gca, 'XTickLabel', strategies);
title('Success Rate');
grid on;

subplot(2, 3, 5);
bar([backoffResults.avgDelay]);
set(gca, 'XTickLabel', strategies);
title('Average Access Delay (ms)');
grid on;

saveas(gcf, 'Backoff_Strategy_Comparison.png');