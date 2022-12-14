///////////////////////////////////////////////////////////
///*** GBUS 401 Final Project: LSAC Comparsion LSAT ***///
///////////////////////////////////////////////////////////

*Name: Noah Blake Smith

*Last updated: December 5, 2022

//global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project"
global path "/Users/justinpotisit/Documents/GitHub/gbus_401_project"
cd "${path}"

//use "${path}/gbus_401_project/Data_Final/gbus_401_project_master.dta", clear

import excel "/Users/justinpotisit/Documents/GBUS_400/Project/Applicants_LSAT_Scores_LSAC.xlsx", sheet("Export") clear

net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
set scheme cleanplots, perm


///cleaning data///

keep if == "a" "b" "c"

rename

