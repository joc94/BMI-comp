function model = positionEstimatorTraining(data_train)
% Template for our training function for the model
% Inputs: trainingData (trials)
% Outputs: modelParameters (Parameters of our regression model, can be anything we choose)
% ---
function output = g_filter(spikes, wdw, sigma)
output = zeros(size(spikes));
    for n = 1:size(spikes,1)
        a = 1/(sigma*sqrt(2*pi));
        x = -(wdw-1)/2:(wdw-1)/2;
        g = a*exp(-(x.^2)./(2*sigma^2)); 
        g_spikes = conv(spikes(n,:),g);
        output(n,:) = g_spikes(wdw/2:end-wdw/2);
    end
end
model = struct();
model.x0 = data_train(1,1).handPos(1,1);
model.y0 = data_train(1,1).handPos(2,1);
hidden = 4;
delays = 2;
wdw = 100;
sigma = 20;
fprintf('Initialising net...\n')
net = layrecnet(1:delays,hidden,'trainrp');
net.trainParam.epochs = 1;
net.trainParam.showWindow = 1;
net.performFcn = 'mse';
net.performParam.regularization = 0.03;
net.performParam.normalization = 'percent';
%% Training
fprintf('Training net...\n')
for learnrate = [10^-2 10^-4 10^-6]
    net.trainParam.lr = learnrate;
    for N = 1:size(data_train,1)
        for D = 1:size(data_train,2)
            rawInput = g_filter(data_train(N,D).spikes,wdw,sigma);
            rawInput(:,end+1:1000) = NaN;
            Seqs{D,1} = rawInput;
            rawTarget = diff(data_train(N,D).handPos(1:2,:),1,2);
            rawTarget(:,end+1) = 0;
            rawTarget(:,end+1:1000) = NaN;
            Diff{D,1} = rawTarget;
        end
        X = con2seq(Seqs);
        T = con2seq(Diff);
        [Xs,Xi,Ai,Ts] = preparets(net,X,T);
        net = train(net,Xs,Ts,Xi,Ai);
        Y = net(Xs,Xi,Ai);
    end
end
model.net = net;
end

