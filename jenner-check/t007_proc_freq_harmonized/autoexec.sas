options obs=100;
options nofmterr;

/* Mock standing in for homepap_baseline_harmonized. Columns are the
   categorical nsrr_* variables that the PROC FREQ check reads, populated
   with the harmonized character labels the upstream recode produces.
   Pipe-delimited so the multi-word race and ethnicity labels stay in
   their own columns. */
data homepap_baseline_harmonized;
  length nsrr_age_gt89 $8 nsrr_sex $16 nsrr_race $50 nsrr_ethnicity $30;
  infile datalines dsd dlm='|';
  input nsrr_age_gt89 $ nsrr_sex $ nsrr_race $ nsrr_ethnicity $;
  datalines;
no|male|white|not hispanic or latino
no|female|black or african american|hispanic or latino
yes|male|multiple|not reported
no|female|asian|not hispanic or latino
no|male|other|not hispanic or latino
no|female|white|not hispanic or latino
;
run;
