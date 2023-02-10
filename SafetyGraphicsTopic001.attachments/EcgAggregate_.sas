libname lib 'd:\BARDS\Study Groups\QTc Graphs\sasdat';
%annomac;

data one; set lib.EcgProfile;

proc transreg data=one;
model identity(QTcB) = class(gender / zero=none)* smooth(time / sm=50);
output p out=goo ;

proc sort data=goo out=foo(keep=pQTcB time gender) nodupkey; ;
by gender time;

data ann; set foo end=eof;
by gender;
retain xx yy ;
%dclanno;
%system(2,2,4);
when='A';
if gender='F' then color='red';
else if gender='M' then color='blue';
if first.gender then do; xx=time; yy=pQTcB; end;
else do;
%line(xx, yy, time, pQTcB, *, 1, 15); xx=time; yy=pQTcB; end;
if eof then do;
%system(3,3,4);
%label(3, 50, "QTc Bazette in msec", black, 90, 0, 1, , 5);
%label(85, 95, "Female", red, 0, 0, 1, , 6);
%label(85, 90, "Male", blue, 0, 0, 1, , 6);
end;

filename grf "d:\BARDS\Study Groups\QTc Graphs\sasgrf\EcgAggregate.cgm";
goptions reset=all dev=cgmofml gsfname=grf ftext="Albany AMT";

symbol v=dot h=0.5 i=sm50 c=ltgray r=500;
axis1 order=(-26 to 14 by 2) label=("Time Relative to the First Dose (hr)");
axis2 label = none ;

PROC GPLOT DATA=one annotate=ann;
plot QTcB * time = subjnbr / haxis=axis1 vaxis=axis2 nolegend ;
run; quit;
