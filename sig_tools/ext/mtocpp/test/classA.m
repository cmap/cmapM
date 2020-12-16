% unnecessary comments in front of class

classdef(Sealed=Initialize) classA < general.reference.classB & a.b.c & ...
    d.e.f ...
    & g.h.i ...
    & grid.rect.rectgrid;
  % help for classA
  %
  % bigger help for classA

  properties ( SetAccess = private, GetAccess = protected, Transient);% garbage comment

    mixed_access; % variable of type gridbase.gridbase storing a grid.

    % longer help with `default` value
    % what is this??
    %
    % can we do some special stuff??
    % @verbatim
    %  a= b;
    %  c= d;
    % @endverbatim
    mixed_access2 = 'test';

    % This documentation is a test for the type keyword.
    %
    % This variable has a special type
    % @type SpecialType @default empty string
    DataStoreDirectory = '';

    SomeProp = struct('xi',[],'ti',[],'mui',[]);

    SomeOtherProp = struct(...
      'xi', [], 'ti', ...
      []);

    % variable with very long default value
    SteadyStates = [[0; 9.8153e-4; 0.1930]*models.pcd.BasePCDSystem.xa0...
      [0; 3.0824e-5; 0.1713]*models.pcd.BasePCDSystem.ya0...
      [.2; 0.1990; 0.0070]*models.pcd.BasePCDSystem.xi0...
      [.2; 0.2; 0.0287]*models.pcd.BasePCDSystem.yi0];

    Property_without_semicolon   % commented anyways

  end; % garbage comment

  properties (Constant); % garbage comment
    aConstant = 1; % help text

    % help text for bConstant
    bConstant = 2;

    cConstant = 3; % help text for cConstant

    vectorConst = [ 1; 2; 3 ]

    % test
    dConstant = { [ 1, 2; 3, 4]; 'test'; [ 1 2; [ [3 [3 [3 4] 4] ] ] ] };

    dConstant = struct('a', [], 'b', {'c', 'd'}, 'e', [1 2 3]);
  end

  properties
    public_access; % short help for public_access

    % longer help for public_access2
    public_access2;

    complexpropertywithoutsemicolon = [['af]adgdg'
        'adgadg']]
    followingpropwithoutsemicolon = 4
    antoheroneWITH;

    % with comments version!
    complexpropertywithoutsemicolon_c = [['af]a"§/$"''dgdg'
        'adgadg']]
    % with comments version! GRR
    followingpropwithoutsemicolon_c = 4
    % with comments version
    antoheroneWITH_c;
  end

  properties (Access = protected)
    protected_access; % short help for protected_access

    % longer help text for protected_access2
    protected_access2;
  end

  methods(Hidden = True); % garbage comment

    function obj = foo(a,b,c);
      % brief doc for foo

      function private_function

        pause;
      end

      bar;
    end; % garbage comment

    % comment
    %  zweite Zeile

    function obj = bar(c,d,e);
      % brief doc for bar

      foo;
    end;

    % last function comment above
    %
    % with main docu block
    function obj = foobar()
    % brief for foobar
    %
    % detail for foobar

     test

    end %garbage comment

    % this is only a declaration without definition of a method
    ret=mdecl(a,b);;;;;;;;
    % this is only a declaration without definition of a method behind

    function obj = classA(param1, param2)
      % bigger constructor
    end;
  end; %garbage comment

  methods
    function value = get.protected_access(this)
      % getter enriching property help text of protected_access

      if a==b
        do something;
      % the following end needs to be indented correctly
      end % garble this correctly

%|
% \todo this is a test

    end

    function set.protected_access(this, value)
      % setter comment is parsed too

      a;
    end


    function set.DataStoreDirectory(this, ds)
      if ~isdir(ds)
        fprintf('Creating directory %s\n',ds);
        mkdir(ds);
      end
      setpref('KERMOR','DATASTORE',ds);
      this.DataStoreDirectory = ds;
      fprintf('Simulation and model data: %s\n',ds);
    end

    function set.protected_access2(this, value)

       a;
    end

  end

  methods (Static) ;;; % garbage comment
    function [a,b] = static_method(notthis,c,~)
      % a static method
    end

    function ret = test(auto_param,b,c)
      % @copybrief grid::rect::rectgrid::test()
      %
      % If copydetails/copydoc commands are used, "parameters" and "return
      % values" are ignored in the derived class, except for the strings
      % 'of type ...' which are used to define the parameter / return value
      % type.
      %
      % @copydetails grid::rect::rectgrid::test()
      %
      % Parameters:
      %   b: second argument in derived class (this is not shown!)
      %   c: object of type test2
    end
  end

  methods (Static, Abstract)
    % a static abstract method
    [a,b] = static_abstract_method(this, c);

  end

  methods (Abstract)

    % an abstract method comment above
    %
    % Parameters:
    %  d:  parameter 1
    %  e:  parameter 2
    %
    % Return values:
    %   a: test object of type
    %        classA.mixed_access which has a line break in it
    [a] = abstract_method(this,d,e);
    % an abstract method comment below
    %
    % further comments

    a = undocumented_abstract_method(t, b, f);

    [b,c,d] = another_undocumented_abstract_method(t, b, c);

    % documentation for next method
    c = followed_by_document_method(t, d, e);
  end

  events

    % a documented event
    documentedEvent

    undocumentedEvent
    followingUndocumentedEvent;
  end

end

