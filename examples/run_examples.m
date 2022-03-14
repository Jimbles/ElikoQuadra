addpath('../src/');

% example uses of the Eliko class functions

%% Write Protocol File

N_elec=16;

% adjacent protocol
Protocol_Adj=[(1:2:15)' (2:2:16)'];
Protocol_Adj=[Protocol_Adj Protocol_Adj];

quadra.writetable('testout/example.csv',Protocol_Adj)


%% Read data 

% Data collected on the Eliko 16 channel EIT resistor phantom

% baseline
Data=quadra.readdata('ex_baseline.txt');

% take only 1 frequency
cfreq=8;
freqhz=Data.freq(cfreq);

% take only the real data - we are expected only resitive changes here
% DataB.Vreal is Chn x freq x repeat
cData=squeeze(Data.Vreal(:,cfreq,:));

figure
title(sprintf('Data at %d Hz',freqhz))
hold on
xlim([0 size(cData,1)])
plot(cData(:,1))
xlabel('Measurement channel')
ylabel('Re (Z)')
