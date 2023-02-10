function [dspred, hyds, vards, nsing]=dsfun(x,y,n,h,mpred,ngrid,xpred, xgrid,vary, epsilon)  
%give the predicted value using double smoothing

nsing=zeros(1,ngrid);
nd=zeros(1,ngrid);
for i=1:ngrid
    w1=zeros(1,n);
    for j=1:n
        arg=(x(j)-xgrid(i))/h;
        if abs(arg)<1
            w1(j)=0.75*(1-arg^2)/h;
            nd(i)=nd(i)+1;
        end
        sw1((i-1)*n+j)=w1(j);
    end
end

for ii=1:mpred
    w2=zeros(1,ngrid);
    for i=1:ngrid
        arg=(xpred(ii)-xgrid(i))/h;
        if abs(arg)<1
            w2(i)=0.75*(1-arg^2)/h;
        end
        sw2((ii-1)*ngrid+i)=w2(i);
    end
end

for i=1:ngrid
    s0=0;
    s1=0;
    s2=0;
    t0=0;
    t1=0;
    for j=1:n
        tmp=(x(j)-xgrid(i));
        s0=s0+sw1((i-1)*n+j);
        s1=s1+sw1((i-1)*n+j)*tmp;
        s2=s2+sw1((i-1)*n+j)*tmp*tmp;
        t0=t0+sw1((i-1)*n+j)*y(j);
        t1=t1+sw1((i-1)*n+j)*y(j)*tmp;
    end
    ss0(i)=s0;
    ss1(i)=s1;
    ss2(i)=s2;
    tt0(i)=t0;
    tt1(i)=t1;
    delta(i)=ss2(i)*ss0(i)-ss1(i)^2;
    if delta(i)==0
        delta1=delta(i)+epsilon;
        nsing(i)=1;
    else
        delta1=delta(i);
    end
    beta0(i)=(ss2(i)*tt0(i)-ss1(i)*tt1(i))/delta1;
    beta1(i)=(ss0(i)*tt1(i)-ss1(i)*tt0(i))/delta1;
end

vards=zeros(1,mpred);
hyds=zeros(1,mpred);
dspred=zeros(1,mpred);
for ii=1:mpred
    temp=0;
    for j=1:ngrid
        if delta(j)~=0
            temp=temp+sw2((ii-1)*ngrid+j);
        end
    end
    for i=1:n
        r1=zeros(1,n);
        for j=1:ngrid
            if delta(j)==0
                delta(j)=delta(j)+epsilon;
            end
            tmp1=ss2(j)-ss1(j)*(x(i)-xgrid(j));
            tmp2=-ss1(j)+ss0(j)*(x(i)-xgrid(j));
            tmp3=1/delta(j)*(tmp1+tmp2*(xgrid(ii)-xgrid(j)))*sw1((j-1)*n+i)*sw1((ii-1)*ngrid+j)/temp;
            r1(i)=r1(i)+tmp3;
        end
        vards(ii)=vards(ii)+r1(i)*vary;
        hyds(ii)=hyds(ii)+r1(i)*y(i);
    end
    for i=1:ngrid
        dspred(ii)=dspred(ii)+(beta0(i)+beta1(i)*(xpred(ii)-xgrid(i)))*sw2((ii-1)*ngrid+i)/temp;
    end
end
                