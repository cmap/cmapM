classdef TestArgParse < matlab.unittest.TestCase
    % Test argument parser
    % runtests mortar.common.tests.TestArgParse
    properties
        p
    end
    
    methods(TestMethodSetup)
        function setUp(self)
            % Setup (called before each test)
            self.p = mortar.common.ArgParse('test_prog', 'A test program');
            
        end
    end
    
    methods(TestMethodTeardown)
        function tearDown(self)
            % Called after each test
        end        
    end
    
    methods(Test)
      
        function testCreateObject(self)            
            self.verifyEqual(self.p.nargs, 1);
        end
        
        function testAddArgAsList(self)
            % add argument as a list
            self.p.add('foo', 10, 'parameter foo');
            self.p.add('bar', 'xyz', 'parameter bar');
            self.verifyEqual(self.p.nargs, 3);
        end
        
        function testAddArgAsStruct(self)
            % add argument as a structure
            param = struct('name', 'foo',...
                           'default', 10,...
                           'help', 'parameter foo');
            self.p.add(param);
            self.verifyEqual(self.p.nargs, 2);
        end
        
        function testAddStructArray(self)
            % add multiple arguments as a struct array
            s = struct('name', {'n';'--zeropad';'--prefix';'--suffix'},...
                        'default', {[];true;'';''});
            self.p.add(s);
            self.verifyEqual(self.p.getPositionalArgs, {'n'});
            self.verifyEqual(self.p.getOptionalArgs,...
                {'--help','-h', '--zeropad','--prefix','--suffix'}');
        end

        function testParseEmptyArg(self)
            res = self.p.parse();
            self.verifyTrue(isempty(res));
        end
        
        function testParsePositionalArg(self)
            param = struct('name', 'foo',...
                'default', 10,...
                'help', 'parameter foo');
            self.p.add(param);
            res = self.p.parse(100);
            self.verifyEqual(res.foo, 100);
        end

        function testParseDefaultOptionalArg(self)
            param = struct('name', '--foo',...
                'default', 10,...
                'help', 'parameter foo');
            self.p.add(param);
            res = self.p.parse();
            self.verifyEqual(res.foo, 10);
        end

        function testParseOptionalArg(self)
            param = struct('name', '--foo',...
                'default', 10,...
                'help', 'parameter foo');
            self.p.add(param);
            res = self.p.parse('--foo', '100');
            self.verifyEqual(res.foo, 100);
        end
        
        function testParseMultiArg(self)
            param1 = struct('name', 'param1',...
                'default', 10);
            param2 = struct('name', '--opt1',...
                'default', true);
            param3 = struct('name', '--opt2',...
                'default', pi);                            
            self.p.add(param1);
            self.p.add(param2);
            self.p.add(param3);
            res = self.p.parse(100, '--opt2', 2*pi);
            self.verifyEqual(res.param1, 100);
            self.verifyEqual(res.opt1, true);
            self.verifyEqual(res.opt2, 2*pi, 'AbsTol', 1e-4);
        end
        
        function testParseStruct(self)
            name = {'param1', '--opt1', '--opt2'};
            default = {10, true, pi};
            param = struct('name', name, 'default', default);
            self.p.add(param);
            res = self.p.parse(100, '--opt2', 2*pi);
            self.verifyEqual(res.param1, 100);
            self.verifyEqual(res.opt1, true);
            self.verifyEqual(res.opt2, 2*pi, 'AbsTol', 1e-4);
        end
        
        function testParseScalarStruct(self)
            name = {'param1', '--opt1', '--opt2'};
            default = {10, true, pi};
            param = struct('name', name, 'default', default);
            self.p.add(param);
            res = self.p.parse(100, '--opt2', 2*pi);
            self.verifyEqual(res.param1, 100);
            self.verifyEqual(res.opt1, true);
            self.verifyEqual(res.opt2, 2*pi, 'AbsTol', 1e-4);
        end
        
        function testAddFile(self)
            cfgfile = fullfile(fileparts(mfilename('fullpath')), 'param01.arg');
            self.p.addFile(cfgfile);
            self.verifyEqual(self.p.getPositionalArgs, {'pos1'});
            self.verifyEqual(self.p.getOptionalArgs,...
                {'--help'; '-h'; '--opt1'; '-o'; '--opt2'; '--config'});
        end
        
        function testParseLogical(self)
            name = {'--opt1'};
            default = {true};
            param = struct('name', name, 'default', default);
            self.p.add(param);
            res = self.p.parse('--opt1', false);
            self.verifyEqual(res.opt1, false);
        end
        
        function testParseLogicalString(self)
            name = {'--opt1'};
            default = {true};
            param = struct('name', name, 'default', default);
            self.p.add(param);
            res = self.p.parse('--opt1', 'false');
            self.verifyEqual(res.opt1, false);            
        end
        
        function testParseLogicalStringNum(self)
            name = {'--opt1'};
            default = {false};
            param = struct('name', name, 'default', default);
            self.p.add(param);
            res = self.p.parse('--opt1', '1');
            self.verifyEqual(res.opt1, true);            
        end
        
        function testUndefActionWarn(self)
            % warn on undefined arguments, default
            param = struct('name', '--foo',...
                'default', 10,...
                'help', 'parameter foo');
            self.p.add(param);   
            expect_warn_id = 'mortar:common:ArgParse:UnknownParameter';
            % suppress warning in stdout
            warning('off', expect_warn_id);
            res = self.p.parse('--foo', '100', '--bar', 'abc');
            self.verifyEqual(res.foo, 100);
            % check if warning was thrown
            [~, msgid] = lastwarn;
            self.verifyEqual(msgid, expect_warn_id)
        end
        
        function testUndefActionIgnore(self)
            % ignore undefined arguments
            param = struct('name', '--foo',...
                'default', 10,...
                'help', 'parameter foo');
            self.p.add(param);
            self.p.undef_action = 'ignore';            
            res = self.p.parse('--foo', '100', '--bar', 'abc');
            self.verifyEqual(res.foo, 100);
        end
        
         function testUndefActionError(self)            
            % throw error if undefined argument
            param = struct('name', '--foo',...
                'default', 10,...
                'help', 'parameter foo');
            expect_error_id = 'mortar:common:ArgParse:UnknownParameter';
            self.p.add(param);
            self.p.undef_action = 'error';
            try
                self.p.parse('--foo', '100', '--bar', 'abc');
                assert(false); 
            catch ME
                self.verifyEqual(ME.identifier, expect_error_id);
                self.verifyEqual(ME.message, 'Unknown parameter --bar');
            end
         end 
        
        function testChoicesChar(self)
                param = struct('name', '--foo',...
                'default', 'a',...
                'choices', {{'a','b','c'}},...
                'help', 'parameter foo');
            self.p.add(param);
            try
                self.p.parse('--foo', 'z');
                assert(false);
            catch ME
                self.verifyEqual(ME.identifier, 'mortar:common:ArgParse:InvalidChoice')
            end
        end
        
        function testChoicesInt(self)
            param = struct('name', '--foo',...
                'default', 5,...
                'choices', {num2cell(1:10)},...
                'help', 'parameter foo');
            self.p.add(param);
            % valid input
            res = self.p.parse('--foo', 8);
            self.verifyEqual(res.foo, 8, 'AbsTol', 1e-4);
            
            % invalid input
            try
                self.p.parse('--foo', '9.5');
                assert(false);
            catch ME
                self.verifyEqual(ME.identifier, 'mortar:common:ArgParse:InvalidChoice')
            end
        end

        function testConfig(self)
            paramfile = fullfile(fileparts(mfilename('fullpath')), 'param01.arg');
            cfgfile = fullfile(fileparts(mfilename('fullpath')), 'cfg01.cfg');
            self.p.addFile(paramfile);            
            res = self.p.parse('', '--config', cfgfile);
            
            self.verifyEqual(res.opt1, 'myopt');
            self.verifyEqual(res.opt2, 10, 'AbsTol', 1e-4);
        end
 
        function testConfigURL(self)
            paramfile = fullfile(fileparts(mfilename('fullpath')), 'param01.arg');
            cfgfile = strcat('file://', fullfile(fileparts(mfilename('fullpath')), 'cfg01.cfg'));
            self.p.addFile(paramfile);
            res = self.p.parse('', '--config', cfgfile, '--opt2', 100);            
            self.verifyEqual(res.opt1, 'myopt');
            self.verifyEqual(res.opt2, 100, 'AbsTol', 1e-4);
        end
        
         function testConfigURLEmpty(self)
            paramfile = fullfile(fileparts(mfilename('fullpath')), 'param01.arg');
            cfgfile = '';
            self.p.addFile(paramfile);
            res = self.p.parse('', '--config', cfgfile, '--opt2', 100);            
            self.verifyEqual(res.opt1, 'default1');
            self.verifyEqual(res.opt2, 100, 'AbsTol', 1e-4);
         end
         
         function testGetArgs(self)
             
             ConfigFile = fullfile(fileparts(mfilename('fullpath')), 'param01.arg');             
             opt = struct('prog', mfilename, 'desc', 'my desc', 'undef_action', 'ignore');
             param = {pi, '--opt2', 100};
             [args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, param{:});
             self.verifyEqual(args.opt2, 100, 'Parameter opt2 is incorrect');
             self.verifyFalse(help_flag, 'Help flag is true, expected false')

         end
         
         function testGetArgsHelp(self)
             
             ConfigFile = fullfile(fileparts(mfilename('fullpath')), 'param01.arg');
             opt = struct('prog', mfilename, 'desc', 'my desc', 'undef_action', 'ignore');
             param = {'--help'};
             [args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, param{:});             
             self.verifyTrue(help_flag, 'Help flag is false, expected true')
             self.verifyTrue(isempty(args), 'Args is non-empty')
         end
 
         function testIncludeFile(self)
         % test argument file includes
             ConfigFile = fullfile(fileparts(mfilename('fullpath')), ...
                                   'param02.arg');
            self.p.addFile(ConfigFile);
            self.verifyEqual(self.p.getPositionalArgs, {'pos1';'pos2'});
            self.verifyTrue(isempty(setdiff(self.p.getOptionalArgs,...
                {'--help'; '-h'; '--opt1'; '-o'; '--opt2'; '--opt3'; ...
                 '--config'})));
            % pos1=10, pos2=200, opt1='default1', opt2=1, opt3='default3'
            argInfo = self.p.getArgInfo('pos1');
            self.verifyEqual(argInfo.default, 10, ['Incorrect default for ' ...
                                'argument pos1']);
            argInfo = self.p.getArgInfo('pos2');
            self.verifyEqual(argInfo.default, 200, ['Incorrect default for ' ...
                                'argument pos2']);
            argInfo = self.p.getArgInfo('--opt1');
            self.verifyEqual(argInfo.default, 'default1', ['Incorrect default for ' ...
                                'argument pos1']);
            argInfo = self.p.getArgInfo('--opt2');
            self.verifyEqual(argInfo.default, 1, ['Incorrect default for ' ...
                                'argument opt2']);
            argInfo = self.p.getArgInfo('--opt3');
            self.verifyEqual(argInfo.default, 'default3', ['Incorrect default for ' ...
                                'argument pos1']);
         end

         function testMultipleAddFile(self)
         % test argument file includes
             ConfigFile1 = fullfile(fileparts(mfilename('fullpath')), ...
                                   'param01.arg');
             ConfigFile2 = fullfile(fileparts(mfilename('fullpath')), ...
                                   'param03.arg');

            self.p.addFile(ConfigFile1);
            self.p.addFile(ConfigFile2);
            self.verifyEqual(self.p.getPositionalArgs, {'pos1';'pos2'});
            self.verifyTrue(isempty(setdiff(self.p.getOptionalArgs,...
                {'--help'; '-h'; '--opt1'; '-o'; '--opt2'; '--opt3'; ...
                 '--config'})));
            % pos1=10, pos2=200, opt1='default1', opt2=1, opt3='default3'
            argInfo = self.p.getArgInfo('pos1');
            self.verifyEqual(argInfo.default, 10, ['Incorrect default for ' ...
                                'argument pos1']);
            argInfo = self.p.getArgInfo('pos2');
            self.verifyEqual(argInfo.default, 200, ['Incorrect default for ' ...
                                'argument pos2']);
            argInfo = self.p.getArgInfo('--opt1');
            self.verifyEqual(argInfo.default, 'default1', ['Incorrect default for ' ...
                                'argument pos1']);
            argInfo = self.p.getArgInfo('--opt2');
            self.verifyEqual(argInfo.default, 1, ['Incorrect default for ' ...
                                'argument opt2']);
            argInfo = self.p.getArgInfo('--opt3');
            self.verifyEqual(argInfo.default, 'default3', ['Incorrect default for ' ...
                                'argument pos1']);
         end

         function testFlagTrue(self)
             param = struct('name', '--myflag',...
                 'action', 'store_true',...
                 'help', 'Flag');
             self.p.add(param);
             res = self.p.parse('--myflag');
             self.verifyEqual(res.myflag, true);
         end
         
         function testFlagFalse(self)
             param = struct('name', '--myflag',...
                 'action', 'store_false',...
                 'help', 'Flag');
             self.p.add(param);
             res = self.p.parse('--myflag');
             self.verifyEqual(res.myflag, false);
         end
         
         function testFlagFalseNoArgs(self)
             param = struct('name', '--myflag',...
                 'action', 'store_false',...
                 'help', 'Flag');
             self.p.add(param);
             res = self.p.parse();
             self.verifyEqual(res.myflag, false);
         end
         function testFlagWithAdditionArg(self)
             param = struct('name', {'--myflag', '--key'},...
                 'action', {'store_false','store'},...
                 'help', {'Flag', 'keyvalue'},...
                 'default', {true, 0});
             self.p.add(param);
             res = self.p.parse('--myflag', '--key', 10);
             self.verifyFalse(res.myflag, 'myflag is not false');
             self.verifyEqual(res.key, 10);
         end
         
%         function testRequiredArg(self)
%             param = struct('name', '--foo',...
%                 'default', 10,...
%                 'help', 'parameter foo',...
%                 'isrequired', true);
%             self.p.add(param);
%             try 
%                 res = self.p.parse();
%                 assert(false);
%             catch ME
%                 self.verifyEqual(ME.identifier, 'mortar:common.ArgParse:MissingRequired');
%             end
%         end
        
%function testChoicesRange(self)
%    param = struct('name', '--foo',...
%                   'default', 5,...
%                   'choices', '1:10',...
%                   'help', 'parameter foo');
%    self.p.add(param);
%    % valid input
%    res = self.p.parse('--foo', 8.5);
%    assertElementsAlmostEqual(res.foo, 8.5);
%    
%    % invalid input
%    try
%        self.p.parse('--foo', '9.5');
%    catch ME
%        self.verifyEqual(ME.identifier, 'mortar:common:ArgParse:InvalidChoice')
%    end
%end

    end
    
    
end
