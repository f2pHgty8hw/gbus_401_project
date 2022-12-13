///////////////////////////////////////////////////////
///*** GBUS 401 Project: Linear Regression Model ***///
///////////////////////////////////////////////////////

*Name: Noah Blake Smith
*Last updated: December 12, 2022

/////////////////////////////////
///*** Estimate All Models ***///
/////////////////////////////////

mat drop _all
clear all

global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project"
cd "${path}/Data_Final" // User must specify appropriate paths

use "gbus_401_project_master.dta", clear

ssc install tuples
tuples gpa lsat urm fee_waived non_trad intl, nopython varlist
macro list

forval i = 1/`ntuples' {

	di `i'

	forval j = 2004/2022 {
		
		gen split = 0
		replace split = 1 if year>`j'
		
		qui reg admit `tuple`i'' i.year i.school_id if split==0

		qui predict yhat_`i'_split_`j' if split==1, xb
		
		local label = strtoname("`tuple`i''")
		la var yhat_`i'_split_`j' "`tuple`i''"
		
		qui drop split
		
	}
}

save "lr_predictions.dta", replace

//////////////////////////////////////
///*** Cross-Validation Metrics ***///
//////////////////////////////////////

mat drop _all
clear all

use "lr_predictions.dta", clear

mkdir "${path}/Data_Final/LR"
cd "${path}/Data_Final/LR"

keep admit yhat_*_split_*
compress

save "master.dta", replace

foreach i of varlist yhat_*_split_* {

	use "master.dta", clear

	di "`i'"

	///*** Mean Squared Error ***///
	
	qui egen mse = mean((admit - `i')^2) if missing(`i')==0
	qui sum mse if missing(`i')==0
	local mse = r(mean)
	
	drop mse
	
	///*** R^2 ***///
	
	qui egen madmit = mean(admit) if missing(`i')==0
	qui egen ssr = sum((admit - `i')^2) if missing(`i')==0
	qui egen sst = sum((admit - madmit)^2) if missing(`i')==0
	qui gen r2 = 1 - (ssr / sst) if missing(`i')==0
	qui sum r2 if missing(`i')==0

	local r2 = r(mean)
	
	qui drop madmit ssr sst r2
	
	///*** Mean Absolute Error ***///
	
	qui gen mae = abs(`i' - admit)
	qui sum mae
	
	local mae = -r(mean)
	
	qui drop mae
	
	///*** Accuracy ***///
	
	qui gen prediction_category = 0 if missing(`i')==0
	qui replace prediction_category = 1 if `i'>=0.5 & missing(`i')==0
	qui la var prediction_category "=1 if predict acceptenace"
	
	qui gen accuracy = 0 if missing(`i')==0
	qui replace accuracy = 1 if admit==1 & prediction_category==1 & missing(`i')==0
	qui replace accuracy = 1 if admit==0 & prediction_category==0 & missing(`i')==0
	qui la var accuracy "=1 if prediction correct"
	
	qui sum accuracy if missing(`i')==0
	
	local accuracy = r(mean)
	
	qui drop prediction accuracy
	
	///*** Log Loss ***///
	
	*Bottom censor at zero
	qui gen `i'_recode = `i' if missing(`i')==0
	qui replace `i'_recode = 0 if `i'_recode<0 & missing(`i')==0
	qui sum `i'_recode if missing(`i')==0
	
	qui replace `i'_recode = r(min) if `i'_recode==0 & missing(`i')==0
	
	*Top censor at one
	qui replace `i'_recode = 1 if `i'_recode>1 & missing(`i')==0
	qui sum `i'_recode if missing(`i')==0
	
	qui replace `i'_recode = r(max) if `i'_recode==0 & missing(`i')==0
	
	*Calculate
	qui gen log_loss = -(admit * ln(`i'_recode) + (1 - admit) * ln(1 - `i'_recode)) if missing(`i')==0
	qui sum log_loss if missing(`i')==0
	
	local log_loss = r(mean)
	
	qui drop `i'_recode log_loss
	
	///*** Save Results ***///
	
	mat cv_metrics = [`mse', `r2', `mae', `accuracy', `log_loss']
	
	svmat cv_metrics, names(matcol)
	
	qui mat drop cv_metrics
	qui keep cv_*
	qui drop if missing(cv_metricsc1)
	
	qui gen model = "`i'"
	qui order model *
	
	save "`i'.dta", replace

}

//////////////////////////////
///*** Clean and Append ***///
//////////////////////////////

use "yhat_1_split_2004.dta", clear
local filelist: dir . files "*2*.dta"

foreach i in `filelist' {
	
	append using `i'
	
}

split model, p(_)
drop model1 model3

destring model2, replace
ren model2 model_no
la var model_no "Model no."

drop model

destring model4, replace
ren model4 split
la var split "Year of CV split"

duplicates drop model_no split, force // Model 1 for 2004 was duplicated because it was appended to itself

ren cv_metricsc1 r2
la var r2 "R-squared"

ren cv_metricsc2 mae
la var mae "Mean absolute error"

ren cv_metricsc3 accuracy
la var accuracy "Accuracy"

ren cv_metricsc4 log_loss
la var log_loss "Log loss (cross entropy)"

order model_no split *

sort model_no (split)

*Check
gen one = 1
tabstat one, by(model_no) s(sum count) // 19 observations for each model
drop one

compress

save "${path}/Data_Final/lr_cv_metrics.dta", replace
