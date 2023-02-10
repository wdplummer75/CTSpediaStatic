/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
Replay Macro Library                                September 2008
  This set of Macros replays graphs 1-N from a SAS graph catalog, up to 16 plots 
per page.  This macro can be embedded between Ods statements to stream graphs 
into an .rtf or .html file.

Syntax:
%ReplayAll(library,replay,graphs);
  library:	Graphics catalog or library to use.  Same as Gout=*library*.
  replay:	Number of graphs to replay on each page(1, 2, 4, 6, 9 or 16).
  graphs:	Total number of graphs to replay.

Example:
Ods rtf style=rtf;
ReplayAll(plots,4,16);
Ods rtf close;

Since the graphics catalog is cumulative, it may be helpful to clear the catalog 
while you are refining your graphs.  You can clear the graphics catalog using 
"Proc Datasets":

Proc Datasets Library=work Memtype=Catalog; Delete *library*; Run;

{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*/

%Macro ReplayAll(mlibrary,replay,graphs);
  %Let gnum=1;
  %If &replay=1 %Then %Do;
    *Replay one graphs on a page to be printed Landscape;
    %Do %While (&gnum<=&graphs);
      %Replay1(&mlibrary,&gnum);
      %Let gnum=%Eval(&gnum+1);
    %End;
  %End; %Else %If &replay=2 %Then %Do;
    *Replay two graphs on a single page to be printed portrait;
    %Do %While (&gnum<=&graphs);
      %Replay2(&mlibrary,&gnum,%Eval(&gnum+1));
      %Let pgnum=%Eval(&gnum+2);
    %End;
  %End; %Else %If &replay=4 %Then %Do;
    *Replay four graphs on a single page to be printed landscape;
    %Do %While (%Eval(&gnum+3)<=&graphs);
      %Replay4(&mlibrary,&gnum,%Eval(&gnum+1),%Eval(&gnum+2),%Eval(&gnum+3));
      %Let gnum=%Eval(&gnum+4);
    %End;
    %If (%Eval(&graphs-&gnum)=2) %Then %Do; %Replay3(&mlibrary,&gnum,%Eval(&gnum+1),%Eval(&gnum+2)); %End;
    %If (%Eval(&graphs-&gnum)=1) %Then %Do; %Replay4(&mlibrary,&gnum,%Eval(&gnum+1),9999,9999); %End;
    %If (%Eval(&graphs-&gnum)=0) %Then %Do; %Replay4(&mlibrary,&gnum,9999,9999,9999); %End;
  %End; %Else %If &replay=6 %Then %Do;
    *Replay six graphs on a single page to be printed landscape;
    %Do %While (&gnum<=&graphs);
      %Replay6(&mlibrary,&gnum,%Eval(&gnum+1),%Eval(&gnum+2),%Eval(&gnum+3),%Eval(&gnum+4),%Eval(&gnum+5));
      %Let gnum=%Eval(&gnum+6);
    %End;
  %End; %Else %If &replay=9 %Then %Do;
    *Replay nine graphs on a single page to be printed landscape;
    %Do %While (&gnum<=&graphs);
      %Replay9(&mlibrary,&gnum,%Eval(&gnum+1),%Eval(&gnum+2),%Eval(&gnum+3),%Eval(&gnum+4),%Eval(&gnum+5),%Eval(&gnum+6),%Eval(&gnum+7),%Eval(&gnum+8));
      %Let gnum=%Eval(&gnum+9);
    %End;
  %End; %Else %Do;
    *Replay sixteen graphs on a single page to be printed landscape;
    %Do %While (&gnum<=&graphs);
      %Replay16(&mlibrary,&gnum,%Eval(&gnum+1),%Eval(&gnum+2),%Eval(&gnum+3),%Eval(&gnum+4),%Eval(&gnum+5),%Eval(&gnum+6),%Eval(&gnum+7),
        %Eval(&gnum+8),%Eval(&gnum+9),%Eval(&gnum+10),%Eval(&gnum+11),%Eval(&gnum+12),%Eval(&gnum+13),%Eval(&gnum+14),%Eval(&gnum+15));
      %Let gnum=%Eval(&gnum+16);
    %End;
  %End;
%Mend ReplayAll;

%Macro Replay1(mlibrary,g1);
  Proc Greplay Nofs;
    Igout &mlibrary;
    Tc work.mtemplt;
    Tdef box1 1/llx=0 lly=0 ulx=0 uly=100 urx=100 ury=100 lrx=100 lry=0;
    Template box1;
    Treplay 1:&g1;
  Run;
%Mend Replay1;

%Macro Replay2(mlibrary,g1,g2);
  Proc Greplay Nofs;
    Igout &mlibrary;
    Tc work.mtemplt;
    Tdef box2 1/llx=0 lly=51 ulx=0 uly=100 urx=100 ury=100 lrx=100 lry=51
              2/llx=0 lly=0 ulx=0 uly=49 urx=100 ury=49 lrx=100 lry=0;
    Template box2;
    Treplay 1:&g1 2:&g2;
  Run;
%Mend Replay2;

%Macro Replay3(mlibrary,g1,g2,g3);
  Proc Greplay Nofs;
    Igout &mlibrary;
    Tc work.mtemplt;
    Tdef box3 1/llx=0 lly=51 ulx=0 uly=100 urx=49 ury=100 lrx=49 lry=51
              2/llx=51 lly=51 ulx=51 uly=100 urx=100 ury=100 lrx=100 lry=51
              3/llx=25 lly=0 ulx=25 uly=49 urx=75 ury=49 lrx=75 lry=0;
    Template box3;
    Treplay 1:&g1 2:&g2 3:&g3;
  Run;
%Mend Replay3;

%Macro Replay4(mlibrary,g1,g2,g3,g4);
  Proc Greplay Nofs;
    Igout &mlibrary;
    Tc work.mtemplt;
    Tdef box4 1/llx=0 lly=51 ulx=0 uly=100 urx=49 ury=100 lrx=49 lry=51
              2/llx=51 lly=51 ulx=51 uly=100 urx=100 ury=100 lrx=100 lry=51
              3/llx=0 lly=0 ulx=0 uly=49 urx=49 ury=49 lrx=49 lry=0
              4/llx=51 lly=0 ulx=51 uly=49 urx=100 ury=49 lrx=100 lry=0;
    Template box4;
    Treplay 1:&g1 2:&g2 3:&g3 4:&g4;
  Run;
%Mend Replay4;

%Macro Replay6(mlibrary,g1,g2,g3,g4,g5,g6);
  Proc Greplay Nofs;
    Igout &mlibrary;
    Tc work.mtemplt;
    Tdef box6 1/llx=0 lly=67 ulx=0 uly=100 urx=49 ury=100 lrx=49 lry=67
              2/llx=51 lly=67 ulx=51 uly=100 urx=100 ury=100 lrx=100 lry=67
              3/llx=0 lly=34 ulx=0 uly=66 urx=49 ury=66 lrx=49 lry=34
              4/llx=51 lly=34 ulx=51 uly=66 urx=100 ury=66 lrx=100 lry=34
              5/llx=0 lly=0 ulx=0 uly=33 urx=49 ury=33 lrx=49 lry=0
              6/llx=51 lly=0 ulx=51 uly=33 urx=100 ury=33 lrx=100 lry=0;
    Template box6;
    Treplay 1:&g1 2:&g2 3:&g3 4:&g4 5:&g5 6:&g6;
  Run;
%Mend Replay6;

%Macro Replay9(mlibrary,g1,g2,g3,g4,g5,g6,g7,g8,g9);
  Proc Greplay Nofs;
    Igout &mlibrary;
    Tc work.mtemplt;
    Tdef box9 1/llx=0  lly=67 ulx=0  uly=100 urx=33  ury=100 lrx=33  lry=67
              2/llx=34 lly=67 ulx=34 uly=100 urx=66  ury=100 lrx=66  lry=67
              3/llx=67 lly=67 ulx=67 uly=100 urx=100 ury=100 lrx=100 lry=67 
              4/llx=0  lly=34 ulx=0  uly=66  urx=33  ury=66 lrx=33   lry=34
              5/llx=34 lly=34 ulx=34 uly=66  urx=66  ury=66 lrx=66   lry=34
              6/llx=67 lly=34 ulx=67 uly=66  urx=100 ury=66 lrx=100  lry=34
              7/llx=0  lly=0  ulx=0  uly=33  urx=33  ury=33 lrx=33   lry=0
              8/llx=34 lly=0  ulx=34 uly=33  urx=66  ury=33 lrx=66   lry=0
              9/llx=67 lly=0  ulx=67 uly=33  urx=100 ury=33 lrx=100  lry=0;
    Template box9;
    Treplay 1:&g1 2:&g2 3:&g3 4:&g4 5:&g5 6:&g6 7:&g7 8:&g8 9:&g9;
  Run;
%Mend Replay9;

%Macro Replay16(mlibrary,g1,g2,g3,g4,g5,g6,g7,g8,g9,g10,g11,g12,g13,g14,g15,g16);
  Proc Greplay Nofs;
    Igout &mlibrary;
    Tc work.mtemplt;
    Tdef box16 1/llx=0  lly=76 ulx=0  uly=100 urx=25  ury=100 lrx=25  lry=76
               2/llx=26 lly=76 ulx=26 uly=100 urx=50  ury=100 lrx=50  lry=76
               3/llx=51 lly=76 ulx=51 uly=100 urx=75  ury=100 lrx=75  lry=76
               4/llx=76 lly=76 ulx=76 uly=100 urx=100 ury=100 lrx=100 lry=76
               5/llx=0  lly=51 ulx=0  uly=75  urx=25  ury=75  lrx=25  lry=51
               6/llx=26 lly=51 ulx=26 uly=75  urx=50  ury=75  lrx=50  lry=51
               7/llx=51 lly=51 ulx=51 uly=75  urx=75  ury=75  lrx=75  lry=51 
               8/llx=76 lly=51 ulx=76 uly=75  urx=100 ury=75  lrx=100 lry=51 
               9/llx=0  lly=26 ulx=0  uly=50  urx=25  ury=50  lrx=25  lry=26
              10/llx=26 lly=26 ulx=26 uly=50  urx=50  ury=50  lrx=50  lry=26
              11/llx=51 lly=26 ulx=51 uly=50  urx=75  ury=50  lrx=75  lry=26 
              12/llx=76 lly=26 ulx=76 uly=50  urx=100 ury=50  lrx=100 lry=26
              13/llx=0  lly=0  ulx=0  uly=25  urx=25  ury=25  lrx=25  lry=0
              14/llx=26 lly=0  ulx=26 uly=25  urx=50  ury=25  lrx=50  lry=0
              15/llx=51 lly=0  ulx=51 uly=25  urx=75  ury=25  lrx=75  lry=0 
              16/llx=76 lly=0  ulx=76 uly=25  urx=100 ury=25  lrx=100 lry=0;
    Template box16;
    Treplay 1:&g1 2:&g2 3:&g3 4:&g4 5:&g5 6:&g6 7:&g7 8:&g8 9:&g9 10:&g10 11:&g11 12:&g12 13:&g13 14:&g14 15:&g15 16:&g16;
  Run;
%Mend Replay16;

