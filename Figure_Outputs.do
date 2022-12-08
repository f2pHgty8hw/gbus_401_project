///////////////////////////////////////////////////////////
///*** GBUS 401 Final Project: Figure Outputs Script ***///
///////////////////////////////////////////////////////////

*Name: Noah Blake Smith
*Last updated: December 5, 2022

global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project"
cd "${path}"

use "${path}/gbus_401_project/Data_Final/gbus_401_project_master.dta", clear

net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
set scheme cleanplots, perm

////////////////////////////////
///*** Consistency Checks ***///
////////////////////////////////

///*** Applicants (LSD.law) ***///

preserve

duplicates tag user_id, gen(apps_per_person)
la var apps_per_person "Applications submitted per user"
replace apps_per_person = apps_per_person + 1 // Note line above marks unique observations as 0
duplicates drop user_id, force

*Pooled Histogram
hist apps_per_person if apps_per_person<30, normal bin(29) title("Applications per LSD.law User, Pooled 2004–2023")
graph export "${path}/gbus_401_project/Outputs/apps_per_user_histogram1.png", as(png) name("Graph") replace

*Histogram by Year
hist apps_per_person if apps_per_person<30 & year>2014, normal bin(29) by(year, title("Applications per LSD.law User, 2015–2023") legend(off))
graph export "${path}/gbus_401_project/Outputs/apps_per_user_histogram2.png", as(png) name("Graph") replace

restore

///*** Applicants (Analytix) ***///

preserve

duplicates tag school_id, gen(apps_per_person)
la var apps_per_person "Applications submitted per user"
replace apps_per_person = apps_per_person + 1 // Note line above marks unique observations as 0
duplicates drop user_id, force


///*** LSAT ***///

// Note mean is consistently above national average. How should we therefore interpret our results?

*Pooled Histogram
hist lsat, normal bin(61) title("Self-Reported LSAT, LSD.law, Pooled 2004–2023")
graph export "${path}/gbus_401_project/Outputs/lsat_histogram1.png", as(png) name("Graph") replace

*Histogram by Year
hist lsat if year>2014, normal bin(61) by(year, title("Self-Reported LSAT, LSD.law, 2015–2023") legend(off))
graph export "${path}/gbus_401_project/Outputs/lsat_histogram2.png", as(png) name("Graph") replace

///*** GPA ***///

// Note the rounding at 0.05, which suggests lying/dishonesty.

*Pooled Histogram
hist gpa if gpa>2.9 & gpa<4.1, bin(119) xtick(2.9(0.05)4.1) xlabel(2.95(0.2)4.05) title("Self-Reported GPA, LSD.law, Pooled 2004–2023")
graph export "${path}/gbus_401_project/Outputs/gpa_histogram.png", as(png) name("Graph") replace
