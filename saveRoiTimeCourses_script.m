% script to save out roi time courses. This script does the following:

% load event onset files: each file should be a text file with a column
% vector of 0s and 1s to signify an event onset. Length of the vector should be
% equal to the # of acquired TRs.

% load roi binary mask files: volumes w/value of 1 signifying which voxels
% are in the roi mask; otherwise 0 values

% load pre-processed functional data 

% load vector that says which volumes to censor based on bad motion

% get stim-locked time series based on event onset files

% plot each trial separately (this should be noisy but potentially useful
% for diagnosing movement, something weird, etc.)

% for each subject, for each roi, for each event type, get the average time
% course & save out in text file


clear all
close all


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% DEFINE VARIABLES (EDIT AS NEEDED) %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% define relevant directories
mainDir = '/Users/kelly/cueexp_claudia';
scriptsDir = [mainDir '/scripts_new']; % this should be the directory where this script is located
dataDir = [mainDir '/data'];
figDir = [mainDir '/figures']; % where to save out figures

path(path,genpath(scriptsDir)); % add scripts dir to matlab search path

% cell array of subject IDs to process (e.g., {'301','308','309'} )
subjects={'291','328','375','B002'};


omitOTs=input('omit trials with outlier TRs? (outlier = zscore > 4) 1=yes 0=no ');

plotSingleTrials=input('plot single trials? Note this *GREATLY* increases processing time but can be helpful for QA. 1=yes 0=no ');


% filepath to pre-processed functional data where %s is subject
funcFilePath = fullfile(dataDir, ['%s/func_proc/pp_cue_tlrc_afni.nii.gz']);


% file path to file that says which volumes to censor due to head movement
censorFilePath = fullfile(dataDir, ['%s/func_proc/cue_censor.1D']);


% filepaths to ROI masks
% roiNames = {'nacc','mpfc','ins_desai','VTA','acing'};
roiNames = {'nacc'};
roiPath = fullfile(dataDir,'ROIs','%s_func.nii'); % %s is roiNames


% directory w/regressor time series (NOT convolved)
stimDir =  fullfile(dataDir,'%s/regs');


% stimuli to process
stims =  {'alcohol','drugs','food','neutral',...
    'strongdontwant','somewhatdontwant','somewhatwant','strongwant'};

% corresponding filenames for stims to process
% (each file is a vector with a length equal to the # of TRs with a 1
% indicating the onset of a stimulus of interest, otherwise 0)
stimFiles = cellfun(@(x) [x '_cue_cue.1D'], stims, 'uniformoutput',0);


% name of dir to save to where %s is task
outDir = fullfile(dataDir,['timecourses_cue_afni' ]);
if omitOTs
    outDir = [outDir '_woOutliers'];
end


nTRs = 10; % # of TRs to extract
TR = 2; % 2 sec TR
t = 0:TR:TR*(nTRs-1); % time points (in seconds) to plot



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% do it


TC = cell(numel(roiNames),numel(stims)); % out data cell array


% get roi masks
rois = cellfun(@(x) niftiRead(sprintf(roiPath,x)), roiNames, 'uniformoutput',0);


i=1; j=1; k=1;
for i=1:numel(subjects) % subject loop
    
    subject = subjects{i};
    
    fprintf(['\n\nworking on subject ' subject '...\n\n']);
    
    % load pre-processed data
    func = niftiRead(sprintf(funcFilePath,subject));
    
    % load subject's motion_censor.1D file that says which volumes to
    % censor due to motion
    censorVols = find(dlmread(sprintf(censorFilePath,subject))==0);
    
    
    % get stim onset times
    onsetTRs = cellfun(@(x) find(dlmread(fullfile(sprintf(stimDir,subject),x))), stimFiles, 'uniformoutput',0);
    
    for j=1:numel(rois)
        
        % this roi time series
        roi_ts = roi_mean_ts(func.data,rois{j}.data);
        
        
        % nan pad the end in case there aren't enough TRs for the last
        % trial
        roi_ts = [roi_ts;nan(nTRs,1)];
        
        
        % if desired, identify outlier TRs
        if omitOTs
            % temporarily assign censored vols due to head motion to nan
            temp = roi_ts; temp(censorVols)=nan;
            Z=(temp-nanmean(temp))./nanstd(temp); % Z-score
            censorVols=[censorVols;find(abs(Z)>4)];
        end
        
        
        for k=1:numel(stims)
            
            % this stim time series
            this_stim_tc = [];
            
            % set time courses to nan if there are no stim events
            if isempty(onsetTRs{k})
                TC{j,k}(i,:) = nan(1,nTRs);
                
                % otherwise, process stim event time courses
            else
                
                this_stim_TRs = repmat(onsetTRs{k},1,nTRs)+repmat(0:nTRs-1,numel(onsetTRs{k}),1);
                
                % single trial time courses for this stim
                this_stim_tc=roi_ts(this_stim_TRs);
                
                 %%%%% TO ONLY OMIT CENSORED TRS:
                censor_idx=find(ismember(this_stim_TRs,censorVols));
                [~,cc]=ind2sub(size(this_stim_TRs),censor_idx);
                censored_trs = this_stim_tc(censor_idx);
                this_stim_tc(censor_idx)=nan;
                
                
                %%%%%% TO OMIT ENTIRE TRIALS THAT CONTAIN CENSORED TRS:
                %                 [censor_idx,~]=find(ismember(this_stim_TRs,censorVols));
                %                 censor_idx = unique(censor_idx);
                %                 censored_trs = this_stim_tc(censor_idx,:);
                %                 this_stim_tc(censor_idx,:) = [];
              
                % keep count of the # of censored & outlier trials
                nBadTRs{j}(i,k) = numel(censored_trs);
               
                % fill in timecourses cell array
                TC{j,k}(i,:) = nanmean(this_stim_tc,1);
                
                % plot single trials
                if plotSingleTrials
                    h = figure;
                    set(gcf, 'Visible', 'off');
                    hold on
                    set(gca,'fontName','Arial','fontSize',12)
                    % plot good and bad (censored) single trials
                    plot(t,this_stim_tc','linewidth',1.5,'color',[.15 .55 .82])
                    if ~isempty(censored_trs)
                        
                        % IF OMITTING JUST CENSORED TRS:
                        plot(t(cc),censored_trs,'*','color',[1 0 0],'markersize',20,'Linewidth',1.5)
                        
                        % IF OMITTING ENTIRE TRIALS THAT HAVE A CENSORED TR:
                        % plot(t,censored_trs','linewidth',1.5,'color',[1 0 0])
             
                    end
                    xlim([t(1) t(end)])
                    set(gca,'XTick',t)
                    xlabel('time (in seconds) relative to cue onset')
                    ylabel('%\Delta BOLD')
                    set(gca,'box','off');
                    set(gcf,'Color','w','InvertHardCopy','off','PaperPositionMode','auto');
                    
                    title(gca,[subject ' ' stims{k}])
                    
                    % save out plot
                    thisOutDir = fullfile(outDir,roiNames{j},'single_trial_plots');
                    if ~exist(thisOutDir,'dir')
                        mkdir(thisOutDir);
                    end
                    outName = [subject '_' stims{k}];
                    print(gcf,'-dpng',fullfile(thisOutDir,outName));
                end
                
                
            end % isempty(onsetTRs)
            
        end % stims
        
    end % rois
    
end % subject loop


%%  save out time courses


% WITH SUBJECT ID:
for j=1:numel(rois)
    
    % roi specific directory
    thisOutDir = fullfile(outDir,roiNames{j});
    if ~exist(thisOutDir,'dir')
        mkdir(thisOutDir);
    end
    
    for k=1:numel(stims)
        T = table([subjects'],[TC{j,k}]);
        writetable(T,fullfile(thisOutDir,[stims{k} '.csv']),'WriteVariableNames',0);
    end
end







