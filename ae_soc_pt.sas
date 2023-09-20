libname rawData "/home/piyushm20010/sasuser.v94";

data ae;
	set rawdata.adae;
	if trtemfl = "Y";
	aebodsys = upcase(aebodsys);
	aedecod = propcase(aedecod);
run;

proc sort data=ae out=ae1;
	by trt01an trt01a;
run;
/*************** BIG N **********/
proc sql;
   create table bign as
   select trt01an,trt01a, count(distinct(usubjid)) as count from ae1
   group by trt01an
   order by trt01an
   ;
quit;

proc sort data=bign nodupkey; by trt01an; run;
 
proc sql noprint;
      select distinct(count) into:n1-:n2 from bign order by trt01an;
 quit;

%let n1 = &n1;
%let n2 = &n2;
%put n1 = &n1.;
%put n2 = &n2.;

** Treatment emergent and all causalities **;
proc sort data = ae1 out = adae;
  by usubjid trt01an trt01a aebodsys aedecod;
  where aeterm ne ' ';
run;

proc sql;
	create table adv as
	select count(distinct(usubjid)) as n, trt01an, -3 as ord, 'With Any Adverse Event' as txt length=200
	from adae
	group by trt01an;

  	
   	create table soc as
   	select count(distinct(usubjid)) as n, aebodsys, trt01an
   	from adae
  	group by trt01an, aebodsys;

	create table preftext as
  	select count(distinct(usubjid)) as n, aebodsys, aedecod, trt01an
   	from adae
  	group by trt01an, aebodsys, aedecod;
quit;

data adv1;
	merge adv (in=a) bign (in=b);
	by trt01an;
	pct= put(n, 5.)||'  ('||strip(put(round(n/count*100,0.001), 6.3))||')';
run;
     
data all;
  set soc(in=a) preftext(in=c);
run;


proc sort data = all;
    by aebodsys aedecod trt01an;
run;
proc sort data = all out = aesoc (keep = aebodsys) nodupkey;
	by aebodsys;
run;

data ae_soc;
	merge all aesoc(in=a);
	by aebodsys;
run;

proc sort data=ae_soc;
	by trt01an;
run;

proc sort data=bign; by trt01an; run;

data ae_soc;
	merge ae_soc(in=a) bign(in=b);
	by trt01an; 	
run;

data all_1;
	set ae_soc;
	length txt $200;
	if aebodsys eq '' then txt = '**UNCODED TERMS BEING QUERIED';
	else if aebodsys ne '' and aedecod eq '' then txt = aebodsys ;
	else if aebodsys ne '' and aedecod ne ''  then txt = '          '|| aedecod;
	if n not in  (.,0) then pct= put(n, 5.)||'  ('||strip(put(round(n/count*100,0.001), 6.3))||')';
	else pct = '0';
run;

data final;
	set all_1;
run;

 proc sort data = final;
    by txt;
 run;

data fin1 fin2(rename=(pct=pct_2 n=n_2));
	set final;
	if trt01an in (1) then output fin1;
	if trt01an in (2) then output fin2;
run;

 proc sort data=fin1; by txt; run;
 proc sort data=fin2; by txt; run;

 data final1;
    merge fin1 fin2;
    by txt;
 run;

 data final1;
     set final1;
 run;
 
**title and footnote**;
title1 "Table 1";
title2 "Treat Emergent All Causality AEs by SOC and PT";

footnote1 "Date of Table Generation: &nsysdt(&systime)";

ODS PDF FILE="Table2.pdf";

ods pdf file="/home/piyushm20010/sasuser.v94/Table2.pdf";

options nobyline   MISSING=' ';
      
 /******************************************************************************
 * Generate Report                   			
 *******************************************************************************/
proc report data=final1 split='$' headline headskip  missing;
   column ("Number of Subjects Evaluable for AEs" txt)
         ("Tquine $   (N=&n1.)" pct)  ("Placebo $   (N=&n2.)"  pct_2);
   DEFINE txt /"Number (%) of Subjects:$by System Organ Class$          and Preferred Term" style(header)={just=l} width=80 left style(column)=[cellwidth=2.75in asis=on];
   DEFINE pct /"    n  (%)    " width=20 left style(column)={cellwidth=1.65in leftmargin=3px rightmargin=3px just=c} display;
   DEFINE pct_2 /"      n  (%)     " width=20 left style(column)={cellwidth=1.65in leftmargin=3px rightmargin=3px just=c} display;
run;

ODS pdf close;

