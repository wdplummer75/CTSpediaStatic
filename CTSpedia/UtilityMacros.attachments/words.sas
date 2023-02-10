* Macro Words counts the words in a string (used only for byvars where shortcut lists not allowed).  This is
  taken directly from p256 of the SAS Macro manual;
%macro words(string);
   %local count word;
   %let count = 1;
   %let word=%qscan(&string,&count,%str( ));
   %do %while(&Word ne);
      %Let count=%eval(&count+1);
      %Let word=%qscan(&string,&count,%str( ));
   %end;
   %eval(&count-1)
%mend words;
