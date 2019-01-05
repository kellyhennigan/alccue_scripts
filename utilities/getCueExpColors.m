function colors = getCueExpColors(labels)
% -------------------------------------------------------------------------
% usage: returns rgb color values for plotting cue experiment results. The
% idea of having this is to keep plot colors for each stimulus consistent.
% Hard code desired colors here, then they will be used by various plotting
% scripts.


% INPUT:
%   labels - cell array of stims or groups to return colors for; options
%   are: 
    %     alcohol
    %     drugs
    %     food 
    %     neutral
    %     strongdontwant
    %     somewhatdontwant
    %     strongwant
    %     somewhatwant
%   format (optional) - 'cell' will return colors in a cell array format
%   set - either 'grayscale' or 'color' to return grayscale or colors
%
% OUTPUT:
%   colors - rgb values in rows for colors
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ~iscell(labels)
    labels = {labels};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% define colors for all possible stims/groups here %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        % define colors for each stim/group
        
        % stims
        alcohol_color = [253 158 33]./255;          % orange
        drug_color = [219 79 106]./255;             % pink
        food_color = [2 117 180]./255;              % blue
        neutral_color = [100 100 100]./255;         % light gray
      
        % want ratings
        strongwant_color =  [219 79 106]./255;      % pink
        somewhatwant_color =  [253 158 33]./255;    % orange
        somewhatdontwant_color = [42 160 120]./255; % green
        strongdontwant_color = [2 117 180]./255;    % blue
        
        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% determine which colors to return based on input labels %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

colors = [];
for i=1:numel(labels)
      
    switch lower(labels{i})
        
        case 'alcohol'
            colors(i,:) = alcohol_color;
            
        case {'drugs','drug'}
            colors(i,:) = drug_color;
            
        case 'food'
            colors(i,:) = food_color;
            
        case 'neutral'
            colors(i,:) = neutral_color;
     
        case 'strongwant'
            colors(i,:) = strongwant_color;
            
        case 'somewhatwant'
            colors(i,:) = somewhatwant_color;
            
        case 'somewhatdontwant'
            colors(i,:) = somewhatdontwant_color;
            
        case 'strongdontwant'
            colors(i,:) = strongdontwant_color;
            
        otherwise
            colors(i,:) = [30 30 30]./255; % return grayish black
            
    end
    
end


