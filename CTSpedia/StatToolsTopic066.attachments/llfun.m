function [llpred, hyll, varll, nsing]=llfun(x,y,n,h,mpred,xpred,vary,epsilon)
% give the  predicted value using local linear regression

nsing=zeros(1,mpred);
varll=zeros(1,mpred);
hyll=zeros(1,mpred);
for ii=1:mpred
    w1=zeros(1,n);
    for j=1:n
        tmp(j)=x(j)-xpred(ii);
        arg=tmp(j)/h;
        if abs(arg)<1
            w1(j)=0.75*(1-arg^2)/h;
            %nhd=nhd+1;
        end
%         s0=s0+w1(j);
%         s1=s1+w1(j)*tmp;
%         s2=s2+w1(j)*tmp*tmp;
%         t0=t0+w1(j)*y(j);
%         t1=t1+w1(j)*y(j)*tmp;
    end
    s0=sum(w1);
    s1=sum(w1.*tmp);
    s2=sum(w1.*tmp.*tmp);
    t0=sum(w1.*y);
    t1=sum(w1.*tmp.*y);
    delta=s2*s0-s1^2;
    if delta==0
        delta=epsilon;
        nsing(ii)=1;
    end
%     for j=1:n
%         tmp=x(j)-xpred(ii);
%         tp1=s2*w1(j);
%         tp2=s1*tmp*w1(j);
%         varll(ii)=varll(ii)+(1/delta*(tp1-tp2))^2*vary;
%         hyll(ii)=hyll(ii)+(1/delta*(tp1-tp2))*y(j);
%     end
    varll(ii)=sum((1/delta*(s2*w1-s1*tmp.*w1)).^2*vary);
    hyll(ii)=sum((1/delta*(s2*w1-s1*tmp.*w1)).*y);
    llpred(ii)=(s2*t0-s1*t1)/delta;
end