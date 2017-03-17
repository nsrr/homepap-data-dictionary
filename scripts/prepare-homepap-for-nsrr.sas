*******************************************************************************;
/* prepare-homepap-for-nsrr.sas */
*******************************************************************************;

*******************************************************************************;
* establish options and libnames ;
*******************************************************************************;
  options nofmterr;

  *project source datasets;
  libname homepaps "\\rfawin\bwh-sleepepi-homepap\nsrr-prep\_source";

  *output location for nsrr sas datasets;
  libname homepapd "\\rfawin\bwh-sleepepi-homepap\nsrr-prep\_datasets";

  *set data dictionary version;
  %let version = 0.1.0.beta1;

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

    *create systolic/diastolic blood pressure variables;
    systolic = mean(pmbs_sysbp2,pmbs_sysbp3);
    diastolic = mean(pmbs_diasbp2,pmbs_diasbp3);
  run;

  *merge baseline data on studyid;
  data homepapbaseline;
    length studyid visit treatmentarm siteid age gender race3 ethnicity 8.;
    merge hpapeligibilityscreening
      hpapmeasbase
      homepaps.homepapcalgarymerge (where=(timepoint=2))
      homepaps.homepapess (where=(timepoint=2))
      homepaps.homepapfosq (where=(timepoint=2))
      homepaps.homepapsf36 (where=(timepoint=2))
      homepaps.hpapanalysis_20110217;
    by studyid;

    *only keep randomized subjects;
    if studyid ne .;

    *create new visit code for nsrr;
    visit = 1;

    *create age variable;
    age = (enroll_date - pmbs_dob) / 365;
    format age 8.;

    *create race (categorical) variable;
    racetotal = sum(amerindian,hawaii,white,asian,aframerican,othrace);
    
    if racetotal = 1 and white = 1 then race3 = 1;
    else if racetotal = 1 and aframerican = 1 then race3 = 2;
    else if racetotal > 0 or othrace = 1 then race3 = 3;

    *only keep subset of variables;
    keep studyid visit treatmentarm siteid age gender race3 ethnicity heightcm
      weightkg bmi neckcm waistcm systolic diastolic cal_total esstotal
      fosq_genprd fosq_socout fosq_actlev fosq_vigiln fosq_sexual
      fosq_global PF_norm RP_norm BP_norm GH_norm VT_norm SF_norm RE_norm
      MH_norm agg_phys agg_ment sf36_PCS sf36_MCS pressure ablation ahi
      ahisource crossover ttt diagnostic ahige15 eligible titrated 
      acceptance completedm1 completedm3 completedm1m3 ;
  run;


*******************************************************************************;
* create month 1 follow-up dataset ;
*******************************************************************************;
  data homepapmonth1;
    length studyid visit treatmentarm siteid age gender race3 ethnicity 8.;
    merge homepapbaseline (keep=studyid visit treatmentarm age gender race3 
        ethnicity)
      homepaps.homepapcalgarymerge (where=(timepoint=5))
      homepaps.homepapess (where=(timepoint=5))
      homepaps.homepapfosq (where=(timepoint=5))
      homepaps.homepapsf36 (where=(timepoint=5));
    by studyid;

    *create new visit code for nsrr;
    visit = 2;

    *only keep subset of variables;
    keep studyid visit treatmentarm siteid age gender race3 ethnicity cal_total 
      esstotal fosq_genprd fosq_socout fosq_actlev fosq_vigiln fosq_sexual
      fosq_global PF_norm RP_norm BP_norm GH_norm VT_norm SF_norm RE_norm
      MH_norm agg_phys agg_ment sf36_PCS sf36_MCS;
  run;


*******************************************************************************;
* create month 3 follow-up dataset ;
*******************************************************************************;
  data homepapmonth3;
    length studyid visit treatmentarm siteid age gender race3 ethnicity 8.;
    merge homepapbaseline (keep=studyid visit treatmentarm age gender race3 
        ethnicity)
      homepaps.homepapcalgarymerge (where=(timepoint=6))
      homepaps.homepapess (where=(timepoint=6))
      homepaps.homepapfosq (where=(timepoint=6))
      homepaps.homepapsf36 (where=(timepoint=6));
    by studyid;

    *create new visit code for nsrr;
    visit = 3;

    *only keep subset of variables;
    keep studyid visit treatmentarm siteid age gender race3 ethnicity cal_total 
      esstotal fosq_genprd fosq_socout fosq_actlev fosq_vigiln fosq_sexual
      fosq_global PF_norm RP_norm BP_norm GH_norm VT_norm SF_norm RE_norm
      MH_norm agg_phys agg_ment sf36_PCS sf36_MCS;
  run;


*******************************************************************************;
* create permanent sas datasets ;
*******************************************************************************;
  data homepapd.homepapbaseline;
    set homepapbaseline;
  run;

  data homepapd.homepapmonth1;
    set homepapmonth1;
  run;

  data homepapd.homepapmonth3;
    set homepapmonth1;
  run;

*******************************************************************************;
* export nsrr csv datasets ;
*******************************************************************************;
  proc export data=homepapbaseline
    outfile="&releasepath\&version\homepap-baseline-&version..csv"
    dbms=csv
    replace;
  run;

  proc export data=homepapmonth1
    outfile="&releasepath\&version\homepap-month1-&version..csv"
    dbms=csv
    replace;
  run;

  proc export data=homepapmonth3
    outfile="&releasepath\&version\homepap-month3-&version..csv"
    dbms=csv
    replace;
  run;
