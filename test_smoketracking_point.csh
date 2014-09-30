#!/bin/csh -f

############################### test_smoketracking.csh ###################################
# This is a script that calls the smoketracking script, after run has been completed
#
# Script created by :  UNC-IE  (September 2014) 
###################################################################################

setenv SRCABBR  point      # abbreviation for naming log and output files
setenv SMK_HOME  /netscr/lizadams/SMOKEv40
setenv SMK_SOURCE   P         # source category to process
setenv G_STDATE 2012186

# add smoketracking script
     $SMK_HOME/subsys/smoke/scripts/run/smoke-tracking/smoketracking status $SMK_SOURCE

exit(0)
