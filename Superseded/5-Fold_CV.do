/////////////////////////////////////////
///*** GBUS 401 Project: 5-Fold CV ***///
/////////////////////////////////////////

*Name: Noah Blake Smith
*December 8, 2022

clear all
mat drop _all

use "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project/Data_Final/gbus_401_project_master.dta", clear

ssc install crossfold

foreach i in "" "mae" "r2" {
	crossfold reg admit gpa i.school_id i.year, k(5) `i'
	svmat r(est), n(model1`i')
	crossfold reg admit lsat i.school_id i.year, k(5) `i'
	svmat r(est), n(model2`i')
	crossfold reg admit urm i.school_id i.year, k(5) `i'
	svmat r(est), n(model3`i')
	crossfold reg admit fee_waived i.school_id i.year, k(5) `i'
	svmat r(est), n(model4`i')
	crossfold reg admit non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model5`i')
	crossfold reg admit intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model6`i')
	crossfold reg admit gpa lsat i.school_id i.year, k(5) `i'
	svmat r(est), n(model7`i')
	crossfold reg admit gpa urm i.school_id i.year, k(5) `i'
	svmat r(est), n(model8`i')
	crossfold reg admit gpa fee_waived i.school_id i.year, k(5) `i'
	svmat r(est), n(model9`i')
	crossfold reg admit gpa non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model10`i')
	crossfold reg admit gpa intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model11`i')
	crossfold reg admit lsat urm i.school_id i.year, k(5) `i'
	svmat r(est), n(model12`i')
	crossfold reg admit lsat fee_waived i.school_id i.year, k(5) `i'
	svmat r(est), n(model13`i')
	crossfold reg admit lsat non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model14`i')
	crossfold reg admit lsat intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model15`i')
	crossfold reg admit urm fee_waived i.school_id i.year, k(5) `i'
	svmat r(est), n(model16`i')
	crossfold reg admit urm non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model17`i')
	crossfold reg admit urm intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model18`i')
	crossfold reg admit fee_waived non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model19`i')
	crossfold reg admit fee_waived intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model20`i')
	crossfold reg admit non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model21`i')
	crossfold reg admit gpa lsat urm i.school_id i.year, k(5) `i'
	svmat r(est), n(model22`i')
	crossfold reg admit gpa lsat fee_waived i.school_id i.year, k(5) `i'
	svmat r(est), n(model23`i')
	crossfold reg admit gpa lsat non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model24`i')
	crossfold reg admit gpa lsat intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model25`i')
	crossfold reg admit gpa urm fee_waived i.school_id i.year, k(5) `i'
	svmat r(est), n(model26`i')
	crossfold reg admit gpa urm non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model27`i')
	crossfold reg admit gpa urm intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model28`i')
	crossfold reg admit gpa fee_waived non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model29`i')
	crossfold reg admit gpa fee_waived intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model30`i')
	crossfold reg admit gpa non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model31`i')
	crossfold reg admit lsat urm fee_waived i.school_id i.year, k(5) `i'
	svmat r(est), n(model32`i')
	crossfold reg admit lsat urm non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model33`i')
	crossfold reg admit lsat urm intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model34`i')
	crossfold reg admit lsat fee_waived non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model35`i')
	crossfold reg admit lsat fee_waived intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model36`i')
	crossfold reg admit lsat non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model37`i')
	crossfold reg admit urm fee_waived non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model38`i')
	crossfold reg admit urm fee_waived intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model39`i')
	crossfold reg admit urm non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model40`i')
	crossfold reg admit fee_waived non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model41`i')
	crossfold reg admit gpa lsat urm fee_waived i.school_id i.year, k(5) `i'
	svmat r(est), n(model42`i')
	crossfold reg admit gpa lsat urm non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model43`i')
	crossfold reg admit gpa lsat urm intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model44`i')
	crossfold reg admit gpa lsat fee_waived non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model45`i')
	crossfold reg admit gpa lsat fee_waived intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model46`i')
	crossfold reg admit gpa lsat non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model47`i')
	crossfold reg admit gpa urm fee_waived non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model48`i')
	crossfold reg admit gpa urm fee_waived intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model49`i')
	crossfold reg admit gpa urm non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model50`i')
	crossfold reg admit gpa fee_waived non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model51`i')
	crossfold reg admit lsat urm fee_waived non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model52`i')
	crossfold reg admit lsat urm fee_waived intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model53`i')
	crossfold reg admit lsat urm non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model54`i')
	crossfold reg admit lsat fee_waived non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model55`i')
	crossfold reg admit urm fee_waived non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model56`i')
	crossfold reg admit gpa lsat urm fee_waived non_trad i.school_id i.year, k(5) `i'
	svmat r(est), n(model57`i')
	crossfold reg admit gpa lsat urm fee_waived intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model58`i')
	crossfold reg admit gpa lsat urm non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model59`i')
	crossfold reg admit gpa lsat fee_waived non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model60`i')
	crossfold reg admit gpa urm fee_waived non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model61`i')
	crossfold reg admit lsat urm fee_waived non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model62`i')
	crossfold reg admit gpa lsat urm fee_waived non_trad intl i.school_id i.year, k(5) `i'
	svmat r(est), n(model63`i')
}
