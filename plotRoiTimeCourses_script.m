% plot roi time courses

% each plot will have time courses for a single ROI, with stims x groups
% lines. Eg, if stims='food' and groups={'controls','patients'}, separate
% time courses will be plotted for controls and patients to food trials.

clear all
close all


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% DEFINE VARIABLES (EDIT AS NEEDED) %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% define relevant directories
mainDir = '/Users/kelly/cueexp_claudia';
scriptsDir = [mainDir '/scripts']; % this should be the directory where this script is located
dataDir = [mainDir '/data'];
figDir = [mainDir '/figures']; % where to save out figures

path(path,genpath(scriptsDir)); % add scripts dir to matlab search path

task='cue';

% cell array of subject ids to include in plots
subjects={'291','328','375'};

tcDir = ['timecourses_' task '_afni' ];

tcPath = fullfile(dataDir,tcDir);


% which rois to process?
roiNames = {'nacc_desai'};


nTRs = 10; % # of TRs to plot
TR = 2; % 2 sec TR
t = 0:TR:TR*(nTRs-1); % time points (in seconds) to plot
xt = t; %  xticks on the plotted x axis

useSpline = 0; % if 1, time series will be upsampled by TR*10

omitSubs = {''}; % any subjects to omit?

plotStats = 0; % 1 to note statistical signficance on figures; otherwise set to 0

saveFig = 1; % 1 to save out figures, otherwise set to 0

plotColorSet = 'color'; % 'grayscale' or 'color'

plotErr = 'shaded'; % 'bar' or 'shaded'

stims = {'alcohol','drugs','food','neutral'}; % which stims to plot?
stimStr = 'stim';

% stims = {'strongdontwant','somewhatdontwant','somewhatwant','strongwant'}; % which stims to plot?
% stimStr = 'want';

% rgb values for each plotted line corresponding to stims
cols = cellfun(@(x) getCueExpColors(x),stims,'uniformoutput',0);

% line specs for each plotted line 
lspec = {'-','-','-','-'};



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%r
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% do it

% get ROI time courses
r=1;
for r = 1:numel(roiNames)
    
    roiName = roiNames{r};
    
    inDir = fullfile(dataDir,tcDir,roiName); % time courses dir for this ROI
    
    tc=cell(size(stims)); % time course cell array
    
    for c = 1:numel(stims)     
        stimFile = fullfile(inDir,[stims{c} '.csv']);
        tc{c}=loadRoiTimeCourses(stimFile,subjects,1:nTRs);
    end % stims
    
   % get the sample size (do it this way bc loadRoiTimeCourses() will
   % return NaN values for desired subjects that don't have timecourse
   % data, so this is returning the # of subjects that actually have data
    n = sum(~isnan(tc{1}(:,1))); 
        
    % make sure all the time courses are loaded
    if any(cellfun(@isempty, tc))
        tc
        error('\hold up - time courses for at least one stim/group weren''t loaded.')
    end
    
    % if there's more than 1 subject, get the average and standard error across
    % subjects
    if numel(subjects)>1
        mean_tc = cellfun(@nanmean, tc,'uniformoutput',0);
        se_tc = cellfun(@(x) nanstd(x)./sqrt(n), tc,'uniformoutput',0);
        
    % otherwise, just plot the single subject's data without standard error
    else
        mean_tc=tc;
        se_tc = repmat({zeros(1,nTRs)},size(tc));
    end
    
%  upsample time courses
if useSpline
    t_orig = t;
    t = t(1):diff(t(1:2))/10:t(end); % upsampled x10 time course
    mean_tc = cellfun(@(x) spline(t_orig,x,t), mean_tc, 'uniformoutput',0);
    se_tc =  cellfun(@(x) spline(t_orig,x,t), se_tc, 'uniformoutput',0);
end


%% set up all plotting params

% fig title
figtitle = [strrep(roiName,'_',' ') ' ' stimStr ' response'];

% x and y labels
%         xlab = 'time (s) relative to trial onset';
xlab = 'time (s)';
ylab = '%\Delta BOLD';


% labels for each line plot (goes in the legend)
lineLabels = stims;


% get stats, if plotting
p=[];
if plotStats && size(tc{1},1)<2 % only do stats if sample is big enough
    p = getPValsRepMeas(tc); % repeated measures ANOVA
end


% filepath, if saving
savePath = [];
if saveFig
    outDir = fullfile(figDir,tcDir,roiName);
    if ~exist(outDir,'dir')
        mkdir(outDir)
    end
    outName = [roiName '_' stimStr];
    savePath = fullfile(outDir,outName);
end


%% finally, plot the thing!

fprintf(['\n\n plotting figure: ' figtitle '...\n\n']);

switch plotErr
    case 'bar'
        [fig,leg]=plotNiceLinesEBar(t,mean_tc,se_tc,cols,p,lineLabels,xlab,ylab,figtitle,savePath,1,lspec);
    case 'shaded'
        [fig,leg]=plotNiceLines(t,mean_tc,se_tc,cols,p,lineLabels,xlab,ylab,figtitle,savePath,1,lspec);
end


fprintf('done.\n\n');


end %roiNames


