% behavioral analysis script

% this script loads behavioral data from the nicotine cue reactivity task
% and plots out some variables of interest (reaction time, preference
% ratings, etc.) for a SINGLE SUBJECT 

% see script: analyzeBehavior_script for analyzing behavioral data for
% multiple subjects


clear all
close all


% define relevant directories
mainDir = '/Users/kelly/cueexp_claudia';
scriptsDir = [mainDir '/scripts']; % this should be the directory where this script is located
dataDir = [mainDir '/data'];
figDir = [mainDir '/figures']; % where to save out figures

path(path,genpath(scriptsDir)); % add scripts dir to matlab search path

task='cue';

% subject id 
subject='301';

conds = {'alcohol','drugs','food','neutral'};


cols = []; % plot colors 



% cue task data
fp1 = fullfile(dataDir, '%s/behavior/cue_matrix.csv');  %s is a placeholder for subj id string
fp2 = fullfile(dataDir, '%s/behavior/cue_ratings.csv');


% directory for saving out figures
outDir = fullfile(figDir,'behavior');

if ~exist(outDir,'dir')
    mkdir(outDir)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load behavioral data

%%%%%%%%%%%%%%%%%%%%%%%%% load task stim files %%%%%%%%%%%%%%%%%%%%%%%%%%%%
[trial,tr,starttime,clock,trial_onset,trial_type,cue_rt,choice,choice_num,...
    choice_type,choice_rt,iti,drift,image_name]=getCueTaskBehData(sprintf(fp1,subject));

ci = trial_type; % condition trial index (should be the same for every subject)


%%%%%%%%%%%%%%%%%%%%%%%% ratings/RT by condition %%%%%%%%%%%%%%%%%%%%%%%%%%
% reorganize pref ratings by condition
pref = []; cueRT = []; choiceRT = [];
for j=1:numel(conds) % # of conds
    pref(:,j) = choice_num(ci==j);
    cueRT(:,j) = cue_rt(ci==j);
    choiceRT(:,j) = choice_rt(ci==j);
end


%%%%%%%%%%%%%%%%%%%%%%% load PA/NA cue ratings %%%%%%%%%%%%%%%%%%%%%%%%%%%%
[cue_type,cue_pa,cue_na] = getCueVARatings(sprintf(fp2,subject));
 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Q: differences in preference across trial types? 

% pref ratings 
dName = 'wanting'; % name of measure to plot
saveStr = 'want'; % string for fig out name
d = pref; % data w/subjects in rows, conds in columns

plotSig = 0;
titleStr = ['subject ' subject ' want ratings'];
plotLeg = 0;
savePath = fullfile(outDir,[saveStr '.png']);

% [fig,leg] = plotNiceBars(d,dName,condNames,groupNames,cols,plotSig,titleStr,plotLeg,savePath)
[fig,leg] = plotNiceBars(d,dName,conds,'',[.25 .25 .25],plotSig,titleStr,plotLeg,savePath);


%% Q: differences in RT across trial types? 

% cue RT
dName = 'cue RT'; % name of measure to plot
saveStr = 'cueRT'; % string for fig out name
d = cueRT; % data w/subjects in rows, conds in columns

plotSig = 0;
titleStr = ['subject ' subject ' ' dName];
plotLeg = 0;
savePath = fullfile(outDir,[saveStr '.png']);

% [fig,leg] = plotNiceBars(d,dName,condNames,groupNames,cols,plotSig,titleStr,plotLeg,savePath)
[fig,leg] = plotNiceBars(d,dName,conds,'',[.25 .25 .25],plotSig,titleStr,plotLeg,savePath);


% choice RT
dName = 'choice RT'; % name of measure to plot
saveStr = 'choiceRT'; % string for fig out name
d = choiceRT; % data w/subjects in rows, conds in columns

plotSig = 0;
titleStr = ['subject ' subject ' ' dName];

plotLeg = 0;
savePath = fullfile(outDir,[saveStr '.png']);

% [fig,leg] = plotNiceBars(d,dName,condNames,groupNames,cols,plotSig,titleStr,plotLeg,savePath)
[fig,leg] = plotNiceBars(d,dName,conds,'',[.25 .25 .25],plotSig,titleStr,plotLeg,savePath);

  

