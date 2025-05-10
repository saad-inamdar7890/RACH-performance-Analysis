% filepath: d:\Codes\Projects\RACH-performance-Analysis\simulateRACH.m
function [accessSuccess, accessDelay, collisionProb, numRetransmissions, energyEfficiency, resourceUtilization] = ...
    simulateRACH(config, numDevices, trafficPattern)
% SIMULATERACH Simulates the RACH procedure
%   config: Configuration parameters
%   numDevices: Number of devices attempting access
%   trafficPattern: Traffic pattern ('periodic', 'bursty', 'random')
%
% Returns performance metrics:
%   accessSuccess: Access success probability
%   accessDelay: Average access delay
%   collisionProb: Collision probability
%   numRetransmissions: Average number of preamble retransmissions
%   energyEfficiency: Transmissions per successful access
%   resourceUtilization: System resource utilization

% Define states
IDLE = 0;               % Device is idle, not attempting access
MSG1_READY = 1;         % Ready to send preamble (MSG1)
MSG2_WAIT = 2;          % Waiting for Random Access Response (MSG2)
MSG3_READY = 3;         % Ready to send RRC Connection Request (MSG3)
MSG4_WAIT = 4;          % Waiting for Contention Resolution (MSG4)
CONNECTED = 5;          % Successfully connected
BACKOFF = 6;            % In backoff state after collision
FAILED = 7;             % Failed after max retransmissions

% Initialize simulation parameters from config
simTime = config.simulationTime;
numPreambles = config.numPreambles;
maxRetransmissions = config.maxRetransmissions;
backoffWindow = config.backoffTime;
prachPeriodicity = config.prachPeriodicity;

% Initialize device states and counters
deviceStates = zeros(1, numDevices);
arrivalTimes = generateArrivalTimes(numDevices, simTime, trafficPattern);
accessStartTimes = zeros(1, numDevices);
accessCompletionTimes = Inf(1, numDevices);
retransmissionCounts = zeros(1, numDevices);
backoffTimers = zeros(1, numDevices);
waitTimers = zeros(1, numDevices);
selectedPreambles = zeros(1, numDevices);
totalTransmissions = zeros(1, numDevices);

% Create RACH opportunity times based on periodicity
rachOpportunities = 0:prachPeriodicity:simTime;

% Statistics counters
collisionCount = 0;
totalAttempts = 0;

% Simulation main loop
for t = 0:simTime
    % Check if current time is a RACH opportunity
    isRachOpportunity = any(t == rachOpportunities);
    
    % Process each device
    for d = 1:numDevices
        % Check for new device arrivals
        if deviceStates(d) == IDLE && t >= arrivalTimes(d)
            deviceStates(d) = MSG1_READY;
            accessStartTimes(d) = t;
        end
        
        % Process device based on its current state
        switch deviceStates(d)
            case MSG1_READY
                % Step 1: Send Random Access Preamble
                if isRachOpportunity
                    % Select random preamble
                    selectedPreambles(d) = randi(numPreambles);
                    totalAttempts = totalAttempts + 1;
                    totalTransmissions(d) = totalTransmissions(d) + 1;
                    
                    % Move to waiting for RAR (MSG2)
                    deviceStates(d) = MSG2_WAIT;
                    waitTimers(d) = 3; % Wait 3ms for RAR window
                end
                
            case MSG2_WAIT
                % Step 2: Wait for Random Access Response (RAR)
                waitTimers(d) = waitTimers(d) - 1;
                
                if waitTimers(d) <= 0
                    % Check for collision (same preamble selected by multiple devices)
                    otherDevicesWithSamePreamble = find(selectedPreambles == selectedPreambles(d) & ...
                                                       deviceStates == MSG2_WAIT & ...
                                                       (1:numDevices) ~= d);
                    
                    if ~isempty(otherDevicesWithSamePreamble)
                        % Collision detected
                        collisionCount = collisionCount + 1;
                        retransmissionCounts(d) = retransmissionCounts(d) + 1;
                        
                        if retransmissionCounts(d) >= maxRetransmissions
                            deviceStates(d) = FAILED;  % Max retransmissions reached
                        else
                            % Apply backoff
                            backoffTimers(d) = randi(backoffWindow);
                            deviceStates(d) = BACKOFF;
                        end
                    else
                        % RAR received successfully
                        deviceStates(d) = MSG3_READY;
                    end
                end
                
            case MSG3_READY
                % Step 3: Send RRC Connection Request
                totalTransmissions(d) = totalTransmissions(d) + 1;
                deviceStates(d) = MSG4_WAIT;
                waitTimers(d) = 5; % Wait 5ms for contention resolution
                
            case MSG4_WAIT
                % Step 4: Wait for Contention Resolution
                waitTimers(d) = waitTimers(d) - 1;
                
                if waitTimers(d) <= 0
                    % High probability of success at this stage
                    if rand() < 0.95  % 95% success rate for MSG4
                        deviceStates(d) = CONNECTED;
                        accessCompletionTimes(d) = t;
                    else
                        retransmissionCounts(d) = retransmissionCounts(d) + 1;
                        
                        if retransmissionCounts(d) >= maxRetransmissions
                            deviceStates(d) = FAILED;
                        else
                            backoffTimers(d) = randi(backoffWindow);
                            deviceStates(d) = BACKOFF;
                        end
                    end
                end
                
            case BACKOFF
                % Process backoff timer
                backoffTimers(d) = backoffTimers(d) - 1;
                
                if backoffTimers(d) <= 0
                    deviceStates(d) = MSG1_READY;  % Try again from the beginning
                end
        end
    end
end

% Calculate performance metrics
connectedDevices = (deviceStates == CONNECTED);
failedDevices = (deviceStates == FAILED);

accessSuccess = sum(connectedDevices) / numDevices;
accessDelay = mean(accessCompletionTimes(connectedDevices) - accessStartTimes(connectedDevices));
if isnan(accessDelay)
    accessDelay = Inf;
end

collisionProb = collisionCount / max(1, totalAttempts);
numRetransmissions = mean(retransmissionCounts);
energyEfficiency = sum(totalTransmissions) / max(1, sum(connectedDevices));
resourceUtilization = totalAttempts / length(rachOpportunities) / numPreambles;
end

% Helper function to generate arrival times based on traffic pattern
function arrivalTimes = generateArrivalTimes(numDevices, simTime, trafficPattern)
    switch trafficPattern
        case 'periodic'
            % Devices arrive at regular intervals
            period = simTime / numDevices;
            arrivalTimes = (0:numDevices-1) * period;
            
        case 'bursty'
            % Most devices arrive in bursts
            burstTime1 = simTime * 0.2;
            burstTime2 = simTime * 0.6;
            burstSize1 = round(numDevices * 0.6);
            burstSize2 = numDevices - burstSize1;
            
            arrivalTimes = zeros(1, numDevices);
            arrivalTimes(1:burstSize1) = burstTime1 + rand(1, burstSize1) * 10;
            arrivalTimes(burstSize1+1:end) = burstTime2 + rand(1, burstSize2) * 10;
            
        case 'random'
            % Random arrivals (Poisson process)
            arrivalTimes = sort(rand(1, numDevices) * simTime);
            
        otherwise
            error('Unknown traffic pattern');
    end
end