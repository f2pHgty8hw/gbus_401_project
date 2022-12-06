/////////////////////////////////////////////////////
///*** GBUS 401 Final Project: Analysis Script ***///
/////////////////////////////////////////////////////

*Name: Noah Blake Smith

*Last updated: December 5, 2022

use "/Users/justinpotisit/Documents/GitHub/gbus_401_project/Data_Intermediate/gbus_401_project_master.dta", clear

////////////////////////////////
///*** Consistency Checks ***///
////////////////////////////////

///*** User ID ***///

preserve

duplicates tag user_id, gen(apps_per_person)
replace apps_per_person = apps_per_person + 1 // Note line above marks unique observations as 0
duplicates drop user_id, force

sum apps_per_person
hist apps_per_person, freq bin(40) // Distribution and summary stats seem reasonable

restore

///*** Cycle ***///

gen syear = year(sent_at)
gen ryear = year(received_at)
gen uyear = year(ur_at)
gen u2year = year(ur2_at)
gen iyear = year(interview_at)
gen dyear = year(decision_at)
tabstat syear ryear uyear u2year iyear dyear, by(cycle_id) s(count mean)
drop ?year

///*** Status/Result ***///

tab result status

/*These are similar, but there are some small differences (which may mater). The result variable is more robust. Why do they differ? My hunch is one comes from the application status checker. Ask website for more information.*/

///*** Attend ***///

sum attend
tab attend

/*Why is there such a huge withdrawn number? My theory is they use "withdrawn" here to mean declined offer. Check with website.*/

///*** LSAT ***///

hist lsat, freq bin(60) normal
sum lsat

codebook lsat

/*Mean here is 163, which is above national mean in the low 150s. However, it looks like a normal distribution with top-censoring, which may suggest users lie about higher scores. Specifically, at 180 there is an increase in frequency, which is off-trend.*/

///*** GPA ***///

hist gpa
hist gpa if gpa>2.9 & gpa<4.1, freq bin(120) xlabel(3.0 3.1 3.2 3.3 3.33 3.4 3.5 3.6 3.67 3.7 3.8 3.9 4.0)

/*Observations:

1. There is consistent bunching at 3.0, 3.1, 3.2, etc., which suggests many users round their GPAs to one decimal. I expected that.

2. There is consistent bunching, albeit at a smaller magnitude, at the halfway points (e.g., 3.15, 3.55, 3.75). This may be due to rounding. However, I suspect liars are more likely to choose such nice numbers. Further investigation into observations with GPAs of the form X.X5 is warranted.

3. There is consistent rounding of a magnitude similar to (1) at 3.33 and 3.67. This sugests users may be rounding their grades or lying. Further investigation is warranted.*/

///*** True/False Variables ***///

tab urm, m // 16% URM seems realistic to me
tab in_state, m // 98% not in-state sounds high to me, may be unreliable
tab fee_waived, m // 7% fee waiver sounds right
tab got_merit_aid, m // 0.51% (conditional) scholarship sounds very, very low; further investigation warranted
tab non_trad, m // 14% non-traditional (unsure of definition) seems realistic
tab intl, m // 3% international seems right
tab gpa_intl, m // Only exists for 0.5% of observations, so discardable
tab military, m // Mostly missing
tab sus, m // Mostly missing; also curious about definition

///*** Softs ***///

tab softs, m
graph bar, over(softs)

/*Missing for 75% of observations. Share claiming T3 is higher than those claiming T4, which is ironic. I doubt accuracy here.*/

///*** Years Out ***///

sum years_out
hist years_out, bin(37) freq
tabstat years_out, by(cycle_id) s(mean n) // Note strange increase starting in cycle_id 19

///*** LSN Import ***///

tab lsn_import, m
tab cycle_id lsn_import, m

/*Almost 70% of observations are from LSN. Pre cycle_id==2016 (applying ~2018), all data are from LSN. Why? Does this matter? Ask website for further information on how data were obtained and any possible methodological differences.*/

/////////////////////////////////////////////////////
///*** Comparing LSD.law vs. Official ABA Data ***///
/////////////////////////////////////////////////////

///*** Applications, Offers, and Acceptance Rates ***///

*Pooled
corr accr accr2
corr apps apps2
corr offers offers2

*By Year
cap forval i = 2011/2022 {
	cap di `i'
	cap corr accr accr2 if year==`i'
	cap corr apps apps2 if year==`i'
	cap corr offers offers2 if year==`i' // Why is this correlation so much lower?
}

//////////////////////////////////
///*** Preliminary Analysis ***///
//////////////////////////////////

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
