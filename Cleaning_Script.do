/////////////////////////////////////////////////////
///*** GBUS 401 Final Project: Cleaning Script ***///
/////////////////////////////////////////////////////


*Name: Noah Blake Smith
*Last Updated: December 5, 2022


/////////////////////////////////////
///*** LSD.law Admissions Data ***///
/////////////////////////////////////

//global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project"
global path "/Users/justinpotisit/Documents/GitHub/gbus_401_project"
cd "${path}/Data_Intermediate" // User must specify appropriate paths

import delim "lsdata.csv", clear

drop in 1

foreach var of varlist * {
	rename `var' `=`var'[1]'
}

drop in 1

destring user_id, replace

///*** Simple Status ***///

replace simple_status = stritrim(strtrim(simple_status))

replace simple_status = "Accepted" if simple_status=="Hold, Accepted" | simple_status=="Hold, Accepted, Withdrawn" | simple_status=="WL, Accepted" | simple_status=="WL, Accepted, Withdrawn" | simple_status=="accepted"
replace simple_status = "Rejected" if simple_status=="Hold, Rejected" | simple_status=="WL, Rejected" | simple_status=="rejected"
replace simple_status = "Waitlisted" if simple_status=="WL, Withdrawn" | simple_status=="waitlisted" | simple_status=="Hold, WL"
replace simple_status = "Other/Unknown" if simple_status!="Accepted" & simple_status!="Rejected" & simple_status!="Waitlisted"

replace simple_status = "0" if simple_status=="Rejected"
replace simple_status = "0" if simple_status=="Waitlisted" // We code waitlists as rejects because most will be rejected; more justification in analysis
replace simple_status = "1" if simple_status=="Accepted"
replace simple_status = "-1" if simple_status=="Other/Unknown"

destring simple_status, replace

la def status_label -1 "Other/Unknown" 0 "Rejected" 1 "Accepted"
la val simple_status "status_label"

ren simple_status status

///*** Conditional Scholarships (Merit Aid) ***///

drop scholarship // All observations blank

///*** Timeline Variables ***///

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

///*** Results ***///

replace result = stritrim(strtrim(result))

replace result = "Accepted" if result=="Hold, Accepted" | result=="Hold, Accepted, Withdrawn" | result=="WL, Accepted" | result=="WL, Accepted, Withdrawn"
replace result = "Rejected" if result=="Hold, Rejected" | result=="WL, Rejected"
replace result = "Waitlisted" if result=="WL, Withdrawn" | result=="waitlisted" | result=="Hold, WL"
replace result = "Other/Unknown" if result!="Accepted" & result!="Rejected" & result!="Waitlisted"

replace result = "0" if result=="Rejected"
replace result = "0" if result=="Waitlisted" // We code waitlists as rejects because most will be rejected; more justification in analysis
replace result = "1" if result=="Accepted"
replace result = "-1" if result=="Other/Unknown"

destring result, replace

la val result "status_label"

///*** Attend Indicator ***///

ren attendance attend

replace attend = "Attending" if attend=="Deferred, Attending"
replace attend = "Withdrawn" if attend=="Deferred, Withdrawn"

replace attend = "0" if attend=="Withdrawn"
replace attend = "1" if attend=="Attending"
replace attend = "2" if attend=="Deferred"

destring attend, replace

la def attend_label 0 "Declined" 1 "Attending" 2 "Deferred"
la val attend "attend_label"

///*** International GPA ***///

ren international_gpa gpa_intl

replace gpa_intl = "1" if gpa_intl=="Below Average"
replace gpa_intl = "2" if gpa_intl=="Average"
replace gpa_intl = "3" if gpa_intl=="Above Average"
replace gpa_intl = "4" if gpa_intl=="Superior"

destring gpa_intl, replace

la def gpa_intl_label 1 "Below Average" 2 "Average" 3 "Above Average" 4 "Superior"
la val gpa_intl "gpa_intl_label"

///*** True/False Indicators ***///

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

///*** Soft Skills ***///

replace softs = subinstr(softs,"T","",.) // See definitions: https://www.lsd.law/softs
destring softs, replace

/*Currently, 1 is highest level, and 4 is lowest. I reverse that below.*/

tab softs // Note ~1.6k 1s, 18.3k 2s, 98.1k 3s, and 74k 4s
replace softs = softs - 5
replace softs = -1 * softs
tab softs

///*** Year ***///

/*Variable cycle_id is an integer that indicates the admissions cycle. Note cycle_id = 1 for the first year of data collection, the 2003-2004 admissions cycle, and cycle_id = 2 for the 2004-2005 cycle, and so on.

However, there is a structural break in this relationship starting in cycle_id = 16, the 2018-2019 admissions cycle. Prior to then, lsd.law did not exist. The website was created in January 2019, and previous cycles' data were imported from lawschoolnumbers.com. Around ~5k applications were directly submitted to lsd.law that cycle, and about 32k were later imported from lawschoolnumbers.com. The following cycle, cycle_id = 17 / the 2019-2020 admissions cycle, lsd.law rapidly rose in popularity, receiving ~33k applications (and ~17k were later imported from lawschoolnumbers.com). this trend accelerated in cycle_id = 18 / the 2020-2021 admissions cycle, which a record-breaking number of applications in the population (i.e., LSAC official numbers) and our sample. Little data were imported from lawschoolnumbers.com from this cycle onward.

We believe, however, the lsd.law creator miscoded cycle_id = 19 and cycle_id = 22 for several reasons. First, both have unusually small sample sizes. Whereas the preceeding cycles_id's have sample sizes of ~75k and 68k, respectively, that of cycle_id = 19 is just 571. Similarly, cycle_id = 22, the current cycle, has only ~2k applications thus far, compared to the ~30k last cycle. (Note that law school applications are submitted on a quasi-rolling basis from September to February of each cycle. While applicants are far from even distributed across this period, we would reasonably expect a much larger sample by now in this cycle, based on previous years' trends and recently released LSAC data.) Second, the cycle_id value is higher than it should be. Prior to cycle_id = 19, the cycle_id's clearly counted up from 1, the 2003-2004 cycle. If that pattern continues, then the supposed current cycle, cycle_id = 22, is the 2024-2025 admissions cycle, which is obviously wrong.

Given we are actually in the 2022-2023 cycle as of writing, we hypothesize that cycle_id = 19 and 22 were incorrectly coded as separate cycles. In reality, the *_at variables of cycle_id = 19 align with those of cycle_id = 18, and those of cycle_id = 22 align with those of cycle_id = 21. Hence, we have recoded cycle_id = 19 as 18 and 22 as 21, and then renumbered the years so as to count up as they should.

We contacted the creator of lsd.law for clarification. He said there might be errors because this has been a "learning experience" for him, but he was occupied with 3L exams at the moment.*/

destring cycle_id, replace

*Tabulations for explanation above
tab cycle_id lsn_import
tabstat cycle_id, by(cycle_id) s(count)
tabstat *_at, by(cycle_id) s(mean) format(%td)

*Recode suspected errors
replace cycle_id = 21 if cycle_id==22
replace cycle_id = 18 if cycle_id==19

*Recode to count by 1
replace cycle_id = 19 if cycle_id==20
replace cycle_id = 20 if cycle_id==21

*Generate year variable
gen year = 2000 + cycle_id + 3
drop if year==2023

///*** School ***///

ren school_name school
replace school = ustrregexra(upper(school),"[^A-Za-z\s]"," ")
replace school = subinstr(school,"PART TIME","",.)
replace school = stritrim(strtrim(school))
replace school = subinstr(school," S ","S ",.) // For apostrophes

*Drop Canadian schools (unavailable in Analytix data)
foreach i in "NEW BRUNSWICK" "TORONTO" "WESTERN ONTARIO" "ALBERTA" "WINDSOR" "BRITISH COLUMBIA" "QUEENS" "MCGILL" "VICTORIA" "OSGOODE HALL" "DALHOUSIE" "CALGARY" "OTTAWA" "MANITOBA" "SASKATCHEWAN" {
	drop if strpos(school,"`i'")
}

///*** Miscellaneous ***///

foreach i of varlist lsat gpa gpa_intl years_out {
	destring `i', replace
}

la var user_id "User ID"
la var school "School name (LSD.law)"
la var status "Status"
la var result "Result"
la var attend "=1 if chose to attend"
la var lsat "Applicant LSAT"
la var gpa "Applicant GPA"
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
la var year "Year (spring of admissions cycle)"

drop gpa_intl // This variable is not used and causes problems later on unless dropped

sort user_id
order user_id year school status result attend lsat gpa urm *_at *
compress

save "gbus_401_project_master.dta", replace

//////////////////////////////////////
///*** Analytix Admissions Data ***///
//////////////////////////////////////

/*I ignore the distinction between full- and part-time students, which may be problematic. Note calendaryear variable refers to spring year of admissions cycle (e.g., 2021 = fall 2020 – spring 2021 cycle).*/

import delim "DataSet Admissions.csv", clear

keep schoolid schoolname calendaryear numapps numoffers nummatriculants uggpa?? lsat?? 

forval i = 25(25)75 {
	ren uggpa`i' gpa`i'
}

///*** Adjust Penn State ***///

/*Penn State's two campuses began reporting data separately in 2015. We aggregate the data 2015 onward for consistency.*/

local system = "Pennsylvania State University"
local campus1 = "Pennsylvania State University-Dickinson School of Law" // Will convert to system
local campus2 = "Pennsylvania State University-Penn State Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 332922 if schoolname=="`campus1'" // Use pre-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total applications
egen numapps_tot = sum(numapps) if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
replace numapps_tot = . if schoolname!="`system'"

*Additional applications
gen tempvar = numapps if schoolname=="`campus2'"
egen numapps_addl = mean(tempvar), by(calendaryear)
replace numapps_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist gpa* lsat* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * numapps + `i'_addl * numapps_addl) / numapps_tot if schoolname=="`system'" & calendaryear>2014
	
	if strpos("`i'","gpa")==1 {
		format `i' %9.3g
	}
	
	if strpos("`i'","lsat")==1 {
		format `i' %8.0f
	}
	
	drop `i'_addl
}

drop numapps_tot numapps_addl

*Add count variables
foreach i of varlist num* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear>2014
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Rutgers ***///

/*Rutgers's two campuses used to jointly report data. However, the data are reported separately from 2015 onward. We aggregate the data from 2015 onward for consistency. The code is adapted from that used for Penn State.*/

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total applications
egen numapps_tot = sum(numapps) if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
replace numapps_tot = . if schoolname!="`system'"

*Additional applications
gen tempvar = numapps if schoolname=="`campus2'"
egen numapps_addl = mean(tempvar), by(calendaryear)
replace numapps_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist gpa* lsat* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * numapps + `i'_addl * numapps_addl) / numapps_tot if schoolname=="`system'" & calendaryear<2015
	
	if strpos("`i'","gpa")==1 {
		format `i' %9.2f
	}
	
	if strpos("`i'","lsat")==1 {
		format `i' %8.0f
	}
	
	drop `i'_addl
}

drop numapps_tot numapps_addl

*Add count variables
foreach i of varlist num* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2015
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Mitchell Hamline ***///

/*Hamline University School of Law and William Mitchell College of Law merged to form the Mitchell Hamline School of Law in 2015, and so data are combined from 2016 onward. For consistency across time, we aggregate the preceeding years' data. The code is adapted from that use for Rutgers.*/

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total applications
egen numapps_tot = sum(numapps) if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
replace numapps_tot = . if schoolname!="`system'"

*Additional applications
gen tempvar = numapps if schoolname=="`campus2'"
egen numapps_addl = mean(tempvar), by(calendaryear)
replace numapps_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist gpa* lsat* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * numapps + `i'_addl * numapps_addl) / numapps_tot if schoolname=="`system'" & calendaryear<2016
	
	if strpos("`i'","gpa")==1 {
		format `i' %9.2f
	}
	
	if strpos("`i'","lsat")==1 {
		format `i' %8.0f
	}
	
	drop `i'_addl
}

drop numapps_tot numapps_addl

*Add count variables
foreach i of varlist num* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2016
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** New Variables ***///

gen accr = numoffers / numapps
format accr %9.2f

tsset schoolid calendaryear, yearly
gen accrl = L.accr
format accrl %9.2f
tsset, clear

gen yield = nummatriculants / numoffers
format yield %9.2f

///*** Outro ***///

sort schoolid (calendaryear)
compress

save "admissions.dta", replace

///////////////////////////////////
///*** Analytix Degrees Data ***///
///////////////////////////////////

import delim "DataSet Degrees.csv", clear

ren totaljddeg jds_tot
ren minorityjddeg jds_urm // All minorities, not necessarily underrepresented (initialism used for its brevity)

///*** Adjust Penn State ***///

local system = "Pennsylvania State University"
local campus1 = "Pennsylvania State University-Dickinson School of Law" // Will convert to system
local campus2 = "Pennsylvania State University-Penn State Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 332922 if schoolname=="`campus1'" // Use pre-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add degrees
foreach i of varlist jds_* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear>2014
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Rutgers ***///

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add degrees
foreach i of varlist jds_* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2015
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Mitchell Hamline ***///

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add degrees
foreach i of varlist jds_* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2016
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** New Variable ***///

replace jds_urm = jds_urm / jds_tot
format jds_urm %9.2f

///*** Outro ***///

keep schoolid schoolname calendaryear jds_urm

sort schoolid (calendaryear)
compress

save "degrees.dta", replace

//////////////////////////////////////
///*** Analytix Employment Data ***///
//////////////////////////////////////

import delim "DataSet Employment.csv", clear

keep schoolid schoolname cohort total_ftlt total_grads

ren cohort calendaryear // Graduation year
ren total_ftlt ftlt_tot
ren total_grads grads_tot

///*** Adjust Penn State ***///

local system = "Pennsylvania State University"
local campus1 = "Pennsylvania State University-Dickinson School of Law" // Will convert to system
local campus2 = "Pennsylvania State University-Penn State Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 332922 if schoolname=="`campus1'" // Use pre-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add employment
foreach i of varlist *_tot {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear>2014
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Rutgers ***///

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add employment
foreach i of varlist *_tot {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2015
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Mitchell Hamline ***///

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add employment
foreach i of varlist *_tot {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2016
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** New Variable ***///

gen empr = ftlt_tot / grads_tot // Note I only count long-term full-time jobs as employment; cannot disaggregate part-time vs. full-time students
format empr %9.2f

///*** Outro ***///

drop ftlt_tot
drop if calendaryear==2010 // All blanks

order schoolid schoolname calendaryear empr
sort schoolid (calendaryear)

compress

save "employment.dta", replace

//////////////////////////////////////
///*** Analytix Enrollment Data ***///
//////////////////////////////////////

import delim "DataSet Enrollment.csv", clear

keep schoolid schoolname calendaryear totaljd minorityjd menjd womenjd totaljd1

///*** Adjust Penn State ***///

local system = "Pennsylvania State University"
local campus1 = "Pennsylvania State University-Dickinson School of Law" // Will convert to system
local campus2 = "Pennsylvania State University-Penn State Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 332922 if schoolname=="`campus1'" // Use pre-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add students
foreach i of varlist *jd* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear>2014
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Rutgers ***///

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add students
foreach i of varlist *jd* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2015
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Mitchell Hamline ***///

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add students
foreach i of varlist *jd* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2016
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** New Variables ***///

gen stud_urm = minorityjd / totaljd
gen stud_men = menjd / totaljd
gen stud_wom = womenjd / totaljd

foreach i of varlist stud_* {
	format `i' %9.2f
}

///*** Outro ***///

keep schoolid schoolname calendaryear stud_*
sort schoolid (calendaryear)

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

/// Part 4: Adjust Penn State ***///

local system = "Pennsylvania State University"
local campus1 = "Pennsylvania State University-Dickinson School of Law" // Will convert to system
local campus2 = "Pennsylvania State University-Penn State Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 332922 if schoolname=="`campus1'" // Use pre-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add faculty
foreach i of varlist fac_* {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear>2014
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Part 5: Adjust Rutgers ***///

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add faculty
foreach i of varlist fac_*  {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2015
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Part 6: Adjust Mitchell Hamline ***///

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Add faculty
foreach i of varlist fac_*  {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2016
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Part 7: New Variables ***///

foreach i of varlist fac_* {
	if "`i'"!="fac_tot" {
		replace `i' = `i' / fac_tot
		format `i' %9.2f
	}
}

///*** Outro ***///

drop fac_tot
sort schoolid calendaryear

compress

save "faculty.dta", replace

/////////////////////////////////////////
///*** Analytix Financial Aid Data ***///
/////////////////////////////////////////

import delim "DataSet Financial Aid.csv", clear

keep schoolid schoolname calendaryear condscholind numstudents totalrecvgrant totalrecvgrant totalgrantfull totalgrantgtfull totalgrantalhalf totalgrantlthalf

///*** Adjust Penn State ***///

local system = "Pennsylvania State University"
local campus1 = "Pennsylvania State University-Dickinson School of Law" // Will convert to system
local campus2 = "Pennsylvania State University-Penn State Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 332922 if schoolname=="`campus1'" // Use pre-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Merit aid
replace condscholind = "N" if schoolname=="`system'"

*Add recipients
foreach i of varlist numstudents-totalgrantgtfull {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear>2014
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Rutgers ***///

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Merit aid
replace condscholind = "Y" if schoolname=="`system'"

*Add recipients
foreach i of varlist numstudents-totalgrantgtfull {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2015
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Adjust Mitchell Hamline ***///

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Merit aid
replace condscholind = "Y" if schoolname=="`system'"

*Add recipients
foreach i of varlist numstudents-totalgrantgtfull {
	egen `i'_tot = sum(`i') if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
	replace `i'_tot = . if schoolname!="`system'"
	
	replace `i' = `i'_tot if schoolname=="`system'" & calendaryear<2016
	
	drop `i'_tot
}

drop if schoolname=="`campus2'"

///*** Merit Aid ***///

ren condscholind merit_aid
replace merit_aid = "1" if merit_aid=="Y"
replace merit_aid = "0" if merit_aid=="N"
destring merit_aid, replace

///*** New Variables ***///

gen stud_aid = totalrecvgrant / numstudents
gen stud_aid_0to50 = totalgrantlthalf / numstudents
gen stud_aid_50to100 = totalgrantalhalf / numstudents
gen stud_aid_100toX = (totalgrantfull + totalgrantgtfull) / numstudents

foreach i of varlist stud_* {
	format `i' %9.2f
}

///*** Outro ***///

keep schoolid schoolname calendaryear merit_aid stud_*
sort schoolid (calendaryear)

compress

save "financial_aid.dta", replace

///////////////////////////////////////
///*** Analytix Bar Passage Data ***///
///////////////////////////////////////

import delim "DataSet First-Time and Ultimate Bar Passage (School-Level).csv", clear

keep schoolid schoolname calendaryear avgschoolpasspct avgstatepasspct avgpasspctdiff totalfirsttimetakers

ren avgschoolpasspct bar_pass_school
ren avgstatepasspct bar_pass_state
ren avgpasspctdiff bar_pass_diff
ren totalfirsttimetakers takers

///*** Adjust Penn State ***///

local system = "Pennsylvania State University"
local campus1 = "Pennsylvania State University-Dickinson School of Law" // Will convert to system
local campus2 = "Pennsylvania State University-Penn State Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 332922 if schoolname=="`campus1'" // Use pre-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total takers
egen takers_tot = sum(takers) if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
replace takers_tot = . if schoolname!="`system'"

*Additional takers
gen tempvar = takers if schoolname=="`campus2'"
egen takers_addl = mean(tempvar), by(calendaryear)
replace takers_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist bar_pass_* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * takers + `i'_addl * takers_addl) / takers_tot if schoolname=="`system'" & calendaryear>2014
	format `i' %9.2f
	
	drop `i'_addl
}

drop takers_*
drop if schoolname=="`campus2'"

///*** Adjust Rutgers ***///

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total takers
egen takers_tot = sum(takers) if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
replace takers_tot = . if schoolname!="`system'"

*Additional takers
gen tempvar = takers if schoolname=="`campus2'"
egen takers_addl = mean(tempvar), by(calendaryear)
replace takers_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist bar_pass_* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * takers + `i'_addl * takers_addl) / takers_tot if schoolname=="`system'" & calendaryear<2015
	format `i' %9.2f
	
	drop `i'_addl
}

drop takers_*
drop if schoolname=="`campus2'"

///*** Adjust Mitchell Hamline ***///

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total takers
egen takers_tot = sum(takers) if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
replace takers_tot = . if schoolname!="`system'"

*Additional takers
gen tempvar = takers if schoolname=="`campus2'"
egen takers_addl = mean(tempvar), by(calendaryear)
replace takers_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist bar_pass_* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * takers + `i'_addl * takers_addl) / takers_tot if schoolname=="`system'" & calendaryear<2016
	format `i' %9.2f
	
	drop `i'_addl
}

drop takers_*
drop if schoolname=="`campus2'"

///*** Outro ***///

drop takers

duplicates list schoolid calendaryear // Marquette University is duplicated in 2011
duplicates drop schoolid calendaryear, force
isid schoolid calendaryear // Variables uniquely identify rows

sort schoolid (calendaryear)

compress

save "bar_passage.dta", replace

//////////////////////////////////////////////
///*** Analytix School Information Data ***///
//////////////////////////////////////////////

/*Note I use the 2021 information, which may be innacurate for schools that moved.*/

import delim "DataSet School Information.csv", clear // I deleted a few misplaced return keys in .csv file

///*** Adjust Penn State, Rutgers, and Mitchell Hamline ***///

drop if schoolname=="Rutgers University-Camden" | schoolname=="Rutgers University-Newark" | schoolname=="Pennsylvania State University-Penn State Law" | schoolname=="Pennsylvania State University-Dickinson School of Law" | schoolname=="Hamline University" | schoolname=="William Mitchell College of Law"

///*** Clean ***///

keep schoolid schoolname schoolcity schoolstate schoolzipcode

ren schoolcity city
ren schoolstate state

foreach i of varlist city state {
	replace `i' = stritrim(strtrim(ustrregexra(upper(`i'),"[^A-Za-z\s]"," ")))
}

ren schoolzipcode zip
replace zip = substr(zip,1,5) // Some ZIP codes have +4 extension
destring zip, replace
format zip %05.0f

///*** Outro ***///

sort schoolid

compress

save "information.dta", replace

////////////////////////////////////////////
///*** Analytix Student Expenses Data ***///
////////////////////////////////////////////

import delim "DataSet Student Expenses.csv", clear

keep schoolid schoolname calendaryear schooltype ftrestuition ftnonrestuition // Full-time only

///*** Clean Variables ***///

ren schooltype private // Note no changes in private/public status of any schools
replace private = "1" if private=="PRI"
replace private = "0" if private=="PUB"
destring private, replace

ren ftrestuition tuition_instate
ren ftnonrestuition tuition_outstate

save "expenses.dta", replace

///*** Get Student Enrollments ***///

import delim "DataSet Enrollment.csv", clear
keep schoolid calendaryear totaljd
ren totaljd stud

merge 1:1 schoolid calendaryear using "expenses.dta" // All matched
drop _merge

///*** Adjust Penn State ***///

local system = "Pennsylvania State University"
local campus1 = "Pennsylvania State University-Dickinson School of Law" // Will convert to system
local campus2 = "Pennsylvania State University-Penn State Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 332922 if schoolname=="`campus1'" // Use pre-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total students
egen stud_tot = sum(stud) if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
replace stud_tot = . if schoolname!="`system'"

*Additional students
gen tempvar = stud if schoolname=="`campus2'"
egen stud_addl = mean(tempvar), by(calendaryear)
replace stud_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist tuition_* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * stud + `i'_addl * stud_addl) / stud_tot if schoolname=="`system'" & calendaryear>2014
	format `i' %9.2f
	
	drop `i'_addl
}

drop stud_*
drop if schoolname=="`campus2'"

///*** Adjust Rutgers ***///

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total students
egen stud_tot = sum(stud) if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
replace stud_tot = . if schoolname!="`system'"

*Additional students
gen tempvar = stud if schoolname=="`campus2'"
egen stud_addl = mean(tempvar), by(calendaryear)
replace stud_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist tuition_* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * stud + `i'_addl * stud_addl) / stud_tot if schoolname=="`system'" & calendaryear<2015
	format `i' %9.2f
	
	drop `i'_addl
}

drop stud_*
drop if schoolname=="`campus2'"

///*** Adjust Mitchell Hamline ***///

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total students
egen stud_tot = sum(stud) if strpos(schoolname,"`system'") & calendaryear>2014, by(calendaryear)
replace stud_tot = . if schoolname!="`system'"

*Additional students
gen tempvar = stud if schoolname=="`campus2'"
egen stud_addl = mean(tempvar), by(calendaryear)
replace stud_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist tuition_* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * stud + `i'_addl * stud_addl) / stud_tot if schoolname=="`system'" & calendaryear>2014
	format `i' %9.2f
	
	drop `i'_addl
}

drop stud_*
drop if schoolname=="`campus2'"

///*** Adjust Rutgers ***///

local system = "Rutgers University"
local campus1 = "Rutgers University-Newark" // Will convert to system
local campus2 = "Rutgers University-Camden" // Will drop after adding

*Combine school names and IDs
replace schoolid = 262900 if schoolname=="`campus1'" // Use post-2014 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total students
egen stud_tot = sum(stud) if strpos(schoolname,"`system'") & calendaryear<2015, by(calendaryear)
replace stud_tot = . if schoolname!="`system'"

*Additional students
gen tempvar = stud if schoolname=="`campus2'"
egen stud_addl = mean(tempvar), by(calendaryear)
replace stud_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist tuition_* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * stud + `i'_addl * stud_addl) / stud_tot if schoolname=="`system'" & calendaryear<2015
	format `i' %9.2f
	
	drop `i'_addl
}

drop stud_*
drop if schoolname=="`campus2'"

///*** Adjust Mitchell Hamline ***///

local system = "Mitchell Hamline School of Law" // Not a state university system, but I use the same local terminology for consistency
local campus1 = "Hamline University" // Will convert to system
local campus2 = "William Mitchell College of Law" // Will drop after adding

*Combine school names and IDs
replace schoolid = 239101 if schoolname=="`campus1'" // Use post-2015 schoolid
replace schoolname = "`system'" if schoolname=="`campus1'"

*Total students
egen stud_tot = sum(stud) if strpos(schoolname,"`system'") & calendaryear<2016, by(calendaryear)
replace stud_tot = . if schoolname!="`system'"

*Additional students
gen tempvar = stud if schoolname=="`campus2'"
egen stud_addl = mean(tempvar), by(calendaryear)
replace stud_addl = . if schoolname!="`system'"
drop tempvar

*Average normalized variables
foreach i of varlist tuition_* {
	gen tempvar = `i' if schoolname=="`campus2'"
	egen `i'_addl = mean(tempvar), by(calendaryear)
	drop tempvar
	
	replace `i' = (`i' * stud + `i'_addl * stud_addl) / stud_tot if schoolname=="`system'" & calendaryear<2016
	format `i' %9.2f
	
	drop `i'_addl
}

drop stud_*
drop if schoolname=="`campus2'"

///*** Outro ***///

drop stud

sort schoolid (calendaryear)
compress

save "expenses.dta", replace

//////////////////////////////////////////
///*** Merge All Analytix Data Sets ***///
//////////////////////////////////////////

///*** Merge ***///

use "admissions.dta", clear

merge 1:1 schoolid calendaryear using "degrees.dta" // All matched
drop _merge

merge 1:1 schoolid calendaryear using "employment.dta" // 14 unmatched in master (none notable)
drop _merge

merge 1:1 schoolid calendaryear using "enrollment.dta" // All matched
drop _merge

merge 1:1 schoolid calendaryear using "faculty.dta" // All matched
drop _merge

merge 1:1 schoolid calendaryear using "financial_aid.dta" // Two unmatched in master (neither notable)
drop _merge

merge 1:1 schoolid calendaryear using "bar_passage.dta" // 610 unmatched (15 only in master; 595 only in using)
list schoolname calendaryear if _merge==1 // My research shows these 15 schools either failed to report or had their ABA accreditation revoked these years
count if _merge==2 & calendaryear<2011 // ABA 509 disclosures have bar passage rates for 393 schools before 2011 but no other information; confirmed with Analytix
list schoolname calendaryear if _merge==2 & calendaryear>2010 & calendaryear<2021 // 6 schools failed to report in 2019-2020 due to pandemic
list schoolname calendaryear if _merge==2 & calendaryear==2021 // 1 school failed to report bar passage in 2021
count if _merge==2 & calendaryear==2022 // 195 schools (of 206 total) have not yet reported their 2022 because the deadline has not yet passed
drop _merge

merge 1:1 schoolid calendaryear using "expenses.dta" // 595 unmatched
tab calendaryear _merge // All non-matches were pre-2011 or in year 2022, so not of concern
drop _merge

merge m:1 schoolid using "information.dta" // All matched
drop _merge

///*** Clean Variables ***///

bysort schoolid (private): replace private = private[1] if missing(private) // Fills in for missing years, which were all pre-2011 and/or post-2021

ren schoolid school_id
la var school_id "School ID"

ren schoolname school
la var school "School name"

ren calendaryear year
la var year "Spring of admissions cycle"

ren numapps apps
la var apps "# applications (official)"

ren numoffers offers
la var offers "# offers (official)"

ren nummatriculants matrics
la var matrics "# matriculants (official)"

forval i = 25(25)75 {
	foreach j in gpa lsat {
		la var `j'`i' "`i'th pctile of all apps (official)"
	}
}

la var accr "Acceptance rate (official)"
la var accrl "Lagged acceptance rate (official)"
la var yield "Yield (official)"

la var jds_urm "% degrees earners URM"

la var empr "% FT long-term employment"

la var stud_urm "% URM students"
la var stud_men "% male students"
la var stud_wom "% female students"

la var fac_men "% male faculty"
la var fac_wom "% female faculty"
la var fac_urm "% URM faculty"

la var merit_aid "=1 if school offers conditional scholarships"
la var stud_aid "% students with any aid"
la var stud_aid_0to50 "% students with 0-50% aid"
la var stud_aid_50to100 "% students with 50-100% aid"
la var stud_aid_100toX "% students with 100%+ aid"

la var bar_pass_school "School 1st-attempt bar pass rate"
la var bar_pass_state "State mean 1st-attempt bar pass rate"
la var bar_pass_diff "Pct points above/below state mean"

la var private "=1 if private school"
la var city "City"
la var state "State"
la var zip "ZIP code"
la var tuition_instate "In-state FT tuition (nominal USD)"
la var tuition_outstate "Out-of-state FT tuition (nominal USD)"

///*** Prep School Variable for LSD.law Merge ***///

replace school = stritrim(strtrim(ustrregexra(upper(school),"[^A-Za-z\s]"," ")))
replace school = subinstr(school," S ","S ",.) // For apostrophes
la var school "School name (Analytix)"

///*** Outro ***///

sort school_id (year)
compress

save "analytix_data.dta", replace

foreach i in "admissions.dta" "bar_passage.dta" "degrees.dta" "employment.dta" "enrollment.dta" "expenses.dta" "faculty.dta" "financial_aid.dta" "information.dta" {
	erase `i'
}

/////////////////////////////////
///*** USNWR Rankings Data ***///
/////////////////////////////////

///*** Intro ***///

import delim "School Rankings.csv", clear

///*** Cleanup ***///

drop rank yearavg v4 v5
drop if missing(school)

foreach i of varlist v* {
    local lbl : var label `i'
    local lbl = strtoname("y`lbl'")
    rename `i' `lbl'
}

order school *, alpha

list if missing(real(y2019))
replace y2019 = "65" if school=="Pepperdine" // Included asterisk in original
destring y2019, replace

///*** Prepare School Names for Merge ***///

replace school = stritrim(strtrim(ustrregexra(upper(school),"[^A-Za-z\s]"," ")))
replace school = upper(school)

replace school = "DENVER" if school=="SAN DIEGO" & y2023==78 // Coding error confirmed by author of data source

/*Some of these school names were unclear, so I cross-checked with rankings for this year.*/

replace school = school + " " + "UNIVERSITY" if school=="YALE" | school=="STANFORD" | school=="HARVARD" | school=="COLUMBIA" | school=="DUKE" | school=="NORTHWESTERN" | school=="CORNELL" | school=="GEORGETOWN" | school=="VANDERBILT" | school=="EMORY" | school=="OHIO STATE" | school=="FORDHAM" | school=="WAKE FOREST" | school=="TULANE" | school=="TEMPLE" | school=="PEPPERDINE" | school=="VILLANOVA" | school=="AMERICAN" | school=="NORTHEASTERN" | school=="RUTGERS" | school=="MICHIGAN STATE" | school=="SYRACUSE" | school=="MARQUETTE" | school=="WEST VIRGINIA" | school=="GEORGE MASON" | school=="BAYLOR" | school=="SETON HALL" | school=="WAYNE STATE" | school=="TEXAS A M"

replace school = "UNIVERSITY OF" + " " + school if school=="CHICAGO" | school=="PENNSYLVANIA" | school=="VIRGINIA" | school=="MICHIGAN" | school=="ALABAMA" | school=="IOWA" | school=="MINNESOTA" | school=="NOTRE DAME" | school=="GEORGIA" | school=="WISCONSIN" | school=="FLORIDA" | school=="ILLINOIS" | school=="MARYLAND" | school=="UTAH" | school=="COLORADO" | school=="ARIZONA" | school=="CONNECTICUT" | school=="HOUSTON" | school=="TENNESSEE" | school=="KENTUCKY" | school=="MISSOURI" | school=="MIAMI" | school=="CINCINNATI" | school=="SAN DIEGO" | school=="PITTSBURGH" | school=="NEW MEXICO" | school=="OREGON" | school=="KANSAS" | school=="OKLAHOMA" | school=="NEBRASKA" | school=="LOUISVILLE" | school=="TULSA" | school=="HAWAII" | school=="NEW HAMPSHIRE" | school=="SOUTH CAROLINA" | school=="DENVER"

foreach i in "BERKELEY" "IRVINE" "DAVIS" "HASTINGS" {
	replace school = "UNIVERSITY OF CALIFORNIA" + " " + "`i'" if strpos(school, "`i'")
}

replace school = "NEW YORK UNIVERSITY" if school=="NYU"
replace school = "UNIVERSITY OF CALIFORNIA LOS ANGELES" if school=="UCLA"
replace school = "UNIVERSITY OF SOUTHERN CALIFORNIA" if school=="USC"
replace school = "GEORGE WASHINGTON UNIVERSITY" if school=="GW"
replace school = "WASHINGTON UNIVERSITY" if school=="WASH"
replace school = "UNIVERSITY OF TEXAS AT AUSTIN" if school=="TEXAS"
replace school = "BRIGHAM YOUNG UNIVERSITY" if school=="BYU"
replace school = "SOUTHERN METHODIST UNIVERSITY" if school=="SMU"
replace school = "CARDOZO SCHOOL OF LAW" if school=="CARDOZO"
replace school = "CHICAGO KENT COLLEGE OF LAW IIT" if school=="CHICAGO KENT"
replace school = "UNIVERSITY OF ARKANSAS FAYETTEVILLE" if school=="ARKANSAS FAY"
replace school = "UNIVERSITY OF NEVADA LAS VEGAS" if school=="UNLV"
replace school = "LOYOLA UNIVERSITY CHICAGO" if school=="LOYOLA CHICAGO"
replace school = "WILLIAM AND MARY LAW SCHOOL" if school=="WILLIAM AND MARY"
replace school = "LOYOLA MARYMOUNT UNIVERSITY LOS ANGELES" if school=="LOYOLA L A"
replace school = "ST JOHNS UNIVERSITY" if school=="ST JOHN S"
replace school = "BROOKLYN LAW SCHOOL" if school=="BROOKLYN"
replace school = "LOUISIANA STATE UNIVERSITY" if school=="LSU"
replace school = "UNIVERSITY OF BUFFALO SUNY" if school=="BUFFALO SUNY"
replace school = "INDIANA UNIVERSITY INDIANAPOLIS" if school=="INDIANA IND"
replace school = "CASE WESTERN RESERVE UNIVERSITY" if school=="CASE WESTERN"
replace school = "CATHOLIC UNIVERSITY OF AMERICA" if school=="CATHOLIC"
replace school = "INDIANA UNIVERSITY BLOOMINGTON" if school=="INDIANA UNIVERSITY BLOOMINGDALE"
replace school = "LEWIS AND CLARK COLLEGE" if school=="LEWIS CLARK"
replace school = "SAINT LOUIS UNIVERSITY" if school=="ST LOUIS UNIVERSITY"
replace school = "WASHINGTON AND LEE UNIVERSITY" if school=="WASHINGTON LEE"

///*** Reshape ***///

reshape long y, i(school) j(year)

ren y rank
la var rank "USNWR Ranking"
la var school ""

///*** Adjust Penn State ***///

egen temp = mean(rank) if school=="PENN STATE UNIVERSITY COLLEGE PARK" | school=="PENN STATE UNIVERSITY DICK", by(year) // Ideally, this should have been a weighted average by student population, I think, but we were on a time crunch and the imapct should be minimal
drop if school=="PENN STATE UNIVERSITY DICK"
replace school = "PENNSYLVANIA STATE UNIVERSITY" if school=="PENN STATE UNIVERSITY COLLEGE PARK"
replace rank = temp if school=="PENNSYLVANIA STATE UNIVERSITY"
drop temp

///*** Generate Tiers ***///

tabstat year, by(year) s(count)

sort year (rank)

ssc install egenmore
egen tier = xtile(rank), by(year) n(4)
replace tier = abs(tier - 6) // Makes 5 highest level, so regression coefficients are more-easily interpreted
la var tier "Tier (of 5) based on USNWR rankings" // Note I later define unranked law schools as the fifth group

///*** Outro ***///

sort school (year)
compress
save "school_rankings.dta", replace

///////////////////////////////////////////
///*** Merge Analytix and USNWR Data ***///
///////////////////////////////////////////

use "analytix_data.dta", clear

merge 1:1 school year using "school_rankings.dta" // All in using matched, as expected; 1.3k unmatched in master because rankings only available 2009-present

drop _merge

save "analytix_data.dta", replace

////////////////////////////
///*** Merge All Data ***///
////////////////////////////

use "gbus_401_project_master.dta", clear

///*** Prep School Variable for Merge ***///

*Clean Penn State, Rutgers, and Mitchell Hamline
replace school = "PENNSYLVANIA STATE UNIVERSITY" if school=="PENNSYLVANIA STATE DICKINSON LAW" | school=="PENNSYLVANIA STATE PENN STATE LAW"
replace school = "RUTGERS UNIVERSITY" if school=="RUTGERS STATE UNIVERSITY CAMDEN OLD" | school=="RUTGERS STATE UNIVERSITY NEWARK OLD" | school=="RUTGERS UNIVERSITY MERGED"
replace school = "MITCHELL HAMLINE SCHOOL OF LAW" if school=="WILLIAM MITCHELL COLLEGE OF LAW"

*Remove name inconsistencies
replace school = "CITY UNIVERSITY OF NEW YORK" if school=="CUNY"
replace school = "CHICAGO KENT COLLEGE OF LAW IIT" if school=="ILLINOIS INSTITUTE OF TECHNOLOGY KENT"
replace school = "INTER AMERICAN UNIVERSITY OF PUERTO RICO" if school=="INTER AMERICAN UNIVERSITY SCHOOL OF LAW"
replace school = "ATLANTAS JOHN MARSHALL LAW SCHOOL" if school=="JOHN MARSHALL LAW SCHOOL"
replace school = "FAULKNER UNIVERSITY" if school=="JONES SCHOOL OF LAW"
replace school = "MITCHELL HAMLINE SCHOOL OF LAW" if school=="MITCHELL HAMLINE"
replace school = "ARIZONA SUMMIT LAW SCHOOL" if school=="PHOENIX SCHOOL OF LAW" // Name changed in 2014
replace school = "PONTIFICAL CATHOLIC UNIVERSITY OF P R" if school=="PONTIFICAL CATHOLIC UNIVERSITY"
replace school = "SOUTH TEXAS COLLEGE OF LAW" if school=="SOUTH TEXAS COLLEGE OF LAW HOUSTON"
replace school = "UNIVERSITY OF COLORADO" if school=="UNIVERSITY OF COLORADO BOULDER"
replace school = "UNIVERSITY OF FLORIDA" if school=="UNIVERSITY OF FLORIDA LEVIN"
replace school = "UNIVERSITY OF ILLINOIS CHICAGO SCHOOL OF LAW" if school=="UNIVERSITY OF ILLINOIS CHICAGO"
replace school = "UNIVERSITY OF ILLINOIS" if school=="UNIVERSITY OF ILLINOIS URBANA CHAMPAIGN"
replace school = "UNIVERSITY OF LA VERNE" if school=="UNIVERSITY OF LA VERNE COLLEGE OF LAW"
replace school = "UNT DALLAS COLLEGE OF LAW" if school=="UNIVERSITY OF NORTH TEXAS AT DALLAS"
replace school = "DISTRICT OF COLUMBIA" if school=="UNIVERSITY OF THE DISTRICT OF COLUMBIA"
replace school = "MCGEORGE SCHOOL OF LAW" if school=="UNIVERSITY OF THE PACIFIC MCGEORGE"
replace school = "WASHINGTON UNIVERSITY" if school=="WASHINGTON UNIVERSITY IN ST LOUIS"
replace school = "WESTERN MICHIGAN UNIVERSITY" if school=="WESTERN MICHIGAN UNIVERSITY COOLEY"
replace school = "WIDENER COMMONWEALTH" if school=="WIDENER UNIVERSITY PENNSYLVANIA COMMONWEALTH"
replace school = "WILLIAM AND MARY LAW SCHOOL" if school=="WILLIAM MARY LAW SCHOOL"
replace school = "CARDOZO SCHOOL OF LAW" if school=="YESHIVA UNIVERSITY CARDOZO"

///*** Merge ***///

merge m:1 school year using "analytix_data.dta"

*Analysis
tab _merge if _merge==1 & year>2010 & year<2022 // 36 applications total unmatched in master; all were not ABA-accredited or failed to report to ABA that year
tab _merge if _merge==2 & year>2010 & year<2022 // 60 school-year observations total unmatched in using; all are small schools, so not surprised to see
tab _merge if _merge!=3 & year<2011 // ~140k applications unmatched here; as expected since most data are unavailable pre-2011
tab _merge if _merge!=3 & year>2021 // ~32k applications from current admissions cycle unmatched, as expected

drop if _merge==2 // Law schools without any corresponding applications
drop _merge

///*** Cleanup ***///

la var school "School name"

sort school school_id year
bysort school (school_id): replace school_id = school_id[1]
count if missing(school_id) // Nashville Law School lacks an ID because it is not ABA-accredited; I add a fake school_id for consistency
replace school_id = 123456 if school=="NASHVILLE SCHOOL OF LAW"

replace tier = 5 if missing(tier) & year>2008 // I put all unranked law schools in tier 5

///*** Outro ***///

sort school (year)
compress

save "gbus_401_project_master.dta", replace

erase "analytix_data.dta"

////////////////////////////////////////
///*** Constructing New Variables ***///
////////////////////////////////////////

use "gbus_401_project_master.dta", clear

///*** Admit Indicators ***///

gen admit = 1 if result==1
replace admit = 0 if result==0 // Exclude ~118k waitlisted and ~179k other/unknown
la var admit "=1 if admitted (result)"

gen admit2 = 1 if status==1
replace admit2 = 0 if status==0 // Exclude ~115k waitlisted and 182k other/unknown
la var admit2 "=1 if admitted (status)"

drop if missing(admit)

///*** T14 Indicator ***///

gen t14 = 0
replace t14 = 1 if school=="CCOLUMBIA UNIVERSITY" | school=="CORNELL UNIVERSITY" | school=="DUKE UNIVERSITY" | school=="GEORGETOWN UNIVERSITY" | school=="HAVARD UNIVERSITY" | school=="NEW YORK UNIVERSITY" | school=="NORTHWESTERN UNIVERSITY" | school=="STANFORD UNIVERSITY" | school=="UNIVERSITY OF CALIFORNIA-BERKELEY"| school=="UNIVERSITY OF CHICAGO" | school=="UNIVERSITY OF MICHIGAN" | school=="UNIVERSITY OF PENNSYLVANIA" | school=="UNIVERSITY OF VIRGINIA" | school=="YALE UNIVERSITY"
la var t14 "=1 if T14 law school" //traditional list of T-14 schools according to https://7sage.com/top-law-school-rankings/

///*** Alternative Acceptance Rate ***///

gen one = 1

egen apps2 = sum(one), by(school_id year)
la var apps2 "# applications (LSD.law)"

egen offers2 = sum(admit), by(school_id year)
la var offers2 "# offers (LSD.law)"

gen accr2 = offers2 / apps2
la var accr2 "Acceptance rate (LSD.law)"
format accr2 %9.2f

drop one

///*** GPA Ranges ***///

foreach i in "gpa" {
	*local j = upper("`i'")
	di "`=upper("`i'")'"
	*di "`j'"
	
}

foreach i in "gpa" "lsat" {
	local j = "`=upper("`i'")'"
	
	gen `i'_0to25 = 0
	replace `i'_0to25 = 1 if `i'<=`i'25
	la var `i'_0to25 "=1 if `j' in 0-25th pctile"

	gen `i'_25to50 = 0
	replace `i'_25to50 = 1 if `i'>`i'25 & `i'<=`i'50
	la var `i'_25to50 "=1 if `j' in 25-50th pctile"

	gen `i'_50to75 = 0
	replace `i'_50to75 = 1 if `i'>`i'50 & `i'<=`i'75
	la var `i'_50to75 "=1 if `j' in 50-75th pctile"

	gen `i'_75to100 = 0
	replace `i'_75to100 = 1 if `i'>`i'75
	la var `i'_75to100 "=1 if `j' in 75-100th pctile"
}

///*** Outro ***///

compress
sort year school user_id

save "${path}/Data_Final/gbus_401_project_master.dta", replace

cd "${path}/Data_Intermediate"
erase "school_rankings.dta"
erase "gbus_401_project_master.dta"
