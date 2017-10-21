classdef experiment < handle
    
    properties
        name = [];
        location = [];
        boutons = [];
        peaks_dFF = [];
        peaks_dGR = [];
    end
    
    properties (SetAccess = private, Hidden = true)
        analysisParams = [];
    end
    
    properties (Transient)
        boutonListeners = [];
    end
    
    events
        Reset
        SaveFigs
        UpdateAnalysis
    end
    
    methods
        
        %starting off
        function obj = experiment(fullPath)
            % make an experiment from folder containing bouton folders
            tic;
            if nargin < 1   %you're in the folder
                fullPath = pwd;
            end
            
            obj.importNameAndLoc(fullPath);
            fprintf('\n')
            disp([obj.name ' Importing...']);
            obj.initializeDefaultAnalysis;
            obj.importBoutons;
            
            dgr=1;
            for i=1:obj.analysisParams.numBoutons;
                dgr = dgr*obj.boutons{i}.analysisParams.dgr;
            end
            obj.analysisParams.dgr = dgr;  % this should be OFF unless ALL 
                                 % linescans have dGR (individual linescans
                                 % have dgr capabilities, but you should 
                                 % write custom scripts if you want to do
                                 % dGR analysis with partial datasets)
                                 
            obj.analysisParams.timeAxis = obj.boutons{1}.relSetTimes;
            
            fprintf('\n')
            fprintf('\n')
            disp([obj.name ' Imported']);
            
            elapsedTime = toc;
            
            function [hours, mins, secs] = sec2hms(t)
                hours = floor(t / 3600);
                t = t - hours * 3600;
                mins = floor(t / 60);
                secs = t - mins * 60;
            end

            [hours, mins, secs] = sec2hms(elapsedTime);
            
            if elapsedTime > 60*60 %greater than an hour
                display(['  --  Import Runtime = ',num2str(hours),...
                    ' Hours, ',num2str(mins),' Min., ',num2str(round(secs,2)),...
                    ' Sec.']);
            elseif elapsedTime > 60 %greater than a minute
                display(['  --  Import Runtime = ',num2str(mins),' Min., ',...
                    num2str(round(secs,2)),' Sec.']);
            else
                display(['  --  Import Runtime = ',num2str(round(secs,2)),' Sec.']);
            end
            
        end
               
        %ANALYSIS SECTION (experiment-specific methods)
        function pullPeaks(this)
            
            if ~(isfield(this.boutons{1}.peak_dFF,'raw_scan_peak'))
                warning('Have to run "analyze" first!');
                return
            end
            
            n_df = zeros(this.analysisParams.numBoutons,...
                this.boutons{1}.analysisParams.numScanSets);
            r_df = zeros(size(n_df));
            n_dgr = zeros(size(n_df));
            r_dgr = zeros(size(n_df));

            dgr = this.analysisParams.dgr;  % means ALL linescans have Red for dgr analysis
            
            for i=1:length(this.boutons);
                r_df(i,:) = this.boutons{i}.peak_dFF.norm_set_peak;
                n_df(i,:) = r_df(i,:)./r_df(i,1);
                if dgr
                    r_dgr(i,:) = this.boutons{i}.peak_dGR.norm_set_peak;
                    n_dgr(i,:) = r_dgr(i,:)./r_dgr(i,1);
                end
            end
            
            this.peaks_dFF.raw = r_df;
            this.peaks_dFF.firstScanNormalized = n_df;
            
            if dgr
                this.peaks_dGR.raw = r_dgr;
                this.peaks_dGR.firstScanNormalized = n_dgr;
            end

        end
        
        %VISUALIZATION SECTION (experiment-specific methods)
        
        function [varargout] = plot_peaks_dFF(this)
            dgr = 0;
            
            varargout{1} = this.plotPeaks(dgr);
        end
        
        function [varargout] = plot_peaks_dGR(this)
            dgr = 1;
            
            varargout{1} = this.plotPeaks(dgr);
        end
        
        %ROUTINES
        function [varargout] = analyze(this)
            
            tic;
            
            display (['-- ',this.name,' Analyzing'])
            
            for i=1:length(this.boutons)
                this.boutons{i}.analyze
            end
            
            fprintf(['-- ',this.name])
            cprintf('*blue',' pullPeaks')
            fprintf('\n')
            this.pullPeaks;
            fprintf('\n')
            fprintf('\n')
            
            varargout{1} = toc;
            elapsedTime = varargout{1};
            
            [hours, mins, secs] = sec2hms(elapsedTime);

            if elapsedTime > 60*60 %greater than an hour
                display(['  --  Runtime = ',num2str(hours),...
                    ' Hours, ',num2str(mins),' Min., ',num2str(round(secs,2)),...
                    ' Sec.']);
            elseif elapsedTime > 60 %greater than a minute
                display(['  --  Runtime = ',num2str(mins),' Min., ',...
                    num2str(round(secs,2)),' Sec.']);
            else
                display(['  --  Runtime = ',num2str(round(secs,2)),' Sec.']);
            end
            
        end
        
        function visualize(this,saveMe)
            
            if nargin<2
                saveMe = 0;
            end
            
            peaksDF = this.plot_peaks_dFF;
            if saveMe
                savefig(peaksDF,[this.location,'/setAmps_dFFallBoutons']);
            end
            
            if this.analysisParams.dgr
                peaksDGR = this.plot_peaks_dGR;
                if saveMe
                    savefig(peaksDGR,[this.location,'/setAmps_dGRallBoutons']);
                end
            end
            
        end
        
        function [varargout] = saveFigs(this)
            
            tic;
            
            saveMe = 1;
            disp(['-- SAVING FIGURES ', this.name]);
            this.visualize(saveMe);            
            close all
            
            notify(this,'SaveFigs',broadcastState(saveMe));
            
            fprintf('\n')
            fprintf('\n')
            elapsedTime = toc;
            
            varargout{1} = elapsedTime;
            
            function [hours, mins, secs] = sec2hms(t)
                hours = floor(t / 3600);
                t = t - hours * 3600;
                mins = floor(t / 60);
                secs = t - mins * 60;
            end

            [hours, mins, secs] = sec2hms(elapsedTime);
            
            if elapsedTime > 60*60 %greater than an hour
                display(['  --  saveFigs Runtime = ',num2str(hours),...
                    ' Hours, ',num2str(mins),' Min., ',num2str(round(secs,2)),...
                    ' Sec.']);
            elseif elapsedTime > 60 %greater than a minute
                display(['  --  saveFigs Runtime = ',num2str(mins),' Min., ',...
                    num2str(round(secs,2)),' Sec.']);
            else
                display(['  --  saveFigs Runtime = ',num2str(round(secs,2)),' Sec.']);
            end
            
        end
                
        function explore(this)
            
            this.analyze;
            display('-------------------------------------------')
            this.saveFigs;
            
            this.save;
        end
        
        %UPDATE
        
        function reset(this)
            
            while (1)
                fprintf('\n');
                cprintf('*red',['Are you SURE you want to RESET ',this.name,'?']);

                fprintf('\n');
                target = input('  --> ','s');
                
                if any([strcmpi(target,'no'),strcmpi(target,'n')...
                        strcmpi(target,'quit'),strcmpi(target,'q')])
                    display('quitting without saving');
                    return
                elseif any([strcmpi(target,'yes'),strcmpi(target,'y')...
                        strcmpi(target,'continue'),strcmpi(target,'cont')])
                    break
                else
                    display('Must answer with "Yes or No"');
                    continue
                end
            end
            
            xmlReset = 0;
            
            while (1)
                fprintf('\n');
                cprintf('*red','Hard Reset? (reimport XML data, this will add a lot of time)?');

                fprintf('\n');
                target = input('  --> ','s');
                
                if any([strcmpi(target,'no'),strcmpi(target,'n')...
                        strcmpi(target,'quit'),strcmpi(target,'q')])
                    break
                elseif any([strcmpi(target,'yes'),strcmpi(target,'y')...
                        strcmpi(target,'continue'),strcmpi(target,'cont')])
                    display('resetting');
                    
                    xmlReset = 1;
                    
                    break
                    
                else
                    display('Must answer with "Yes or No"');
                    continue
                end
            end
            
            if xmlReset
                fullReset = 1;
            else
                fullReset = 0;
            end
            
            delete([this.location '*.mat'])
            delete([this.location '*.fig'])
            
            notify(this,'Reset',broadcastState(fullReset));
            
            this.peaks_dFF = [];
            this.peaks_dGR = [];
            this.initializeDefaultAnalysis;
            
            dgr=1;
            for i=1:this.analysisParams.numBoutons;
                dgr = dgr*this.boutons{i}.analysisParams.dgr;
            end
            this.analysisParams.dgr = dgr;  % this should be OFF unless ALL 
                                 % linescans have dGR (individual linescans
                                 % have dgr capabilities, but you should 
                                 % write custom scripts if you want to do
                                 % dGR analysis with partial datasets)
            
            this.analysisParams.timeAxis = this.boutons{1}.relSetTimes;
        end
        
        function save(this)
            exper = this; %#ok<NASGU>
            save([this.location,'/',this.name,'.mat'],'exper');
        end
                
        function updateAnalysisSettings(this)

            fprintf('\n');
            display('Change Experiment Settings or Bouton/Linescan Settings?');
            fprintf('\n');
            cprintf('*blue','Experiment Settings:');
            fprintf('\n');
            exp_params = {'dgr','timeAxis','conditionTimes'};
            
            for i=1:length(exp_params)
                display(['    ',exp_params{i},repmat(' ',1,20-length(exp_params{i})),...
                    ':      ',num2str(reshape(this.analysisParams.(exp_params{i})',1,[]))])
            end
            
            fprintf('\n');
            cprintf('*blue','Bouton Settings (first bouton shown):');
            fprintf('\n');
            bout_params = {'isSingle','smoothing','dgr','norm_range','triple_sub',...
                'triple_peak','single_sub','single_peak'};
            
            for i=1:length(bout_params)
                display(['    ',bout_params{i},repmat(' ',1,20-length(bout_params{i})),...
                    ':      ',num2str(this.boutons{1}.analysisParams.(bout_params{i}))])
            end
            
            fprintf('\n');
            expOrBout = input('  Enter E or B --> ','s');
            fprintf('\n');
            display('-----------------')
            
            if any([strcmpi(expOrBout,'no'),strcmpi(expOrBout,'n')...
                    strcmpi(expOrBout,'quit'),strcmpi(expOrBout,'q')])
                display('quitting without saving');
                return
            end
            
            fprintf('\n');
            display('What do you want to modify?');
            fprintf('\n');
                        
            target = input('  --> ','s');
            
            if any([strcmpi(target,'no'),strcmpi(target,'n')...
                    strcmpi(target,'quit'),strcmpi(target,'q')])
                display('quitting without saving');
                return
            end
            
            if strcmpi(expOrBout,'e')   %if experiment
                switch target
                    case 'timeAxis'
                        prompt = {'Enter start of time axis (for linspace)',...
                            'Enter end of time axis (for linespace)'...
                            'Enter length of time axis vector (for linspace)'};
                        defaultans = {'0','20','11'};
                    case 'dgr'
                        prompt = {'Turn on delta G/R analysis? (1 for yes, 0 for no)'};
                        defaultans = {num2str(this.analysisParams.dgr)};
                    case 'conditionTimes'
                        prompt = {'New condition start (min.):',...
                            'New condition end (min.):'};
                        defaultans = {'10','20'};
                    otherwise
                        warning('That is not a thing!')
                        return
                end
                
                dlg_title = ['Update Analysis Settings - ',target];
                num_lines = length(prompt);

                answer = inputdlg(prompt,dlg_title,num_lines,defaultans);

                tempParams = struct();

                switch target
                    case 'timeAxis'
                        tempParams.timeAxis = linspace(str2double(answer{1}),...
                            str2double(answer{2}),str2double(answer{3}));
                    case 'dgr'
                        tempParams.dgr = str2double(answer{1});
                    case 'conditionTimes'
                        tempParams.conditionTimes = [str2double(answer{1}),str2double(answer{2})];
                end

                if strcmpi(target,'conditionTimes')
                    this.analysisParams.conditionTimes = ...
                        [this.analysisParams.conditionTimes;tempParams.(target)];
                else
                    this.analysisParams.(target) = tempParams.(target);
                end
                
                %if it's one of the targets that gets broadcast, then do so
                switch target
                    case 'dgr'
                        notify(this,'UpdateAnalysis',broadcastState(target,tempParams.dgr))
                end
                
            elseif strcmpi(expOrBout,'b')   %if boutons
            
            %(will only update boutons/linescans if they actually have this field)
            
                notify(this,'UpdateAnalysis',broadcastState(target))
                
            end
                
            
        end
                
    end
    
    methods (Access = private)
        
        %Importing Functions
        function importNameAndLoc(this,path)
            [~, this.name] = fileparts(path);
            this.location = path;
        end
        
        function initializeDefaultAnalysis(this)
            
            main_listing = dir([this.location,'/*_*_*/']);

            this.analysisParams.boutonDirectory = main_listing;
            this.analysisParams.numBoutons = size(main_listing,1);
            this.analysisParams.boutonNumber = zeros(1,this.analysisParams.numBoutons);
            for i=1:this.analysisParams.numBoutons
                remain = this.analysisParams.boutonDirectory(i).name;
                for j=1:2
                    [str,remain] = strtok(remain,'_');
                end
                this.analysisParams.boutonNumber(i) = str2double(str);
            end
            this.analysisParams.dgr = 1;
            this.analysisParams.timeAxis = 0:2:(9*2);
            this.analysisParams.conditionTimes = [];    
                %matrix of start/end times for N conditions (e.g. drug application)            
        
        end
        
        function importBoutons(this)
            
            for i=1:this.analysisParams.numBoutons
                
                str = num2str(this.analysisParams.boutonNumber(i));
                sub_listing = dir([this.location,'/*_',str,'_*']);
                
                if (length(sub_listing)>1)
                    warning('DUPLICATE BOUTON NUMBERS IN LISTING, ERROR');
                else
                    subdirectory = [this.location,'/',sub_listing.name];
                end
                
                this.boutons{i} = bouton(subdirectory, this);
%                 this.boutonListeners{i} = 
            end
            
        end
        
        %Plotting Functions
        function [varargout] = plotPeaks(this,dgr)
            
            if nargin<2
                dgr = 0;
            end
            
            r_df = this.peaks_dFF.raw;
            n_df = this.peaks_dFF.firstScanNormalized;
            if dgr
                r_df = this.peaks_dGR.raw;
                n_df = this.peaks_dGR.firstScanNormalized;
            end
            
            % plot raw
            scrsz = get(groot,'ScreenSize');
            varargout{1} = figure('Position',scrsz);
            subplot(1,2,1)
            hold on
            meanRaw = errorbar(this.analysisParams.timeAxis,mean(r_df),std(r_df)./sqrt(size(r_df,1)),'Color',[0.2 0.3 1],'Marker','o','MarkerSize',7);
            singleBoutonsRaw = plot(this.analysisParams.timeAxis,r_df','Color',[0.7 0.7 0.7]);
            ylabel('Peak, Triple')
            xlabel('Time (minutes)')

            if this.name
                scanSetNum = this.boutons{1}.analysisParams.numScanSets;
                scansPerSet = this.boutons{1}.scans{1}.numTrials;
                title([this.name,' (',num2str(scanSetNum),' Sets of Linescans, '...
                    num2str(scansPerSet),' trials each.)'])
            else
                title('Time-Locked Controls (20 trials, 1 set per 5 min.)')
            end

            axis([(this.analysisParams.timeAxis(1)-2),(this.analysisParams.timeAxis(end)+2),0,1.5])
            topPlot = mean(r_df(:,1));
            plot([(this.analysisParams.timeAxis(1)-2),(this.analysisParams.timeAxis(end)+2)],[topPlot,topPlot],'--k')
            legend([meanRaw,singleBoutonsRaw(1)],['Mean +/- SEM, n=',num2str(size(n_df,1))],'Singles')
            
            if this.analysisParams.conditionTimes %if there are conditions
                cTimes = this.analysisParams.conditionTimes;
                for i=1:size(cTimes,1)
                    %loop through and plot them
                    scale = 1+0.1*i;
                    plot(cTimes(i,:),[scale*mean(r_df(:,1)),scale*mean(r_df(:,1))]);
                end
            end

            % plot norm

            subplot(1,2,2)
            hold on
            meanNorm = errorbar(this.analysisParams.timeAxis,mean(n_df),std(n_df)./sqrt(size(n_df,1)),'Color',[0.2 0.3 1],'Marker','.','MarkerSize',30);
            singlesNorm = plot(this.analysisParams.timeAxis,n_df','Color',[0.7 0.7 0.7]);
            ylabel('Peak, Triple (norm.)')
            xlabel('Time (minutes)')

            if this.name
                scanSetNum = this.boutons{1}.analysisParams.numScanSets;
                scansPerSet = this.boutons{1}.scans{1}.numTrials;
                title([this.name,' (',num2str(scanSetNum),' Sets of Linescans, '...
                    num2str(scansPerSet),' trials each.)'])
            else
                title('Time-Locked Controls (20 trials, 1 set per 5 min.)')
            end
            
            axis([(this.analysisParams.timeAxis(1)-2),(this.analysisParams.timeAxis(end)+2),0,1.5])
            plot([(this.analysisParams.timeAxis(1)-2),(this.analysisParams.timeAxis(end)+2)],[1,1],'--k')
            legend([meanNorm,singlesNorm(1)],['Mean +/- SEM, n=',num2str(size(n_df,1))],'Singles')

            if this.analysisParams.conditionTimes %if there are conditions
                cTimes = this.analysisParams.conditionTimes;
                for i=1:size(cTimes,1)
                    %loop through and plot them
                    scale = 1+0.1*i;
                    plot(cTimes(i,:),[scale*mean(r_df(:,1)),scale*mean(r_df(:,1))]);
                end
            end
            
            hold off
        end        
        
    end
    
    methods (Static)
        %Loading Function
        function obj = loadobj(obj)
            
            display(['LOADING EXPERIMENT ', obj.name])
            fprintf('\n')
            
            obj.boutonListeners = cell(1,obj.analysisParams.numBoutons);
            
            for i=1:obj.analysisParams.numBoutons
                obj.boutonListeners{i} = obj.boutons{i}.restoreListeners(obj);
            end
            
            display('LOADED')
            
        end
    end
    
    
end