*******************************************************************************;
/* prepare-homepap-for-nsrr.sas */
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
  %let version = 0.1.0.beta3;

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

    *create race (categorical) variable;
    racetotal = sum(amerindian,hawaii,white,asian,aframerican,othrace);

    if racetotal = 1 and white = 1 then race3 = 1;
    else if racetotal = 1 and aframerican = 1 then race3 = 2;
    else if racetotal > 0 or othrace = 1 then race3 = 3;

    *create diagnostic type from analysis dataset;
    if ahisource = "EMB" then diagtype = 1;
    else if ahisource = "PSG" then diagtype = 2;
    else if ahisource = "SPL" then diagtype = 3;

    *only keep subset of variables;
    keep 
      /* administrative */
      studyid visit treatmentarm age gender race3 ethnicity 

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

      /* analysis indicators */
      pressure ablation ahi diagtype crossover ttt diagnostic ahige15 eligible 
      titrated acceptance completedm1 completedm3 completedm1m3 ;
  run;


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
    merge homepapbaseline (keep=studyid visit treatmentarm age gender race3
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
    keep studyid visit treatmentarm age gender race3 ethnicity systolic diastolic cal_total
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
    length studyid visit treatmentarm age gender race3 ethnicity 8.;
    merge homepapbaseline (keep=studyid visit treatmentarm age gender race3
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
    keep studyid visit treatmentarm age gender race3 ethnicity weightkg bmi systolic diastolic cal_total
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
