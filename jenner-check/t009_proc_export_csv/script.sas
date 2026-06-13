/* Adapted from prepare-homepap-for-nsrr.sas (nsrr/homepap-data-dictionary).
   Block: export nsrr csv datasets.
   The hardcoded UNC release path is rewritten to a relative filename so the
   PROC EXPORT can run in isolation; the export statement is otherwise the
   repository authors, unchanged. The version macro variable mirrors the
   upstream "%let version = 0.2.0;". */

  %let version = 0.2.0;

  proc export data=homepapbaseline_nsrr
    outfile="homepap-baseline-dataset-&version..csv"
    dbms=csv
    replace;
  run;
