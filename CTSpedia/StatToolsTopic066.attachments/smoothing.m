function [meanpred,hy,var,nsing]=smoothing(method,datax,datay,bandwidth,xpred,sigma,varargin)

if strcmp(method,'local linear')
    [meanpred,hy,var,nsing]=llfun(datax,datay,length(datax),bandwidth,length(xpred),xpred,sigma^2,99999);
elseif strcmp(method,'local cubic')
    [meanpred,hy,var,nsing]=lcfun(datax,datay,length(datax),bandwidth,length(xpred),xpred,sigma^2,99999);
elseif strcmp(method,'choi hall')
    [meanpred,hy,var,nsing]=chfun(datax,datay,length(datax),bandwidth,length(xpred),xpred,sigma^2,99999,varargin{1},varargin{2});
elseif strcmp(method,'double smoothing')
    [meanpred,hy,var,nsing]=dsfun(datax,datay,length(datax),bandwidth,length(xpred),length(xpred),xpred,xpred,sigma^2,99999);
end