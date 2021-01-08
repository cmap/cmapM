classdef SigToolify < handle
    
    properties
        % Package name for all sig tools
        SigToolPackage = 'mortar.sigtools';
        inventory_file = fullfile(mortarpath, 'toolchain', 'jenkins.prop');
    end
    
    methods(Static=true);
        function new(varargin)
            % NEW Create boilerplate files for a new sig tool.
            % NEW without arguments, will prompt the user for input.
            % NEW(ClassName, Description) will use the provided arguments to generate to files.
            % ClassName is a valid class name for the Sig Tool beginning with Sig.
            % e.g SigHClust
            toolObj = mortar.base.SigToolify;
            toolObj.new_(varargin{:});
        end
        
        function open(varargin)
            % OPEN Edit files associated with a sig tool.   
            % OPEN(ClassName)
            % See also EDIT.
           toolObj = mortar.base.SigToolify;
           toolObj.edit_(varargin{:});        
        end
        
        function edit(varargin)
            % EDIT Edit files associated with a sig tool.   
            % EDIT(ClassName)
           toolObj = mortar.base.SigToolify;
           toolObj.edit_(varargin{:});
        end
        
        function move(varargin)
            % EDIT Edit files associated with a sig tool.   
            % EDIT(ClassName)
           toolObj = mortar.base.SigToolify;
           toolObj.move_(varargin{:});
        end
        
        function remove(varargin)
            % REMOVE Delete files associated with a sig tool.
            % REMOVE(ClassName)
            toolObj = mortar.base.SigToolify;
            toolObj.delete_(varargin{:});
        end
        
        function close(varargin)
            % CLOSE Close open files in the editor.
            % CLOSE without arguments will prompt for a name
            % CLOSE(ClassName)
            
            toolObj = mortar.base.SigToolify;
            toolObj.close_(varargin{:});
        end
        
        function varargout = list(varargin)
            % LIST List available sig tools.
            % LIST without arguments prints a list of available sig tools
            % L = LIST Returns a cell array of sig tools.
           toolObj = mortar.base.SigToolify;
           if ~nargout
               toolObj.printList_(varargin{:});
           else               
            varargout(1) = {toolObj.list_(varargin{:})};
           end
        end
        
        function varargout = list_registry()
            % LIST_REGISTRY List sig tools in registry.
            % L = LIST Returns a cell array of registered tools.
            toolObj = mortar.base.SigToolify;            
            if ~nargout
                toolObj.list_registry_();
            else
                varargout(1) = {toolObj.list_registry_()};
            end
        end

        function register(varargin)
            % REGISTER Add tool to tool list
            % REGISTER without arguments prompts the user for tools to add
            % REGISTER(ClassName)
            toolObj = mortar.base.SigToolify;
            toolObj.register_(varargin{:});            
        end
        
        function deregister(varargin)
            % DEREGISTER Delete tool from tool list
            % DEREGISTER without arguments prompts the user for tools to
            % remove
            % DEREGISTER(ClassName)
            toolObj = mortar.base.SigToolify;
            toolObj.deregister_(varargin{:});            
        end
    end
    
    methods

    end
    methods(Access=protected)
        new_(obj, varargin);
        edit_(obj, varargin);
        delete_(obj, varargin);
        close_(obj, varargin);
        varargout = list_(obj, varargin);
        printList_(obj, varargin);
    end
end