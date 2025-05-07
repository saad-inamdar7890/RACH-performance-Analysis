% filepath: d:\Codes\Projects\RACH-performance-Analysis\main_RACH_simulation.m
% RACH Performance Analysis
% Main simulation script

clc;
clear all;
close all;

% Configuration parameters
config = struct();
config.numPreambles = 54;            % Number of preambles (54-64)
config.maxRetransmissions = 10;      % Maximum number of retransmission attempts
config.backoffTime = 20;             % Backoff window size (in ms)
config.simulationTime = 1000;        % Total simulation time (in ms)
config.prachPeriodicity = 5;         % PRACH periodicity (in ms)

% Traffic patterns
trafficPatterns = {'periodic', 'bursty', 'random'};

% Device counts to simulate
deviceCounts = [50, 100, 200,300, 400, 500, 600, 700, 800, 900, 1000];

% Store results
results = struct();

% Run simulations for different scenarios
for t = 1:length(trafficPatterns)
    trafficPattern = trafficPatterns{t};
    
    for d = 1:length(deviceCounts)
        numDevices = deviceCounts(d);
        
        fprintf('Simulating %s traffic with %d devices...\n', trafficPattern, numDevices);
        
        % Run the RACH simulation
        [accessSuccess, accessDelay, collisionProb, numRetransmissions, energyEfficiency, resourceUtilization] = ...
            simulateRACH(config, numDevices, trafficPattern);
        
        % Store results
        results(t,d).trafficPattern = trafficPattern;
        results(t,d).numDevices = numDevices;
        results(t,d).accessSuccess = accessSuccess;
        results(t,d).accessDelay = accessDelay;
        results(t,d).collisionProb = collisionProb;
        results(t,d).numRetransmissions = numRetransmissions;
        results(t,d).energyEfficiency = energyEfficiency;
        results(t,d).resourceUtilization = resourceUtilization;
    end
end

% Analyze and plot results
plotResults(results, deviceCounts, trafficPatterns);