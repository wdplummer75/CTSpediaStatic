function [lcpred, hylc, varlc,nsing]=lcfun(x,y,n,h,mpred,xpred, vary,epsilon)
% give the predicted value using local cubic regression

nsing=zeros(1,mpred);
varlc=zeros(1,mpred);
hylc=zeros(1,mpred);
for ii=1:mpred
    w1=zeros(1,n);
    s0=0; s1=0; s2=0; s3=0; s4=0; s5=0; s6=0; t0=0; t1=0; t2=0; t3=0;
    for j=1:n
        tmp=x(j)-xpred(ii);
        arg=tmp/h;
        if abs(arg)<1
            w1(j)=0.75*(1-arg^2)/h;
            %nhd=nhd+1;
        end
        
        s0=s0+w1(j);
        s1=s1+w1(j)*tmp;
        s2=s2+w1(j)*tmp^2;
        s3=s3+w1(j)*tmp^3;
        s4=s4+w1(j)*tmp^4;
        s5=s5+w1(j)*tmp^5;
        s6=s6+w1(j)*tmp^6;
        t0=t0+w1(j)*y(j);
        t1=t1+w1(j)*y(j)*tmp;
        t2=t2+w1(j)*y(j)*tmp^2;
        t3=t3+w1(j)*y(j)*tmp^3;
    end
    b0=-s4*s4*s4+ 2*s3*s4*s5 - s2*s5*s5 - s3*s3*s6 + s2*s4*s6; 
    b1=s3*s4*s4 - s3*s3*s5 - s2*s4*s5 + s1*s5*s5 + s2*s3*s6 - s1*s4*s6;
    b2=-s3*s3*s4 + s2*s4*s4 + s2*s3*s5 - s1*s4*s5 - s2*s2*s6 + s1*s3*s6;
    b3=s3*s3*s3 - 2*s2*s3*s4 + s1*s4*s4 + s2*s2*s5 - s1*s3*s5;
    temp1=s3*s3*s3*s3- 3*s2*s3*s3*s4 + s2*s2*s4*s4 + 2*s1*s3*s4*s4 - s0*s4*s4*s4 + 2*s2*s2*s3*s5 - 2*s1*s3*s3*s5 - 2*s1*s2*s4*s5; 
    temp2=2*s0*s3*s4*s5 + s1*s1*s5*s5 - s0*s2*s5*s5 -s2*s2*s2*s6 + 2*s1*s2*s3*s6 - s0*s3*s3*s6 - s1*s1*s4*s6 + s0*s2*s4*s6; 
    delta=temp1+temp2;
    if delta==0
        delta=epsilon;
        nsing(ii)=1;
    end
    for j=1:n
        tmp=x(j)-xpred(ii);
        tp0=b0*w1(j);
        tp1=b1*w1(j)*tmp;
        tp2=b2*w1(j)*tmp^2;
        tp3=b3*w1(j)*tmp^3;
        varlc(ii)=varlc(ii)+(1/delta*(tp0+tp1+tp2+tp3))*(1.0/delta*(tp0+tp1+tp2+tp3))*vary;
        hylc(ii)=hylc(ii)+(1.0/delta*(tp0+tp1+tp2+tp3))*y(j);
    end
    lcpred(ii)= (b0*t0+b1*t1+b2*t2+b3*t3)/delta;
end