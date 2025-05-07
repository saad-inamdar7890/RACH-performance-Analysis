config = struct();
config.numPreambles = 64;           
config.simulationTime = 1000;       
config.numDevices = 1000;          
 
trafficPatterns = {'periodic', 'bursty', 'random'};
deviceCounts = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];


% Run simulations
for t = 1:length(trafficPatterns)
    trafficPattern = trafficPatterns{t};
    
    for d = 1:length(deviceCounts)
      
        config.numDevices = deviceCounts(d);
        
        fprintf('Simulating %s traffic with %d devices...\n', trafficPattern, config.numDevices);
        
        metrics = implementRACH(config, trafficPattern);
        
      
        results{t,d} = metrics;
    end
end


