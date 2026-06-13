options obs=100;
options nofmterr;

/* Mock standing in for homepap_baseline_harmonized (the output of the
   harmonization step). Columns are the continuous nsrr_* variables that
   the PROC MEANS extreme-value check reads. */
data homepap_baseline_harmonized;
  input nsrr_age nsrr_bmi nsrr_bp_systolic nsrr_bp_diastolic
        nsrr_ahi_hp4u_aasm15 nsrr_ttldursp_f1;
  datalines;
54.30 28.50 130 82 12.0 380.5
67.10 31.20 142 91 22.0 410.0
91.50 26.00 120 78 9.0  395.0
45.00 24.10 118 76 5.0  400.5
72.80 33.00 150 95 30.0 360.0
58.20 27.40 128 80 15.0 388.0
;
run;
