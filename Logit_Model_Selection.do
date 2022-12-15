///////////////////////////////////////////
///*** GBUS 401 Project: Logit Model ***///
///////////////////////////////////////////

*Name: Noah Blake Smith
*Last updated: December 13, 2022

mat drop _all
clear all

//global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/GBUS 401/1 Project/gbus_401_project"
global path "/Users/justinpotisit/Documents/GitHub/gbus_401_project"
cd "${path}/Data_Final" // User must specify appropriate paths

use "gbus_401_project_master.dta", clear

keep if year>2011 // Only years all features are non-missing

compress
save "${path}/Data_Final/logit_master.dta", replace

mkdir "${path}/Data_Final/Logit"
cd "${path}/Data_Final/Logit"

ssc install tuples
tuples gpa "gpa_*" lsat "lsat_*" urm fee_waived accrl, nopython
macro list

forval i = 1/`ntuples' {

	di `i'

	forval j = 2012/2021 {
		
		use "${path}/Data_Final/logit_master.dta", clear
		
		gen split = 0
		replace split = 1 if year>`j'

		cap qui logit admit `tuple`i'' i.year i.tier if split==0, difficult technique(nr 10 bhhh 1000)
		
		///*** Goodness-of-Fit Test ***///
		
		cap qui estat gof if split==1, outsample
		cap local gof = r(p)
		
		///*** Accuracy ***///
		
		cap qui estat classification if split==1
		cap local accuracy = r(P_corr)
		
		///*** Log Loss ***///
		
		cap qui predict yhat_`i'_split_`j' if split==1, pr
		cap local label = strtoname("`tuple`i''")
		cap la var yhat_`i'_split_`j' "`tuple`i''"
		
		cap qui gen log_loss = -(admit * ln(yhat_`i'_split_`j') + (1 - admit) * ln(1 - yhat_`i'_split_`j')) if split==1
		cap qui sum log_loss if split==1
		cap local log_loss = r(mean)
	
		cap qui drop yhat_`i'_split_`j' log_loss
		
		///*** Save Results ***///
		
		cap qui mat cv_metrics = [`j', `gof', `accuracy', `log_loss']
		cap qui svmat cv_metrics, names(matcol)
	
		cap qui mat drop cv_metrics
		cap qui keep cv_*
		cap qui drop if missing(cv_metricsc1)
	
		cap qui gen model = "`i'"
		cap qui order model *
	
		cap save "yhat_`i'_split_`j'_logit.dta", replace
		
	}
}

///*** Combine and Cleanup ***///

cd "/Users/nbs/Desktop/models_as_of_dec13_10pm/Logit"

use "yhat_1_split_2012_logit.dta", clear

local filelist: dir . files "*.dta"

foreach i in `filelist' {
	
	append using `i'
	
}

destring model, replace
ren model model_no
la var model_no "Model no."

ren cv_metricsc1 split
la var split "Year of CV split"

ren cv_metricsc2 gof
la var gof "Pearson goodness-of-fit test"

ren cv_metricsc3 accuracy
replace accuracy = accuracy / 100 // Rescaled for consistency with OLS models
la var accuracy "Accuracy"

ren cv_metricsc4 log_loss
la var log_loss "Negative log loss"

sort model_no (split)

duplicates drop model_no split, force

save "/Users/nbs/Desktop/logit_cv_metrics.dta", replace


///

use "/Users/justinpotisit/Documents/GitHub/gbus_401_project/Data_Final/logit_cv_metrics.dta"

sum accuracy

*Mean accuracy
egen maccuracy = mean(accuracy), by(model_no)
la var maccuracy "Mean accuracy score"


tabstat accuracy, by(model_no) s(mean sd)

scatter maccuracy model_no, xsize(10) xlabel(#20) 

scatter maccuracy model_no if maccuracy >.73, xsize(10) xlabel(#20) 

*Variance/SD
egen vaccuracy = sd(accuracy), by(model_no)
la var vaccuracy "SD of accuracy"

scatter vaccuracy model_no if , xsize(10) xlabel(#20) 

graph export "variance and model #", as(png) name("Graph") replace


scatter vaccuracy model_no if vaccuracy <.013, xsize(10) xlabel(#20) 

ssc install colorscatter

ssc install sepscatter

colorscatter maccuracy vaccuracy model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Mean") xtitle("Standard deviation") title("{bf:Accuracy Mean and Standard Deviation by Logit Model}") legend(off) 

sepscatter maccuracy vaccuracy if maccuracy<0.5 & vaccuracy>0.03, separate(model_no) legend(on)

colorscatter mll vaccuracy model_no, cmin(1) cmax(127) rgb_low(10 10 10) rgb_high(254 254 254) scatter_options(msymb(o)) ytitle("Log Loss") xtitle("Standard deviation") title("{bf:Log Loss and Standard Deviation by Logit Model}") legend(off) 

sepscatter maccuracy vaccuracy if mll<0.5 & vaccuracy>0.03, separate(model_no) legend(on)


compress

save "${path}/Data_Final/logit_cv_metrics.dta", replace
