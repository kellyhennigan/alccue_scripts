
%%%%%%%% do QA on motion on data from cue fmri experiment

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


% cell array of subject ids to process - should be the whole group
subjects={'291','301','308','316','319','328','375','B002'};


mp_file = [dataDir '/%s/func_proc/cue_vr.1D']; % motion param file 
roits_file = [dataDir '/%s/func_proc/cue_nacc_ts.1D']; % roi time series file to plot 

motionThresh = 1; % euclidean distance limit to plot; 

outDir = fullfile(figDir,'QA');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test various criteria for excluding a subject based on head motion:

en_thresh = [1 2 3]; % motion threshold to determine bad volumes (try these different values)
 
percent_bad_thresh = [1 .5 .5]; % percent of volumes that can have bad motion

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% do it

if ~exist(outDir,'dir') 
    mkdir(outDir);
end

% define vectors and matrices to be filled in
nBad = nan(numel(subjects),numel(en_thresh)); % # of vols w/movement > en_thresh
omit_idx = nan(numel(subjects),numel(en_thresh)); % 1 to suggest omitting, otherwise 0


for s = 1:numel(subjects)
    
    subject = subjects{s};
    fprintf(['\nworking on subject ' subject '...\n\n']);
    
    mp = []; % this subject's motion params
    
    % get task motion params
    try
        mp = dlmread(sprintf(mp_file,subject));
        mp = mp(:,[6 7 5 2:4]); % rearrange to be in order dx,dy,dz,roll,pitch,yaw
    catch
        warning(['couldnt get motion params for subject ' subject ', so skipping...'])
    end

    
    if ~isempty(mp)
        
        % calculate euclidean norm (head motion distance roughly in mm units)
        en = [0;sqrt(sum(diff(mp).^2,2))];
        
        
        for i=1:numel(en_thresh)
            
            % calculate # of bad vols based on en_thresh
            nBad(s,i) = numel(find(en>en_thresh(i)));
            
            fprintf('\n%s has %d vols with motion > %.1f, which is %.2f percent of task vols\n\n',...
                subject,nBad(s,i),en_thresh(i),100.*nBad(s,i)/numel(en));
            
            
            % determine whether to omit subject or not, based on percent_bad_thresh
            if 100.*nBad(s,i)/numel(en)>percent_bad_thresh(i)
                omit_idx(s,i) = 1;
            else
                omit_idx(s,i) = 0;
            end
            
        end
        
    end % isempty(mp)
    
end % subjects



%% plot histogram of bad volume count

    
for i=1:numel(en_thresh)

    fig=setupFig;     
    hist(nBad(:,i),numel(subjects));
    
    xlabel(['# of TRs with motion > ' num2str(en_thresh(i))])
    ylabel('# of subjects')
    title(['head movement during cue task'])
    
    hold on
    yl=ylim;
    h2=plot([floor(numel(en).*percent_bad_thresh(i)./100) floor(numel(en).*percent_bad_thresh(i)./100)],[yl(1) yl(2)],'k--');
    
    legend(h2,{['percent bad thresh=' num2str(percent_bad_thresh(i))]})
    legend('boxoff')
   
    figPath = fullfile(outDir,['subj_hist_en_thresh' num2str(en_thresh(i)) '.png']);
    print(gcf,'-dpng','-r300',figPath)

   
end


%% print out subjects to be excluded based on different motion criteria:

for i=1:numel(en_thresh)
    fprintf('\nif criteria for exclusion is motion > %d in %.1f percent of total volumes,\nthen the following subjects should be excluded:\n\n',en_thresh(i),percent_bad_thresh(i));
    disp(subjects(omit_idx(:,1)==1)');
end

