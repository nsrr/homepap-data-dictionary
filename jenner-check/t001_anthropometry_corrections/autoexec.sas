options obs=100;
options nofmterr;

/* Mock source dataset standing in for the external libname homepaps
   (UNC path nsrr-prep/_source) used upstream. Column shapes match the
   variables that the hpapmeasbase DATA step reads. Row 3 triggers the
   neck-greater-than-waist swap; row 4 triggers the inch-to-cm conversion. */
data homepapmeasbase;
  input studyid pmbs_heightcm pmbs_weightkg pmbs_bmi
        pmbs_neckcmmean pmbs_waistcmmean
        pmbs_sysbp2 pmbs_sysbp3 pmbs_diasbp2 pmbs_diasbp3;
  datalines;
1001 170.2 82.5 28.5 40.1 98.4 128 132 80 84
1002 165.0 70.0 25.7 38.0 92.0 118 122 76 78
1003 178.0 95.0 30.0 105.0 99.0 140 144 90 92
1004 160.0 60.0 23.4 15.5 90.0 110 114 70 72
1005 182.0 100.0 30.2 42.5 110.0 135 138 88 90
;
run;
