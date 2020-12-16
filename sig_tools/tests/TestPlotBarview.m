classdef TestPlotBarview < matlab.unittest.TestCase
   properties (Constant)
   end

   properties
   end

   methods(TestMethodSetup)
   end

   methods(Test)
        function obj = TestPlotBarview(args)
        end

        function testOne(testCase)
           N = 374;
           data = rand(N, 1);
           mark_index = {122};
           columnlabel = 1;
           rid = cell(N, 1);
           rid(:) = {'J07'};
           title = 'Poscon Connectivity: 1 queries, 1 unique wells';
           name = 'poscon_query_wtcs';
           ylabelrt = 'CAL062_XC.L10_24H_X1_B24';

           plot_barview(data, 'mark_index', mark_index, ...
                'columnlabel', columnlabel, 'rid', rid, ...
		'title', title, ...
                'showfig', false, 'name', name, 'ylabelrt', ylabelrt)
        end
    end
end
