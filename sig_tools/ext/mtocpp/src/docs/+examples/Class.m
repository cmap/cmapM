classdef Class
    % Doxygen documentation guidlines example class
    %
    % This is the documentation guideline file for class and function
    % documentation. KerMor uses 'doxygen' and a custom tool 'mtoc' to
    % create the documentation from the source files. Doxygen has specific
    % tags to enable easy documentation formatting/layout within the source
    % files. Doxygen commands always begin with an at-character(\@) OR a
    % backslash(\\).
    %
    % For a full list of commands supported by doxygen look up
    % http://www.stack.nl/~dimitri/doxygen/commands.html.
    %
    % @section dg_formatting mtoc++ Formatting commands
    % These commands are available to you within class and function
    % comments.
    %
    % The doxygen filter provides the following shortcuts for non-default text
    % content: 
    % - @verbatim 'word' @endverbatim results in the output: 'word',
    % - @verbatim ` \sum_{n=0}^N \frac{1}{n} ` @endverbatim results in the
    %   output: ` \sum_{n=0}^N \frac{1}{n} ` and
    % - @verbatim `` \sum_{n=0}^N \frac{1}{n} `` @endverbatim results in the
    %   output: `` \sum_{n=0}^N \frac{1}{n} ``
    %
    % You therefore need to be careful with the use of characters @verbatim ' `
    % @endverbatim If you want to say something about the transposed of a Matrix
    % 'A', better do it in a Tex-Environment as `A' * B'` or in a verbatim/code
    % environment as @code A' * B' @endcode
    %
    % @note These shortcuts are provided in mtoc as a replacement of the
    % default doxygen @verbatim @c @f$, @f$ @f[, @f] @endverbatim in order to
    % increase readability in the default matlab documentation output created
    % by 'doc' or 'help'.
    %
    % Paragraphs starting with a line ending with a double-colon:
    % are started with a bold title line
    %
    % If, however, a double-colon at the end of a line is succeeded by: 
    % whitespace characters, like spaces or tabulators the line is not written in a
    % bold font.
    % @attention The auto-indentation command 'STRG+I' removes any
    % empty spaces after a line, so "Sometext: " will become "Sometext:"
    % and will be treated by doxygen as paragraph!
    %
    % Linking to other files and classes:
    % The matlab commands "See also" and "See also:" are also recognized by
    % mtoc++ and translated to the doxygen @@sa tag.
    %
    % @section doxygen_useful Further useful doxygen formatting shortcuts
    %
    % - Words prepended by @@b are written in a @b bold font.
    % - Words prepended by @@em are written in an @em emphasized font.
    %
    % Blocks starting with @@verbatim or @@code and are ended with @@endverbatim or
    % @@endcode are written unformatted in a type-writer font and are not
    % interpreted by doxygen.
    %
    % Example:
    % @verbatim
    %                /| |\
    %               ( |-| )
    %                ) " (
    %               (>(Y)<)
    %                )   (
    %               /     \
    %              ( (m|m) )  hjw
    %            ,-.),___.(,-.\`97
    %            \`---\'   \`---\'
    % @endverbatim
    %
    % Listings can be added by prepending lines with a dash(-)
    %  - list 1 item which can also include
    %   newlines
    %  - list 2 item
    %    - and they can be nested
    %    - subitem 2
    %    .
    %  - list 3 item
    %
    % and they are ended by an empty documentation line.
    %
    % Enumerations can be added by prepending lines with a dash and hash (-#)
    %  -# first item
    %  -# second item
    %  -# third item
    %

    properties(SetAccess=private)

        % Some comment on the property SomeClass.
        %
        % Properties can have specified types by use of one of the keyword
        % strings "of type" or "@type" in its documentation header or
        % documentation block. The word followed by this keyword string is
        % interpreted as the typename.
        %
        % The "of type" keyword only works if the
        % option "ENABLE_OF_TYPE_PARSING" is enabled and only in the first two
        % lines of the documentation block.
        %
        % @type Class
        %
        % See also: Class
        SomeClass = Class;
    end
    
    properties
        % Summary comment for SomeProp of type int
        %
        % Detailed comment for SomeProp. Here you can write more detailed
        % text for the SomeProp property.
        %
        % @default 0 @type integer
        SomeProp = 0;
        
        % Some row vector property.
        %
        % @type rowvec @default [1 2 3]
        %
        MyRowVec = [1 2 3]; 
    end
    
    properties(Dependent)
        % Short description for a dependent property.
        %
        % Equals SomeProp times five.
        %
        % @type integer @default 0
        %
        % See also: SomeProp
        % @see SomeProp
        SomeDepProp;
    end
    
    methods
        
        function this = Class
            % This a class constructor
        end
        
        function set.SomeProp(this, value)
            % Brief setter method description
            %
            % More details on the setter
            this.SomeProp = value;
        end
        
        function v = get.SomeProp(this)
            % Getter brief description
            %
            % More details on the getter!
            v = this.SomeProp;
        end
        
        function v = get.SomeDepProp(this)
            v = this.SomeProp * 5;
        end
        
        function rv = example_function(this, param1, param2)%#ok
            % function rv = example_function(this, param1, param2) is ignored
            % First line: short description text for example function
            %
            % After the first empty documentation line, paragraphs of the detailed
            % description begin.
            %
            % Lines beginning with the words "Parameters" or "Return values" start a block
            % of argument respectively return argument descriptions.
            %
            % Parameters:
            %  param1: first parameter of type double
            %  param2: second parameter with description @type Class @default []
            %          
            %
            % Parameters and return values can have specified types by use of
            % one of the keyword strings "of type" or "@type" in its
            % documentation block. The word followed by this keyword string is
            % interpreted as the typename.
            %
            % The "of type" keyword only works if the option
            % "ENABLE_OF_TYPE_PARSING" is enabled and only in the first two
            % lines of the documentation block.
            %
            % Return values:
            %  rv: return value @type barType
            %
            % References to other classes/members/properties can be made in
            % the matlab-fashion via
            % See also:
            % SomeProp noRealArguments
            %
            % or using the <tt> @@see </tt> doxygen command
            % @see SomeProp noRealArguments
            %
            % @note There is no technical difference as the 'See also'
            % keyword is simply replaced by @@see upon parsing. It is just
            % a convenience implementation.

            % After the first non-comment line the function body begins:

            %| After the first non-comment line, doxygen stops parsing
            % comments. An exception are comment blocks starting with '%%|', which
            % are interpreted as doxygen documentation blocks by mtoc++ and can
            % include doxygen commands like @@todo : 
            
            %| @todo There needs to be done something in this file. (included
            % after main comment block)
            sdflkdjsf
        end

        function [ret1, ret2, ret3] = many_return_args(this, arg1, arg2)%#ok
            % This is a base function with three left hand side arguments!
            %
            % This are function details described in the class
            % Class. To all three return values, one can attach type
            % information and documentation.
            %
            % Parameters:
            %  arg1:     A variable of type fooType.
            %  arg2:     A variable of type fooType.
            %
            % Return values:
            %   ret1:    A return value of type fooType.
            %   ret2:    A return value of type Class.
            %   ret3:    A return value with no specified type.
            %
            %
            % Blah. Blah.
            returnarg = arg1;
        end
        
        function returnarg = iwillbeoverridden(this, arg1, arg2)%#ok
            % This is a base function which will be overridden in a
            % subclass!
            %
            % This are function details described in the class
            % Class.
            %
            % Parameters:
            %  arg1:     A variable of type matrix . The type information for
            %            this parameter is also copied to inherited classes if
            %            @@copydoc or @@copydetails are used.
            %  arg2:     A variable of type matrix . The type information for
            %            this parameter is also copied to inherited classes if
            %            @@copydoc or @@copydetails are used. 
            %
            % Blah. Blah.
            returnarg = arg1;
        end
    end
    
    methods(Sealed, Access=protected)
        function noRealArguments(this)
            % This is the function brief description.
            %
            % Here are more details on the no real arguments function.
            % And even some more!
            %
            % @change{0,1,dw,2011-03-22} You can even specify/log changes
            % on a function or property level!
        end
    end

    events
        % This is the Test event's commentary.
        Test;

        UndocumentedEvent;
    end
end

