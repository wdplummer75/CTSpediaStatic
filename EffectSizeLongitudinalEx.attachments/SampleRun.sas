
* example for how to call the macro;
* -----------------------------------------------------------------------------------;
footnote1 '\Chen\Effect Size Longitudinal Data';

data mydata;
   input ID	age	time group race depression;
   datalines;
1001	51.13746216	0	2	2	21.18563074
1001	51.1605986	1	2	2	6.445694198
1001	51.46819264	2	2	2	
1001	51.77276452	3	2	2	6.380204628
1002	48.26992178	0	1	1	25.21057457
1002	48.25782885	1	1	1	23.50004684
1002	48.22897001	2	1	1	25.56788712
1002	48.90487788	3	1	1	23.426654
1003	44.53076661	0	1	2	21.46192204
1003	44.70846496	1	1	2	13.75594359
1003	44.83285089	2	1	2	9.663910186
1003	44.61969414	3	1	2	2.111243568
1004	34.02406233	0	2	1	18.32395728
1004	34.38482664	1	2	1	23.3231233
1004	34.04471439	2	2	1	21.08738436
1004	34.29987262	3	2	1	22.78645407
1005	20.03482477	0	1	2	18.67052891
1005	20.17461739	1	1	2	6.721086828
1005	20.4840476	2	1	2	12.02266453
1005	20.67605357	3	1	2	14.49288705
1006	50.01315293	0	1	2	27.9391514
1006	50.56646511	1	1	2	
1006	50.652299	2	1	2	21.00092669
1006	50.96138727	3	1	2	19.22804921
1008	25.68046651	0	1	1	21.71783964
1008	25.445651	1	1	1	15.57420994
1008	25.3030911	2	1	1	
1008	25.00546763	3	1	1	
1009	26.22794747	0	1	2	24.38802622
1009	26.58568777	1	1	2	25.2639454
1009	26.45516131	2	1	2	21.06519364
1009	26.05385941	3	1	2	9.322451755
1010	37.01747098	0	2	2	16.92823728
1010	37.26066522	1	2	2	2.255591835
1010	37.65176746	2	2	2	12.60324041
1010	37.91477813	3	2	2	3.263624123
1011	32.871134	0	1	2	15.66787061
1011	32.55212014	1	1	2	23.19324308
1011	32.02547751	2	1	2	
1011	32.01754561	3	1	2	
1012	35.64832419	0	2	2	21.54199409
1012	35.13807414	1	2	2	23.84635859
1012	35.27212674	2	2	2	
1012	35.31832477	3	2	2	
1013	27.57424625	0	2	1	26.2336772
1013	27.03911865	1	2	1	26.12759433
1013	27.08500751	2	2	1	24.60599383
1013	27.25021289	3	2	1	24.14243805
1014	44.9506564	0	1	2	24.8842862
1014	44.59355644	1	1	2	14.52797094
1014	44.26830548	2	1	2	13.53092358
1014	44.63784429	3	1	2	16.67433352
1015	22.497037	0	1	2	27.59741002
1015	22.5172676	1	1	2	17.07574086
1015	22.78976997	2	1	2	
1015	22.73888911	3	1	2	
1016	47.30185405	0	1	2	26.74976054
1016	47.49888054	1	1	2	5.086341392
1016	47.60995761	2	1	2	
1016	47.50425484	3	1	2	22.07334417
1017	23.65751428	0	1	2	17.7155344
1017	23.41343625	1	1	2	6.549863143
1017	23.54623829	2	1	2	
1017	23.81220819	3	1	2	7.986432287
1018	21.29543743	0	2	2	18.40157683
1018	21.94296059	1	2	2	17.41410885
1018	21.81432344	2	2	2	
1018	21.24344371	3	2	2	
1019	33.98882672	0	1	1	17.53014192
1019	33.15869688	1	1	1	19.93570927
1019	33.88021588	2	1	1	20.47488915
1019	33.41934392	3	1	1	15.30078299
1020	31.23861304	0	1	1	21.32436627
1020	31.6704052	1	1	1	13.82332169
1020	31.49129007	2	1	1	18.54919958
1020	31.50935819	3	1	1	
1021	30.82515963	0	2	1	31.95436535
1021	30.14561617	1	2	1	26.05528957
1021	30.65479028	2	2	1	26.83585804
1021	30.12852385	3	2	1	17.64727105
1022	40.7640552	0	2	1	19.55858015
1022	40.81983211	1	2	1	24.77694595
1022	40.44972408	2	2	1	22.72557086
1022	40.85833423	3	2	1	
1023	49.08813713	0	1	1	27.99288507
1023	49.86222392	1	1	1	27.46591222
1023	49.81387438	2	1	1	22.47696193
1023	49.16059428	3	1	1	25.48694602
1024	44.16455654	0	2	2	17.36038896
1024	44.51574085	1	2	2	13.41134689
1024	44.49900668	2	2	2	8.052241661
1024	44.03187419	3	2	2	7.481403316
1025	47.22510495	0	1	1	31.2801478
1025	47.29095656	1	1	1	
1025	47.78915564	2	1	1	
1025	47.55970179	3	1	1	
1026	57.52615735	0	1	2	25.73606049
1026	57.72389196	1	1	2	
1026	57.92432739	2	1	2	17.73582445
1026	57.7822568	3	1	2	13.70674094
1027	43.18562007	0	2	2	19.85947633
1027	43.35428322	1	2	2	11.86453838
1027	43.84270536	2	2	2	18.98363777
1027	43.86745001	3	2	2	16.61236467
1028	37.53350545	0	1	2	21.63565775
1028	37.25914828	1	1	2	11.08630966
1028	37.98068652	2	1	2	2.501199751
1028	37.03421453	3	1	2	
1029	28.31453092	0	1	1	16.9725864
1029	28.74725459	1	1	1	17.26602056
1029	28.09475052	2	1	1	12.74664539
1029	28.64423252	3	1	1	19.59232252
1030	28.43192323	0	2	1	25.84762141
1030	28.81132433	1	2	1	12.40055543
1030	28.91718767	2	2	1	
1030	28.93432675	3	2	1	
1031	36.46291164	0	1	1	26.27687391
1031	36.73018699	1	1	1	28.10594913
1031	36.21392936	2	1	1	20.13219936
1031	36.80962381	3	1	1	9.394407704
1032	27.05209045	0	2	2	19.89547102
1032	27.36339094	1	2	2	20.89844634
1032	27.57382521	2	2	2	10.88372794
1032	27.22420122	3	2	2	
1033	53.01783098	0	1	2	23.46491396
1033	53.05611409	1	1	2	21.52358329
1033	53.92871752	2	1	2	15.97550794
1033	53.44892999	3	1	2	21.76535418
1034	37.02020365	0	2	2	29.06577823
1034	37.6871969	1	2	2	19.60634631
1034	37.65853153	2	2	2	20.76583888
1034	37.94357455	3	2	2	25.94830259
1035	19.22165108	0	2	2	21.9871431
1035	19.90623766	1	2	2	17.11220348
1035	19.649162	2	2	2	15.29213433
1035	19.17403161	3	2	2	20.91250649
1036	45.68330712	0	1	1	30.50833116
1036	45.55611574	1	1	1	23.5087989
1036	45.87825886	2	1	1	
1036	45.64682717	3	1	1	25.84243142
1037	40.5930472	0	1	2	24.10771805
1037	40.80020015	1	1	2	9.239004711
1037	40.17024023	2	1	2	9.810558801
1037	40.32650842	3	1	2	4.842294577
1038	46.42456811	0	2	1	31.19667223
1038	46.60743755	1	2	1	7.240290627
1038	46.79466845	2	2	1	13.33723247
1038	46.25643861	3	2	1	21.53232618
1039	44.63759517	0	1	2	22.15102018
1039	44.91451851	1	1	2	9.362405494
1039	44.27958576	2	1	2	16.67128028
1039	44.28476203	3	1	2	11.54769339
1040	30.7939476	0	2	2	20.15051992
1040	30.46301381	1	2	2	26.14491536
1040	30.86537672	2	2	2	15.92835636
1040	30.13011006	3	2	2	21.98302273
1041	42.92221025	0	1	2	14.13761983
1041	42.06468599	1	1	2	10.49883091
1041	42.79704423	2	1	2	11.25553067
1041	42.52881124	3	1	2	3.390617065
1042	44.25938061	0	2	2	24.77035121
1042	44.64269917	1	2	2	22.02653538
1042	44.20636577	2	2	2	
1042	44.16986921	3	2	2	
1043	55.38160366	0	1	2	17.43508828
1043	55.47867521	1	1	2	21.98220109
1043	55.12480382	2	1	2	20.01355537
1043	55.16097828	3	1	2	21.33719227
1044	37.82391823	0	1	1	19.74359274
1044	37.60865058	1	1	1	25.52536348
1044	37.0654797	2	1	1	30.61807875
1044	37.61109724	3	1	1	24.256541
1045	47.33188258	0	2	2	22.92386024
1045	47.11648596	1	2	2	21.93227203
1045	47.55041045	2	2	2	15.16758513
1045	47.56223838	3	2	2	15.47062523
1046	52.99630266	0	1	1	24.04791429
1046	52.14906089	1	1	1	18.97005128
1046	52.64669022	2	1	1	14.00701516
1046	52.38212907	3	1	1	13.35578366
1047	41.6961895	0	2	1	28.50988106
1047	41.57878755	1	2	1	28.17881876
1047	41.91759411	2	2	1	
1047	41.46800851	3	2	1	
1048	31.38255561	0	2	1	19.92595787
1048	31.07937106	1	2	1	22.4839878
1048	31.70035785	2	2	1	23.64389938
1048	31.09285758	3	2	1	22.11430285
1049	27.95934422	0	2	1	20.72342875
1049	27.07755578	1	2	1	18.05478831
1049	27.38155456	2	2	1	12.0173631
1049	27.50396467	3	2	1	13.41906363
1050	45.57524345	0	1	1	24.13977547
1050	45.74155633	1	1	1	26.03176663
1050	45.05851381	2	1	1	20.76170082
1050	45.43205048	3	1	1	20.94447595
1051	34.01447288	0	2	2	21.75208557
1051	34.26621241	1	2	2	16.24003878
1051	34.41713878	2	2	2	
1051	34.79662306	3	2	2	
1052	38.23860985	0	1	1	21.21990294
1052	38.26359015	1	1	1	19.67934411
1052	38.2045557	2	1	1	21.75094593
1052	38.65228589	3	1	1	17.89099158
1053	36.05377555	0	1	2	22.976821
1053	36.83040322	1	1	2	21.46415031
1053	36.38042343	2	1	2	22.69683529
1053	36.58601857	3	1	2	24.43018481
1054	24.95734041	0	2	2	22.51539412
1054	24.70115655	1	2	2	
1054	24.13829723	2	2	2	
1054	24.55348859	3	2	2	
1055	25.46495988	0	2	2	21.48275416
1055	25.15130135	1	2	2	23.06706571
1055	25.71953665	2	2	2	27.33199172
1055	25.38914913	3	2	2	28.62930541
1056	33.99641512	0	2	1	23.36731921
1056	33.33460036	1	2	1	23.91036387
1056	33.49473781	2	2	1	
1056	33.61631298	3	2	1	11.75115889
1057	47.50078418	0	1	2	19.32403003
1057	47.93353157	1	1	2	25.83450021
1057	47.83949304	2	1	2	18.82873121
1057	47.08078135	3	1	2	26.52596608
1058	30.10244964	0	1	2	22.84376084
1058	30.60467738	1	1	2	20.4119417
1058	30.07814685	2	1	2	20.17229145
1058	30.86868538	3	1	2	14.74708854
1059	31.24213565	0	2	2	26.01008007
1059	31.19239311	1	2	2	23.97827093
1059	31.17209794	2	2	2	
1059	31.24872697	3	2	2	
1060	49.38043314	0	2	1	26.28338508
1060	49.66653833	1	2	1	24.56442873
1060	49.75368432	2	2	1	20.45059484
1060	49.85739503	3	2	1	18.82048044
1061	42.69594352	0	1	2	29.65648467
1061	42.06518843	1	1	2	6.626123098
1061	42.8801672	2	1	2	5.648817852
1061	42.55438874	3	1	2	4.0189958
1062	40.88843486	0	2	1	27.89263755
1062	40.63132067	1	2	1	24.03861355
1062	40.71674447	2	2	1	33.70558432
1062	40.17608798	3	2	1	
1063	33.73375161	0	1	2	28.65576711
1063	33.19966588	1	1	2	
1063	33.91742025	2	1	2	27.8626168
1063	33.05539915	3	1	2	18.9025595
1064	32.08251378	0	2	1	25.72250927
1064	32.59589969	1	2	1	26.71032353
1064	32.87380115	2	2	1	17.56874982
1064	32.00485154	3	2	1	26.1660599
1065	24.23306013	0	2	2	26.3998734
1065	24.24551696	1	2	2	22.31507111
1065	24.93468128	2	2	2	23.46095851
1065	24.44675004	3	2	2	25.89933308
1066	34.40764168	0	2	1	31.14103887
1066	34.46271777	1	2	1	29.09806269
1066	34.36617583	2	2	1	22.67384338
1066	34.62928486	3	2	1	27.67691254
1067	23.23265239	0	1	1	34.73079316
1067	23.68573798	1	1	1	32.34908462
1067	23.44319503	2	1	1	23.69924945
1067	23.32219776	3	1	1	23.99574342
1068	19.00837409	0	1	2	23.40511253
1068	19.52386986	1	1	2	26.24953885
1068	19.24209551	2	1	2	19.05617086
1068	19.54510398	3	1	2	14.20475227
1069	28.00886648	0	2	2	22.812977
1069	28.54117834	1	2	2	17.37613072
1069	28.55392611	2	2	2	17.4786596
1069	28.62979034	3	2	2	23.3193696
1070	25.11473369	0	2	1	20.189811
1070	25.54687522	1	2	1	19.23088489
1070	25.57623376	2	2	1	23.19995894
1070	25.13100238	3	2	1	17.48990556
1071	49.93206854	0	1	2	30.5176777
1071	49.30911174	1	1	2	27.02836142
1071	49.04079163	2	1	2	25.52812232
1071	49.7539047	3	1	2	24.00051873
;
run;


filename ESMacro URL "http://ctspedia.org/twiki/pub/CTSpedia/EffectSizeLongitudinalEx/ESMacro.sas";
%include ESMacro;

%ESMacro(MacroDir=\\Bio3\ctsiberd\BERDmacros\Chen\Effect Size\GLM\CTSpedia public,
		DSName=mydata,
		ID=ID,
		Outcome=depression,
		TimeSeq=time,
		Treatment=group,
		CovariateNum=age,
		CovariateClass=race,
		AdjustTimeBase=Y,
		ResultsFormat=htm);


