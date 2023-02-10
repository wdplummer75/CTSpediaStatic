*SAS for Poisson and Negative Binomial GLMs for Crab Data
*--------------------------------------------------------------	;

data crab;
input id color spine width satell weight; 
   weight=weight/1000; color=color-1;
datalines;
1	3	3	28.3	8	3050
2	4	3	22.5	0	1550
3	2	1	26	9	2300
4	4	3	24.8	0	2100
5	4	3	26	4	2600
6	3	3	23.8	0	2100
7	2	1	26.5	0	2350
8	4	2	24.7	0	1900
9	3	1	23.7	0	1950
10	4	3	25.6	0	2150
11	4	3	24.3	0	2150
12	3	3	25.8	0	2650
13	3	3	28.2	11	3050
14	5	2	21	0	1850
15	3	1	26	14	2300
16	2	1	27.1	8	2950
17	3	3	25.2	1	2000
18	3	3	29	1	3000
19	5	3	24.7	0	2200
20	3	3	27.4	5	2700
21	3	2	23.2	4	1950
22	2	2	25	3	2300
23	3	1	22.5	1	1600
24	4	3	26.7	2	2600
25	5	3	25.8	3	2000
26	5	3	26.2	0	1300
27	3	3	28.7	3	3150
28	3	1	26.8	5	2700
29	5	3	27.5	0	2600
30	3	3	24.9	0	2100
31	2	1	29.3	4	3200
32	2	3	25.8	0	2600
33	3	2	25.7	0	2000
34	3	1	25.7	8	2000
35	3	1	26.7	5	2700
36	5	3	23.7	0	1850
37	3	3	26.8	0	2650
38	3	3	27.5	6	3150
39	5	3	23.4	0	1900
40	3	3	27.9	6	2800
41	4	3	27.5	3	3100
42	2	1	26.1	5	2800
43	2	1	27.7	6	2500
44	3	1	30	5	3300
45	4	1	28.5	9	3250
46	4	3	28.9	4	2800
47	3	3	28.2	6	2600
48	3	3	25	4	2100
49	3	3	28.5	3	3000
50	3	1	30.3	3	3600
51	5	3	24.7	5	2100
52	3	3	27.7	5	2900
53	2	1	27.4	6	2700
54	3	3	22.9	4	1600
55	3	1	25.7	5	2000
56	3	3	28.3	15	3000
57	3	3	27.2	3	2700
58	4	3	26.2	3	2300
59	3	1	27.8	0	2750
60	5	3	25.5	0	2250
61	4	3	27.1	0	2550
62	4	3	24.5	5	2050
63	4	1	27	3	2450
64	3	3	26	5	2150
65	3	3	28	1	2800
66	3	3	30	8	3050
67	3	3	29	10	3200
68	3	3	26.2	0	2400
69	3	1	26.5	0	1300
70	3	3	26.2	3	2400
71	4	3	25.6	7	2800
72	4	3	23	1	1650
73	4	3	23	0	1800
74	3	3	25.4	6	2250
75	4	3	24.2	0	1900
76	3	2	22.9	0	1600
77	4	2	26	3	2200
78	3	3	25.4	4	2250
79	4	3	25.7	0	1200
80	3	3	25.1	5	2100
81	4	2	24.5	0	2250
82	5	3	27.5	0	2900
83	4	3	23.1	0	1650
84	4	1	25.9	4	2550
85	3	3	25.8	0	2300
86	5	3	27	3	2250
87	3	3	28.5	0	3050
88	5	1	25.5	0	2750
89	5	3	23.5	0	1900
90	3	2	24	0	1700
91	3	1	29.7	5	3850
92	3	1	26.8	0	2550
93	5	3	26.7	0	2450
94	3	1	28.7	0	3200
95	4	3	23.1	0	1550
96	3	1	29	1	2800
97	4	3	25.5	0	2250
98	4	3	26.5	1	1967
99	4	3	24.5	1	2200
100	4	3	28.5	1	3000
101	3	3	28.2	1	2867
102	3	3	24.5	1	1600
103	3	3	27.5	1	2550
104	3	2	24.7	4	2550
105	3	1	25.2	1	2000
106	4	3	27.3	1	2900
107	3	3	26.3	1	2400
108	3	3	29	1	3100
109	3	3	25.3	2	1900
110	3	3	26.5	4	2300
111	3	3	27.8	3	3250
112	3	3	27	6	2500
113	4	3	25.7	0	2100
114	3	3	25	2	2100
115	3	3	31.9	2	3325
116	5	3	23.7	0	1800
117	5	3	29.3	12	3225
118	4	3	22	0	1400
119	3	3	25	5	2400
120	4	3	27	6	2500
121	4	3	23.8	6	1800
122	2	1	30.2	2	3275
123	4	3	26.2	0	2225
124	3	3	24.2	2	1650
125	3	3	27.4	3	2900
126	3	2	25.4	0	2300
127	4	3	28.4	3	3200
128	5	3	22.5	4	1475
129	3	3	26.2	2	2025
130	3	1	24.9	6	2300
131	2	2	24.5	6	1950
132	3	3	25.1	0	1800
133	3	1	28	4	2900
134	5	3	25.8	10	2250
135	3	3	27.9	7	3050
136	3	3	24.9	0	2200
137	3	1	28.4	5	3100
138	4	3	27.2	5	2400
139	3	2	25	6	2250
140	3	3	27.5	6	2625
141	3	1	33.5	7	5200
142	3	3	30.5	3	3325
143	4	3	29	3	2925
144	3	1	24.3	0	2000
145	3	3	25.8	0	2400
146	5	3	25	8	2100
147	3	1	31.7	4	3725
148	3	3	29.5	4	3025
149	4	3	24	10	1900
150	3	3	30	9	3000
151	3	3	27.6	4	2850
152	3	3	26.2	0	2300
153	3	1	23.1	0	2000
154	3	1	22.9	0	1600
155	5	3	24.5	0	1900
156	3	3	24.7	4	1950
157	3	3	28.3	0	3200
158	3	3	23.9	2	1850
159	4	3	23.8	0	1800
160	4	2	29.8	4	3500
161	3	3	26.5	4	2350
162	3	3	26	3	2275
163	3	3	28.2	8	3050
164	5	3	25.7	0	2150
165	3	3	26.5	7	2750
166	3	3	25.8	0	2200
167	4	3	24.1	0	1800
168	4	3	26.2	2	2175
169	4	3	26.1	3	2750
170	4	3	29	4	3275
171	2	1	28	0	2625
172	5	3	27	0	2625
173	3	2	24.5	0	2000
;
run;


filename Countreg URL "http://www.ctspedia.org/wiki/pub/CTSpedia/CountRegressionSASMacro/Countreg.sas";
%include Countreg;

%Countreg(DSName=crab,
		Dir=,
		ID=id,
		Outcome=satell,
		PredictNum=width,
		PredictClass=color(ref="1") spine(ref="3"), 
		Format=. .,
		ScaleCutpoint=1.5,
		AlternateMod=gee,
		OutForm=html);


