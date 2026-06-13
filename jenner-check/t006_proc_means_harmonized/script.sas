/* Adapted from prepare-homepap-for-nsrr.sas (nsrr/homepap-data-dictionary).
   Block: checking harmonized datasets - extreme values for continuous
   variables. The PROC MEANS step below is the repository authors,
   unchanged; it runs against the mock homepap_baseline_harmonized built
   in autoexec.sas. */

/* Checking for extreme values for continuous variables */

proc means data=homepap_baseline_harmonized;
VAR   nsrr_age
    nsrr_bmi
    nsrr_bp_systolic
    nsrr_bp_diastolic
    nsrr_ahi_hp4u_aasm15
    nsrr_ttldursp_f1;
run;
