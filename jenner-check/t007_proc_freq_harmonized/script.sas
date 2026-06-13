/* Adapted from prepare-homepap-for-nsrr.sas (nsrr/homepap-data-dictionary).
   Block: checking harmonized datasets - categorical variables. The PROC
   FREQ step below is the repository authors, unchanged; it runs against
   the mock homepap_baseline_harmonized built in autoexec.sas. */

/* Checking categorical variables */

proc freq data=homepap_baseline_harmonized;
table   nsrr_age_gt89
    nsrr_sex
    nsrr_race
    nsrr_ethnicity;
run;
