///////////////////////////////////////////////////////////
///*** GBUS 401 Final Project: Figure Outputs Script ***///
///////////////////////////////////////////////////////////

*Name: Noah Blake Smith
*Last updated: December 5, 2022

global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project"
// global path "/Users/justinpotisit/Documents/GitHub/gbus_401_project"
cd "${path}/Outputs"

use "${path}/Data_Final/gbus_401_project_master.dta", clear

*net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
*set scheme cleanplots, perm

////////////////////////////////////
///*** 2.3 Summary Statistics ***///
////////////////////////////////////

///*** Table of Variables ***///

preserve

keep admit urm fee_waived non_trad intl gpa* lsat* accr year t14 yield

ssc install asdoc, replace

asdoc des, font(Latin Modern Roman) fs(12) replace save(Appendix.doc) title(Table 2.3a: Summary of Variables) align(center)

restore

///*** Summary Statistics ***///

asdoc tabstat admit urm fee_waived non_trad intl gpa* lsat* accr year t14 yield, m stat(mean sd min max) c(s) title(Table 2.3b: Summary Statistics) save(Appendix.doc) format(%9.2gc) font(Latin Modern Roman) fs(12) append

/*estpost tabstat admit urm fee_waived non_trad intl gpa* lsat* accr year t14 yield, m s(n mean sd min max) c(s)
esttab using Appendix.doc, cells("count(fmt(%9.3gc)) mean sd min max") nonumber nomtitle noobs title(Table 2.3a: Summary Statistics) fonttbl("\f0\fnil Times New Roman") replace*/

///*** Observations and LSN Imports by Year ***///

preserve

la var lsn_import "LSN import"
la var year "Year"

asdoc tab year lsn_import, title(Table 2.3c: Observations & LSN Imports by Year) font(Latin Modern Roman) fs(12) save(Appendix.doc) append

restore

////////////////////////////////////////////////////////////////////
///*** 2.4.1 Data Representativeness: Distributional Analysis ***///
////////////////////////////////////////////////////////////////////

///*** Applications per Person ***///

preserve

duplicates tag user_id, gen(apps_per_person)
la var apps_per_person "Applications submitted per user"
replace apps_per_person = apps_per_person + 1 // Note line above marks unique observations as 0
duplicates drop user_id, force

hist apps_per_person if apps_per_person<30, normal bin(29) title("{bf:Applications per LSD.law User, Pooled 2004–2023}")
graph export "fig_241a.png", as(png) name("Graph") replace

restore

///*** Sample Share of Applicants and Applications ***///

*LSD.law applications
preserve

egen applications_lsd = count(year), by(year)
la var applications_lsd "Sample (LSD.law)"

duplicates drop applications_lsd year, force

tempfile applications
save `applications'

restore
preserve

*LSD.law applicants
egen temp = tag(user_id year)
drop if temp==0
isid user_id // No user applied in more than one year
drop temp

egen applicants_lsd = count(user_id), by(year)
la var applicants_lsd "Sample (LSD.law)"

duplicates drop applicants_lsd year, force

*Merge LSD.law data
merge 1:1 year using `applications'
drop _merge // All matched
drop if year==2023
tempfile lsd_applicants_applications
save `lsd_applicants_applications'

*LSAC data
import excel "${path}/Data_Intermediate/lsac_application_applicant_volumes.xlsx", sheet("Export") firstrow clear

keep Year Applicants Applications

replace Year = year(Year)
format Year %ty
ren Year year

qui des
set obs `=r(N) + 1'

replace year = 2022 if missing(year)
replace Applicants = 62578 if year==2022 // Source: https://report.lsac.org/View.aspx?Report=FiveYearComparison
replace Applications = 430354 if year==2022 // Source: https://report.lsac.org/View.aspx?Report=FiveYearComparison

keep if year>2003

ren Applicants applicants_lsac
la var applicants_lsac "Total Applicants (LSAC)"

ren Applications applications_lsac
la var applications_lsac "Total Applications (LSAC)"

*Merge LSAC and LSD.law data
merge 1:1 year using `lsd_applicants_applications' // All matched except 2023, as expected
keep year *_lsd *_lsac

foreach i of varlist *_* {
	replace `i' = `i' / 1000
	format %9.0gc `i'
}

tsset year, yearly

*LSAC total
tsline *_lsac, legend(position(6)) xscale(range(2004 2022)) xmtick(2004(1)2022) xlabel(2005 2010 2015 2020) ytitle("Total") legend(cols(2) label(1 "Applicants") label(2 "Applications")) title("{bf:LSAC Applications and Applicants, Annual Volumes, 2004–2022}")
graph export "fig_241b.png", as(png) name("Graph") replace

*Sample shares
gen application_share = (applications_lsd / applications_lsac) * 100
la var application_share "Applications"

gen applicant_share = (applicants_lsd / applicants_lsac) * 100
la var applicant_share "Applicants"

tsline *_share, legend(position(6)) xscale(range(2004 2022)) xmtick(2004(1)2022) xlabel(2005 2010 2015 2020) ytitle("Total") legend(cols(2) label(1 "Applications") label(2 "Applicants")) ytitle("Share of Total Pool (%)") title("{bf:Sample Share of Applications and Applicants, Annual Volumes, 2004–2022}")
graph export "fig_241c.png", as(png) name("Graph") replace

restore

///*** LSAT ***///

hist lsat if lsat>=140, normal bin(41) title("{bf:Self-Reported LSAT, LSD.law, 2004–2023}")

graph export "fig_241d.png", as(png) name("Graph") replace

///*** GPA ***///

hist gpa if gpa>2.9 & gpa<4.1, bin(119) xtick(2.9(0.05)4.1) xlabel(2.95(0.2)4.05) title("{bf:Self-Reported GPA, LSD.law, Pooled 2004–2023}")
graph export "fig_241e.png", as(png) name("Graph") replace

////////////////////////////////////
///*** 2.4.2 Hypothesis Tests ***///
////////////////////////////////////

/////////////////////////////////////
///*** 2.4.2.1 Admission Rates ***///
/////////////////////////////////////

///*** Correlations ***///

preserve

collapse (firstnm) school accr* apps* offers*, by(school_id year)

*By Year
drop if missing(year) | missing(accr) | missing(accr2)
gen corr = .

forval i = 2011/2021 {
	di `i'
	corr accr accr2 if year==`i'
	replace corr = r(rho) if year==`i'
}

*Pooled
tostring year, replace
qui des
local no = `r(N)' + 1
set obs `no'
replace year = "Pooled" if missing(year)
corr accr accr2
local temp "`r(rho)'"
replace corr = `temp' if year=="Pooled"

asdoc tabstat corr if school_id==3691400 | year=="Pooled", by(year) stat(mean) title(Figure 2.4.2.1b: Correlation of Sample and Official Admission Rates) font(Latin Modern Roman) fs(12) save(Appendix.doc) append // School ID chosen arbitrarily (does not matteras long as it has 11 observations); mean is not relevant because equal across years

restore

///*** t-tests ***///

qui des
duplicates drop school_id year, force
drop if missing(accr) | missing(apps2) | missing(offers2)

gen z_accr = .
la var z_accr "Z-score of one-sample test of proportion"
gen p_accr = .
la var p_accr "p-value of one-sample test of proportion"

qui des
forval i = 1/`r(N)' {

	di `i'
	
	local n = apps2[`i']
	local a = offers2[`i']
	local accr = accr[`i']
	
	cap prtesti `n' `a' `accr', count // Test
	cap replace z_accr = `r(z)' if z_accr==z_accr[`i']
	cap replace p_accr = `r(p)' if p_accr==p_accr[`i']

}

asdoc tabstat *_accr, stat(count mean sd min max) col(s) title(Figure 2.4.2.1a: One-Sample Proportional t-tests by School and Year) font(Latin Modern Roman) fs(12) save(Appendix.doc) append

///////////////////////
///*** 4 Results ***///
///////////////////////

/////////////////////
///*** 4.1 OLS ***///
/////////////////////

use "${path}/Data_Final/ols_cv_metrics.dta", clear

*Model no. labels
gen temp = model_no

qui levelsof model_no
forval i = 1/`r(r)' {
	if mod(`i', 20) {
		la def temp_lbl `i' `"{c 0xa0}"', add 
	}
}

la val temp temp_lbl

///*** Negative RMSE ***///

graph box rmse, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1a: Negative Root Mean Squared Error across OLS Models}") b1title("Model no.") ytitle("Negative RMSE") 

graph export "fig_41a.png", as(png) name("Graph") replace

///*** R^2 ***///

graph box r2, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1b: R-squared across OLS Models}") b1title("Model no.") ytitle("R-squared")

graph export "fig_41b.png", as(png) name("Graph") replace

tsset model_no split, yearly

// Below is a nice graph of R^2 but not sure if still relevant. Choose best models and swap if statements below.

/*tsline r2 if model_no==26 || tsline r2 if model_no==27 || tsline r2 if model_no==28 || tsline r2 if model_no==29 || tsline r2 if model_no==30 || tsline r2 if model_no==31 || tsline r2 if model_no==38 || tsline r2 if model_no==40, legend(cols(8) position(6) label(1 "26") label(2 "27") label(3 "28") label(4 "29") label(5 "30") label(6 "31") label(7 "38") label(8 "40") title("Model no.", size(small))) yscale(range(0.1 0.3)) ylabel(0.1(0.05)0.3) xscale(range(2004 2022)) xlabel(2005 2010 2015 2020) xmtick(2004(1)2022) title("{bf:Figure 4.1c: Time Series of R-squared for Selected OLS Models}")*/

graph export "fig_41c.png", as(png) name("Graph") replace

///*** Negative MAE ***///

graph box mae, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1d: Negative Mean Absolute Error across OLS Models}") b1title("Model no.") ytitle("Negative MAE")

graph export "fig_41d.png", as(png) name("Graph") replace

///*** Accuracy ***///

graph box accuracy, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1e: Accuracy across OLS Models}") b1title("Model no.") ytitle("Accuracy")

graph export "fig_41e.png", as(png) name("Graph") replace

///*** Negative Log Loss ***///

graph box accuracy, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1f: Negative Log Loss across OLS Models}") b1title("Model no.") ytitle("Negative log loss")

graph export "fig_41f.png", as(png) name("Graph") replace

*Outro
drop temp
la drop temp_lbl

///////////////////////
///*** 4.2 Logit ***///
///////////////////////

use "${path}/Data_Final/logit_cv_metrics.dta", clear

*Model no. labels
gen temp = model_no

qui levelsof model_no
forval i = 1/`r(r)' {
	if mod(`i', 20) {
		la def temp_lbl `i' `"{c 0xa0}"', add 
	}
}

la val temp temp_lbl

///*** Accuracy ***///

graph box accuracy, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.2a: Accuracy across Logit Models}") b1title("Model no.") ytitle("Accuracy")

graph export "fig_42a.png", as(png) name("Graph") replace

///*** Negative Log Loss ***///

graph box accuracy, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.2b: Negative Log Loss across Logit Models}") b1title("Model no.") ytitle("Negative log loss")

graph export "fig_42b.png", as(png) name("Graph") replace
