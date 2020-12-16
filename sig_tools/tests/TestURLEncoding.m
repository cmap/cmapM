classdef TestURLEncoding < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        tolerance = 1e-6;
    end
    methods(TestMethodSetup)
        
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        
        function testEncodeUrl(testCase)
            url_in='http://data.clue.io/api/jasiedu#123@broadinstitute.org/gutc results/Dec_14_2016/my_analysis.sig_gutc_tool.5851b06c87a167375cecbbe5/config.yaml';
            url_encoded='http://data.clue.io/api/jasiedu%23123%40broadinstitute.org/gutc+results/Dec_14_2016/my_analysis.sig_gutc_tool.5851b06c87a167375cecbbe5/config.yaml';
            % encode the url
            encoded = mortar.util.File.encodeURL(url_in);
            % decode the encoded url
            decoded = mortar.util.File.decodeURL(encoded);
            testCase.assertEqual(encoded, url_encoded, 'Encode mismatch');
            testCase.assertEqual(url_in, decoded, 'Decode mismatch');
        end       
        
    end
end