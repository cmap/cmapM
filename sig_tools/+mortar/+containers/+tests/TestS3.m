classdef TestS3 < TestCase
    
    properties
        access_key= '';
        secret_key= '';
        enc_file = fullfile(fileparts(mfilename('fullpath')), 's3auth.enc');
        enc_password = 'L1Thousand';
        S3
    end
    
    methods
        function self = TestS3(name)
            % Constructor
            self = self@TestCase(name);

        end
        
        function setUp(self) %#ok<*MANU>
            % Setup (called before each test)
            awsCredentials = mortar.containers.S3.AWSCredentialsFromFile(self.enc_file, self.enc_password);
            self.S3 = mortar.containers.S3(awsCredentials);
        end
        
        function tearDown(self)
            % Called after each test
        end  
        
        function testCreate(self)
            % Create an S3 object            
            s3Object = mortar.containers.S3;
            assert(~isempty(s3Object));
        end
        
        function testCreateWithCredentials(self)
            % create s3 object and login with credentials
            awsCredentials = mortar.containers.S3.AWSCredentials(self.access_key, self.secret_key);
            s3Object = mortar.containers.S3(awsCredentials);
            assert(~isempty(s3Object));
        end
        
        function testCreateWithEncryptedCredentials(self)
            % create s3 object and login with encrypted  credentials file            
            awsCredentials = mortar.containers.S3.AWSCredentialsFromFile(self.enc_file, self.enc_password);
            s3Object = mortar.containers.S3(awsCredentials);
            assert(~isempty(s3Object));
        end
        
        function testListBuckets(self)
            % list all buckets
            buckets = self.S3.listBuckets;
            assert(~isempty(buckets));
        end
        
        function testIsBucket(self)
            % checks if buckets exist
            bucketList = {'data.lincscloud.org','does.not.exist'};
            tf = self.S3.isBucket(bucketList);
            assert(tf(1), 'expected %s to exist but was not found', bucketList{1});
            assert(~tf(2), 'expected %s to not exist, but reported as found', bucketList{2});
        end
   
        function testIsObjectInBucket(self)
            % checks for existence of keys
           bucketName = 'data.lincscloud.org';
           objectKey = {'index.html', 'missing'};
           tf = self.S3.isObjectInBucket(bucketName, objectKey);
           assert(tf(1), 'expected %s to exist but was not found', objectKey{1});
           assert(~tf(2), 'expected %s to not exist, but reported as found', objectKey{2});
            
        end
        
        function testDownloadSingleObject(self)
            % download an object to a local file
            bucketName = 'data.lincscloud.org';
            objectKey = 'index.html';
            outPath = fileparts(mfilename('fullpath'));            
            outFile = fullfile(outPath, objectKey);
            
            if mortar.common.FileUtil.isfile(outFile)
                delete(outFile);
            end
            [of, status] = self.S3.downloadObject(bucketName, objectKey, outFile);
            
            assert(isequal(status, 1), 'Status failed');
            assert(mortar.common.FileUtil.isfile(outFile),...
                'Error downloading file');
            
        end
        
        function testDownloadMultiObject(self)
            % download multiple objects to a local filesystem
            bucketName = 'data.lincscloud.org';
            objectKey = {'index.html', 'p100/index.html'};
            outPath = fileparts(mfilename('fullpath'));
            no = length(objectKey);
            outFile = cell(no, 1);
            for ii=1:no
                outFile{ii} = fullfile(outPath, objectKey{ii});
                if mortar.common.FileUtil.isfile(outFile{ii})
                    delete(outFile{ii});
                end
            end
            % download objects
            self.S3.downloadObjects(bucketName, objectKey, outPath);
            for ii=1:no
                assert(mortar.common.FileUtil.isfile(outFile{ii}),...
                    'Error downloading file: %s', outFile{ii});
            end
        end        
        
        function testURIParse(self)
            uri = {'s3://data.lincscloud.org/object';...
             's3://cmap_data/object/foo/test.txt';...
             'http://data.lincscloud.org/object';...
             'https://data.lincscloud.org/object';...
             };
            bucket = {'data.lincscloud.org';...
                      'cmap_data';...
                      'data.lincscloud.org';...
                      'data.lincscloud.org'};
            object = {'object';...
                      'object/foo/test.txt';...
                      'object';...
                      'object'};
            nuri = length(uri);
            for ii=1:nuri
                [b, o] = mortar.containers.S3.URIParse(uri{ii});
                assert(isequal(b, bucket{ii}),...
                    'Bucket name mismatch. Expected %s, got %s', bucket{ii}, b);
                assert(isequal(o, object{ii}),...
                    'Object name mismatch. Expected %s, got %s', object{ii}, o);
            end
        end
                
        function testListObjects(self)
            bucket = 'data.lincscloud.org';
            prefix = '';
            delimiter = '/';
            objectList = self.S3.listObjects(bucket, prefix, delimiter);
            assert(~isempty(objectList), 'no objects found');
            
        end
                
        function testReadTextObject(self)
            uri = 'http://data.lincscloud.org.s3.amazonaws.com/p100/index.html';
            [b, o] = mortar.containers.S3.URIParse(uri);
            [textObject, status] = self.S3.readTextObject(b, o);
            assert(isequal(status, 1), 'Status failed');
            assert(ischar(textObject), 'textObject is not a string');            
        end
        
    end
end