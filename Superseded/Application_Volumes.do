/////////////////////////////////
///*** Application Volumes ***///
/////////////////////////////////

*Name: Noah Blake Smith
*Last Updated: December 7, 2022

/*Source: https://report.lsac.org/View.aspx?Report=FiveYearComparison.*/

clear all

set obs 4

gen year = _n + 2018
la var year "Year"

///*** Analytix Data ***///

gen applicants_aba = .

replace applicants_aba = 62176 if year==2019
replace applicants_aba = 63128 if year==2020
replace applicants_aba = 70978 if year==2021
replace applicants_aba = 62578 if year==2022

gen applications_aba = .

replace applications_aba = 380256 if year==2019
replace applications_aba = 381462 if year==2020
replace applications_aba = 481125 if year==2021
replace applications_aba = 430354 if year==2022

///*** LSD.law Data ***///

gen applicants_lsd = .

replace applicants_lsd = 4617 if year==2019
replace applicants_lsd = 6197 if year==2020
replace applicants_lsd = 8843 if year==2021
replace applicants_lsd = 6805 if year==2022

gen applications_lsd = .

replace applications_lsd = 37698 if year==2019
replace applications_lsd = 49763 if year==2020
replace applications_lsd = 75282 if year==2021
replace applications_lsd = 67482 if year==2022

///*** Graph and Analyze ***///

tsset year
tsline applications_* applicants_*

gen applications_share = (applications_lsd / applications_aba) * 100
la var applications_share "Applications"

gen applicants_share = (applicants_lsd / applicants_aba) * 100
la var applicants_share "Applicants"

tsline *_share, ytitle("% of Total Pool") title("LSD.law Share of Total Applicant Pool Increases over Time") legend(pos(6))

graph export "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project/Outputs/app_share.png", as(png) name("Graph") replace
