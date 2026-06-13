options obs=100;
options nofmterr;

/* Mock standing in for homepapbaseline_nsrr (the NSRR-id-merged baseline).
   Columns match the variables the harmonization DATA step reads. Rows
   exercise the sex, race, ethnicity, and age_gt89 recode branches,
   including missing values that map to "not reported". */
data homepapbaseline_nsrr;
  input nsrrid visit age gender race7 ethnicity bmi systolic diastolic ahi tst_modified;
  datalines;
200001 1 54.3 1 1 2 28.5 130 82 12.0 380.5
200002 1 67.1 0 3 1 31.2 142 91 22.0 410.0
200003 1 91.5 1 7 . 26.0 120 78 9.0  395.0
200004 1 45.0 0 4 2 24.1 118 76 5.0  400.5
200005 1 72.8 1 6 2 33.0 150 95 30.0 360.0
;
run;
