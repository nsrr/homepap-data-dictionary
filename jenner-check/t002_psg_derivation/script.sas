/* Adapted from prepare-homepap-for-nsrr.sas (nsrr/homepap-data-dictionary).
   Block: modify lab psg dataset to get key variables.
   The source libname homepaps.homepappsg is replaced by the mock dataset
   built in autoexec.sas; the derivation logic below is the repository
   authors, unchanged. */

  *modify lab psg dataset to get key variables;
  data hpappsg;
    set homepappsg;

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

  proc print data=hpappsg;
    var studyid type avgsao2 ahi_full ahi_d ahi_t;
  run;
