data mydata;
  input ID	T1	T2	T3	group @@;
  datalines;
1	2.226364587	0.927244553	1.375803736	1
2	1.277286527	1.27073279	1.381299107	1
3	2.749114953	2.465239866	1.820786823	1
4	0.274000043	1.433219359	2.226321667	1
5	0.787577157	2.083854315	2.887913988	1
6	1.935163547	2.072562576	2.470084824	1
7	3.754223396	2.050355065	1.648738519	1
8	3.441084685	2.892159493	2.031257612	1
9	0.314500189	0.298453527	-0.089196903	1
10	1.157587654	1.575623622	3.408971159	1
11	0.879726771	0.723801118	0.987580008	1
12	2.249355162	1.814418907	2.788067989	1
13	3.241945401	2.114804728	2.651584896	1
14	1.00161815	2.173882648	1.990160955	1
15	2.735954579	2.403359423	3.857319207	1
16	2.107465183	2.579690276	1.613813763	1
17	1.639153537	1.029754546	2.243926737	1
18	2.251332849	2.145735857	3.392759938	1
19	1.953688876	2.027173357	1.67588522	1
20	1.897031801	2.011082561	2.644435928	1
21	4.143978698	5.165310706	3.82588331	2
22	2.344100699	2.343647619	4.046167884	2
23	3.111563168	1.324980895	1.346337985	2
24	5.159936076	3.84758388	1.329320742	2
25	4.398558352	5.545999233	5.592779901	2
26	3.211604139	2.929626228	3.055827851	2
27	1.580831246	4.394939304	2.18714012	2
28	2.643150659	4.311464099	4.403608896	2
29	2.814667374	1.889896339	2.983127536	2
30	4.411264463	2.111795407	2.08152355	2
31	2.568309122	2.442363763	3.617885368	2
32	3.670153166	0.718941073	2.204929152	2
33	2.708144833	0.134891128	4.986532716	2
34	4.086045384	4.4383032	-0.374164523	2
35	3.800536472	2.72548269	3.508344081	2
36	3.942905888	3.729673253	2.238675498	2
37	3.157595748	0.838946886	1.360144323	2
38	0.165056725	4.251983337	2.858628671	2
39	2.325640748	4.400782789	3.971128022	2
40	1.651379129	3.365651987	5.79374332	2
41	5.010082761	5.508497675	4.219853224	2
42	3.618038315	4.033863567	4.109363832	2
43	5.080732653	2.66874005	3.925030934	2
44	1.168730331	1.23466798	2.823733162	2
45	4.445315863	4.584878142	5.35678042	2
46	1.18199898	2.85671648	2.945853051	2
47	2.102929565	2.783035328	4.725551437	2
48	4.736193488	3.61122205	3.200657226	2
49	1.421088323	2.052775761	2.957349286	2
50	0.333361845	2.500245703	2.870963308	2
;
run;

filename MWW URL "http://www.ctspedia.org/wiki/pub/CTSpedia/StatToolsTopic062/Rochester_MWWlongitudinal_SAS.sas";
%include MWW;	


%Rochester_MWWlongitudinal_SAS(DSName=mydata,
		Timevar=T1 T2 T3,
		Group=group);

*
   DSName       = name of a SAS longitudinal dataset
   Timevar      = name of (multiple) time variables.
   Group      	= name of group variable;
