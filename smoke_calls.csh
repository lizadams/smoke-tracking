#!/bin/csh -f

############################### smoke_calls.csh ###################################
# This is a script that calls the SMOKE executables, manages MWSS process,
# creates QA reports, etc.  These setting were removed from the source-specific 
# run scripts to clean them up.
#
# Script created by :  UNC-IE  (Jan 2014) 
###################################################################################
set month = $argv[1]
setenv T_TYPE $L_TYPE                 # Set temporal type to type for temporal
source $SCRIPTS/run/set_days_v3.csh   # Call script to set dates for run
set g_stdate_sav = $G_STDATE

# Run Part 1: Smkinven, Grdmat, and Spcmat
#
if ( $RUN_SMKINVEN == Y || $RUN_SPCMAT == Y || $RUN_GRDMAT == Y || \
     $RUN_CNTLMAT == Y || $RUN_SMKREPORT == Y || $RUN_NORMBEIS3 == Y || \
     $RUN_MBSETUP == Y || $RUN_PREMOBL == Y || $RUN_GRWINVEN == Y ) then

   setenv RUN_PART1 Y
   source $ASSIGNS_FILE                     # Invoke Assigns file (RUN_PART1 needs to be set for files to be deleted)
   source $SCRIPTS/run/smk_run_v2.csh       # Run programs

   if ( $RUN_CNTLMAT == Y || $RUN_GRWINVEN == Y ) then
      setenv APMAT01 $APMAT
      source $SCRIPTS/run/cntl_run.csh      # Run Cntlmat and Grwinven
   endif

   if ( $RUN_SMKREPORT == Y ) then
    if (  $QA_TYPE == part1 || $QA_TYPE == all ) then
      setenv QA_LABEL $SRCABBR           # Used to name the report inputs and outputs
      setenv REPLABEL $SRCABBR           # Used internally by Smkreport
      source $SCRIPTS/run/qa_run.csh     # Run QA for part 1
      setenv RUN_PART1 N
    endif
   endif
   setenv RUN_PART1 N
endif ## Run Part 1

## Run Part 1.5: Emisfac for mobile sources
#
if ( $RUN_EMISFAC == Y ) then

   source $ASSIGNS_FILE      # Invoke Assigns file
   source $SCRIPTS/run/emisfac_run.csh    # Run Emisfac

endif ## Run Part 1.5

## Run Part 2: Time-dependent non-merge programs
#
if ( $RUN_TEMPORAL == Y || $RUN_TMPBEIS3 == Y || $RUN_SMKREPORT == Y ) then

   setenv RUN_PART2 Y
   setenv tmpb_save $RUN_TMPBEIS3         # Save Tmpbeis3 settings
   setenv smkrep_save $RUN_SMKREPORT      # Save Smkreport settings

   ## Determine dates to run in this month
   #
   setenv MONTH ${month}                 # Set variable for month name
   source $ASSIGNS_FILE                  # Invoke Assigns file to set new dates
   setenv T_TYPE $L_TYPE                 # Set type for Temporal
   source $SCRIPTS/run/set_days_v3.csh   # Call script to set dates for run

   ## Run Temporal
   #
   if ( $RUN_TEMPORAL == Y ) then
      setenv RUN_TMPBEIS3 N
      setenv RUN_SMKREPORT N
      source $ASSIGNS_FILE
      source $SCRIPTS/run/set_days_v3.csh
      set ndays = `cat $SMK_RUN_DATES | wc -l`

      if($M_TYPE == all ) then
        if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then
            @ ndy = $ENDDATE_OVERRIDE - $STDATE_OVERRIDE
            @ ndays = $ndy + 1
            set x = 0
            set diff = 0
            set g_stdate_sav = $G_STDATE
      ## Loop through days to run during the month.
          while ( $x < $ndays )
	       set diff = $x
	       @ x = $x + 1
               setenv G_STDATE_ADVANCE $diff
               source $ASSIGNS_FILE                  # Invoke Assigns to set new dates
               source $SCRIPTS/run/set_days_v3.csh
               source $SCRIPTS/run/smk_run_v2.csh    # Run TEMPORAL
            end # while

         else
            source $ASSIGNS_FILE  # Invoke Assigns to set new dates
            source $SCRIPTS/run/smk_run_v2.csh    # Run programs
         endif
      else
         source $ASSIGNS_FILE  # Invoke Assigns to set new dates
         source $SCRIPTS/run/smk_run_v2.csh    # Run programs
      endif

        unsetenv G_STDATE_ADVANCE
        setenv RUN_TEMPORAL N
        setenv RUN_TMPBEIS3 $tmpb_save
        setenv RUN_SMKREPORT $smkrep_save
   endif

   ## Run Tmpbeis
   # 
   if ( $RUN_TMPBEIS3 == Y ) then
      source $ASSIGNS_FILE
      set ndays = `cat $SMK_RUN_DATES | wc -l`
      if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then
         set ndays = $EPI_NDAY
      endif
      set x = 0
      set diff = 0
      set g_stdate_sav = $G_STDATE
      ## Loop through days to run during the month.
      while ( $x < $ndays )
	 if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then 
           @ STDATE_OVERRIDE = $STDATE_OVERRIDE + $x
	   set diff = $x
	   @ x = $x + 1
	 else
	    @ x = $x + 1
	    set line = `head -n $x $SMK_RUN_DATES | tail -n 1`
            @ diff = $line[1] - $g_stdate_sav
         endif
         setenv G_STDATE_ADVANCE $diff
         source $ASSIGNS_FILE                  # Invoke Assigns to set new dates
         source $SCRIPTS/run/smk_run_v2.csh    # Run Tmpbeis3
      end # while
   endif                                       # End run Tmpbeis3 loop
  
   ## Run Smkreport for part 2
   #
   if ( $RUN_SMKREPORT == Y ) then
      if ( $QA_TYPE == part2  || $QA_TYPE == custom || $QA_TYPE == profile || $QA_TYPE == all ) then
      ## Determine the number of days to run for merge etc
      set ndays = `cat $SMK_RUN_DATES | wc -l`
      if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then
         set ndays = $EPI_NDAY
      endif
      set x = 0
      set diff = 0
      set g_stdate_sav = $G_STDATE
      ## Loop through days to run during the month.
      while ( $x < $ndays )
	 if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then 
	   set diff = $x
	   @ x = $x + 1
	 else
	   @ x = $x + 1
	   set line = `head -n $x $SMK_RUN_DATES | tail -n 1`
           @ diff = $line[1] - $g_stdate_sav
         endif
	 setenv G_STDATE_ADVANCE $diff
	 source $ASSIGNS_FILE               # Invoke Assigns to set new dates
	 setenv QA_LABEL $SRCABBR           # Used to name the report inputs and outputs
	 setenv REPLABEL $SRCABBR           # Used internally by Smkreport
	 source $SCRIPTS/run/qa_run.csh     # Run programs
      end # while
   endif 
   endif # End Part 2 Smkreport Loop
   setenv RUN_PART2 N

endif  ## End Part 2
 
## Run Parts 3 and 4:  Elevpoint, Smkmerge and Smkreport, and optionally, Smk2emis (for CAMx)
#
if ( $RUN_LAYPOINT == Y || $RUN_SMKMERGE == Y || $RUN_SMK2EMIS == Y || \
      $RUN_MRGELEV == Y || $RUN_MRGGRID == Y || $RUN_SMKREPORT == Y || \
      $RUN_MOVESMRG == Y || $RUN_ELEVPOINT == Y ) then
   setenv mrg_save $RUN_SMKMERGE         # Save Smkmerge settings
   setenv layp_save $RUN_LAYPOINT        # Save Laypoint settings
   setenv smk2emis_save $RUN_SMK2EMIS    # Save Smk2emis settings
   setenv mrggrid_save $RUN_MRGGRID      # Save Mrggrid settings
   setenv mrgelev_save $RUN_MRGELEV      # Save Mrgelev settings
   setenv smkrept_save $RUN_SMKREPORT      # Save Mrgelev settings
   setenv G_STDATE $g_stdate_sav
   source $ASSIGNS_FILE                   # Invoke Assigns file to set new dates  

   ## First run Elevpoint
   #
   if ( $RUN_ELEVPOINT == Y ) then
      setenv RUN_PART3 Y

    if ( $ELEVPOINT_MULTI == Y ) then
      ## Determine the number of days to run for laypoint
      source $ASSIGNS_FILE

      source $SCRIPTS/run/set_days_v3.csh
      set ndays = `cat $SMK_RUN_DATES | wc -l`
      if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then
         set ndays = $EPI_NDAY
      else
      endif
      set x = 0
      set diff = 0
      set g_stdate_sav = $G_STDATE
      ## Loop through days to run during the month.
      while ( $x < $ndays )
	 if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then 
	   set diff = $x
	   @ x = $x + 1
	 else
	    @ x = $x + 1
	    set line = `head -n $x $SMK_RUN_DATES | tail -n 1`
            @ diff = $line[1] - $g_stdate_sav
         endif
         setenv G_STDATE_ADVANCE $diff
         source $ASSIGNS_FILE  # Invoke Assigns to set new dates
         source $SCRIPTS/run/smk_run_v2.csh    # Run programs
      
      end # while
      else
         source $ASSIGNS_FILE  # Invoke Assigns to set new dates
         source $SCRIPTS/run/smk_run_v2.csh    # Run programs
      endif
      unsetenv G_STDATE_ADVANCE
      setenv RUN_ELEVPOINT N
      setenv RUN_PART3 N
      setenv G_STDATE $g_stdate_sav
   endif                                   # Run Laypoint loop
   #
   ## Then run Laypoint
   #
   if ( $RUN_LAYPOINT == Y ) then
      setenv RUN_PART4 Y
      setenv RUN_ELEVPOINT N
      setenv RUN_SMKMERGE N
      setenv RUN_SMK2EMIS N
      setenv RUN_MRGGRID N
      setenv RUN_MRGELEV N
      setenv RUN_SMKREPORT N

      ## Determine the number of days to run for laypoint
      source $ASSIGNS_FILE
      setenv T_TYPE all
      source $SCRIPTS/run/set_days_v3.csh
      set ndays = `cat $SMK_RUN_DATES | wc -l`
      if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then
         set ndays = $EPI_NDAY
      else
      endif
      set x = 0
      set diff = 0
      set g_stdate_sav = $G_STDATE
      ## Loop through days to run during the month.
      while ( $x < $ndays )
	 if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then 
	   set diff = $x
	   @ x = $x + 1
	 else
	    @ x = $x + 1
	    set line = `head -n $x $SMK_RUN_DATES | tail -n 1`
            @ diff = $line[1] - $g_stdate_sav
         endif
         setenv G_STDATE_ADVANCE $diff
         source $ASSIGNS_FILE  # Invoke Assigns to set new dates
         source $SCRIPTS/run/smk_run_v2.csh    # Run programs

      end # while

      unsetenv G_STDATE_ADVANCE
      setenv RUN_LAYPOINT N
      setenv RUN_PART4 N
      setenv RUN_SMKMERGE $mrg_save        # Reset the Smkmerge run setting from above
      setenv RUN_SMK2EMIS $smk2emis_save   # Reset the Smk2emis run setting from above
      setenv RUN_MRGGRID $mrggrid_save     # Reset the Mrggrid run setting from above
      setenv RUN_MRGELEV $mrgelev_save     # Reset the Mrgelev run setting from above
      setenv RUN_SMKREPORT $smkrept_save   # Reset the Mrgelev run setting from above
      setenv G_STDATE $g_stdate_sav
   endif                                   # Run Laypoint loop
   #
   ## Run Smkreport for part 4
   #
   if ( $RUN_SMKREPORT == Y ) then
   if ( $QA_TYPE == part4 || $QA_TYPE == all ) then
      setenv RUN_PART4 Y
      ## Determine the number of days to run for merge etc
      set ndays = `cat $SMK_RUN_DATES | wc -l`
      if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then
         set ndays = $EPI_NDAY
      endif
      set x = 0
      set diff = 0
      set g_stdate_sav = $G_STDATE
      ## Loop through days to run during the month.
      while ( $x < $ndays )
         if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then
           set diff = $x
           @ x = $x + 1
         else
           @ x = $x + 1
           set line = `head -n $x $SMK_RUN_DATES | tail -n 1`
           @ diff = $line[1] - $g_stdate_sav
         endif
         setenv G_STDATE_ADVANCE $diff
         source $ASSIGNS_FILE               # Invoke Assigns to set new dates
         setenv QA_LABEL $SRCABBR           # Used to name the report inputs and outputs
         setenv REPLABEL $SRCABBR           # Used internally by Smkreport
         source $SCRIPTS/run/qa_run.csh     # Run programs
      end # while
   endif                                    # End Part 4 Smkreport Loop
      unsetenv G_STDATE_ADVANCE
      setenv G_STDATE $g_stdate_sav
   endif 
   setenv RUN_PART4 N
     
   ## First set MWDSS temporal intermediates if MRG_BYDAY is set
   #
   if ( $MRG_BYDAY == A || $MRG_BYDAY == M || $MRG_BYDAY == P ) then
      setenv T_TYPE $L_TYPE 
      source $SCRIPTS/run/set_days_v3.csh

      setenv G_STDATE_MON `grep Monday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
      setenv ESDATE_MON   `$IOAPIDIR/datshift $G_STDATE_MON 0`
      setenv G_STDATE_WKD `grep Tuesday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
      setenv ESDATE_WKD   `$IOAPIDIR/datshift $G_STDATE_WKD 0`
      setenv G_STDATE_SAT `grep Saturday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
      setenv ESDATE_SAT   `$IOAPIDIR/datshift $G_STDATE_SAT 0`
      setenv G_STDATE_SUN `grep Sunday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
      setenv ESDATE_SUN   `$IOAPIDIR/datshift $G_STDATE_SUN 0`
      source $ASSIGNS/smokev2.mwss_settings.csh  # Set MWSS temporal intermediate files
   endif
   
   ## Next set the days to merge
   #
   setenv T_TYPE $M_TYPE                 # Set temporal type to type for merge
   source $ASSIGNS_FILE
   source $SCRIPTS/run/set_days_v3.csh   # Call script to set dates for run
   ## If using date overrides, reset the merge days
   #
   if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then
      set ndays = $EPI_NDAY
   else
      set ndays = `cat $SMK_RUN_DATES | wc -l`
   endif
   set x = 0
   set diff = 0
   set g_stdate_sav = $G_STDATE

   ## Loop through days to run during the month.
   while ( $x < $ndays )
      if ( $?STDATE_OVERRIDE && $?ENDDATE_OVERRIDE ) then 
	 @ diff = $x
	 @ x = $x + 1
      else
	 @ x = $x + 1
	 set line = `head -n $x $SMK_RUN_DATES | tail -n 1`
         @ diff = $line[1] - $g_stdate_sav
      endif
      setenv G_STDATE_ADVANCE $diff
      set save_mrgsta = $MRG_REPSTA_YN
      set save_mrgcny = $MRG_REPCNY_YN
     setenv RUN_PART4 Y     
    
     if ( $RUN_MRGGRID == Y ) then
        source $ASSIGNS_FILE
        echo "Running Mrggrid" 
        if ( $MRG_BYDAY != " " ) then

	   setenv T_TYPE week
	   source $SCRIPTS/run/set_days_v3.csh
	   setenv G_STDATE_WKD `grep Tuesday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
	   setenv ESDATE_WKD   `$IOAPIDIR/datshift $G_STDATE_WKD 0`
	   setenv G_STDATE_MON `grep Monday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
	   setenv ESDATE_MON   `$IOAPIDIR/datshift $G_STDATE_MON 0`
	   setenv G_STDATE_TUE `grep Tuesday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
	   setenv ESDATE_TUE   `$IOAPIDIR/datshift $G_STDATE_TUE 0`
	   setenv G_STDATE_WED `grep Wednesday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
	   setenv ESDATE_WED   `$IOAPIDIR/datshift $G_STDATE_WED 0`
	   setenv G_STDATE_THU `grep Thursday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
	   setenv ESDATE_THU   `$IOAPIDIR/datshift $G_STDATE_THU 0`
	   setenv G_STDATE_FRI `grep Friday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
	   setenv ESDATE_FRI   `$IOAPIDIR/datshift $G_STDATE_FRI 0`
	   setenv G_STDATE_SAT `grep Saturday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
	   setenv ESDATE_SAT   `$IOAPIDIR/datshift $G_STDATE_SAT 0`
	   setenv G_STDATE_SUN `grep Sunday $SMK_RUN_DATES | grep -v H | cut -d" " -f 1`
	   setenv ESDATE_SUN   `$IOAPIDIR/datshift $G_STDATE_SUN 0`
	   setenv T_TYPE $M_TYPE 
	   source $SCRIPTS/run/set_days_v3.csh
	endif
        if ( `grep "^$G_STDATE " $SMK_RUN_DATES | grep H` == "" ) then 
	   if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 5` == Monday, ) then
	      set G_STDATE_MWSS = $G_STDATE_MON
	      set G_STDATE_MWSS_NH = $G_STDATE_MON
	      set G_STDATE_WEEK = $G_STDATE_MON
	      set G_STDATE_WEEK_NH = $G_STDATE_MON
	   else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 5` == Tuesday, ) then
              set G_STDATE_MWSS = $G_STDATE_WKD
              set G_STDATE_MWSS_NH = $G_STDATE_WKD
              set G_STDATE_WEEK = $G_STDATE_TUE
              set G_STDATE_WEEK_NH = $G_STDATE_TUE
	   else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 5` == Wednesday, ) then
              set G_STDATE_MWSS = $G_STDATE_WKD
              set G_STDATE_MWSS_NH = $G_STDATE_WKD
              set G_STDATE_WEEK = $G_STDATE_WED
              set G_STDATE_WEEK_NH = $G_STDATE_WED
	   else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 5` == Thursday, ) then
              set G_STDATE_MWSS = $G_STDATE_WKD
              set G_STDATE_MWSS_NH = $G_STDATE_WKD
              set G_STDATE_WEEK = $G_STDATE_THU
              set G_STDATE_WEEK_NH = $G_STDATE_THU
	   else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 5` == Friday, ) then
              set G_STDATE_MWSS = $G_STDATE_WKD
              set G_STDATE_MWSS_NH = $G_STDATE_WKD
              set G_STDATE_WEEK = $G_STDATE_FRI
              set G_STDATE_WEEK_NH = $G_STDATE_FRI
	   else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 5` == Sunday, ) then
              set G_STDATE_MWSS = $G_STDATE_SUN
              set G_STDATE_MWSS_NH = $G_STDATE_SUN
              set G_STDATE_WEEK = $G_STDATE_SUN
              set G_STDATE_WEEK_NH = $G_STDATE_SUN
	   else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 5` == Saturday, ) then
              set G_STDATE_MWSS = $G_STDATE_SAT
              set G_STDATE_MWSS_NH = $G_STDATE_SAT
              set G_STDATE_WEEK = $G_STDATE_SAT
              set G_STDATE_WEEK_NH = $G_STDATE_SAT
	   endif
        else
          set G_STDATE_MWSS = $G_STDATE
          set G_STDATE_WEEK = $G_STDATE
          if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 4` == Monday, ) then
             set G_STDATE_MWSS_NH = $G_STDATE_MON
             set G_STDATE_WEEK_NH = $G_STDATE_MON
	  else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 4` == Tuesday, ) then
             set G_STDATE_MWSS_NH = $G_STDATE_WKD
             set G_STDATE_WEEK_NH = $G_STDATE_TUE
	  else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 4` == Wednesday, ) then
             set G_STDATE_MWSS_NH = $G_STDATE_WKD
             set G_STDATE_WEEK_NH = $G_STDATE_WED
	  else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 4` == Thursday, ) then
             set G_STDATE_MWSS_NH = $G_STDATE_WKD
             set G_STDATE_WEEK_NH = $G_STDATE_THU
	  else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 4` == Friday, ) then
             set G_STDATE_MWSS_NH = $G_STDATE_WKD
             set G_STDATE_WEEK_NH = $G_STDATE_FRI
	  else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 4` == Sunday, ) then
             set G_STDATE_MWSS_NH = $G_STDATE_SUN
             set G_STDATE_WEEK_NH = $G_STDATE_SUN
	  else if ( `grep "^$G_STDATE " $SMK_RUN_DATES | cut -d" " -f 4` == Saturday, ) then
             set G_STDATE_MWSS_NH = $G_STDATE_SAT
             set G_STDATE_WEEK_NH = $G_STDATE_SAT
	  endif
	endif

        set G_STDATE_AVEDAY = $G_STDATE_TUE
     endif  #end MRGGRID

        echo 'G_STDATE ... '$G_STDATE

     setenv mrg_byday_sav $MRG_BYDAY
     if ( $RUN_SMKMERGE == Y && $MRG_BYDAY != ' ' ) then    
	   echo "MRG_BYDAY = $MRG_BYDAY"
	if ( `grep $G_STDATE $SMK_RUN_DATES | grep H` != "" ) then
#	   unsetenv MRG_BYDAY
	endif

     endif

     source $ASSIGNS_FILE                      # Invoke Assigns file to set new dates
     echo $month
     echo "Running for Date...: $G_STDATE"

     source $SCRIPTS/run/smk_run_v2.csh        # Run Smkmerge to create model-ready emissions

     setenv MRG_BYDAY $mrg_byday_sav

     # Reset Smkmerge reporting settings
     setenv MRG_REPSTA_YN $save_mrgsta
     setenv MRG_REPCNY_YN $save_mrgcny

     # Run Smkmerge to get state totals
     if ( $RUN_SMKMERGE == Y ) then 
        if ( $MRG_REPSTA_YN == Y || $MRG_REPCNY_YN == Y ) then
           setenv MRG_GRDOUT_UNIT      tons/hr    # units for gridded outputs
           setenv MRG_TOTOUT_UNIT      tons/day   # units for state and/or county totals   
           source $ASSIGNS_FILE
           source $SCRIPTS/run/smk_run_v2.csh
        endif
     endif
   end 

endif  ## End part 4
#
setenv RUN_PART4 N
unsetenv G_STDATE_ADVANCE
#
# add smoketracking script
     $SMK_HOME/subsys/smoke/scripts/run/smoke-tracking/smoketracking status $SMK_SOURCE

exit(0)
