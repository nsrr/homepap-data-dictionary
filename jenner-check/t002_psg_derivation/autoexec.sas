options obs=100;
options nofmterr;

/* Mock source standing in for homepaps.homepappsg (the lab PSG dataset).
   Columns match the variables the hpappsg DATA step reads. Row with
   type "H" is dropped by the type filter; studyid 2159 type "S" and
   studyid 6480 with psg_qsrdi = 0 are dropped by the de-duplication rules. */
data homepappsg;
  input studyid type $ avsao2nh avsao2rh tmstg1p tmstg2p tmstg34p tmremp
        ahi rdi_d rdi_t psg_qsrdi;
  datalines;
1001 D 95.0 92.0 5 50 30 15 12.0 14.0 16.0 11.0
1002 S 96.0 .    8 48 28 16 22.0 25.0 27.0 21.0
1003 H 97.0 93.0 6 52 27 15 5.0  6.0  7.0  4.0
2159 S 94.0 90.0 7 49 29 15 30.0 33.0 35.0 28.0
6480 D 96.5 91.5 6 50 29 15 18.0 20.0 22.0 0.0
1006 D 95.5 92.5 5 51 29 15 9.0  10.0 11.0 8.0
;
run;
