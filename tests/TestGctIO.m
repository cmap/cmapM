classdef TestGctIO < matlab.unittest.TestCase
    
    properties
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        gctx_file = 'gctv13_02.gctx';
        gct_file = 'matrix_with_na.gct';
        tolerance = 1e-4;
    end
    
    methods(TestMethodSetup)
    end
    methods(TestMethodTeardown)
    end
    methods(Test)
        
        function testCreateGCTX(self)
            % Create a GCTX file
            gctx_path = fullfile(self.asset_path, self.gctx_file);
            ds = cmapm.Pipeline.parse_gctx(gctx_path);
            gctx_outpath = tempname;
            ds2_file = cmapm.Pipeline.mkgctx(gctx_outpath, ds);
            ds2 = cmapm.Pipeline.parse_gctx(ds2_file);
            self.assertEqual(ds.mat, ds2.mat, 'AbsTol', self.tolerance);
        end

    end
end