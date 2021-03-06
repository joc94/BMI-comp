%% Initialisation
clearvars;
close all;
fprintf('Loading data...\n')
load('monkeydata_training.mat');
data_train = trial(1:90,:);
data_test = trial(91:end,:);
max_D = 8;
hidden = 4;
delays = 2;
wdw = 100;
sigma = 20;
neurons = 98;
fprintf('Initialising model...\n')
model = layrecnet(1:delays,hidden,'traingdx');
model.trainParam.epochs = 20;
model.trainParam.showWindow = 1;
showFig = 1;
%% Training
j = 1;
AEX = zeros(1,size(data_train,1));
AEY = zeros(1,size(data_train,1));
for N = 1:size(data_train,1)
    EX = zeros(1,max_D);
    EY = zeros(1,max_D);
    for D = 1:max_D
        fprintf(strcat('Trial:',num2str(N),',Dir:',num2str(D),'\n'))
        X = con2seq(g_filter(data_train(N,D).spikes(1:neurons,:),wdw,sigma));
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
        EX(D) = mean((DT(1,delays+1:end)-DY(1,:)).^2);
        EY(D) = mean((DT(2,delays+1:end)-DY(2,:)).^2);
    end
    if showFig == 1
        figure(2)
        subplot(1,2,1)
        AEX(N) = mean(EX);
        plot(AEX(1:N),'rx-')
        subplot(1,2,2)
        AEY(N) = mean(EY);
        plot(AEY(1:N),'rx-')
    end
end
%% Testing
close all
TEX = zeros(1,size(data_test,1));
TEY = zeros(1,size(data_test,2));
fprintf('Testing model...\n')
for N = 1:size(data_test,1)
    D = randi(8);
    X = con2seq(g_filter(data_test(N,D).spikes(1:neurons,:),wdw,sigma));
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