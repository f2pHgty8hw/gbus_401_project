///////////////////////////////////////////////////////
///*** GBUS 401 Project: Linear Regression Model ***///
///////////////////////////////////////////////////////

*Name: Noah Blake Smith
*Last updated: December 13, 2022

/////////////////////////////////
///*** Estimate All Models ***///
/////////////////////////////////

mat drop _all
clear all

global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project"
cd "${path}/Data_Final" // User must specify appropriate paths

use "gbus_401_project_master.dta", clear

keep if year>2011 // Only years all features are non-missing

ssc install tuples
tuples gpa "gpa_*" lsat "lsat_*" urm fee_waived accrl, nopython
macro list

forval i = 1/`ntuples' {

	di `i'

	forval j = 2012/2021 {
		
		gen split = 0
		replace split = 1 if year>`j'

		qui reg admit `tuple`i'' i.year i.school_id if split==0

		qui predict yhat_`i'_split_`j' if split==1, xb
		
		local label = strtoname("`tuple`i''")
		la var yhat_`i'_split_`j' "`tuple`i''"
		
		qui drop split
		
	}
}

save "ols_predictions.dta", replace

//////////////////////////////////////
///*** Cross-Validation Metrics ***///
//////////////////////////////////////

mat drop _all
clear all

use "ols_predictions.dta", clear

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
	qui replace mse = - mse
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

use "yhat_1_split_2012.dta", clear
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

ren cv_metricsc1 mse
la var mse "Mean squared error"

ren cv_metricsc2 r2
la var r2 "R-squared"

ren cv_metricsc3 mae
la var mae "Mean absolute error"

ren cv_metricsc4 accuracy
la var accuracy "Accuracy"

ren cv_metricsc5 log_loss
la var log_loss "Log loss (cross entropy)"

order model_no split *

sort model_no (split)

*Check
gen one = 1
tabstat one, by(model_no) s(sum count) // 19 observations for each model
drop one

compress

save "${path}/Data_Final/ols_cv_metrics.dta", replace





//////////////////////////////
///*** Model Comparison ***///
//////////////////////////////


// This is just me messing around. There are some good graphs here you might consider adding.

use "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project/Data_Final/ols_cv_metrics.dta", clear




use "${path}/Data_Final/lr_cv_metrics.dta", clear

*Model no. labels

gen temp = model_no

forval i = 1/127 {
	if (mod(`i', 20)) {
		la def temp_lbl `i' `"{c 0xa0}"', add 
	}
}

la val temp temp_lbl





///*** Negative MSE ***///

graph box mse, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1a: Negative Mean Squared Error across OLS Models}") b1title("Model no.") ytitle("Negative MSE")



graph export "fig_41a.png", as(png) name("Graph") replace



egen mse_sd = sd(mse), by(model_no)
sort mse_sd
scatter mse_sd model_no







///*** R^2 ***///


graph box r2 if model_no>20 & model_no<45, over(model_no) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1b: R-squared across OLS Models}") b1title("Model no.") ytitle("R-squared")


graph box r2 if (model_no>25 & model_no<32) | model_no==38 | model_no==40, over(split) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1b: R-squared across OLS Models}") b1title("Model no.") ytitle("R-squared")


sepscatter r2 split if (model_no>25 & model_no<32) | model_no==38 | model_no==40, separate(model_no) xsize(10)

tsset model_no split, yearly

tsline r2 if model_no==26 || tsline r2 if model_no==27 || tsline r2 if model_no==28 || tsline r2 if model_no==29 || tsline r2 if model_no==30 || tsline r2 if model_no==31 || tsline r2 if model_no==38 || tsline r2 if model_no==40, legend(cols(8) position(6) label(1 "26") label(2 "27") label(3 "28") label(4 "29") label(5 "30") label(6 "31") label(7 "38") label(8 "40") title("Model no.", size(small))) yscale(range(0.1 0.3)) ylabel(0.1(0.05)0.3) xscale(range(2004 2022)) xlabel(2005 2010 2015 2020) xmtick(2004(1)2022) title("{bf:Time Series of R-squared for Selected OLS Models}")



///*** Negative MAE ***///

graph box mae, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1c: Negative Mean Absolute Error across OLS Models}") b1title("Model no.") ytitle("Negative MAE")

graph export "fig_41c.png", as(png) name("Graph") replace

///*** Accuracy ***///

graph box accuracy if model_no>30, over(model_no) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1d: Accuracy across OLS Models}") b1title("Model no.") ytitle("Accuracy")

sepscatter accuracy model_no, separate(split) legend(on) xlabel(0(10)130) mc(gs0 gs1 gs2 gs3 gs4 gs4 gs6 gs7 gs8 gs9 gs10 gs11 gs12 gs13 gs14 gs15 gs16 green red) ms(o o o o o o o o o o o o o o o o o o o o) xsize(15)

scatter accuracy model_no if split==2004, color(gs0) ms(o) msize(small)

graph export "fig_41d.png", as(png) name("Graph") replace

///*** Negative Log Loss ***///

graph box accuracy, over(temp) xsize(11) ysize(5) box(1, color(black)) marker(1, mcolor(black)) title("{bf:Figure 4.1e: Negative Log Loss across OLS Models}") b1title("Model no.") ytitle("Negative log loss")

graph export "fig_41e.png", as(png) name("Graph") replace

*Outro
drop temp
la drop temp_lbl



