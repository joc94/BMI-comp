%% Initialisation
clearvars;
close all;
fprintf('Loading data...\n')
load('monkeydata_training.mat');
% for unitNum = 1:98
%     for dirNum = 1:8
%         for trialNum = 1:100
%             spikeTrain = trial(trialNum,dirNum).spikes(unitNum,:);
%             for timeIdx = length(spikeTrain)
%                 collate(trialNum,timeIdx) = spikeTrain(timeIdx);
%             end
%         end
%         mean(collate,1)
%         avgSpikecounts{unitNum,dirNum} = mean(collate,1);
%         clearvars collate
%     end
% end
% for n=1:size(trial,1)
%     for a = 1:size(trial,2)
%     positions = trial(n,a).handPos;
%     [theta, rho] = cart2pol(positions(1,:),positions(2,:));
%     trial(n,a).handPosPolar = [theta; rho];
%     end
% end
output = fr_processing(trial,20);
max_D = 8;
hidden = 4;
delays = 2;
fprintf('Initialising model...\n')
model = layrecnet(1:delays,hidden,'traingdx');
model.trainParam.epochs = 20;
%% Training
    for D = 1:8
        fprintf(strcat('Dir:',num2str(D),'\n'))
        X = con2seq(output.l_PSTH_non_shifted);
        T = con2seq(data_train(N,D).handPos(1:2,:));
        [Xs,Xi,Ai,Ts] = preparets(model,X,T);
        fprintf('Training model...\n')
        model = train(model,Xs,Ts,Xi,Ai);
        Y = model(Xs,Xi,Ai);
        perf = perform(model,Y,Ts);
        fprintf(strcat(num2str(perf),'\n'))
        CY = seq2con(Y);
        CT = seq2con(T);
        DY = CY{:};
        DT = CT{:};
        if showFig == 1
            figure(1)
            [theta, rho] = cart2pol(DY(1,:),DY(2,:));
            polarplot(theta,rho,'r')
            hold on;
            [theta, rho] = cart2pol(DT(1,:),DT(2,:));
            polarplot(theta,rho,'b')
            hold off;
        end
    end
%% Testing
close all
TEX = zeros(1,size(data_test,1));
TEY = zeros(1,size(data_test,2));
fprintf('Testing model...\n')
for N = 1:size(data_test,1)
    D = randi(8);
    X = con2seq(data_test(N,D).spikes(1:neurons,:));
    T = con2seq(data_test(N,D).handPos(1:2,:));
    [Xs,Xi,Ai,Ts] = preparets(model,X,T);
    Y = model(Xs,Xi,Ai);
    CY = seq2con(Y);
    CT = seq2con(T);
    DY = CY{:};
    DT = CT{:};
    figure(1)
    [theta, rho] = cart2pol(DY(1,:),DY(2,:));
    polarplot(theta,rho,'r')
    hold on;
    [theta, rho] = cart2pol(DT(1,:),DT(2,:));
    polarplot(theta,rho,'b')
    hold off;  
    TEX(N) = mean((DT(1,delays+1:end)-DY(1,:)).^2);  
    TEY(N) = mean((DT(2,delays+1:end)-DY(2,:)).^2);
    pause(0.01)
end
figure(2)
subplot(1,2,1)
plot(TEX,'rx')
subplot(1,2,2)
plot(TEY,'rx')