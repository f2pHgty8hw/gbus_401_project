///////////////////////////////////////////////////////////////////////
///*** GBUS 401 Final Project: Sample Representativeness Testing ***///
///////////////////////////////////////////////////////////////////////


*Name: Noah Blake Smith

*Last Updated: December 6, 2022

clear all

use "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project/Data_Final/gbus_401_project_master.dta", clear

count if missing(school_id) // None found
count if missing(user_id) // None found

//////////////////////////////////////
///*** School-Year Observations ***///
//////////////////////////////////////

collapse (mean) lsat gpa years_out (firstnm) school apps* offers* matrics* accr yield merit_aid-stud_aid_100toX t14 accr2 gpa75-lsat25 (sum) fee_waived got_merit_aid attend urm admit* gpa_* lsat_* (count) user_id, by(school_id year)

gen id = _n

///*** Acceptance Rates ***///

preserve

sort school_id (year)
order school_id school year accr apps apps2 offers offers *

drop if missing(accr) | missing(accr2)

gen z_accr = .
la var z "Z-score of one-sample test of proportion"
gen p_accr = .
la var p_accr "p-value of one-sample test of proportion"

des

forval i = 1/`r(N)' {

	di `i'
	
	local n = apps2[`i']
	local a = offers2[`i']
	local accr = accr[`i']
	
	cap prtesti `n' `a' `accr', count // Test
	cap replace z_accr = `r(z)' if z==z[`i']
	cap replace p_accr = `r(p)' if p==p[`i']

}

restore

///*** GPA and LSAT ***///

preserve

foreach i of varlist gpa25 gpa50 gpa75 {
	di "`i'"
	drop if missing(`i')
}

foreach j in "gpa" "lsat" {
	
	forval k = 0(25)75 {
		
		local l = `k' + 25
		
		gen z_`j'_`k'to`l' = .
		gen p_`j'_`k'to`l' = .
		
		des
		forval i = 1/`r(N)' {
			
			local score = `j'_`k'to`l'[`i']
			local n = apps2[`i']
			
			di `i'
			di `n'
			di `score'
			di `l'
			cap prtesti `n' `score' 0.25, count
			cap replace z_`j'_`k'to`l' = `r(z)' if z_`j'_`k'to`l'==z_`j'_`k'to`l'[`i']
			cap replace p_`j'_`k'to`l' = `r(p)' if p_`j'_`k'to`l'==p_`j'_`k'to`l'[`i']
		
		}
		
	}

}

restore

////////////////////////////////////////
///*** Pooled School Observations ***///
////////////////////////////////////////

/*

clear all

use "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project/Data_Final/gbus_401_project_master.dta", clear

sort school_id (year)
order school_id school year accr apps apps2 offers offers *

collapse (mean) lsat gpa years_out (firstnm) school apps* offers* matrics* accr yield merit_aid-stud_aid_100toX t14 accr2 gpa75-lsat25 (sum) fee_waived got_merit_aid attend urm admit* gpa_* lsat_* (count) user_id, by(school_id)

gen id = _n

///*** Acceptance Rate ***///

preserve

drop if missing(accr) | missing(accr2)

gen z_accr = .
la var z "Z-score of one-sample test of proportion"
gen p_accr = .
la var p_accr "p-value of one-sample test of proportion"

des

forval i = 1/`r(N)' {

	di `i'
	
	local n = apps2[`i']
	local a = offers2[`i']
	local accr = accr[`i']
	
	cap prtesti `n' `a' `accr', count // Test
	cap replace z_accr = `r(z)' if z==z[`i']
	cap replace p_accr = `r(p)' if p==p[`i']

}

restore

///*** GPA and LSAT ***///

preserve

foreach i of varlist gpa25 gpa50 gpa75 {
	di "`i'"
	drop if missing(`i')
}

foreach j in "gpa" "lsat" {
	
	forval k = 0(25)75 {
		
		local l = `k' + 25
		
		gen z_`j'_`k'to`l' = .
		gen p_`j'_`k'to`l' = .
		
		des
		forval i = 1/`r(N)' {
			
			local score = `j'_`k'to`l'[`i']
			local n = apps2[`i']
			
			di `i'
			di `n'
			di `score'
			di `l'
			cap prtesti `n' `score' 0.25, count
			cap replace z_`j'_`k'to`l' = `r(z)' if z_`j'_`k'to`l'==z_`j'_`k'to`l'[`i']
			cap replace p_`j'_`k'to`l' = `r(p)' if p_`j'_`k'to`l'==p_`j'_`k'to`l'[`i']
		
		}
		
	}

}

restore
