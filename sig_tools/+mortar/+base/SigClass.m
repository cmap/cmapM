classdef SigClass < handle
    % SigClass Base class for Sig classes
    
    % Protected properties
    properties (Access=protected)
        % Input arguments
        args_;
        % Fully qualified class name
        sigName_;
        % class name
        className_;
        % Argument and doc configuration
        configFile_;
        % Test suite
        testSuite_;
        % Results
        res_;
        % Working directory
        wkdir_;
        % timer start/stop
        t0_;
        tend_;
        % Original input arguments without dereferencing URLs
        args0_;
        % Mode flag
        mode_ = mortar.base.ProgramModes.null;
        % State flag
        state_ = mortar.base.ProgramStates.null;
        % Error object
        stack_trace_;
    end
    
    % Public methods
    methods
        function obj = SigClass(sigName, configFile, varargin)
            % SigClass Class constructor
            obj.sigName_ = sigName;
            assert(mortar.util.File.isfile(configFile),...
                'Config file not found: %s', configFile);
            obj.configFile_ = configFile;
            tok = tokenize(sigName, '.');
            className = tok{end};
            if obj.versionCheck_
                testSuite = fullfile(mortarpath, 'tests',...
                    strcat('Test', className,'.m'));
                assert(mortar.util.File.isfile(testSuite),...
                    'testSuite file not found: %s', testSuite);
                demoElement = strcat('Test', className, '/testDemo*');
                assert(obj.hasDemo_(testSuite, demoElement),...
                    'No Demos named %s found in %s', demoElement, ...
                    testSuite);
                obj.testSuite_ = testSuite;
            end
            obj.className_ = className;
            if nargin>2
                obj.parseArgs(varargin{:});
            end
        end
        
        function parseArgs(obj, varargin)
            % parseArgs Parse and validate inputs
            obj.parseArgs_(varargin{:});
        end
        
        function run(obj, varargin)
            % run parse arguments, run and save analysis
            try
                obj.parseArgs(varargin{:});
                obj.runAnalysis;
                if isequal(obj.state_, mortar.base.ProgramStates.success) &&...
                        isequal(obj.mode_, mortar.base.ProgramModes.default)
                    obj.saveResults;
                end
                if isdir(obj.wkdir_)
                    out_stream = fullfile(obj.wkdir_, 'success.txt');
                    mortar.util.Message.log(out_stream, ...
                        '# Completed in %2.2fs', obj.tend_);
                end

            catch e
                obj.state_ = mortar.base.ProgramStates.failure;
                %mortar.util.Message.log(1, e);
                if isdir(obj.wkdir_)
                    err_file = fullfile(obj.wkdir_, 'failure.txt');
                    mortar.util.Message.log(err_file, e);
                    mortar.util.Message.log(1, '#Stack trace saved in %s', err_file);
                end
                rethrow(e);
            end
        end
        
        function runAnalysis(obj)
            % runAnalysis Execute main analysis
            if ~isequal(obj.mode_, mortar.base.ProgramModes.help)
                obj.state_ = mortar.base.ProgramStates.running;
                obj.tic;
                obj.classMain_;
                tend = obj.toc;
                mortar.util.Message.log(1, ...
                    '# Completed in %2.2fs', tend);
                obj.state_ = mortar.base.ProgramStates.success;
            end
        end
        
        function saveResults(obj, varargin)
            % saveResults Save results and reports
            if nargin>1
                wkdir = varargin{1};
            else
                wkdir = obj.wkdir_;
            end
            if ~isdirexist(wkdir)
                mortar.util.Message.log(1, 'Creating working dir: %s', wkdir);
                mkdir(wkdir);
            else
                mortar.util.Message.log(1, 'Working dir: %s exists', wkdir)
            end
            % save config
            mkconfigyaml(fullfile(wkdir, 'config.yaml'), obj.args0_);
            obj.saveResults_(wkdir);            
        end
        
        function runTests(obj)
            % runTests Execute functional and unit-tests
            obj.runTests_();
        end
        
        function runDemo(obj)
            % runDemo Run the sig tool with sample inputs
            obj.runDemo_();
        end
        
        function args = getArgs(obj)
            % getArgs Returns a structure of input arguments
            args = obj.args_;
        end
        
        function setArg(obj, key, value)
            % setArg Update a key in args struct
            if isfield(obj.args_, key)
                obj.args_.(key) = value;
                obj.args0_.(key) = value;
            else
                error('Key:%s is not a valid argument', key);
            end
        end
        
        function setArgs(obj, s)
            % setArgs Update multiple keys in args struct
            assert(isstruct(s), 'Structure expected, got %s', class(s));
            fn = fieldnames(s);
            for ii=1:numel(fn)
                obj.setArg(fn{ii}, s.(fn{ii}));
            end
        end
        
        function sigName = getSigName(obj)
            % getSigName returns name of the sigClass
            sigName = obj.sigName_;
        end
        
        function configFile = getConfigFile(obj)
            % getConfigFile returns the location of the argument
            % configuration file
            configFile = obj.configFile_;
        end
        
        function res = getResults(obj)
            % getResult Returns a result sults
            res = obj.res_;
        end
        
        function state = getState(obj)
            % getState Get the current state of the program
            state = obj.state_;
        end
        
        function program_mode = getMode(obj)
            % getMode Get the operating mode of the program
            program_mode = obj.mode_;
        end
        
        function wkdir = getWkdir(obj)
            % getWkdir Get working directory
            wkdir = obj.wkdir_;
        end
        
        function tic(obj)
            % tic Start internal timer
            obj.t0_ = tic;
            obj.tend_=-1;
        end
        
        function tsec = toc(obj)
            % toc Stop timer and return elapsed time in secs
            if ~isempty(obj.t0_)
                tsec = toc(obj.t0_);
                obj.tend_ = tsec;
            else
                tsec = obj.tend_;
            end
        end
        
    end
    
    % Protected methods
    methods (Access=protected)
        function classMain_(obj)
            % classMain_(varargin) Main function block
            switch(obj.mode_)
                case mortar.base.ProgramModes.test
                    obj.runTests_();
                case mortar.base.ProgramModes.demo
                    obj.runDemo_();
                case mortar.base.ProgramModes.default
                    obj.runAnalysis_();
            end
        end
        
        function parseArgs_(obj, varargin)
            
            % parseArgs_(varargin) Parse arguments
            if nargin<2
                warning('No arguments supplied')
                varargin={'-h'};
            end
            opt = struct('prog', '',...
                'desc', '',...
                'undef_action', 'error');
            [obj.args0_, help_flag] = mortar.common.ArgParse.getArgs(...
                obj.configFile_, opt, varargin{:});
            obj.args_ = obj.args0_;
            if ~help_flag
                if obj.args_.rundemo
                    obj.mode_ = mortar.base.ProgramModes.demo;
                elseif obj.args_.runtests
                    obj.mode_ = mortar.base.ProgramModes.test;
                else
                    obj.mode_ = mortar.base.ProgramModes.default;
                    % sanity checks
                    obj.checkArgs_();
                    args = obj.args_;
                    % create a work folder for output and temp datasets
                    wkdir = mortar.util.File.makeToolFolder(args.out,...
                        obj.getSigName, args.rpt, args.create_subdir);
                    % Update args and download remote URLs if needed
                    obj.args_ = get_config_url(args, wkdir, true, args.encode_url);
                    obj.wkdir_ = wkdir;
                end
            else
                obj.mode_ = mortar.base.ProgramModes.help;
            end
        end
        
        function runTests_(obj, varargin)
            % Run functional and unit test suite
            if ~isempty(obj.args_) && ~isempty(obj.args_.out)
                outPath = obj.args_.out;
            else
                outPath = tempdir;
            end
            dbg(1, 'Test results folder: %s', outPath);
            if ~mortar.util.File.isfile(outPath, 'dir')
                dbg(1, 'Created TAP result folder');
                mkdir(outPath);
            end
            resultFile = fullfile(outPath, 'test_results.tap');
            if mortar.util.File.isfile(resultFile)
                dbg(1, 'deleted TAP result file')
                delete(resultFile);
            end
            obj.testRunner_(obj.testSuite_, resultFile);
        end
        
        function runDemo_(obj)
            % Run demos using sample inputs
            demoElement = sprintf('Test%s/testDemo*', obj.className_);
            obj.demoRunner_(obj.testSuite_, demoElement);
        end
        
        function testResult = testRunner_(obj, suiteName, tapFile)
            % testRunner_(suiteName, tapFile) Run tests and output results
            % to a file in TAP format
            if obj.versionCheck_
                suite =  matlab.unittest.TestSuite.fromFile(suiteName);
                runner = matlab.unittest.TestRunner.withTextOutput('Verbosity',  matlab.unittest.Verbosity.Detailed);
                plugin =  matlab.unittest.plugins.TAPPlugin.producingOriginalFormat(matlab.unittest.plugins.ToFile(tapFile));
                runner.addPlugin(plugin);
                dbg(1, '## Saving test results to : %s', tapFile);
                testResult = runner.run(suite);
            else
                warning(['Incorrect Matlab version, skipping ' ...
                    'tests']);
                testResult = [];
            end
        end
        
        function demoResult = demoRunner_(obj, suiteName, demoElement)
            % demoRunner_(suiteName, demoElement) Run demos from a test
            % suite
            if obj.versionCheck_
                suite =  matlab.unittest.TestSuite.fromFile(suiteName, 'Name', demoElement);
                runner =  matlab.unittest.TestRunner.withTextOutput('Verbosity',  matlab.unittest.Verbosity.Terse);
                demoResult = runner.run(suite);
            else
                warning(['Incorrect Matlab version, skipping ' ...
                    'demo']);
                demoResult = [];
            end
        end
        
        function tf = versionCheck_(obj)
            tf = ~verLessThan('matlab','8.4');
            if ~tf
                warning(['A minimum Matlab version of 8.4 is needed ' ...
                    'for full functionality']);
            end
        end
        
        function tf = hasDemo_(obj, suiteName, demoElement)
            % Check if test suite has demos
            if obj.versionCheck_
                suite = matlab.unittest.TestSuite.fromFile(suiteName, 'Name', demoElement);
                tf = ~isempty(suite);
            else
                tf = true;
            end
        end
    end
    
    % Abstract methods
    methods(Abstract=true, Access=protected)
        % Protected methods implemented in the sub class
        % Execute analysis
        runAnalysis_(obj);
        % save analysis results
        saveResults_(obj, out_path);
        % Validate input arguments
        checkArgs_(obj);
        %         % run functional / unit-tests
        %         runTests_(obj);
        %         % run a demo with sample inputs
        %         runDemo_(obj);
    end
end
