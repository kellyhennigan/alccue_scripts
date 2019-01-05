% behavioral analysis script

% this script loads behavioral data from the nicotine cue reactivity task
% and plots out some variables of interest (reaction time, preference
% ratings, etc.) 

clear all
close all


% define relevant directories
mainDir = '/Users/kelly/cueexp_claudia';
scriptsDir = [mainDir '/scripts']; % this should be the directory where this script is located
dataDir = [mainDir '/data'];
figDir = [mainDir '/figures']; % where to save out figures

path(path,genpath(scriptsDir)); % add scripts dir to matlab search path

task='cue';

% cell array of subject ids to include in plots
subjects={'301';'291';'328';'375';'327';'368';'380'};


conds = {'alcohol','drugs','food','neutral'};


groupStr = 'alcohol patients';  % string label for group

cols = []; % plot colors 

% # of total subjects, and # of controls and patients
N=numel(subjects);


% cue task data
fp1 = fullfile(dataDir, '%s/behavior/cue_matrix.csv');  %s is a placeholder for subj id string


% directory for saving out figures
outDir = fullfile(figDir,'behavior');

if ~exist(outDir,'dir')
    mkdir(outDir)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load behavioral data

if size(subjects,2)>1
    subjects=subjects';
end

%%%%%%%%%%%%%%%%%%%%%%%%% load task stim files %%%%%%%%%%%%%%%%%%%%%%%%%%%%
fp1s = cellfun(@(x) sprintf(fp1,x), subjects, 'uniformoutput',0);
[trial,tr,starttime,clock,trial_onset,trial_type,cue_rt,choice,choice_num,...
    choice_type,choice_rt,iti,drift,image_name]=cellfun(@(x) getCueTaskBehData(x,'short'), fp1s, 'uniformoutput',0);

ci = trial_type{1}; % condition trial index (should be the same for every subject)


%%%%%%%%%%%%%%%%%%%%%%%%%%%% pref ratings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get mean pref ratings by condition w/subjects in rows
pref = cell2mat(choice_num')'; % subjects x items pref ratings
mean_pref = [];
for j=1:numel(conds) % # of conds
    mean_pref(:,j) = nanmean(pref(:,ci==j),2);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RTs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get mean cue/choice RTs & # of no responses by condition w/subjs in rows
cue_rt = cell2mat(cue_rt')'; % subjects x items cue RT
choice_rt=cell2mat(choice_rt')'; % subjects x items choice RT

% re-code no responses from -1 to NaN
cue_rt(cue_rt<0)=nan;  choice_rt(choice_rt<0)=nan;

mean_cueRT = []; n_cueNoresp = []; mean_choiceRT = []; n_choiceNoresp = [];
for j=1:numel(conds)
    
    % cue rts
    mean_cueRT(:,j) = nanmean(cue_rt(:,ci==j),2);
    n_cueNoresp(:,j) = sum(isnan(cue_rt(:,ci==j)),2);
    
    % choice rts
    mean_choiceRT(:,j) = nanmean(choice_rt(:,ci==j),2);
    n_choiceNoresp(:,j) = sum(isnan(choice_rt(:,ci==j)),2);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Q: differences in preference across trial types & groups? 

% pref ratings 
dName = 'wanting'; % name of measure to plot
saveStr = 'want'; % string for fig out name
d = mean_pref; % data w/subjects in rows, conds in columns

plotSig = [1 1];
titleStr = 'want ratings by condition';
plotLeg = 1;
savePath = fullfile(outDir,[saveStr groupStr '.png']);

[fig,leg] = plotNiceBars(d,dName,conds,groupStr,cols,plotSig,titleStr,plotLeg,savePath);




%% Q: differences in cue RT or # of no responses by trial type between groups? 


dName = 'cue RT'; % name of measure to plot
saveStr = 'cueRT'; % string for fig out name
d = mean_cueRT; % data w/subjects in rows, conds in columns

plotSig = [1 1];
titleStr = 'cue RT by condition';
plotLeg = 1;
savePath = fullfile(outDir,[saveStr groupStr '.png']);


[fig,leg] = plotNiceBars(d,dName,conds,groupStr,cols,plotSig,titleStr,plotLeg,savePath);


dName = 'cue no responses'; % name of measure to plot
saveStr = 'cueNoresp'; % string for fig out name
d = n_cueNoresp; % data w/subjects in rows, conds in columns

plotSig = [1 1];
titleStr = 'omitted cue responses';
plotLeg = 1;
savePath = fullfile(outDir,[saveStr groupStr '.png']);

[fig,leg] = plotNiceBars(d,dName,conds,groupStr,cols,plotSig,titleStr,plotLeg,savePath);




%% Q: differences in choice RT or # of no responses by trial type between groups? 


dName = 'choice RT'; % name of measure to plot
saveStr = 'choiceRT'; % string for fig out name
d = mean_choiceRT; % data w/subjects in rows, conds in columns

plotSig = [1 1];
titleStr = 'choice RT by condition';
plotLeg = 1;
savePath = fullfile(outDir,[saveStr groupStr '.png']);


[fig,leg] = plotNiceBars(d,dName,conds,groupStr,cols,plotSig,titleStr,plotLeg,savePath);


dName = 'choice no responses'; % name of measure to plot
saveStr = 'choiceNoresp'; % string for fig out name
d = n_choiceNoresp; % data w/subjects in rows, conds in columns

plotSig = [1 1];
titleStr = 'omitted choice responses';
plotLeg = 1;
savePath = fullfile(outDir,[saveStr groupStr '.png']);

[fig,leg] = plotNiceBars(d,dName,conds,groupStr,cols,plotSig,titleStr,plotLeg,savePath);




%% Q: is there a relationship between RT and preference ratings?


figure
plot(pref,choice_rt,'.','markersize',10,'color',[.2 .2 .2])
xlabel('pref rating')
ylabel('choice RT')

% looks slightly quadratic - shorter RTs for strong prefs & slightly longer
% rts for weaker prefs 





