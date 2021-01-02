function greek_alphabet
% GREEK_ALPHABET Display greek alphabet with Tex and ASCII codes
% Ref: http://www.mathworks.com/matlabcentral/answers/14751-greek-alphabet-and-latex-commands-not-a-question

greeks = ...
    {'ALPHA'      'A'         '\alpha'
    'BETA'       'B'         '\beta'
    'GAMMA'      '\Gamma'    '\gamma'
    'DELTA'      '\Delta'    '\delta'
    'EPSILON'    'E'         {'\epsilon','\varepsilon'}
    'ZETA'       'Z'         '\zeta'
    'ETA'        'H'         '\eta'
    'THETA'      '\Theta'    {'\theta','\vartheta'}
    'IOTA'       'I'         '\iota'
    'KAPPA'      'K'         '\kappa'
    'LAMBDA'     '\Lambda'   '\lambda'
    'MU'         'M'         '\mu'
    'NU'         'N'         '\nu'
    'XI'         '\Xi'       '\xi'
    'OMICRON'    'O'         'o'
    'PI'         '\Pi'       {'\pi','\varpi'}
    'RHO'        'P'         {'\rho','\varrho'}
    'SIGMA'      '\Sigma'    {'\sigma','\varsigma'}
    'TAU'        'T'         '\tau'
    'UPSILON'    '\Upsilon'  '\upsilon'
    'PHI'        '\Phi'      {'\phi','\varphi'}
    'CHI'        'X'         '\chi'
    'PSI'        '\Psi'      '\psi'
    'OMEGA'      '\Omega'    '\omega'};

h = figure('units','pixels','pos',[300,100,620,620],'Color','w');
axes('units','pixels','pos',[10,10,600,600],'Xcol','w','Ycol','w',...
    'Xtick',[],'Ytick',[],'Xlim',[0 6],'Ylim',[0,4]);

for r = 1:4
    for c = 1:6
        el = (r-1)*6 + c;
        % Title
        text(c-0.5,5-r,greeks{el,1},'fontsize',14,'fontname','FixedWidth',...
            'horizontal','center','vertical','cap')
        % Color cap latter in grey or black
        if strcmp(greeks{el,2}(1),'\')
            clr = [0, 0, 0];
        else
            clr = [0.65, 0.65, 0.65];
        end
        % Cap letter
        text(c-0.5,4.87-r,['$\rm{' greeks{el,2} '}$'],'fontsize',40,...
            'Hor','center','Ver','cap','Interp','Latex','Color',clr)
        % Lowercase letter/s (if two variants)
        if iscell(greeks{el,3})
            text(c-0.75,4.48-r,['$' greeks{el,3}{1} '$'],'fontsize',20,...
                'Hor','center','Interp','Latex')
            text(c-0.25,4.48-r,['$' greeks{el,3}{2} '$'],'fontsize',20,...
                'Hor','center','Interp','Latex')
            % Latex command
            text(c-0.82,4.3-r,['\' greeks{el,3}{1}],'fontsize',11,'FontN','FixedWidth',...
                'Hor','center','Ver','base')
            text(c-0.21,4.3-r,['\' greeks{el,3}{2}],'fontsize',11,'FontN','FixedWidth',...
                'Hor','center','Ver','base')
            
        else
            text(c-0.5,4.48-r,['$' greeks{el,3} '$'],'fontsize',20,...
                'Hor','center','Interp','Latex')
            text(c-0.5,4.3-r,['\' greeks{el,3}],'fontsize',12,'FontN','FixedWidth',...
                'Hor','center','Ver','base')
        end
        % ASCII code
        text(c-0.5,4.15-r, num2str(944+el),'color','b','Hor','center','Ver','base');
    end
    
end