function [aoc,x,f] = mkrec(e,varargin)
% MKREC Regression Error Characteristic Curve
%   MKREC(e,varargin) will draw the error characteristic curve for a single
%   or multiple models. The REC curve is similar to a ROC curve in that you
%   can evalute graphically the trade offs between expected error and
%   degree of accuracy. 
%   Inputs: 
%       e : A vector of loss measure between observed and inferred, i.e.
%       the absolute deviation or squared difference. 
%       varargin: 
%           'spec' : line specification, default = 'b'
%           'type' : x-axis label, default = 'x'
%           'show' : logical indicator, indicates whether or not the REC
%           should be plotted, default = 1
%   Outputs:
%       aoc : The area above the REC curve. Scalar if e is a vector and
%       multidemsional if e is a matrix. Elements are consistent with the
%       input e
%       [x,f] : output from the ecdf(aoc) call
%       Note: In the case that e is a vector, a plot is drawn showing the
%       REC curve for that particular model fit. In the case that e is a
%       matrix, the ecdf of all AOC values is plotted. ALSO, if a
%       matlabpool session is open then evaluation of a matrix e will be
%       done in parallel, using parfor
% 
%   See also parfor, matlabpool
% 
% Author: Brian Geier, Broad 2010

pnames = {'spec','type','show'}; 
dflts = {'b','x',1}; 

arg = parse_args(pnames,dflts,varargin{:}); 

% print_args(toolName,1,arg); 

if size(e,2) == 1
    [f,x] = ecdf(e); 
    aoc = max(x) - AUC(x,f); % e is on (0 , inf) 

    if arg.show
        figure
        font_size = 15; 
        stairs(x,f,arg.spec)

        grid on 
        xlabel(arg.type,'FontSize',font_size)
        ylabel('F(x)','FontSize',font_size)
        set(gca,'FontSize',font_size,'YTick',0:0.1:1)

    end
else
    aoc = zeros(size(e,2),1) ;
    parfor i = 1 : size(e,2)
        ix = isnan(e(:,i)); 
        aoc(i) = mkrec(e(~ix,i),'show',0); 
    end
    
    if arg.show
        figure
        font_size = 15; 
        [f,x] = ecdf(aoc); 
        stairs(x,f,arg.spec)

        grid on 
        xlabel('Expected Loss','FontSize',font_size)
        ylabel('F(x)','FontSize',font_size)
        set(gca,'FontSize',font_size,'YTick',0:0.1:1)
    end
end