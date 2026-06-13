options obs=100;
options nofmterr;

/* Mock standing in for homepapbaseline_nsrr, the dataset the upstream
   release step exports to CSV. The hardcoded UNC release path
   (&releasepath/&version/...) is rewritten to a relative file below so the
   export can run in isolation. */
data homepapbaseline_nsrr;
  input nsrrid clusterid visit treatmentarm age gender race7 ethnicity;
  datalines;
200001 1 1 1 54 1 1 2
200002 1 1 2 67 0 3 1
200003 2 1 1 45 1 4 2
200004 2 1 2 72 1 7 2
;
run;
