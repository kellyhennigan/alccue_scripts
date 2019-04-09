
%%%%%%%% do QA for cue experiment data


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

% cell array of subject ids to process
subjects={'328','375','B002'};


mp_file = [dataDir '/%s/func_proc/cue_vr.1D']; % motion param file 
roits_file = [dataDir '/%s/func_proc/cue_nacc_ts.1D']; % roi time series file to plot 

motionThresh = 1; % euclidean distance limit to plot; 

outDir = fullfile(figDir,'QA');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%r
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% do it

if ~exist(outDir,'dir')
    mkdir(outDir);
end


for s = 1:numel(subjects)
    
    subject = subjects{s};
    fprintf(['\nworking on subject ' subject '...\n\n']);
    
    mp = dlmread(sprintf(mp_file,subject));
    mp = mp(:,2:7);
    
    % plot motion params
    fig = plotMotionParams(mp);
    
    a=get(fig,'Children');
    title(a(end),subject)
    
    outName = [subject '_mp_' task];
    
    print(gcf,'-dpng','-r600',fullfile(outDir,outName));
    
    
    %% plot roi ts w/enorm of movement
    
    en = [0;sqrt(sum(diff(mp).^2,2))]; % euclidean norm (head motion distance roughly in mm units)
    
    nBadTRs = numel(find(en>motionThresh));
    fprintf(['\nsubject ' subject ' has ' num2str(nBadTRs) ' bad motion vols,\n' ...
        'which is ' num2str(100.*nBadTRs./numel(en)) ' percent of cue task trials\n\n'])
    
    task_nBadTRs(s) = nBadTRs;
    
    [max_en,max_TR]=max(en);
    
    
    figH = figure;
%     set(gcf,'Visible','off')
    set(gcf,'Color','w','InvertHardCopy','off','PaperPositionMode','auto');
    
    subplot(2,1,1)
    hold on
    plot(en,'color',[ 0.1490    0.5451    0.8235],'linewidth',1.5)
    set(gca,'box','off');
    plot(ones(numel(en),1).*motionThresh,'color',[ 0.8627    0.1961    0.1843])
    ylabel('head motion (in ~mm units)','FontSize',12)
    
    title(sprintf('max displacement: ~ %.2f mm, at TR=%d',max_en,max_TR),'FontSize',14)
    
    ts = dlmread(sprintf(roits_file,subject));
    
    subplot(2,1,2)
    plot(ts,'color',[0.1647    0.6314    0.5961],'linewidth',1.5)
    set(gca,'box','off');
    ylabel('BOLD signal','FontSize',12)
    xlabel('TRs','FontSize',12)
    title('nacc roi ts','FontSize',14)
    
    outName = [subject '_mp2_cue'];
    
    print(gcf,'-dpng','-r600',fullfile(outDir,outName));
    close all
    
    
end % subjects


