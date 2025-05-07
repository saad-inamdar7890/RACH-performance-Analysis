% filepath: d:\Codes\Projects\RACH-performance-Analysis\fullRACHStateMachine.m
function [deviceStates, metrics] = fullRACHStateMachine(config, numDevices, trafficPattern)
% FULLRACHSTATEMACHINE Implements the complete 4-step RACH procedure
%   Simulates the full RACH procedure with all 4 steps

% Define states for the state machine
INACTIVE = 0;           % Device not yet attempting access
MSG1_READY = 1;         % Ready to send Msg1 (Preamble)
MSG2_WAITING = 2;       % Waiting for Msg2 (RAR)
MSG3_READY = 3;         % Ready to send Msg3 (RRC Connection Request)
MSG4_WAITING = 4;       % Waiting for Msg4 (Contention Resolution)
BACKOFF = 5;            % In backoff state after collision
SUCCESS = 6;            % Successfully completed RACH
FAILURE = 7;            % Failed after max retransmissions

% Initialize device states and timers
deviceState = zeros(1, numDevices);
arrivalTime = generateArrivalTimes(numDevices, config.simulationTime, trafficPattern);
retransmissionCount = zeros(1, numDevices);
backoffTimer = zeros(1, numDevices);
msg2WaitTimer = zeros(1, numDevices);
msg4WaitTimer = zeros(1, numDevices);

% Performance tracking
accessStartTime = zeros(1, numDevices);
accessCompletionTime = inf(1, numDevices);
preambleAttempts = zeros(1, numDevices);
totalTransmissions = zeros(1, numDevices);

% RACH opportunity times
rachOpportunities = 0:config.prachPeriodicity:config.simulationTime;

% Run simulation
for t = 0:config.simulationTime
    % Check if this is a RACH opportunity
    isRachOpportunity = any(rachOpportunities == t);
    
    % Process each device
    for d = 1:numDevices
        % Handle state transitions
        switch deviceState(d)
            case INACTIVE
                % Check if it's time for the device to start RACH
                if t >= arrivalTime(d)
                    deviceState(d) = MSG1_READY;
                    accessStartTime(d) = t;
                end
                
            case MSG1_READY
                % Can only send MSG1 at RACH opportunities
                if isRachOpportunity
                    % Select random preamble and transmit
                    preambleAttempts(d) = preambleAttempts(d) + 1;
                    totalTransmissions(d) = totalTransmissions(d) + 1;
                    
                    % Wait for MSG2 (RAR) response - typically 2-10ms
                    msg2WaitTimer(d) = 5; % Wait 5ms for RAR
                    deviceState(d) = MSG2_WAITING;
                end
                
            case MSG2_WAITING
                % Decrement wait timer
                msg2WaitTimer(d) = msg2WaitTimer(d) - 1;
                
                % Check if timer expired
                if msg2WaitTimer(d) <= 0
                    % Simulate whether RAR was received successfully
                    % This depends on whether there was a collision in MSG1
                    
                    % For simplicity, use a probability model for collisions
                    % The more devices active, the higher chance of collision
                    activeDevices = sum(deviceState == MSG1_READY | deviceState == MSG2_WAITING);
                    collisionProb = min(0.9, activeDevices / (config.numPreambles * 2));
                    
                    if rand() < collisionProb
                        % Collision occurred, go to backoff
                        retransmissionCount(d) = retransmissionCount(d) + 1;
                        
                        if retransmissionCount(d) >= config.maxRetransmissions
                            deviceState(d) = FAILURE;
                        else
                            backoffTimer(d) = randi(config.backoffTime);
                            deviceState(d) = BACKOFF;
                        end
                    else
                        % RAR received, proceed to MSG3
                        deviceState(d) = MSG3_READY;
                    end
                end
                
            case MSG3_READY
                % Send MSG3 (RRC Connection Request)
                totalTransmissions(d) = totalTransmissions(d) + 1;
                
                % Wait for MSG4 (Contention Resolution)
                msg4WaitTimer(d) = 5; % Wait 5ms for MSG4
                deviceState(d) = MSG4_WAITING;
                
            case MSG4_WAITING
                % Decrement wait timer
                msg4WaitTimer(d) = msg4WaitTimer(d) - 1;
                
                % Check if timer expired
                if msg4WaitTimer(d) <= 0
                    % Simulate whether MSG4 was received successfully
                    % For simplicity, use high success probability at this stage
                    if rand() < 0.95
                        % Successfully completed RACH
                        deviceState(d) = SUCCESS;
                        accessCompletionTime(d) = t;
                    else
                        % Failed, go to backoff or failure
                        retransmissionCount(d) = retransmissionCount(d) + 1;
                        
                        if retransmissionCount(d) >= config.maxRetransmissions
                            deviceState(d) = FAILURE;
                        else
                            backoffTimer(d) = randi(config.backoffTime);
                            deviceState(d) = BACKOFF;
                        end
                    end
                end
                
            case BACKOFF
                % Decrement backoff timer
                backoffTimer(d) = backoffTimer(d) - 1;
                
                % Check if backoff completed
                if backoffTimer(d) <= 0
                    deviceState(d) = MSG1_READY;
                end
        end
    end
end

% Compile final states and metrics
deviceStates = deviceState;

% Calculate metrics
successfulDevices = deviceState == SUCCESS;
failedDevices = deviceState == FAILURE;

metrics = struct();
metrics.successRate = sum(successfulDevices) / numDevices;
metrics.failureRate = sum(failedDevices) / numDevices;
metrics.incompleteRate = 1 - metrics.successRate - metrics.failureRate;

metrics.avgDelay = mean(accessCompletionTime(successfulDevices) - accessStartTime(successfulDevices));
if isnan(metrics.avgDelay)
    metrics.avgDelay = inf;
end

metrics.avgRetransmissions = mean(retransmissionCount);
metrics.avgPreambleAttempts = mean(preambleAttempts);
metrics.avgTransmissions = mean(totalTransmissions);
metrics.energyEfficiency = sum(totalTransmissions) / max(1, sum(successfulDevices));

end

% Helper function to generate arrival times based on traffic pattern
function arrivalTimes = generateArrivalTimes(numDevices, simulationTime, trafficPattern)
    switch trafficPattern
        case 'periodic'
            period = simulationTime / numDevices;
            arrivalTimes = (0:numDevices-1) * period;
            
        case 'bursty'
            burstTime1 = simulationTime * 0.2;
            burstTime2 = simulationTime * 0.6;
            burstSize1 = round(numDevices * 0.6);
            burstSize2 = numDevices - burstSize1;
            
            arrivalTimes = zeros(1, numDevices);
            arrivalTimes(1:burstSize1) = burstTime1 + rand(1, burstSize1) * 10;
            arrivalTimes(burstSize1+1:end) = burstTime2 + rand(1, burstSize2) * 10;
            
        case 'random'
            % Poisson arrival process
            arrivalTimes = sort(rand(1, numDevices) * simulationTime);
            
        otherwise
            error('Unknown traffic pattern');
    end
end