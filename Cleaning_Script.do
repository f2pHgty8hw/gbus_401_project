/////////////////////////////////////////////////////
///*** GBUS 401 Final Project: Cleaning Script ***///
/////////////////////////////////////////////////////


*Name: Noah Blake Smith

*Last Updated: November 27, 2022


/////////////////////////////////////
///*** LSD.law Admissions Data ***///
/////////////////////////////////////

///*** Cleaning ***///

cd "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project/Data_Intermediate"

import delim "lsdata.csv", clear // User should specify appropriate filepath

drop in 1

foreach var of varlist * {
	rename `var' `=`var'[1]'
}

drop in 1

destring user_id, replace

///*** simple_status ***///

replace simple_status = stritrim(strtrim(simple_status))

replace simple_status = "Accepted" if simple_status=="Hold, Accepted" | simple_status=="Hold, Accepted, Withdrawn" | simple_status=="WL, Accepted" | simple_status=="WL, Accepted, Withdrawn" | simple_status=="accepted"
replace simple_status = "Rejected" if simple_status=="Hold, Rejected" | simple_status=="WL, Rejected" | simple_status=="rejected"
replace simple_status = "Waitlisted" if simple_status=="WL, Withdrawn" | simple_status=="waitlisted" | simple_status=="Hold, WL"
replace simple_status = "Other/Unknown" if simple_status!="Accepted" & simple_status!="Rejected" & simple_status!="Waitlisted"

replace simple_status = "0" if simple_status=="Rejected"
replace simple_status = "1" if simple_status=="Accepted"
replace simple_status = "2" if simple_status=="Waitlisted"
replace simple_status = "-1" if simple_status=="Other/Unknown"

destring simple_status, replace

la def status_label -1 "Other/Unknown" 0 "Rejected" 1 "Accepted" 2 "Waitlisted"
la val simple_status "status_label"

ren simple_status status

///*** scholarship ***///

drop scholarship // This variable is blank or filled with spaces

///*** *_at ***///

foreach i of varlist sent_at received_at complete_at ur_at ur2_at interview_at decision_at { // Note: ur = under review and ur2 = under review in round 2

	split `i', p(-)
	drop `i'

	forval j = 1/3 {
		destring `i'`j', replace
	}

	gen `i' = mdy(`i'2,`i'3,`i'1)
	format `i' %td

	drop `i'1 `i'2 `i'3
	
}

///*** result ***///

replace result = stritrim(strtrim(result))

replace result = "Accepted" if result=="Hold, Accepted" | result=="Hold, Accepted, Withdrawn" | result=="WL, Accepted" | result=="WL, Accepted, Withdrawn"
replace result = "Rejected" if result=="Hold, Rejected" | result=="WL, Rejected"
replace result = "Waitlisted" if result=="WL, Withdrawn" | result=="waitlisted" | result=="Hold, WL"
replace result = "Other/Unknown" if result!="Accepted" & result!="Rejected" & result!="Waitlisted"

replace result = "0" if result=="Rejected"
replace result = "1" if result=="Accepted"
replace result = "2" if result=="Waitlisted"
replace result = "-1" if result=="Other/Unknown"

destring result, replace

la val result "status_label"

///*** attend ***///

ren attendance attend

replace attend = "Attending" if attend=="Deferred, Attending"
replace attend = "Withdrawn" if attend=="Deferred, Withdrawn"

replace attend = "0" if attend=="Withdrawn"
replace attend = "1" if attend=="Attending"
replace attend = "2" if attend=="Deferred"

destring attend, replace

la def attend_label 0 "Declined" 1 "Attending" 2 "Deferred"
la val attend "attend_label"

///*** intl_gpa ***///

ren international_gpa gpa_intl

replace gpa_intl = "1" if gpa_intl=="Below Average"
replace gpa_intl = "2" if gpa_intl=="Average"
replace gpa_intl = "3" if gpa_intl=="Above Average"
replace gpa_intl = "4" if gpa_intl=="Superior"

destring gpa_intl, replace

la def gpa_intl_label 1 "Below Average" 2 "Average" 3 "Above Average" 4 "Superior"
la val gpa_intl "gpa_intl_label"

///*** true/false ***///

la def true_false 0 "False" 1 "True"

foreach i of varlist is_* urm non_trad {
	replace `i' = "0" if `i'=="false"
	replace `i' = "1" if `i'=="true"
	destring `i', replace
	la val `i' "true_false"
}

ren is_in_state in_state
ren is_fee_waived fee_waived
ren is_conditional_scholarship got_merit_aid
ren is_international intl
ren is_lsn_import lsn_import // lsn = law school numbers, another data source
ren is_military military
ren is_character_and_fitness_issues sus

///*** softs ***///

replace softs = subinstr(softs,"T","",.) // See definitions: https://www.lsd.law/softs
destring softs, replace

/*Currently, 1 is highest level, and 4 is lowest. I reverse that below.*/

tab softs // Note ~1.6k 1s, 18.3k 2s, 98.1k 3s, and 74k 4s
replace softs = softs - 5
replace softs = -1 * softs
tab softs

///*** year ***///

/*cycle_id lags *_at variables by ~2 years for unknown reasons. For example, cycle_id 17 corresponds to the 2019-2020 admissions cycle. However, this relationship breaks in recent years, per our later analysis. However, I create a year variable that leads the cycle_id by 3 (e.g., year is 2020 if cycle_id is 17).*/

destring cycle_id, replace
gen year = 2000 + cycle_id + 3
la var year "Spring of admissions cycle"

///*** school_name ***///

ren school_name school

replace school = stritrim(strtrim(school))
replace school = subinstr(school,"(Part-time)","",.)
replace school = stritrim(strtrim(school))

///*** Cleaning ***///

foreach i of varlist lsat gpa gpa_intl years_out {
	destring `i', replace
}

la var user_id "User ID"
la var school "School name"
la var status "Status"
la var result "Result"
la var attend "=1 if chose to attend"
la var lsat "Applicant's LSAT"
la var gpa "Applicant's GPA"
la var urm "=1 if applicant is URM"
la var sent_at "Date app was sent"
la var received_at "Date app was received"
la var complete_at "Date app was marked complete"
la var ur_at "Date app was marked under review (1st round)"
la var ur2_at "Date app was marked under review (2nd round)"
la var interview_at "Date of interview"
la var decision_at "Date of decision release"
la var in_state "=1 if school is in state"
la var fee_waived "=1 if application fee was waived"
la var got_merit_aid "=1 if received conditional scholarship"
la var softs "Soft skill tier (4 is best)"
la var non_trad "=1 if non-traditional applicant"
la var intl "=1 if international"
la var gpa_intl "International GPA"
la var years_out "# years since college graduation"
la var lsn_import "=1 if imported from Law School Numbers"
la var military "=1 if military service"
la var sus "=1 if character/fitness issues"
la var cycle_id "Cycle ID"

sort user_id
order user_id year school status result attend lsat gpa urm *_at *
compress

save "gbus_401_project_master.dta", replace


//////////////////////////////////////
///*** Analytix Admissions Data ***///
//////////////////////////////////////

/*I ignore the distinction between full- and part-time students, which may be problematic. Note calendaryear variable refers to spring year of admissions cycle (e.g., 2021 = fall 2020 – spring 2021 cycle).*/

import delim "DataSet Admissions.csv", clear

drop numptapps numftapps numptoffers numftoffers numftmatriculants numptmatriculants totalfirstyear ftfirstyear ptfirstyear otherfirstyear

gen acc_rate = numoffers / numapps
la var acc_rate "Acceptance rate (official)"

gen yield = nummatriculants / numoffers
la var yield "Yield (official)"

forval i = 25(25)75 {
	drop ftuggpa`i' ptuggpa`i'
	ren uggpa`i' gpa`i' // Only full-time
}

drop uggpaexcl ftuggpaexcl ptuggpaexcl // Why excluded? What does negative value signify?

forval i = 25(25)75 {
	drop ptlsat`i' ftlsat`i'
}

drop *lsatexcl // Why excluded? Why does negative value signify?
drop gmatenrolled-ptgreverbal75 // Minimal and not available in LSD.law data

compress

save "admissions.dta", replace

/////////////////////////////////////
///*** Analytix Attrition Data ***///
/////////////////////////////////////

import delim "DataSet Attrition.csv", clear

keep schoolid schoolname calendaryear pctjd1attrition

ren pctjd1attrition attrition

compress

save "attrition.dta", replace

///////////////////////////////////
///*** Analytix Degrees Data ***///
///////////////////////////////////

import delim "DataSet Degrees.csv", clear

keep schoolid schoolname calendaryear totaljddeg minorityjddeg

ren totaljddeg jds_tot
ren minorityjddeg jds_urm // All minorities, not necessarily underrepresented

compress

save "degrees.dta", replace

//////////////////////////////////////
///*** Analytix Employment Data ***///
//////////////////////////////////////

import delim "DataSet Employment.csv", clear

keep schoolid schoolname cohort total_ftlt total_grads

gen emp_rate = total_ftlt / total_grads // Note I only count long-term full-time jobs as employment; cannot disaggregate part-time vs. full-time students
drop total_ftlt total_grads

ren cohort calendaryear // Graduation year

order schoolid schoolname calendaryear emp_rate

drop if calendaryear==2010 // All blanks

compress

save "employment.dta", replace

//////////////////////////////////////
///*** Analytix Enrollment Data ***///
//////////////////////////////////////

import delim "DataSet Enrollment.csv", clear

keep schoolid schoolname calendaryear totaljd minorityjd menjd womenjd

gen stud_urm = minorityjd / totaljd
gen stud_men = menjd / totaljd
gen stud_wom = womenjd / totaljd

keep schoolid schoolname calendaryear stud_*

compress

save "enrollment.dta", replace

///////////////////////////////////
///*** Analytix Faculty Data ***///
///////////////////////////////////

/*Split into two data sets, which I combine.*/

///*** Part 1: 2017-2021 ***///

import delim "DataSet Faculty (Academic Year).csv", clear

keep schoolid schoolname calendaryear factotal facmen facwomen facminority // Includes part-time faculty, which may be problematic; exclude academic year, as it corresponds to fall year (I think)

ren factotal fac_tot
ren facmen fac_men
ren facwomen fac_wom
ren facminority fac_urm

compress

save "faculty.dta", replace

///*** Part 2: 2011-2016 ***///

import delim "DataSet Faculty (Calendar Year).csv", clear

keep schoolid schoolname calendaryear sprfactotal sprfacmen sprfacwomen sprfacminority // Use spring faculty count, per LSD.law data

ren sprfactotal fac_tot
ren sprfacmen fac_men
ren sprfacwomen fac_wom
ren sprfacminority fac_urm

compress

///*** Part 3: Combine ***///

append using "faculty.dta"

order schoolid schoolname calendaryear *

isid schoolid calendaryear // No duplication

replace fac_men = fac_men / fac_tot
replace fac_wom = fac_wom / fac_tot
replace fac_urm = fac_urm / fac_tot

compress

save "faculty.dta", replace

/////////////////////////////////////////
///*** Analytix Financial Aid Data ***///
/////////////////////////////////////////

import delim "DataSet Financial Aid.csv", clear

keep schoolid schoolname calendaryear condscholind numstudents totalrecvgrant totalrecvgrant totalgrantfull totalgrantgtfull totalgrantalhalf totalgrantlthalf

ren condscholind merit_aid
replace merit_aid = "1" if merit_aid=="Y"
replace merit_aid = "0" if merit_aid=="N"
destring merit_aid, replace

gen stud_aid = totalrecvgrant / numstudents
gen stud_aid_0to50 = totalgrantlthalf / numstudents
gen stud_aid_50to100 = totalgrantalhalf / numstudents
gen stud_aid_100toX = (totalgrantfull + totalgrantgtfull) / numstudents

keep schoolid schoolname calendaryear merit_aid stud_*

compress

save "financial_aid.dta", replace

///////////////////////////////////////
///*** Analytix Bar Passage Data ***///
///////////////////////////////////////

import delim "DataSet First-Time and Ultimate Bar Passage (School-Level).csv", clear

keep schoolid schoolname calendaryear avgschoolpasspct avgstatepasspct avgpasspctdiff

ren avgschoolpasspct bar_pass_school
ren avgstatepasspct bar_pass_state
ren avgpasspctdiff bar_pass_diff

duplicates list schoolid calendaryear // Marquette University is duplicated in 2011
duplicates drop schoolid calendaryear, force

compress

save "bar_passage.dta", replace

//////////////////////////////////////////////
///*** Analytix School Information Data ***///
//////////////////////////////////////////////

/*Note I use the 2021 information, which may be innacurate for schools that moved.*/

import delim "DataSet School Information.csv", clear // I deleted a few misplaced return keys in .csv file

drop mainopeid termtype schooltype

ren schoolcity city
replace city = stritrim(strtrim(city))

ren schoolstate state
replace state = stritrim(strtrim(state))

ren schoolzipcode zip
replace zip = substr(zip,1,5) // Some ZIP codes have +4 extension
destring zip, replace
format zip %05.0f

ren schoolstatus active
replace active = "1" if active=="Active"
replace active = "0" if active=="InActive"
destring active, replace

compress

save "information.dta", replace

////////////////////////////////////////////
///*** Analytix Student Expenses Data ***///
////////////////////////////////////////////

import delim "DataSet Student Expenses.csv", clear

keep schoolid schoolname calendaryear schooltype ftrestuition ftnonrestuition // Full-time only

ren schooltype private
replace private = "1" if private=="PRI"
replace private = "0" if private=="PUB"
destring private, replace

ren ftrestuition tuition_res
ren ftnonrestuition tuition_nonres

compress

save "expenses.dta", replace

/////////////////////////////////
///*** MERGE Analytix Data ***///
/////////////////////////////////

use "admissions.dta", clear

merge 1:1 schoolid calendaryear using "attrition.dta" // Two unmatched in master (neither notable)
drop _merge

merge 1:1 schoolid calendaryear using "degrees.dta" // All matched
drop _merge

merge 1:1 schoolid calendaryear using "employment.dta" // 12 unmatched in master (none notable)
drop _merge

merge 1:1 schoolid calendaryear using "enrollment.dta" // All matched
drop _merge

merge 1:1 schoolid calendaryear using "faculty.dta" // All matched
drop _merge

merge 1:1 schoolid calendaryear using "financial_aid.dta" // Two unmatched in master (neither notable)
drop _merge

merge 1:1 schoolid calendaryear using "bar_passage.dta" // Substantial non-matches because pre-2011 and post-2021 data are unavailable for master
drop _merge

merge m:1 schoolid using "information.dta" // All matched
drop _merge

merge 1:1 schoolid calendaryear using "expenses.dta" // Substantial non-matches because pre-2011 and post-2021 data are unavailable for master
drop _merge

///*** Cleanup ***///

ren schoolid school_id
la var school_id "LSAC school ID"

ren schoolname school
la var school "School name"

ren calendaryear year
la var year "Spring of admissions cycle"

ren numapps apps
la var apps "# applications"

ren numoffers offers
la var offers "# offers"

ren nummatriculants matrics
la var matrics "# matriculants"

forval i = 25(25)75 {
	foreach j in gpa lsat {
		la var `j'`i' "`i'th pctile of all applicants"
	}
}

la var attrition "1L attrition rate"

la var jds_tot "# degrees awarded to all students"
la var jds_urm "# degrees awarded to URM"

la var emp_rate "FT long-term employment rate"

la var stud_urm "% URM students"
la var stud_men "% male students"
la var stud_wom "% female students"

la var fac_tot "# faculty"
la var fac_men "% male faculty"
la var fac_wom "% female faculty"
la var fac_urm "% URM faculty"

la var merit_aid "=1 if school offers conditional scholarships"
la var stud_aid "% students with any aid"
la var stud_aid_0to50 "% students with 0-50% aid"
la var stud_aid_50to100 "% students with 50-100% aid"
la var stud_aid_100toX "% students with 100%+ aid"

la var bar_pass_school "School's mean 1st-attempt bar pass rate"
la var bar_pass_state "State's mean 1st-attempt bar pass rate"
la var bar_pass_diff "Pct points above/below state's mean"

la var city "City"
la var state "State"
la var zip "ZIP code"
la var active "=1 if school is active as of 2021"
la var private "=1 if school is private as of 2021"
la var tuition_res "Residential FT tuition (nominal USD)"
la var tuition_nonres "Nonresidential FT tuition (nominal USD)"

///*** Prep for Merge ***///

ren school Uschool

gen merge_var = Uschool
replace merge_var = lower(merge_var)
replace merge_var = subinstr(merge_var,"university","",.) if school_id!=252000 & school_id!=379800
replace merge_var = subinstr(merge_var,"school","",.)
replace merge_var = subinstr(merge_var,"of","",.) if school_id!=252000 | school_id!=379800
replace merge_var = subinstr(merge_var,"-"," ",.) // Dash
replace merge_var = subinstr(merge_var,"—"," ",.) // Em dash
replace merge_var = subinstr(merge_var,".","",.)
replace merge_var = subinstr(merge_var,"&","and",.)
replace merge_var = subinstr(merge_var,"the","",.)
replace merge_var = subinstr(merge_var,",","",.)
replace merge_var = subinstr(merge_var,"(","",.)
replace merge_var = subinstr(merge_var,")","",.)
replace merge_var = stritrim(strtrim(merge_var))

replace merge_var = "mitchell hamline" if strpos(merge_var,"william mitchell") | strpos(merge_var,"mitchell hamline")
replace merge_var = "pennsylvania state" if (strpos(merge_var,"pennsylvania state") | strpos(merge_var,"penn state")) & strpos(merge_var,"dickinson")==0

compress

save "analytix_data.dta", replace

foreach i in "admissions.dta" "attrition.dta" "bar_passage.dta" "degrees.dta" "employment.dta" "enrollment.dta" "expenses.dta" "faculty.dta" "financial_aid.dta" "information.dta" {
	erase `i'
}

/////////////////////////
///*** FINAL MERGE ***///
/////////////////////////

use "gbus_401_project_master.dta", clear

///*** Prep for Merge ***///

gen merge_var = school

replace merge_var = lower(merge_var)
replace merge_var = subinstr(merge_var,"university","",.) if school!="University of Washington" & school!="Washington University in St. Louis"
replace merge_var = subinstr(merge_var,"school","",.)
replace merge_var = subinstr(merge_var,"of","",.)
replace merge_var = subinstr(merge_var,"-"," ",.) // Dash
replace merge_var = subinstr(merge_var,"—"," ",.) // Em dash
replace merge_var = subinstr(merge_var,".","",.)
replace merge_var = subinstr(merge_var,"&","and",.)
replace merge_var = subinstr(merge_var,"the","",.)
replace merge_var = subinstr(merge_var,",","",.)
replace merge_var = subinstr(merge_var,"(","",.)
replace merge_var = subinstr(merge_var,")","",.)
replace merge_var = stritrim(strtrim(merge_var))

replace merge_var = "pennsylvania state" if strpos(merge_var,"pennsylvania state") | strpos(merge_var,"penn state")
replace merge_var = "washington university" if merge_var=="washington university in st louis"
drop if merge_var=="new brunswick" | merge_var=="toronto" | merge_var=="western ontario" | merge_var=="alberta" | merge_var=="windsor" | merge_var=="british columbia" | merge_var=="queen's" | merge_var=="mcgill" | merge_var=="victoria" | merge_var=="york osgoode hall" | merge_var=="dalhousie" | merge_var=="calgary" | merge_var=="ottawa" | merge_var=="manitoba" | merge_var=="saskatchewan"
replace merge_var = "rutgers camden" if strpos(merge_var,"rutgers") & strpos(merge_var,"camden") & year<2015
replace merge_var = "rutgers newark" if strpos(merge_var,"rutgers") & strpos(merge_var,"newark") & year<2015
replace merge_var = "rutgers" if strpos(merge_var,"rutgers") & year>=2015
replace merge_var = "chicago kent college law iit" if strpos(merge_var,"illinois") & strpos(merge_var,"kent")
replace merge_var = "cardozo law" if strpos(merge_var,"yeshiva") | strpos(merge_var,"cardozo")
replace merge_var = "mitchell hamline" if strpos(merge_var,"william mitchell") | strpos(merge_var,"mitchell hamline")
replace merge_var = "la verne" if strpos(merge_var,"la verne")
replace merge_var = "south texas college law" if merge_var=="south texas college law houston"
replace merge_var = "colorado" if strpos(merge_var,"colorado")
replace merge_var = "illinois chicago law" if merge_var=="illinois chicago"
replace merge_var = "faulkner" if merge_var=="jones law"
replace merge_var = "city new york" if merge_var=="cuny"
replace merge_var = "western michigan" if merge_var=="western michigan cooley"
replace merge_var = "florida" if merge_var=="florida levin"
replace merge_var = "mcgeorge law" if merge_var=="pacific mcgeorge"
replace merge_var = "illinois" if merge_var=="illinois urbana champaign"
replace merge_var = "inter american puerto rico" if merge_var=="inter american law"
replace merge_var = "pontifical catholic pr" if merge_var=="pontifical catholic"
replace merge_var = "unt dallas college law" if merge_var=="north texas at dallas"
replace merge_var = "arizona summit law" if merge_var=="phoenix law"

///*** Merge ***///

merge m:1 merge_var year using "analytix_data.dta"

tab _merge if year>2010 & year<2022 // As of now, we only have school-level data for 2010 to 2021
drop _merge merge_var

compress

save "gbus_401_project_master.dta", replace

erase "analytix_data.dta"
