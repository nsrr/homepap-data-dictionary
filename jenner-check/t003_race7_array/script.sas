/* Adapted from prepare-homepap-for-nsrr.sas (nsrr/homepap-data-dictionary).
   Block: making new race with 7 categories (race7).
   The merged baseline inputs are replaced by the mock eligibility dataset
   built in autoexec.sas; the array-based counting logic below is the
   repository authors, unchanged. */

  data race;
    set elig;

  *making new race with 7 categories. There is a race variable with 7 categories, but did not take into account ethncity, also unclear which race corresponded to which number;
    if ethnicity = 1 and othrace = 1 then othrace = 0;
    race_count = 0;
    array elig_race(5) white aframerican hawaii asian amerindian;
    do i = 1 to 5;
      if elig_race(i) in (0,1) then race_count = race_count + elig_race(i);
    end;
    drop i;

    if white = 1 and race_count = 1 then race7 = 1; *White;
  if amerindian = 1 and race_count = 1 then race7 = 2; *American indian or Alaskan native;
    if aframerican = 1 and race_count = 1 then race7 = 3; *Black or african american;
    if asian = 1 and race_count = 1 then race7 = 4; *Asian;
  if hawaii = 1 and race_count = 1 then race7 =5; *native hawaiian or other pacific islander;
    if othrace = 1 and race_count = 0 then race7 = 6; *Other;
  if race_count > 1 then race7 = 7;  *Multiple;
  run;

  proc print data=race;
    var studyid race_count race7;
  run;
