% Example of loading Eliko Quadra data into Matlab and EIDORS

% make sure EIDORS is on path

% clear; clc; close all
% eidors_cache( 'clear_all' ); 
% run('eidors-v3.10-ng\eidors\startup.m')

%% create protocol

%create protocol - this is better than opposite, here we are using "off
%polar" i.e. one electrode off from directly opposite. We have set AMP to 1
%as the Eliko gives Z not V, as Z=VI  set I=1 to convert Z to V which EIDORS expects 
[stim, meas_sel] = mk_stim_patterns(16, 1, [0,9], [9 0], {'no_meas_current'}, 1);
prt=stim_meas_list(stim);

%write to Eliko Quadra Table - then upload to USER FRAM on the Eliko System
quadra.writetable('testout/off8_prt.csv',prt);

%% make dual meshes

% fine model for the forward problem
% fmdl = mk_common_model('j2c',16); 
fine_mdl=mk_common_model('d2d4c',16);

fine_mdl.fwd_model.stimulation = stim;
fine_mdl.fwd_model.meas_select = meas_sel;

%reconstruct in small mesh
coarse_mdl = mk_common_model('b2d1c',16);

%map between coarse and fine
c2f = mk_coarse_fine_mapping(fine_mdl.fwd_model, coarse_mdl.fwd_model);

imdl=fine_mdl;
imdl.rec_model = coarse_mdl.fwd_model;
imdl.fwd_model.coarse2fine=c2f;


%% Read data for EIT Resistor Phantom

% baseline
DataB=quadra.readdata('ex_baseline.txt');
% with button pressed which changes resisitance in one place
DataP=quadra.readdata('ex_perturbation.txt');

% take only 1 frequency
cfreq=8;
freqhz=DataB.freq(cfreq);

% take only the real data - we are expected only resitive changes here
% DataB.Vreal is Chn x freq x repeat
cDataB=squeeze(DataB.Vreal(:,cfreq,:));
cDataP=squeeze(DataP.Vreal(:,cfreq,:));

figure
subplot(2,1,1)
title(sprintf('Data at %d Hz',freqhz))
hold on
plot(cDataB(:,1))
plot(cDataP(:,1))
plot(cDataP(:,1)-cDataB(:,1))
xlim([0 size(cData,1)])
legend('Baseline','Perturbation','Difference')
xlabel('Measurement channel')
ylabel('Re (Z)')

subplot(2,1,2)
plot( [cDataB - cDataB(:,1) cDataP - cDataB(:,1)]' )
xlabel('Frame')
ylabel('Re (Z)')

% average all time points - we can do this in this case as we know the
% experiment was fixed

good_rep=[1:10]; 

cDataB_ave=mean(cDataB(:,good_rep),2);
cDataP_ave=mean(cDataP(:,good_rep),2);

%% Reconstruct

% % Laplace image prior
imdl.hyperparameter.value = 0.01;
imdl.solve = @inv_solve_diff_GN_one_step; % this is default anyway
imdl.RtR_prior=   @prior_laplace;


% Tikhonov - can be smoother, and handle noise a little differently
% imdl.hyperparameter.value = .01;
% imdl.solve = @inv_solve_diff_GN_one_step; % this is default anyway
% imdl.RtR_prior=   @prior_tikhonov;

% % Total variation using PDIPM - more complicated but gives better sharp
% % edges
% imdl.hyperparameter.value = 0.05;
% imdl.solve=       @inv_solve_TV_pdipm;
% imdl.R_prior=     @prior_TV;
% imdl.parameters.max_iterations= 25;
% imdl.parameters.term_tolerance= 1e-8;


%%
img=inv_solve(imdl,cDataB_ave,cDataP_ave);
figure
show_fem(img,[1,1])
title(sprintf('Rec:%d Hz w/ %s h=%.2f',freqhz,char(imdl.solve),imdl.hyperparameter.value),'Interpreter','none')

