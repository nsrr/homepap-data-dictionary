/* Adapted from prepare-homepap-for-nsrr.sas (nsrr/homepap-data-dictionary).
   Block: create harmonized datasets (the nsrr_* variables).
   The source homepapbaseline_nsrr is replaced by the mock dataset built in
   autoexec.sas; the harmonization recode logic below is the repository
   authors, unchanged. */

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

  proc print data=homepap_baseline_harmonized;
    var nsrrid nsrr_age nsrr_age_gt89 nsrr_sex nsrr_race nsrr_ethnicity;
  run;
