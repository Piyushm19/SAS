%macro desc_char;
options nofmterr;
%put _global_;

data heightInfo;
	set sasuser.vs(keep= usubjid vstest vsstresn vsstresu rename=(vsstresn=Height vsstresu= HT_U));
	where vstest = "Height";
run;

data wtInfo;
	set sasuser.vs(keep= usubjid vstest vsstresn vsstresu rename=(vsstresn=Weight vsstresu= WT_U));
	where vstest = "Weight";
run;

proc sort data=wtInfo(drop=VSTEST);
	by usubjid;
run;

proc sort data=heightInfo(drop=VSTEST);
	by usubjid;
run;


proc sort data=sasuser.dm out=dm;
	by usubjid;
	where arm ne " ";
run;

data dm_h;
	merge dm(in=a) heightinfo(in=b) wtInfo(in=c);
	by usubjid;
 	if a;
run;


/* BMI CALCULATION */
data dm_h1;
	set dm_h;
	if height ne . and weight ne . then BMI = fuzz(Weight/((Height/100)**2));
	if arm = "Placebo" then armn = 101;
	if arm = "Tafenoquine" then armn = 102;
run;

data dm_cb;
	length agecat $25. sex $8.; 
	merge dm_h(in=d) dm_h1(in=e);
	by usubjid;
	if d;
	if Sex in ("M", "F");
  	if Age ne . and age lt 65 then do; agecatn=1; agecat="Age < 65" ; end;
  	if Age ne . and age ge 65 then do; agecatn=2; agecat="Age >= 65" ; end;
  	if Sex = "M" then Sex = "Male";
  	if Sex = "F" then Sex = "Female";
run;

proc sort data=dm_cb out=dm_100 nodupkey;
	by usubjid armn arm;
run;

proc sql;
	create table bign as
	select distinct armn, arm, count(distinct usubjid) as bign
	from dm_100
	group by armn, arm;
quit;

proc sql noprint;
	select bign into: bn1 - :bn2 from bign;
quit;

%put &bN1 &bN2;

proc sort data=dm_100;
	by armn arm;
run;

%macro trans (din= , dsnout= , var1= , var= , lb= , intord=);

proc means data=dm_100 n mean median min max std;
	by armn arm;
	var &var1;
	output out= out&var1 n=N mean=mean median=median std=std min=min max=max;
run;

data tot&var1;
	set out&var1;
    by armn arm;
    if std=. then std=0;
    if n = . then n=0;
   	_n = strip(put (n,5.));
   	_std=put(std,6.2);
  	_min=put(min,6.2);
  	_max=put(max,6.2);
  	mean_=put(round(mean,0.01),6.2);
  	median_=put(median,6.2);
  	range="("||strip(_min) ||', ' ||strip(_max)||")" ;
run;

proc sort data=tot&var1;
	by arm;
run;

proc transpose data=&din out=&dsnout;
	var &var;
	id arm;
run;

data &dsnout;
    length label $40.;
    set &dsnout;
    label = "&lb" ;
    intord = &intord;
run;

%mend trans;

%trans (din = tot&var1,  dsnout =ageout1 ,  var1=age, var = _n ,      lb =N,      intord =1 );
%trans (din = tot&var1,  dsnout =ageout2 ,  var1=age, var = mean_,    lb =Mean   ,  intord =2);
%trans (din = tot&var1,  dsnout =ageout3 ,  var1=age, var = median_,  lb =Median   ,intord =3);
%trans (din = tot&var1,  dsnout =ageout4 ,  var1=age, var = _std,     lb = SD  ,    intord =4);
%trans (din = tot&var1,  dsnout =ageout5 ,  var1=age, var = range,    lb =Range (min, max) , intord =5);
%trans (din = tot&var1,  dsnout =bmiout1 ,  var1=bmi, var = _n ,      lb =N,      intord =8);
%trans (din = tot&var1,  dsnout =bmiout2 ,  var1=bmi, var = mean_,    lb =Mean   ,  intord =9);
%trans (din = tot&var1,  dsnout =bmiout3 ,  var1=bmi, var = median_,  lb =Median   ,intord =10);
%trans (din = tot&var1,  dsnout =bmiout4 ,  var1=bmi, var = _std,     lb = SD  ,    intord =11);
%trans (din = tot&var1,  dsnout =bmiout5 ,  var1=bmi, var = range,    lb =Range (min, max) , intord =12);
%trans (din = tot&var1,  dsnout =htout1 ,  var1=height, var = _n ,      lb =N,      intord =15);
%trans (din = tot&var1,  dsnout =htout2 ,  var1=height, var = mean_,    lb =Mean   ,  intord =16);
%trans (din = tot&var1,  dsnout =htout3 ,  var1=height, var = median_,  lb =Median   ,intord =17);
%trans (din = tot&var1,  dsnout =htout4 ,  var1=height, var = _std,     lb = SD  ,    intord =18);
%trans (din = tot&var1,  dsnout =htout5 ,  var1=height, var = range,    lb =Range (min, max) , intord =19);
%trans (din = tot&var1,  dsnout =wtout1 ,  var1=weight, var = _n ,      lb =N,      intord =22);
%trans (din = tot&var1,  dsnout =wtout2 ,  var1=weight, var = mean_,    lb =Mean   ,  intord =23);
%trans (din = tot&var1,  dsnout =wtout3 ,  var1=weight, var = median_,  lb =Median   ,intord =24);
%trans (din = tot&var1,  dsnout =wtout4 ,  var1=weight, var = _std,     lb = SD  ,    intord =25);
%trans (din = tot&var1,  dsnout =wtout5 ,  var1=weight, var = range,    lb =Range (min, max) , intord =26);


proc sql;
	create table cat_cnt as
	select agecat, armn, arm, count(distinct usubjid) as ncount from dm_100
	group by armn, arm, agecat order by armn, arm, agecat;
quit;

proc sort data=cat_cnt nodupkey;
	by armn arm agecat;
run;

data mock0;
	intord=0;
	label="Age (in Years):";
	output;
	intord=6;
	label=" " ;
	output;
	intord=7;
	label="BMI (kg/m2):";
	output;
	intord=13;
	label=" " ;
	output;
	intord=14;
	label="Height (in cm):";
	output;
	intord=20;
	label=" " ;
	output;
	intord=21;
	label="Weight (in kg):";
	output;
	intord=27;
	label=" " ;
	output;
	intord=28;
	label="Age (in Years) Group:";
	output;
run;

data mock(drop=i);
	length agecat label $40.;
	set cat_cnt(keep=armn arm);
	do i=29 to 30;
    intord=i;
    if i=29 then agecat="Age < 65";
    else if i=30 then agecat="Age >= 65";
    label=agecat;
    output;
    end;
run;

proc sort data=mock nodupkey;
	by armn arm agecat;
run;

data fin1;
	merge mock(in=b) bign(keep=armn arm bign);
	by armn arm;
run;

proc sort data=fin1;
	by armn arm agecat;
run;

 data fin2;
    length agecat $40;
    merge fin1(in=b) cat_cnt;
    by armn arm agecat;
    if ncount=. then ncount=0;
    per = ncount/bign*100;
    nper = strip (put (ncount,5.))||" ("|| strip(put(per,6.2))||")";
run;

proc sort data=fin2 nodupkey; by intord label arm; run;

proc transpose data=fin2 out=fin3;
	by intord label;
	var nper;
	id arm;
run;

data all(drop=_name_);
	length label $40.;
	set mock0 fin3 ageout1 ageout2 ageout3 ageout4 ageout5 bmiout1 bmiout2 bmiout3 bmiout4 bmiout5
			htout1 htout2 htout3 htout4 htout5 wtout1 wtout2 wtout3 wtout4 wtout5;
run;

proc sort data=all;
	by intord label;
run;

data _null_;
  call symput('nsysdt',put("&sysdate"d,date9.));
run;

title1 "Table 101";
title2 "Demographics and Baseline Characteristics";

footnote1 "Date of Table Generation: &nsysdt(&systime)";

ODS PDF FILE="Table101.pdf";

ods pdf file="/home/piyushm20010/sasuser.v94/Table101.pdf";

options nobyline   MISSING=' ';



************ Generate the Report ***************************;
options nobyline;

proc report data = all  nowd headline headskip missing split = "^";
    column  intord label  Placebo Tafenoquine;
    define intord  /order order = Internal noprint;
    define label /display  "  ";
    define Placebo / display  "Placebo^(N=&bn1)" width=30;
    define Tafenoquine / display  "Tafenoquine^(N=&bn2)" width=35;
run;
   
%mend desc_char;

%desc_char;

ODS pdf close;







