/* Adapted from prepare-homepap-for-nsrr.sas (nsrr/homepap-data-dictionary).
   Block: incorporate nsrrid and clusterid into datasets.
   The libnames homepapi and the work baseline are replaced by the mock
   datasets built in autoexec.sas; the merge-and-sort logic below is the
   repository authors, unchanged. */

  data homepapbaseline_nsrr;
    length nsrrid clusterid 8.;
    merge homepap_nsrr_ids (keep=studyid nsrrid clusterid)
      homepapbaseline;
    by studyid;

    drop studyid;
  run;

  proc sort data=homepapbaseline_nsrr;
    by nsrrid;
  run;

  proc print data=homepapbaseline_nsrr;
    var nsrrid clusterid age gender race7;
  run;
