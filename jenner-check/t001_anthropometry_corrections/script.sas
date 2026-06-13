/* Adapted from prepare-homepap-for-nsrr.sas (nsrr/homepap-data-dictionary).
   Block: modify baseline measurement dataset to get key variables.
   The source libname homepaps.homepapmeasbase is replaced by the mock
   dataset built in autoexec.sas; the transformation logic below is the
   repository authors, unchanged. */

  *modify baseline measurement dataset to get key variables;
  data hpapmeasbase;
    set homepapmeasbase;

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

  proc print data=hpapmeasbase;
    var studyid heightcm weightkg bmi neckcm waistcm systolic diastolic;
  run;
