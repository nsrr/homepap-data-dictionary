options obs=100;
options nofmterr;

/* Mock standing in for homepapi.homepap_nsrr_ids (the NSRR id crosswalk)
   and homepapbaseline (the analytic baseline). Both are keyed by studyid;
   the merge attaches nsrrid/clusterid, drops studyid, and sorts by nsrrid. */
data homepap_nsrr_ids;
  input studyid nsrrid clusterid;
  datalines;
1001 200003 1
1002 200001 1
1003 200002 2
1006 200004 2
;
run;

data homepapbaseline;
  input studyid age gender race7;
  datalines;
1001 54 1 1
1002 67 0 3
1003 45 1 4
1006 72 1 7
;
run;
