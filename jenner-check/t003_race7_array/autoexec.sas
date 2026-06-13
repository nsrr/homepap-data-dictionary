options obs=100;
options nofmterr;

/* Mock eligibility/screening source standing in for the merged baseline
   inputs. Columns are the race indicator flags and ethnicity that the
   race7 categorization block reads. The rows exercise every race7 branch:
   single-race white/amerindian/black/asian/hawaiian, other, and multiple. */
data elig;
  input studyid white aframerican hawaii asian amerindian othrace ethnicity;
  datalines;
1 1 0 0 0 0 0 2
2 0 0 0 0 1 0 2
3 0 1 0 0 0 0 2
4 0 0 0 1 0 0 2
5 0 0 1 0 0 0 2
6 0 0 0 0 0 1 2
7 1 1 0 0 0 0 2
8 0 0 0 0 0 1 1
;
run;
