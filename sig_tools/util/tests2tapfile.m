function testResult = tests2tapfile(suitePath, tapFile)
% TESTS2TAPFILE Run unit tests and save results to a file in TAP format
% RES = TESTS2TAPFILE(suitePath, tapFile) Run tests in suitePath and 
%   output results to a tapFile in TAP format. suitePath can refer to a 
%   folder in which case all tests in that folder are run or a single test 
%   file

if isdirexist(suitePath)
    suite =  matlab.unittest.TestSuite.fromFolder(suitePath);
elseif isfileexist(suitePath,'file')
    suite =  matlab.unittest.TestSuite.fromFile(suitePath);
else
    error('suitePath: %s could not be found',suitePath)
end
runner = matlab.unittest.TestRunner.withTextOutput('Verbosity',  matlab.unittest.Verbosity.Detailed);
plugin =  matlab.unittest.plugins.TAPPlugin.producingOriginalFormat(matlab.unittest.plugins.ToFile(tapFile));
runner.addPlugin(plugin);

testResult = runner.run(suite);
dbg(1, '## Saved test results to : %s', tapFile);

end