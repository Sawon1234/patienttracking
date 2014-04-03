function [net,tr,target]=latentO2Delivery(trainData,trainComm,commorbidityNames,show)


%Define the following variables as being indicative of an increase in O2
%demands
trueVar={'CONGESTIVE_HEART_FAILURE',...
    'CARDIAC_ARRHYTHMIAS',...
    'VALVULAR_DISEASE',...
    'BLOOD_LOSS_ANEMIA',...
    'COAGULOPATHY',...
    'DEFICIENCY_ANEMIAS',...
    'PEPTIC_ULCER',...
    'PERIPHERAL_VASCULAR',...
    'PULMONARY_CIRCULATION',...
    'RENAL_FAILURE'};

Ntrue=length(trueVar);
bx=0;   %constant for mapping the target ( if bx=2 -> covers the range 0.1192-1)
%Convert commorbidities from char to double
trainComm=double(trainComm-double('0'));
%Generate Target by logistic function based on commorbidities that are true
%in trueVar
indTrue=[];
N=length(trainComm(:,1));
target=zeros(N,1);
for n=1:Ntrue
    indTrue=find(strcmp(commorbidityNames,trueVar{n})==1);
    target=target+trainComm(:,indTrue);
end
%Normalize target by the maximum number of variables
%and so that the target is logsig (0-1) within x=0-20 (with x= 10 -> y= 0.5)
scale=20;
target=scale*target./Ntrue;
bx=scale/2;

target=1./(1+exp(-target+bx));


%Train NN based on target
testN=10;
net=[];
tr=[];
for i=1:testN
    tmp_net= fitnet([50 5]);
    tmp_net= configure(tmp_net,trainData',target');
    tmp_net.inputs{1}.processFcns={'mapstd','mapminmax'};
    %tmp_net.layers{end}.transferFcn = 'logsig';
    tmp_net.trainParam.showWindow = false;
    tmp_net.trainParam.showCommandLine = false;
    [tmp_net,tmp_tr] = train(tmp_net,trainData',target');
    tmp_tr.best_tperf
    if(i==1 || tmp_tr.best_tperf<tr.best_tperf)
        net=tmp_net;
        tr=tmp_tr;
    end
end

if(show)
    plotperf(tr)
    yhat = net(trainData');
    plotregression(target,yhat);
end

