classdef TestPermuteZs < matlab.unittest.TestCase
    properties (Constant)
    end

    properties
    end

    methods(TestMethodSetup)
        %setup conditions for the tests
    end
    
    methods(TestMethodTeardown)
        %cleanup after running the tests
    end

    methods(Test)
        function testOne(testCase)  % Test fails
            rid = {'1', '2', '3', '4'};
            cid = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'};
            mat = rand(length(rid), length(cid))
            chd = {'pert_id'};
            cdesc = {'p1', 'p2', 'p3', 'p1', 'p2', 'p3', 'p1', 'p2', 'p3'};
            ds = mkgctstruct(mat, 'rid', rid, 'cid', cid, 'chd', chd, 'cdesc', cdesc)

            niter = 10;
            [perm_stat, permzs] = permute_zs(ds, 3, 'ssn', 2, 'niter', niter)

            fprintf('permzs.chd:\n')
            permzs.chd
            fprintf('permzs.cid:\n')
            permzs.cid
            fprintf('permzs.cdesc:\n')
            permzs.cdesc
            fprintf('permzs.mat:\n')
            permzs.mat

            distil_id_index = ismember(permzs.chd, 'distil_id');
            testCase.assertTrue(any(distil_id_index));

            testCase.assertTrue(any(ismember(permzs.chd, 'sig_strength')));
            testCase.assertTrue(any(ismember(permzs.chd, 'cc_q75')));

            testCase.assertEqual(length(rid), length(permzs.rid));
            testCase.assertEqual(niter, length(permzs.cid));

            for ii = 1:length(permzs.cid)
                distil_id = permzs.cdesc{ii, distil_id_index};
                pipe_inds = strfind(distil_id, '|');
                testCase.assertEqual(2, length(pipe_inds));
            end
        end
    end
end

