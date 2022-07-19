*******************************************************************************;
* Program           : prepare-homepap-for-nsrr.sas
* Project           : National Sleep Research Resource (sleepdata.org)
* Author            : Michael Rueschman (mnr)
* Date Created      : 20170823
* Purpose           : Prepare HomePAP data for posting on NSRR.
* Revision History  :
*   Date      Author    Revision
*   20170823  mnr       Add header to SAS script
*******************************************************************************;

*******************************************************************************;
* establish options and libnames ;
*******************************************************************************;
  options nofmterr;
  data _null_;
    call symput("sasfiledate",put(year("&sysdate"d),4.)||put(month("&sysdate"d),z2.)||put(day("&sysdate"d),z2.));
  run;

  *project source datasets;
  libname homepaps "\\rfawin\bwh-sleepepi-homepap\nsrr-prep\_source";

  *output location for nsrr sas datasets;
  libname homepapd "\\rfawin\bwh-sleepepi-homepap\nsrr-prep\_datasets";
  libname homepapa "\\rfawin\bwh-sleepepi-homepap\nsrr-prep\_archive";

  *nsrr id location;
  libname homepapi "\\rfawin\bwh-sleepepi-homepap\nsrr-prep\_ids";

  *set data dictionary version;
  %let version = 0.2.0.pre;

  *set nsrr csv release path;
  %let releasepath = \\rfawin\bwh-sleepepi-homepap\nsrr-prep\_releases;
*******************************************************************************;
* create baseline dataset ;
*******************************************************************************;
  data hpapeligibility;
    set homepaps.homepapeligibility;
  run;

  data hpapscreening;
    set homepaps.homepapmeasscrn;
  run;

  data hpapeligibilityscreening;
    merge hpapeligibility hpapscreening;
    by screenid;

    *rename variables;
    rename random_assign = treatmentarm;

    *drop certain variables to avoid conflicts later;
    drop sitread--driving race;
  run;

  *sort by studyid to be like other datasets;
  proc sort data=hpapeligibilityscreening;
    by studyid;
  run;

  *modify baseline measurement dataset to get key variables;
  data hpapmeasbase;
    set homepaps.homepapmeasbase;

    *create anthropometry variables;
    heightcm = pmbs_heightcm;
    weightkg = pmbs_weightkg;
    bmi = pmbs_bmi;
    neckcm = pmbs_neckcmmean;
    waistcm = pmbs_waistcmmean;

    *corrections for errant measurements;
    if neckcm > waistcm and neckcm ne . and waistcm ne . then do;
      waistcm2 = neckcm;
      neckcm2 = waistcm;
      neckcm = neckcm2;
      waistcm = waistcm2;
      drop waistcm2 neckcm2;
    end; /* values recorded in wrong order on data entry sheet */
    if neckcm < 20 then neckcm = neckcm * 2.54; *value recorded in inches;
    if waistcm < 60 then waistcm = waistcm * 2.54;

    *create systolic/diastolic blood pressure variables;
    systolic = mean(pmbs_sysbp2,pmbs_sysbp3);
    diastolic = mean(pmbs_diasbp2,pmbs_diasbp3);
  run;

  *modify lab psg dataset to get key variables;
  data hpappsg;
    set homepaps.homepappsg;

    *only keep diagnostic and split-night studies;
    if type in ("S","D");

    *create average sao2 for recording;
    if avsao2rh = . then avsao2rh_holder = 0;
      else avsao2rh_holder = avsao2rh;

    avgsao2 = ((avsao2nh) * (tmstg1p+tmstg2p+tmstg34p) + (avsao2rh_holder)*(tmremp))/100;
    drop avsao2rh_holder;
    format avgsao2 8.;

    *create new ahi variables;
    ahi_full = ahi;
    ahi_d = rdi_d;
    ahi_t = rdi_t;

    *delete duplicate/extraneous studies;
    if studyid = 2159 and type = "S" then delete;
    if studyid = 6480 and psg_qsrdi = 0 then delete;
  run;

  *modify home psg (embletta) dataset to get key variables;
  data hpapemb;
    set homepaps.homepapemb;

    *only keep passing studies;
    if emb_status = 1;
  run;

/*
  *checking race variable;
proc freq data=hpapeligibilityscreening;
table white aframerican hawaii asian amerindian othrace;
run;
*/

  *merge baseline data on studyid;
  data homepapbaseline;
    length studyid visit treatmentarm age gender race3 ethnicity 8.;
    merge hpapeligibilityscreening
      hpapmeasbase
      homepaps.homepapcalgarymerge (where=(timepoint=2))
      homepaps.homepapess (where=(timepoint=2))
      homepaps.homepapfosq (where=(timepoint=2))
      homepaps.homepapsf36 (where=(timepoint=2))
      homepaps.homepapsleepbase (where=(timepoint=2))
      hpappsg (drop=ahi)
      hpapemb
      homepaps.hpapanalysis_20110217;
    by studyid;

    *only keep randomized subjects;
    if studyid ne .;

    *create new visit code for nsrr;
    visit = 1;

    *create age variable;
    age = (enroll_date - pmbs_dob) / 365;
    if age < 20 then age = incl1_age; /* pull from eligibility if dob is missing */
    format age 8.;
  
  *making new race with 7 categories. There is a race variable with 7 categories, but did not take into account ethncity, also unclear which race corresponded to which number;
    if ethnicity = 1 and othrace = 1 then othrace = 0;
    race_count = 0;
    array elig_race(5) white aframerican hawaii asian amerindian;
    do i = 1 to 5;
      if elig_race(i) in (0,1) then race_count = race_count + elig_race(i);
    end;
    drop i;

    if white = 1 and race_count = 1 then race7 = 1; *White;
  if amerindian = 1 and race_count = 1 then race7 = 2; *American indian or Alaskan native;
    if aframerican = 1 and race_count = 1 then race7 = 3; *Black or african american;
    if asian = 1 and race_count = 1 then race7 = 4; *Asian;
  if hawaii = 1 and race_count = 1 then race7 =5; *native hawaiian or other pacific islander;
    if othrace = 1 and race_count = 0 then race7 = 6; *Other;
  if race_count > 1 then race7 = 7;  *Multiple;
    
  /*
  *Old race with 3 categories;
    *create race (categorical) variable;
    racetotal = sum(amerindian,hawaii,white,asian,aframerican,othrace);

    if racetotal = 1 and white = 1 then race3 = 1;
    else if racetotal = 1 and aframerican = 1 then race3 = 2;
    else if racetotal > 0 or othrace = 1 then race3 = 3;
  */

    *create diagnostic type from analysis dataset;
    if ahisource = "EMB" then do;
  diagtype = 1;
  tst_modified = index_time;
  end;
  else if ahisource = "PSG" then do;
  diagtype = 2;
  tst_modified = slpprdp;
  end;
  else if ahisource = "SPL" then do;
  diagtype = 3;
  tst_modified = slpprd_d;
  end;

    *for lab sleep studies, modify certain variables based on full/split night;
    if diagtype = 3 then slpprdp = .; /* use slpprd_d */
    pctsa90p_d = 100 * (PCTSA90_D / SLPPRD_D);
    pctsa90p_t = 100 * (PCTSA90_T / SLPPRD_T);
    format pctsa90p_d pctsa90p_t 8.1;

    *only keep subset of variables;
    keep
      /* administrative */
      studyid visit treatmentarm age gender race7 ethnicity

      /* anthropometry */
      heightcm weightkg bmi neckcm waistcm systolic diastolic

      /* calgary */
      cal_total

      /* epworth, ess */
      esstotal

      /* fosq */
      fosq_genprd fosq_socout fosq_actlev fosq_vigiln fosq_sexual
      fosq_global

      /* sf-36 */
      PF_norm RP_norm BP_norm GH_norm VT_norm SF_norm RE_norm MH_norm agg_phys
      agg_ment sf36_PCS sf36_MCS

      /* medical history */
      dxasth dxadhd dxca dxcatyp dxchf dxchd dxdep dxdiab dxemph dxgerd dxhay
      dxhich dxhtn dxhyperthy dxhypothy dxkidney dxliver dxplhtn dxseiz dxstroke

      /* psg - full */
      slpprdp slpeffp TMSTG1P TMSTG2P TMSTG34P TMREMP avgsao2
      PCTSA90H AVGHR ahi_full STLOUTP STLONP

      /* psg - split, diagnostic */
      SLPPRD_D slpeff_d PCTSTG1_D PCTSTG2_D PCTSTG34_D PCTREM_D AVGSAO2_D
      pctsa90p_d AVGHR_D ahi_d

      /* psg - split, treatment */
      SLPPRD_T slpeff_t PCTSTG1_T PCTSTG2_T PCTSTG34_T PCTREM_T AVGSAO2_T
      pctsa90p_t AVGHR_T ahi_t

      /* embletta */
      index_time aphypi avgsat satlt90p avgbpn starttime endtime

      /* analysis indicators */
      pressure ablation ahi diagtype crossover ttt diagnostic ahige15 eligible
      titrated acceptance completedm1 completedm3 completedm1m3 tst_modified;
  run;

/*
  proc print data = homepapbaseline (obs=3);
  var gender;
  run;
  *checking race variable;
proc freq data=homepapbaseline;
table race7;
run;
*/

*******************************************************************************;
* create month 1 follow-up dataset ;
*******************************************************************************;
  *modify month1 measurement dataset to get key variables;
  data hpapmeasm1;
    set homepaps.homepapmeasm1;

    *create systolic/diastolic blood pressure variables;
    systolic = mean(pmm1_sysbp2,pmm1_sysbp3);
    diastolic = mean(pmm1_diasbp2,pmm1_diasbp3);
  run;

  data homepapmonth1;
    length studyid visit treatmentarm age gender race3 ethnicity 8.;
    merge homepapbaseline (keep=studyid visit treatmentarm age gender race7
        ethnicity)
      hpapmeasm1
      homepaps.homepapcalgarymerge (where=(timepoint=5))
      homepaps.homepapess (where=(timepoint=5))
      homepaps.homepapfosq (where=(timepoint=5))
      homepaps.homepapsf36 (where=(timepoint=5))
      homepaps.hpapanalysis_20110217 (keep=studyid avguse_m1 rename=(avguse_m1=avgpapuse));
    by studyid;

    *only keep randomized subjects;
    if studyid ne .;

    *create new visit code for nsrr;
    visit = 2;

    *only keep subset of variables;
    keep studyid visit treatmentarm age gender race7 ethnicity systolic diastolic cal_total
      esstotal fosq_genprd fosq_socout fosq_actlev fosq_vigiln fosq_sexual
      fosq_global PF_norm RP_norm BP_norm GH_norm VT_norm SF_norm RE_norm
      MH_norm agg_phys agg_ment sf36_PCS sf36_MCS avgpapuse;
  run;


*******************************************************************************;
* create month 3 follow-up dataset ;
*******************************************************************************;
  *modify month3 measurement dataset to get key variables;
  data hpapmeasm3;
    set homepaps.homepapmeasm3;

    *create anthropometry variables;
    weightkg = pmm3_weightkg;
    bmi = pmm3_bmi;

    *create systolic/diastolic blood pressure variables;
    systolic = mean(pmm3_sysbp2,pmm3_sysbp3);
    diastolic = mean(pmm3_diasbp2,pmm3_diasbp3);
  run;

  data homepapmonth3;
    length studyid visit treatmentarm age gender ethnicity 8.;
    merge homepapbaseline (keep=studyid visit treatmentarm age gender race7
        ethnicity)
      hpapmeasm3
      homepaps.homepapcalgarymerge (where=(timepoint=6))
      homepaps.homepapess (where=(timepoint=6))
      homepaps.homepapfosq (where=(timepoint=6))
      homepaps.homepapsf36 (where=(timepoint=6))
      homepaps.hpapanalysis_20110217 (keep=studyid avguse_m3 rename=(avguse_m3=avgpapuse));
    by studyid;

    *only keep randomized subjects;
    if studyid ne .;

    *create new visit code for nsrr;
    visit = 3;

    *only keep subset of variables;
    keep studyid visit treatmentarm age gender race7 ethnicity weightkg bmi systolic diastolic cal_total
      esstotal fosq_genprd fosq_socout fosq_actlev fosq_vigiln fosq_sexual
      fosq_global PF_norm RP_norm BP_norm GH_norm VT_norm SF_norm RE_norm
      MH_norm agg_phys agg_ment sf36_PCS sf36_MCS avgpapuse;
  run;

*******************************************************************************;
* incorporate nsrrid and clusterid into datasets ;
*******************************************************************************;
  data homepapbaseline_nsrr;
    length nsrrid clusterid 8.;
    merge homepapi.homepap_nsrr_ids (keep=studyid nsrrid clusterid)
      homepapbaseline;
    by studyid;

    drop studyid;
  run;

  proc sort data=homepapbaseline_nsrr;
    by nsrrid;
  run;

  data homepapmonth1_nsrr;
    length nsrrid clusterid 8.;
    merge homepapi.homepap_nsrr_ids (keep=studyid nsrrid clusterid)
      homepapmonth1;
    by studyid;

    drop studyid;
  run;

  proc sort data=homepapmonth1_nsrr;
    by nsrrid;
  run;

  data homepapmonth3_nsrr;
    length nsrrid clusterid 8.;
    merge homepapi.homepap_nsrr_ids (keep=studyid nsrrid clusterid)
      homepapmonth3;
    by studyid;

    drop studyid;
  run;

  proc sort data=homepapmonth3_nsrr;
    by nsrrid;
  run;


*******************************************************************************;
* create harmonized datasets ;
*******************************************************************************;
data homepap_baseline_harmonized;
  set homepapbaseline_nsrr;
*demographics
*age;
*use age;
  format nsrr_age 8.2;
  nsrr_age = age;

*age_gt89;
*use age;
  format nsrr_age_gt89 $100.; 
  if age gt 89 then nsrr_age_gt89='yes';
  else if age le 89 then nsrr_age_gt89='no';

*sex;
*use gender;
  format nsrr_sex $100.;
    if gender = 1 then nsrr_sex='male';
  else if gender = 0 then nsrr_sex='female';
  else nsrr_sex = 'not reported';

*race;
*race7 created above for homepapbaseline from racetotal and specific race variables;
    format nsrr_race $100.;
  if race7 = 1 then nsrr_race = 'white';
    else if race7 = 2 then nsrr_race = 'american indian or alaska native';
  else if race7 = 3 then nsrr_race = 'black or african american';
  else if race7 = 4 then nsrr_race = 'asian';
  else if race7 = 5 then nsrr_race = 'native hawaiian or other pacific islander';
    else if race7 = 6 then nsrr_race = 'other';
    else if race7 = 7 then nsrr_race = 'multiple';
  else nsrr_race  = 'not reported';

*ethnicity;
*use ethnicity;
  format nsrr_ethnicity $100.;
    if ethnicity = 1 then nsrr_ethnicity = 'hispanic or latino';
    else if ethnicity = 2 then nsrr_ethnicity = 'not hispanic or latino';
  else if ethnicity = . then nsrr_ethnicity = 'not reported';

*anthropometry
*bmi;
*use bmi;
  format nsrr_bmi 10.9;
  nsrr_bmi = bmi;

*clinical data/vital signs
*bp_systolic;
*use systolic;
  format nsrr_bp_systolic 8.2;
  nsrr_bp_systolic = systolic;

*bp_diastolic;
*use diastolic;
  format nsrr_bp_diastolic 8.2;
  nsrr_bp_diastolic = diastolic;

*lifestyle and behavioral health
*current_smoker;
*ever_smoker;
  *not available;

*polysomnography;
  
*nsrr_ahi_hp4u_aasm15;
*use ahi;
  format nsrr_ahi_hp4u_aasm15 8.2;
  nsrr_ahi_hp4u_aasm15 = ahi;
  
*nsrr_ttldursp_f1;
*use tst_modified;
  format nsrr_ttldursp_f1 8.2;
  nsrr_ttldursp_f1 = tst_modified;
 
 
  keep 
    nsrrid
    visit
    nsrr_age
    nsrr_age_gt89
    nsrr_sex
    nsrr_race
    nsrr_ethnicity
    nsrr_bp_systolic
    nsrr_bp_diastolic
    nsrr_bmi
    nsrr_ahi_hp4u_aasm15
    nsrr_ttldursp_f1
    ;
run;

*******************************************************************************;
* checking harmonized datasets ;
*******************************************************************************;

/* Checking for extreme values for continuous variables */

proc means data=homepap_baseline_harmonized;
VAR   nsrr_age
    nsrr_bmi
    nsrr_bp_systolic
    nsrr_bp_diastolic
    nsrr_ahi_hp4u_aasm15
    nsrr_ttldursp_f1;
run;

/* Checking categorical variables */

proc freq data=homepap_baseline_harmonized;
table   nsrr_age_gt89
    nsrr_sex
    nsrr_race
    nsrr_ethnicity;
run;

*******************************************************************************;
* make all variable names lowercase ;
*******************************************************************************;
  options mprint;
  %macro lowcase(dsn);
       %let dsid=%sysfunc(open(&dsn));
       %let num=%sysfunc(attrn(&dsid,nvars));
       %put &num;
       data &dsn;
             set &dsn(rename=(
          %do i = 1 %to &num;
          %let var&i=%sysfunc(varname(&dsid,&i));    /*function of varname returns the name of a SAS data set variable*/
          &&var&i=%sysfunc(lowcase(&&var&i))         /*rename all variables*/
          %end;));
          %let close=%sysfunc(close(&dsid));
    run;
  %mend lowcase;

  %lowcase(homepapbaseline_nsrr);
  %lowcase(homepapmonth1_nsrr);
  %lowcase(homepapmonth3_nsrr);
  %lowcase(homepap_baseline_harmonized);

*******************************************************************************;
* create permanent sas datasets ;
*******************************************************************************;
  data homepapd.homepapbaseline homepapa.homepapbaseline_&sasfiledate;
    set homepapbaseline_nsrr;
  run;

  data homepapd.homepapmonth1 homepapa.homepapmonth1_&sasfiledate;;
    set homepapmonth1_nsrr;
  run;

  data homepapd.homepapmonth3 homepapa.homepapmonth3_&sasfiledate;;
    set homepapmonth3_nsrr;
  run;

*******************************************************************************;
* export nsrr csv datasets ;
*******************************************************************************;
  proc export data=homepapbaseline_nsrr
    outfile="&releasepath\&version\homepap-baseline-dataset-&version..csv"
    dbms=csv
    replace;
  run;

  proc export data=homepapmonth1_nsrr
    outfile="&releasepath\&version\homepap-month1-dataset-&version..csv"
    dbms=csv
    replace;
  run;

  proc export data=homepapmonth3_nsrr
    outfile="&releasepath\&version\homepap-month3-dataset-&version..csv"
    dbms=csv
    replace;
  run;

  proc export data=homepap_baseline_harmonized
    outfile="&releasepath\&version\homepap-baseline-harmonized-dataset-&version..csv"
    dbms=csv
    replace;
  run;


