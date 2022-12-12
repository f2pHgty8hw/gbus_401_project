//////////////////////////////////////////////////////
///*** GBUS 401 Final Project: Model Estimation ***///
//////////////////////////////////////////////////////

*Name: Noah Blake Smith

*Last updated: December 8, 2022

use "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project/Data_Final/gbus_401_project_master.dta", clear

///*** Basic Regressions ***///

*Performance-Related
reg admit gpa, r // Should cluster by school if trying for causal interpretation
reg admit lsat, r
reg admit softs, r
reg admit gpa lsat softs, r

*Non-Performance-Related
reg admit urm, r
reg admit fee_waived, r // Is this fair proxy for poverty?
reg admit non_trad, r
reg admit intl, r
reg admit years_out, r
reg admit i.year, r
reg admit urm fee_waived non_trad intl years_out, r

////////////////////////////////////////
///*** Model 1: Linear Regression ***///
////////////////////////////////////////

/*Note: This is also run in Python.*/

reg admit gpa lsat softs urm fee_waived non_trad intl years_out i.year i.school_id, r // N=76k

reg admit gpa lsat urm fee_waived non_trad intl i.year i.school_id, r // N=373k (removed softs and years_out)

////////////////////////////
///*** Model 2: Logit ***///
////////////////////////////

//logit admit gpa lsat urm fee_waived non_trad intl i.year i.school_id, r or

/////////////////////////////////////
///*** Analysis: T14 Subsample ***///
/////////////////////////////////////

reg admit gpa lsat softs urm fee_waived non_trad intl years_out i.year i.school_id if t14==1, r
reg admit gpa lsat urm fee_waived non_trad intl i.year i.school_id if t14==1, r

reg admit lsat gpa urm if t14==1, r // Way higher URM coefficient
reg admit lsat gpa urm fee_waived if t14==1, r // Way higher URM coefficient

tw (hist lsat if urm==0 & admit==1, bin(60) color(green)) || (hist lsat if urm==1 & admit==1, bin(60) color(none) lcolor(black)), by(t14) // Stark difference here

tw (hist lsat if urm==0 & admit==1 & t14==1 & lsat>150, bin(60) color(green)) || (hist lsat if urm==1 & admit==1 & t14==1 & lsat>150, bin(60) color(none) lcolor(black)) // Stark difference here

reg admit gpa lsat urm##fee_waived urm##non_trad intl i.year i.school_id if if , r
