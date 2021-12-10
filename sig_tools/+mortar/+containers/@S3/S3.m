classdef S3 < handle
    % Class for Amazon S3 service
    
    % Dependencies: JetS3t java toolkit
    % Author: Rajiv Narayan
    
    properties (Access = private)
        % S3 communiction object
        S3_
    end
    
    % Constants
    properties(Constant = true, GetAccess=private)
        S3_JARPATH = fullfile(fileparts(mfilename('fullpath')),...
                                '../../../ext/jars');
                            
        S3_JARLIST = {'commons-codec-1.3.jar';...
                      'commons-httpclient-3.1.jar';...
                      'commons-logging-1.1.1.jar';...
                      'java-xmlbuilder-0.4.jar';...
                      'log4j-api-2.15.0.jar';...
                      'log4j-core-2.15.0.jar';...
                      'jets3t-0.8.1a.jar'};
    end
    
    % Public methods
    methods
        function obj = S3(varargin)
            % Constructor
            obj.importDriver_();
            if nargin
                obj.login(varargin{:});
            end
        end
        
%         function delete(obj)
%             % Destructor
%             try                
%             catch e
%             end
%         end
        
        function status = login(obj, awsCredentials)
            % 
            narginchk(2, 2);
            obj.S3_ = org.jets3t.service.impl.rest.httpclient.RestS3Service(awsCredentials);
            
            status = false;
            try
                obj.S3_.listAllBuckets;
                status = true;
            catch e
                disp(e);
                error('Could not login to S3, are the credentials valid?');
            end
            
        end
        
        function buckets = listBuckets(obj)
            % Return cell array of all buckets
            bucketsObject = obj.listBucketsObject;
            nb = length(bucketsObject);
            buckets = cell(nb, 1);
            for ii=1:nb
                buckets{ii} = char(bucketsObject(ii).getName);                
            end
        end
        
        function bucketsObject = listBucketsObject(obj)
            % Return S3Bucket Objects belonging to S3 user
            bucketsObject = obj.S3_.listAllBuckets;
        end
        
        function tf = isBucket(obj, bucketName)
            % Check if bucket(s) are valid and accessible            
            if ischar(bucketName)
                bucketName = {bucketName};
            end
            nb = length(bucketName);
            tf = false(nb, 1);
            for ii=1:nb
                tf(ii) = obj.S3_.isBucketAccessible(bucketName{ii});
            end
        end
        
        function objectsList = listObjects(obj, bucketName, objectPrefix, delimiter)
            % List Objects in a bucket
            % listObjects(bucketName, objectPrefix, delimiter)
            % listObjects(bucketName) list all objects in a bucket
            
            narginchk(2, 4);
            nin = nargin;
            if isequal(nin, 2)
                assert(ischar(bucketName), 'bucketName should be a string');
                objects = obj.S3_.listObjects(bucketName);
            elseif isequal(nin, 4)
                assert(ischar(objectPrefix), 'objectPrefix should be a string');
                assert(ischar(delimiter), 'delimiter should be a string');
                objects = obj.S3_.listObjects(bucketName, objectPrefix, delimiter);
            end
            nobjects = length(objects);
            objectsList = cell(nobjects, 1);
            for ii=1:nobjects
                objectsList{ii} = char(objects(ii).getKey);
            end            
        end
        
        function tf = isObjectInBucket(obj, bucketName, objectKey)
            % Check for existence of keys in a bucket
            narginchk(3,3);
            assert(ischar(bucketName), 'Bucket name should be a string');
            assert(ischar(objectKey) || iscell(objectKey), 'Object key should be a string or cell array');
            if ischar(objectKey)
                objectKey = {objectKey};
            end
            nk = length(objectKey);
            tf = false(nk, 1);
            for ii=1:nk
                tf(ii) = obj.S3_.isObjectInBucket(bucketName, objectKey{ii});
            end
            
        end
        
        function [textData, status] = readTextObject(obj, bucketName, objectKey)
            % Read S3 object into string            
            narginchk(3, 3);
            downloadedObject =  obj.S3_.getObject(bucketName, objectKey);            
            textData = char(org.jets3t.service.utils.ServiceUtils.readInputStreamToString(...
                        downloadedObject.getDataInputStream(), 'UTF-8'));

            status = true;
        end
        
        function [outPath, status] = downloadObject(obj, bucketName, objectKey, outPath)
            % Download S3 object(s) to local filesystem
            narginchk(4, 4);
            assert(ischar(bucketName), 'Bucket name should be a string');
            assert(ischar(objectKey), 'Object key should be a string');
            assert(ischar(outPath), 'outFile should be a string');
                        
            % verify if object(s) exist
            status = false;            
            isObjectExists = obj.isObjectInBucket(bucketName, objectKey);
            if isObjectExists
                simpleThread = org.jets3t.service.multi.SimpleThreadedStorageService(obj.S3_);                
                downloadPackage = javaArray('org.jets3t.service.multi.DownloadPackage', 1);
                objectArray = javaArray('java.lang.String', 1);
                objectArray(1) = java.lang.String(objectKey);                 
                s3Objects = simpleThread.getObjects(bucketName, objectArray);
                
                if mortar.common.FileUtil.isfile(outPath, 'dir')                    
                    % save the object using terminal part of key
                   [~, fileName, fileExt]=fileparts(char(s3Objects(1).getKey));
                   outPath = fullfile(outPath, [fileName, fileExt]); 
                end
                downloadPackage(1) = org.jets3t.service.multi.DownloadPackage(s3Objects(1),...
                        java.io.File(outPath));                                                                                                                                          
                simpleThread.downloadObjects(bucketName, downloadPackage);
                
                status = true;
            else                
                error('S3 Object not found: %s', objectKey);
            end
        end
        
        function status = downloadObjects(obj, bucketName, objectKey, outPath)
            % Download multiple S3 objects to local filesystem
            narginchk(4, 4);
            assert(ischar(bucketName), 'Bucket name should be a string');
            assert(ischar(objectKey) || iscell(objectKey),...
                'Object key should be a string or cell array');
            assert(ischar(outPath), 'outFile should be a string');
            if ischar(objectKey)
                objectKey = {objectKey};
            end
                        
            % verify if object(s) exist
            status = false;
            no = length(objectKey);
            isObjectExists = obj.isObjectInBucket(bucketName, objectKey);
            if all(isObjectExists)
                % create simple multithreading service for downloads                
                simpleThread = org.jets3t.service.multi.SimpleThreadedStorageService(obj.S3_);                

                % setup multi downloads                
                downloadPackage = javaArray('org.jets3t.service.multi.DownloadPackage', no);
                objectArray = javaArray('java.lang.String', no);
                for ii=1:no
                    objectArray(ii) = java.lang.String(objectKey{ii});
                end
                
                s3Objects = simpleThread.getObjects(bucketName, objectArray);
                
                for ii=1:no
                    downloadPackage(ii) = org.jets3t.service.multi.DownloadPackage(s3Objects(ii),...
                        java.io.File(fullfile(outPath, char(s3Objects(ii).getKey))));
                end
                simpleThread.downloadObjects(bucketName, downloadPackage);
                status = true;
            else
                disp(objectKey(~isObjectExists));
                error('Some objects not found');
            end
        end
        
    end

    
    % Static methods
    methods(Static=true)
        function credentials = AWSCredentials(varargin)
            nin = nargin;
            if isequal(nin, 1)
                % file or struct
                if mortar.common.FileUtil.isfile(varargin{1})
                    error('Files not supported yet');
                elseif isstruct(varargin{1})
                    if all(isfield(varargin{1}, {'access_key','secret_key'}))
                        access_key = varargin{1}.access_key;
                        secret_key = varargin{1}.secret_key;
                    else
                        error('Expected fields {access_key, secret_key}, not found')
                    end
                end
            elseif isequal(nin, 2)
                % strings
                assert(ischar(varargin{1}) && ischar(varargin{2}), 'Expected strings as input');
                access_key = varargin{1};
                secret_key = varargin{2};
            else
                error ('Invalid inputs')
            end
            credentials = org.jets3t.service.security.AWSCredentials(access_key, secret_key);
        end
        
        function credentials = AWSCredentialsFromFile(filename, password)
            % load credentials from encrypted file
            narginchk(2, 2);
            assert(mortar.common.FileUtil.isfile(filename), 'Credential file not found');
            assert(ischar(password), 'Password is not a string');            
            credentials = org.jets3t.service.security.AWSCredentials.load(password,...
                java.io.File(filename));
        end
        
        function credentials = AWSCredentialsFromEnv()
            % load credentials from environtment variables
            % AWS_ACCESS_KEY, AWS_SECRET_KEY
            [~, access_key]=system('bash -c ''echo -n ${AWS_ACCESS_KEY}''');
            [~, secret_key]=system('bash -c ''echo -n ${AWS_SECRET_KEY}''');
            
            credentials = org.jets3t.service.security.AWSCredentials(access_key, secret_key);            
        end        
        
        function [bucket, object] = URIParse(s3uri)
            
            bucket = '';
            object = '';
            tokens = regexpi(s3uri, '(s3|http|https)://([^\/]+)/(.*)', 'tokens');
            
            if ~isempty(tokens)
                tokens = tokens{1};
                nt = length(tokens);
                if isequal(nt, 3)                    
                    bucket = tokens{2};
                    object = tokens{3};
                    bucket = regexprep(bucket, '\.s3\.amazonaws\.com$', '');                    
                end
            end
        end
                
        function [outFile, status] = get(s3URI, outFile, overwrite)
            % GET download an Amazon S3 object.
            % GET(S3URI, OUTFILE, OVERWRITE) Downloads the object specified by S3URI and saves
            % it to th
            %
            % Example: get('s3://data.lincscloud.org/index.html','index.html')
            
            %% TODO implement overwrite check
            
            assert(ischar(s3URI), 'S3 URI should be a string');
            assert(ischar(outFile), 'Outfile should be a string');
            assert(islogical(overwrite), 'Overwrite should be logical');
            
            [bucket, object] = mortar.containers.S3.URIParse(s3URI);
            awsCredentials = mortar.containers.S3.AWSCredentialsFromEnv;
            s3 = mortar.containers.S3(awsCredentials);
            [outFile, status] = s3.downloadObject(bucket, object, outFile);            
            
        end
        
        function [outText, status] = read(s3URI)
            % READ an Amazon S3 object into a string.
            % S = READ(S3URI) Reads object specified by S3URI into a string
            %
            % Example: get('s3://data.lincscloud.org/index.html','index.html')
            
            assert(ischar(s3URI), 'S3 URI should be a string');            
            
            [bucket, object] = mortar.containers.S3.URIParse(s3URI);
            awsCredentials = mortar.containers.S3.AWSCredentialsFromEnv;
            s3 = mortar.containers.S3(awsCredentials);
            [outText, status] = s3.readTextObject(bucket, object);
        end
        
        
    end
    
    % Private methods
    methods(Access = private)
        function importDriver_(obj)
            % Load S3 driver
            mortar.common.Util.addJar(obj.S3_JARLIST, obj.S3_JARPATH, true);
        end        
    end
    
end
