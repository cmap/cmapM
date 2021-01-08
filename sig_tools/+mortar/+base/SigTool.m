classdef SigTool < mortar.base.SigClass
    % SigTool Base class for sig tools

    properties (Access=protected)
        toolName_;
%         configFile_;
    end
    
    methods
        function obj = SigTool(toolName, configFile, varargin)
            %Class constructor
            obj.toolName_ = toolName;
            obj.configFile_ = configFile;
            obj.main_(varargin{:});
        end
                
        function getArgs(obj, varargin)
            %Get arguments
            obj.getArgs_(obj.toolName_, obj.configFile_, varargin{:});
        end
    end
    
    methods (Access=protected)
        function main_(obj, varargin)
            import mortar.util.Message
            obj.getArgs(varargin{:});
            if obj.test_flag_
                obj.runTests_();
            elseif obj.demo_flag_
                obj.runDemo_();
            elseif ~obj.help_flag_
                try
                    wkdir = obj.args_.out;
                    t0 = tic;
                    obj.runAnalysis_();
                    obj.saveResults_();
                    tend = toc(t0);
                    Message.log(fullfile(wkdir, 'success.txt'), ...
                        'Completed in %2.2fs', tend);
                catch e
                    mortar.util.Message.log(1, e);
                    if ~isempty(wkdir)
                        err_file = fullfile(wkdir, 'failure.txt');
                        Message.log(err_file, e);
                        Message.log(1, 'Stack trace saved in %s', err_file);
                    end
                end
            end
            
        end
        
        function getArgs_(obj, toolName, configFile, varargin)
            % Parse arguments
            if nargin<3
                error('Both toolName and configFile must be specified');
            elseif nargin<4
                warning('No arguments supplied')
                varargin={'-h'};
            end
            opt = struct('prog', toolName, 'desc', '', 'undef_action', 'warn');
            [obj.args_, obj.help_flag_] = mortar.common.ArgParse.getArgs(...
                                             configFile, opt, varargin{:});            
            if ~obj.help_flag_
                if obj.args_.rundemo
                    obj.demo_flag_ = true;
                elseif obj.args_.runtests
                    obj.test_flag_ = true;
                else
                    % sanity checks
                    obj.checkArgs_();
                    wkdir = mortar.util.File.makeToolFolder(obj.args_.out,...
                        toolName, obj.args_.rpt, obj.args_.create_subdir);
                    args_save = obj.args_;
                    % handle remote URLs
                    obj.args_ = get_config_url(obj.args_, wkdir, true, args.encode_url);
                    % save config with remote URLS if applicable
                    WriteYaml(fullfile(wkdir, 'config.yaml'), args_save);
                    obj.args_.out = wkdir;
                end
            end
        end
    end
    
    methods(Access=protected, Abstract=true)
        % Methods implemented in the sub classes
%         % Execute analysis
%         runAnalysis_(obj);
%         % save analysis results
%         saveResults_(obj);
%         % Check parsed inputs
%         checkArgs_(obj);
        % run functional / unit-tests
        runTests_(obj);
        % run a demo with sample inputs
        runDemo_(obj);     
    end
end