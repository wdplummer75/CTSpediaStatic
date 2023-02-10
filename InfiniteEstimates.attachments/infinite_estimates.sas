options nocenter pageno=1 linesize=90 nodate;


data temp;
  do i=1 to 20; pred=1; outcome=1; output; end;
  do i=1 to 10; pred=0; outcome=0; output; end;
  do i=1 to 10; pred=0; outcome=1; output; end;
run;
proc logistic data=temp descending;
  model outcome=pred / clodds=both;
run;
proc logistic data=temp descending;
  model outcome=pred / clodds=both clparm=PL firth;
run;
proc logistic data=temp exactonly descending;
  model outcome=pred;
  exact pred / estimate=odds;
run;
