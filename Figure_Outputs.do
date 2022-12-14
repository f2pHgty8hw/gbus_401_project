///////////////////////////////////////////////////////////
///*** GBUS 401 Final Project: Figure Outputs Script ***///
///////////////////////////////////////////////////////////

*Name: Noah Blake Smith
*Last updated: December 13, 2022

global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project"
cd "${path}/Outputs"

use "${path}/Data_Final/gbus_401_project_master.dta", clear

*net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
*set scheme cleanplots, perm

////////////////////////////////////
///*** 2.3 Summary Statistics ***///
////////////////////////////////////

///*** Table 1: Table of Variables ***///

preserve

*ssc install asdoc

keep admit urm fee_waived gpa gpa_* lsat lsat_* accrl year t14

asdoc des, font(Latin Modern Roman) fs(12) replace save(table01.doc) title(Table 1: Table of Variables) align(center)

restore

///*** Table 2: Model No. and Feature Sets ***///

///*** Table 3: Summary Statistics ***///

asdoc tabstat admit urm fee_waived gpa gpa_* lsat lsat_* accrl year t14, m stat(mean sd min max) c(s) title(Table 3: Summary Statistics) save(table03.doc) format(%9.2gc) font(Latin Modern Roman) fs(12) replace

///*** Table 4: LSN Imports by Year ***///

preserve

la var lsn_import "LSN import"
la var year "Year"

asdoc tab year lsn_import, title(Table 4: LSN Imports by Year) font(Latin Modern Roman) fs(12) save(table04.doc) replace

restore

////////////////////////////////////////////////////////////////////
///*** 2.4.1 Data Representativeness: Distributional Analysis ***///
////////////////////////////////////////////////////////////////////

///*** Figure 1: Applications per LSD.law User 2004–2022 ***///

preserve

duplicates tag user_id, gen(apps_per_person)
la var apps_per_person "Applications submitted per user"
replace apps_per_person = apps_per_person + 1 // Note line above marks unique observations as 0
duplicates drop user_id, force

hist apps_per_person if apps_per_person<30, normal bin(29) title("{bf:Figure 1: Applications per LSD.law User, 2004–2022}")
graph export "fig01.png", as(png) name("Graph") replace

restore

///*** Figures 2 & 3: Sample Share of Applicants and Applications ***///

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
tsline *_lsac, legend(position(6)) xscale(range(2004 2022)) xmtick(2004(1)2022) xlabel(2005 2010 2015 2020) ytitle("Total") legend(cols(2) label(1 "Applicants") label(2 "Applications")) title("{bf:Figure 2: LSAC Applications and Applicants, Annual Volumes, 2004–2022}")
graph export "fig02.png", as(png) name("Graph") replace

*Sample shares
gen application_share = (applications_lsd / applications_lsac) * 100
la var application_share "Applications"

gen applicant_share = (applicants_lsd / applicants_lsac) * 100
la var applicant_share "Applicants"

tsline *_share, legend(position(6)) xscale(range(2004 2022)) xmtick(2004(1)2022) xlabel(2005 2010 2015 2020) ytitle("Total") legend(cols(2) label(1 "Applications") label(2 "Applicants")) ytitle("Share of Total Pool (%)") title("{bf:Figure 3: Sample Share of Applications and Applicants, Annual Volumes, 2004–2022}")
graph export "fig03.png", as(png) name("Graph") replace

restore

///*** LSAT ***///

hist lsat if lsat>=140, normal bin(41) title("{bf:Figure 4: Self-Reported LSAT Scores, 2004–2022}")
graph export "fig04.png", as(png) name("Graph") replace

///*** GPA ***///

hist gpa if gpa>2.9 & gpa<4.1, bin(119) xtick(2.9(0.05)4.1) xlabel(2.95(0.2)4.05) title("{bf:Figure 5: Self-Reported GPA, 2004–2022}")
graph export "fig05.png", as(png) name("Graph") replace

///////////////////////////////////
///*** 2.4.2 Admission Rates ***///
///////////////////////////////////

///*** Z-tests ***///

qui des
duplicates drop school_id year, force
drop if missing(accr) | missing(apps2) | missing(offers2)

gen z_score = .
la var z_score "Z-score of one-sample test of proportion"
gen p_value = .
la var p_value "p-value of one-sample test of proportion"

qui des
forval i = 1/`r(N)' {

	di `i'
	
	local n = apps2[`i']
	local a = offers2[`i']
	local accr = accr[`i']
	
	cap prtesti `n' `a' `accr', count // Test
	cap replace z_score = `r(z)' if z_score==z_score[`i']
	cap replace p_value = `r(p)' if p_value==p_value[`i']

}

asdoc tabstat z_score p_value, stat(count mean sd min max) col(s) title(Table 5: One-Sample Proportional t-tests by School and Year) font(Latin Modern Roman) fs(12) save(table05.doc) replace

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

asdoc tabstat corr if school_id==3691400 | year=="Pooled", by(year) stat(mean) title(Table 6: Correlation of Sample and Official Admission Rates) font(Latin Modern Roman) fs(12) save(table06.doc) replace // School ID chosen arbitrarily (does not matteras long as it has 11 observations); mean is not relevant because equal across years

restore

///////////////////////
///*** 4 Results ***///
///////////////////////

/////////////////////
///*** 4.2 OLS ***///
/////////////////////

use "${path}/Data_Final/ols_cv_metrics.dta", clear

/*
*Model no. labels
gen temp = model_no

qui levelsof model_no
forval i = 1/`r(r)' {
	if mod(`i', 20) {
		la def temp_lbl `i' `"{c 0xa0}"', add 
	}
}

la val temp temp_lbl
*/

////////////////////////////////////////////////
///*** Summary of Goodness-of-Fit Metrics ***///
////////////////////////////////////////////////

asdoc sum accuracy rmse r2 mae, title(Table 7: OLS Goodness-of-Fit Measures) save(table07.doc) format(%9.2gc) font(Latin Modern Roman) fs(12) replace

//////////////////////
///*** Accuracy ***///
//////////////////////

*Mean
egen maccuracy = mean(accuracy), by(model_no)
la var maccuracy "Mean accuracy score"

*Variance
egen vaccuracy = sd(accuracy), by(model_no)
la var vaccuracy "SD of accuracy"

*Box scatter
graph box accuracy, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 6: Accuracy Box Plots by OLS Model No.}") b1title("Model no.") ytitle("Accuracy")
graph export "fig06.png", as(png) name("Graph") replace

*Bias-variance tradeoff
ssc install colorscatter
colorscatter maccuracy vaccuracy model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Mean") xtitle("Standard deviation", yoffset(-10)) title("{bf:Figure 7: Accuracy-Variance Tradeoff by OLS Model No.}") xscale(range(0 0.045)) xlabel(0(0.01)0.04) graphregion(margin(large))
graph export "fig07.png", as(png) name("Graph") replace

*Over time
colorscatter accuracy split model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Accuracy") xtitle("Year of CV split", yoffset(-15) margin(vlarge)) title("{bf:Figure 8: Accuracy over Time by OLS Model No.}") legend(title("Model no.", size(small) margin(small))) ysize(11) xsize(8.5) ylabel(0.5(0.05)0.8)
graph export "fig08.png", as(png) name("Graph") replace

///////////////////////////
///*** Negative RMSE ***///
///////////////////////////

*Box scatter
graph box rmse, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 10: Negative RMSE Box Plots by OLS Model No.}") b1title("Model no.") ytitle("Negative RMSE") 
graph export "fig10.png", as(png) name("Graph") replace // Note: figure 9 was removed, so we go from 8 to 10

*Mean
egen mrmse = mean(rmse), by(model_no)
la var mrmse "Mean of RMSE"

*Variance
egen vrmse = sd(rmse), by(model_no)
la var vrmse "SD of RMSE"

*Bias-variance tradeoff
*ssc install colorscatter
colorscatter mrmse vrmse model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Mean") xtitle("Standard deviation", yoffset(-10)) title("{bf:Figure 11: Negative RMSE–Variance Tradeoff by OLS Model No.}") xscale(range(0 0.045)) xlabel(0(0.01)0.04) graphregion(margin(large))
graph export "fig11.png", as(png) name("Graph") replace

*Over time
colorscatter rmse split model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Negative RMSE") xtitle("Year of CV split", yoffset(-15) margin(vlarge)) title("{bf:Figure 12: Negative RMSE over Time by OLS Model No.}") legend(title("Model no.", size(small) margin(small))) ysize(11) xsize(8.5) yscale(range(-0.55 -0.4)) ylabel(-0.55(0.05)-0.4)
graph export "fig12.png", as(png) name("Graph") replace

/////////////////
///*** R^2 ***///
/////////////////

*Box scatter
graph box r2, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 13: R-squared Box Plots by OLS Model No.}") b1title("Model no.") ytitle("R-squared")
graph export "fig13.png", as(png) name("Graph") replace

*Mean
egen mr2 = mean(r2), by(model_no)
la var r2 "Mean of R^2"

*Variance
egen vr2 = sd(r2), by(model_no)
la var vr2 "SD of R^2"

*Bias-variance tradeoff
colorscatter mr2 vr2 model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Mean") xtitle("Standard deviation", yoffset(-10)) title("{bf:Figure 14: R-squared–Variance Tradeoff by OLS Model No.}") graphregion(margin(large))
graph export "fig14.png", as(png) name("Graph") replace

*Over time
colorscatter r2 split model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("R-squared") xtitle("Year of CV split", yoffset(-15) margin(vlarge)) title("{bf:Figure 15: R-squared over Time by OLS Model No.}") legend(title("Model no.", size(small) margin(small))) ysize(11) xsize(8.5) yscale(range(-0.3 0.4)) ylabel(-0.3(0.1)0.4)
graph export "fig15.png", as(png) name("Graph") replace

//////////////////////////
///*** Negative MAE ***///
//////////////////////////

*Box scatter
graph box mae, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 16: Negative MAE Box Plots by OLS Model No.}") b1title("Model no.") ytitle("Negative MAE")
graph export "fig16.png", as(png) name("Graph") replace

*Mean
egen mmae = mean(mae), by(model_no)
la var mmae "Mean of negative MAE"

*Variance
egen vmae = sd(mae), by(model_no)
la var vmae "SD of negative MAE"

*Bias-variance tradeoff
colorscatter mmae vmae model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Mean") xtitle("Standard deviation", yoffset(-10)) title("{bf:Figure 17: Negative MAE–Variance Tradeoff by OLS Model No.}") graphregion(margin(large))
graph export "fig17.png", as(png) name("Graph") replace

*Over time
colorscatter mae split model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Negative MAE") xtitle("Year of CV split", yoffset(-15) margin(vlarge)) title("{bf:Figure 18: Negative MAE over Time by OLS Model No.}") legend(title("Model no.", size(small) margin(small))) ysize(11) xsize(8.5)
graph export "fig18.png", as(png) name("Graph") replace

/////////////////////////////////////
///*** OLS Model 22 Estimation ***///
/////////////////////////////////////

use "${path}/Data_Final/gbus_401_project_master.dta", clear

asdoc reg admit gpa_* lsat i.year i.school_id if year>2011 & year<2022, nest drop(i.year i.school_id) title(Table 8: OLS Model 22 Estimation on Full Sample) save(table08.doc) format(%9.2gc) font(Latin Modern Roman) fs(12) replace

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

////////////////////////////////////////////////
///*** Summary of Goodness-of-Fit Metrics ***///
////////////////////////////////////////////////

asdoc sum accuracy, title(Table 9: Logit Goodness-of-Fit Measures) save(table09.doc) format(%9.2gc) font(Latin Modern Roman) fs(12) replace

//////////////////////
///*** Accuracy ***///
//////////////////////

*Mean
egen maccuracy = mean(accuracy), by(model_no)
la var maccuracy "Mean accuracy score"

*Variance
egen vaccuracy = sd(accuracy), by(model_no)
la var vaccuracy "SD of accuracy"

*Box scatter
graph box accuracy, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 19: Accuracy Box Plots by Logit Model No.}") b1title("Model no.") ytitle("Accuracy")
graph export "fig19.png", as(png) name("Graph") replace

*Bias-variance tradeoff
colorscatter maccuracy vaccuracy model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Mean") xtitle("Standard deviation", yoffset(-10)) title("{bf:Figure 20: Accuracy-Variance Tradeoff by Logit Model No.}") xscale(range(0 0.045)) xlabel(0(0.01)0.04) graphregion(margin(large))
graph export "fig20.png", as(png) name("Graph") replace

*Over time
colorscatter accuracy split model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Accuracy") xtitle("Year of CV split", yoffset(-15) margin(vlarge)) title("{bf:Figure 21: Accuracy over Time by Logit Model No.}") legend(title("Model no.", size(small) margin(small)))
graph export "fig21.png", as(png) name("Graph") replace

///*** Negative Log Loss ***///

graph box accuracy, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 22: Negative Log Loss Box Plots by Logit Model No.}") b1title("Model no.") ytitle("Negative log loss")
graph export "fig22.png", as(png) name("Graph") replace

///////////////////////////////////////
///*** Logit Model 52 Estimation ***///
///////////////////////////////////////

use "${path}/Data_Final/gbus_401_project_master.dta", clear

asdoc logit admit gpa lsat_* accrl i.tier i.year if year>2011 & year<2022, nest drop(i.year i.tier) title(Table 10: Logit Model 52 Estimation on Full Sample) save(table10.doc) format(%9.2gc) font(Latin Modern Roman) fs(12) replace
