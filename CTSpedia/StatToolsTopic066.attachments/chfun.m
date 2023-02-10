function [chpred, hych, varch,nsing]=chfun(x,y,n,h,mpred,xpred,vary, epsilon,k2,lambda)
% give the predicted value using Choi & Hall's method

l=sqrt((1+2*lambda)*k2/(2*lambda));

nsing=zeros(1,mpred);
hych=zeros(1,mpred);
varch=zeros(1,mpred);
for i=1:mpred
    xgrid1(i)=xpred(i)-l*h;   
    xgrid2(i)=xpred(i)+l*h;  
    w0=zeros(1,n);
    w1=zeros(1,n);
    w2=zeros(1,n);
    s00=0; s01=0; s02=0; t00=0; t01=0;
    s10=0; s11=0; s12=0; t10=0; t11=0;
    s20=0; s21=0; s22=0; t20=0; t21=0;
    for j=1:n
        tmp0=x(j)-xpred(i);
        tmp1=x(j)-xgrid1(i);
        tmp2=x(j)-xgrid2(i);
        
        arg0=tmp0/h;
        arg1=tmp1/h;
        arg2=tmp2/h;
        if abs(arg0)<1
            w0(j)=0.75*(1-arg0^2)/h;
        end
        if abs(arg1)<1
            w1(j)=0.75*(1-arg1^2)/h;
        end
        if abs(arg2)<1
            w2(j)=0.75*(1-arg2^2)/h;
        end
        
        s00=s00+w0(j);
        s01=s01+w0(j)*tmp0;
        s02=s02+w0(j)*tmp0^2;
        t00=t00+w0(j)*y(j);
        t01=t01+w0(j)*y(j)*tmp0;
        
        s10=s10+w1(j);
        s11=s11+w1(j)*tmp1;
        s12=s12+w1(j)*tmp1^2;
        t10=t10+w1(j)*y(j);
        t11=t11+w1(j)*y(j)*tmp1;
        
        s20=s20+w2(j);
        s21=s21+w2(j)*tmp2;
        s22=s22+w2(j)*tmp2^2;
        t20=t20+w2(j)*y(j);
        t21=t21+w2(j)*y(j)*tmp2;
    end
    delta0=s02*s00-s01^2;
    delta1=s12*s10-s11^2;
    delta2=s22*s20-s21^2;

    if delta0==0
        delta0=epsilon;
        nsing(i)=1;
    end
    if delta1==0
        delta1=epsilon;
    end
    if delta2==0
        delta2=epsilon;
    end
    for j=1:n
        tmp0=x(j)-xpred(i);
        tmp1=x(j)-xgrid1(i);
        tmp2=x(j)-xgrid2(i);
        
        tp01=s02*w0(j);
        tp02=s01*w0(j)*tmp0;
        tp11=s12*w1(j);
        tp12=s11*w1(j)*tmp1;
        tp21=s22*w2(j);
        tp22=s21*w2(j)*tmp2;
        
        tempp0=1/delta0*(tp01-tp02);
        tempp1=1/delta1*(tp11-tp12);
        tempp2=1/delta2*(tp21-tp22);
        tempp=1/(1+2*lambda)*(lambda*tempp1+tempp0+lambda*tempp2);
        varch(i)=varch(i)+tempp*tempp*vary;
        hych(i)=hych(i)+tempp*y(j);
    end
    temp0=(s02*t00 - s01*t01)/delta0;              
    temp1=(s12*t10 - s11*t11)/delta1;      
    temp2=(s22*t20 - s21*t21)/delta2;
    chpred(i)=1/(1+2*lambda)*(lambda*temp1+temp0+lambda*temp2);
end
        