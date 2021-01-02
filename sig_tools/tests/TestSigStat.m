classdef TestSigStat < matlab.unittest.TestCase
    properties
        file_path = fullfile(fileparts(mfilename('fullpath')), ...
            'assets','TestSigStat','modzs_gct_n3x978.gctx')

        espresso_path = '';

        ds = [];
    end

    methods(TestMethodSetup)
        function setupPath(testCase)
            addpath(fullfile(testCase.espresso_path, 'brew'));
        end

        function loadDataset(testCase)
            testCase.ds = parse_gctx(testCase.file_path)
        end
    end

    methods(Test)
        function obj = TestSigStat(espresso_path)
            obj.espresso_path = espresso_path;
        end

        % When running sigstat, should keep fields distil_ss_ngene
        %   and distil_tas.
        function testSigStatTas(testCase)
            [ss,~] = sigstat(testCase.ds);
            tas_scores = [ss(1:end).tas];
            ss_ngene_scores = [ss(1:end).sig_strength_ngene];

            testCase.verifyNumElements(tas_scores,3, ...
                'sigstat: distil_tas column is not length 3');
            testCase.verifyNumElements(ss_ngene_scores,3, ...
                'sigstat: distil_ss_ngene column is not length 3');
        end
    end
end
