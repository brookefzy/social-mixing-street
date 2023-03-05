set more off

* This file contains data and code for 
*- Table S1. 
* Fig 2 e, d, e, f
* Fig 3 a.

clear all
* Set directory to location of data
global setting "D:\Dropbox (MIT)\2020_Rentify_Business\submission\ESM_PNAS\code"

global project "${setting}/_data/"
global savefile "${setting}/_table"
cd "${setting}"

global lmg "${setting}/_table/lmg"

global graphic "${setting}/_graphic"


import delimited using "${project}/str_para_3city_join_week.csv", clear

describe

tabulate city


*******************************************************************************
//////////////// Meta Data /////////////////////
*******************************************************************************
* newid： Unique Street Segment ID

* incomediversity4adj: Residential Diversity (Census Block Group Level)
* counts_total: Average number of unique people (adjusted by same \tau) visit each street segment per day
* length: Segment Length
* tot_pop_cbgadj : Total Population at adjacent CBG
* img_count: Number Image Sample
* totalpoi: Total number of POI adjacent to each street segment
* unique_total: Total number of unique device (user) visited each street
* counts_total: Weighted number of unique device (user) visited each street
* dist_home: Average visitors' home distance from each street
* mhincomeadj: Median Household Income of each street segment's neighborhood
* safety: Safety Score predicted from deep learning model using google street view images
* dist_center: Distance from the urban core center

*******************************************************************************
//////////////// setup Sample Rules ////////////////////
*******************************************************************************

drop if img_count<8 
drop if totalpoi<3
drop if tot_pop_cbgadj<50
keep if unique_total>20
drop if length>9000


*******************************************************************************
//////////////// Transform data ////////////////////////////
*******************************************************************************
egen ncity = group(city)
egen ncounty = group(metro_county)


gen logpoi = log(totalpoi +1)
gen logincome = log(mhincomeadj)
gen logpopdensity = log(pop_density_c)
gen logdist = log(dist_center)
gen logpop = log(tot_pop_cbgadj)

gen logcount = log(counts_total+1)
gen logcount610 = log(counts_6_10+1)
gen logcount1014 = log(counts_10_14+1)
gen logcount1418 = log(counts_14_18+1)
gen logcount1822 = log(counts_18_22+1) 

gen logunique = log(unique_total+1)

// Time spent at a street segment per day

gen logtime = log(timevisit+1)
gen logtime610 = log(timevitist_6_10 +1)
gen logtime1014 = log(timevitist_10_14 +1)
gen logtime1418 = log(timevitist_14_18 +1)
gen logtime1822 = log(timevitist_18_22 +1)



*******************************************************************************
	       * Set up group variables *
		   * Adding the neighbor characteristics*
*******************************************************************************
global controls length logdist logpopdensity logpoi logincome bachelor_rateadj park_dist_m station_dist_m
global residiv incomediversity4adj

global place cityoutdoors artsmuseum coffeetea entertainment food grocery health religious school service shopping sports transportation work college
global dependent div_6_10 seg_6_10 div_10_14 seg_10_14 div_14_18 seg_14_18 div_18_22 seg_18_22 expdiv dexpseg logtime logtime610 logtime1014 logtime1418 logtime1822

global logplace logcityoutdoors logartsmuseum logcoffeetea logentertainment logfood loggrocery loghealth logreligious logschool logservice logshopping logsports logtransportation logwork logcollege

*******************************************************************************
	* Standardize all variables (for 2016 only) *
*******************************************************************************


foreach v of varlist $place{
	replace `v' = 0 if `v' ==.
	gen log`v' = log(`v'+1)
}

global varis $controls $residiv $dependent safety $logplace 

foreach v of varlist $varis { 
    egen std_`v' = std(`v')
	
}
egen std_logcount = std(logcount)
egen std_logcount610 = std(logcount610)
egen std_logcount1014 = std(logcount1014)
egen std_logcount1418 = std(logcount1418)
egen std_logcount1822 = std(logcount1822)

egen std_safety2 = std(safety*safety)
egen std_logtimevisit = std(log(timevisit+1))
egen std_loguser = std(logunique)
egen std_logcounts = std(logcount)


*******************************************************************************
	*label all variables  *
*******************************************************************************

*** Main X 1 ****

label var std_incomediversity4adj "Resi. Div."
// label var std_incomediversity12adj "Resi. Entropy (16 cate)"


*** Control and X ***
label var std_length "Street Length"
label var std_logpoi "Log(\#POI)"
label var std_logpopdensity "Log(Pop. Den)"
label var std_logincome "Log(MH Income)"
label var std_bachelor_rateadj "\% Bachelor"
label var std_park "Dist Parks"
label var std_station_dist_m "Dist Transit"
label var std_logdist "Log(Dist from CBD)"
label var std_safety "Street Score"
label var std_safety2 "Street Score (Sq)"


label var std_logfood "Log(Food)" 
label var std_logshopping "Log(Shopping)"
label var std_logcollege "Log(College)"
label var std_logwork "Log(Work)"
label var std_logsports "Log(Sports)"
label var std_logtransportation "Log(Transportation)"
label var std_logservice "Log(Service)"
label var std_logschool "Log(School)"
label var std_logreligious "Log(Religious)"
label var std_loghealth "Log(Health)"
label var std_loggrocery "Log(Grocery)"
label var std_logentertainment "Log(Entertainment)"
label var std_logcoffee "Log(Coffee / Tea)"
label var std_logartsmuseum "Log(Arts / Museum)"
label var std_logcityout "Log(City / Outdoor)"

*** Dependent ****
label var std_expdiv "Experienced Diversity"
// label var std_dexpseg "Experienced Segregation"
label var std_div_6_10 "ESM 6-10"
label var std_div_10_14 "ESM 10-14"
label var std_div_14_18 "ESM 14-18"
label var std_div_18_22 "ESM 18-22"

label var std_logtime610 "Time 6-10"
label var std_logtime1014 "Time 10-14"
label var std_logtime1418 "Time 14-18"
label var std_logtime1822 "Time 18-22"

label var std_logcount1014 "Visitors 10-14"
label var std_logcount610 "Visitors 6-10"
label var std_logcount1418 "Visitors 14-18"
label var std_logcount1822 "Visitors 18-22"


label var std_logtimevisit "Log(Total Time)"
// label var std_count "Average Daily Visitors"
label var std_logcount "Log(Visitors)"

*******************************************************************************
	*1. Simple Linear: Time in-variant  *
*******************************************************************************

global basics std_length std_logdist
global fixed i.ncounty
global stdemo std_logpopdensity std_logincome std_incomediversity4adj
global stdplace  std_logfood std_logshopping std_logcollege std_logwork std_logsports std_logtransportation std_logservice std_loghealth std_loggrocery std_logentertainment std_logcoffee std_logartsmuseum std_logcityout std_safety

corr $logplace $stdemo


*******************************************************************************
	*1.1 ESM and environment Factors
*******************************************************************************

eststo clear

drop if std_incomediversity4adj==.
drop if std_logincome==.
drop if std_bachelor_rateadj==.

egen std_timevisit = std(timevisit)

egen std_logtime2 = std(logtime*logtime)


// 0. Regress on total time spent
eststo rt0: reg std_logtimevisit $basics $stdemo $fixed std_logpoi std_safety if (totalpoi>=3), r

// 1. Regress on daily unique visitors (adjusted by factor)
eststo rt1: reg std_logcount $basics $stdemo $fixed std_logpoi std_safety if (totalpoi>=3), r


// 2. Regress on social mixing
eststo rt2: reg std_expdiv $basics $stdemo $fixed std_logpoi std_safety if (totalpoi>=3), r

// 3. Include a quadratic term
eststo rt3: reg std_expdiv $basics $stdemo $fixed std_logpoi std_safety std_safety2 if (totalpoi>=3), r



// 4. Include total time as a variable
eststo rt4: reg std_expdiv $basics $stdemo $fixed std_logpoi std_safety std_logtimevisit if (totalpoi>=3), r

// 5. Include a daily unique visitors as a variable
eststo rt5: reg std_expdiv $basics $stdemo $fixed std_logpoi std_safety std_logcount if (totalpoi>=3), r

eststo rt6: reg std_expdiv $basics $stdemo $fixed std_logpoi std_safety std_safety2 std_logcount if (totalpoi>=3), r


esttab rt2 using "${savefile}/st_std_3city_resi.csv", replace wide plain r2
esttab rt1 rt2 rt4 rt5 using "${savefile}/st_std_3city_density.csv", replace wide plain r2

 
 * Table S1 (Supplemental)
 esttab rt1 rt2 rt3 rt5 using "${savefile}/tableS1_street.tex", replace booktabs label ///
 cells(b(star fmt(%9.3f)) se(par)) stats(N r2, fmt(%7.0f %7.4f) labels("Observations" "R-squared")) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.005) 
 
*******************************************************************************
	*1.2. Visiting Density and ESM  Appendix + Spatial Spi
*******************************************************************************

// 1. Regress on daily unique visitors (adjusted by factor)
eststo ivrt1: ivreg2 std_logcount $basics $stdemo $fixed std_logpoi std_safety (spill_count = $basics $fixed) if (totalpoi>=3), r


// 2. Regress on social mixing
eststo ivrt2: ivreg2 std_expdiv $basics $stdemo $fixed std_logpoi std_safety (spill_esm = $basics $fixed) if (totalpoi>=3), r

// 3. Include a quadratic term
eststo ivrt3: ivreg2 std_expdiv $basics $stdemo $fixed std_logpoi std_safety std_safety2 if (totalpoi>=3), r


// 5. Include a daily unique visitors as a variable
eststo ivrt5: ivreg2 std_expdiv $basics $stdemo $fixed std_logpoi std_safety std_logcount if (totalpoi>=3), r

 * Table S1 (Supplemental)
 esttab rt1 rt2 rt3 rt5 using "${savefile}/tableS1_street.tex", replace booktabs label ///
 cells(b(star fmt(%9.3f)) se(par)) stats(N r2, fmt(%7.0f %7.4f) labels("Observations" "R-squared")) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.005) 

*******************************************************************************
	*1.2. Visiting Density and ESM  Fig. S4*
*******************************************************************************

binscatter expdiv logcount if(totalpoi>3), nq(100) absorb(city) line(qfit) controls(length) savegraph("${graphic}/sup_count_esm.eps") replace ///
ytitle("ESM (Street Level)", margin(small) size(small)) ///
xtitle("Log(Total Visitors)") ///
xsize(2.5) ysize(2) graphregion(fcolor(white)) plotregion(fcolor(white))

binscatter expdiv logtime if(totalpoi>3), nq(100) absorb(city) line(qfit) controls(length) savegraph("${graphic}/sup_time_esm.eps") replace ///
ytitle("ESM (Street Level)", margin(small) size(small)) ///
xtitle("Log(Time)") ///
xsize(2.5) ysize(2) graphregion(fcolor(white)) plotregion(fcolor(white))


****************************************************************************************
	    *2. Time variant- Table S2  *
****************************************************************************************

gen n = 20

* Balance the dataset
global condition unique_6_10>n & unique_10_14>n & unique_14_18>n & unique_18_22>n


eststo clear
eststo r11: reg std_div_6_10 $basics $stdemo $stdplace $fixed if($condition), r 

eststo r12: reg std_div_10_14 $basics $stdemo $stdplace $fixed if($condition), r  

eststo r13: reg std_div_14_18 $basics $stdemo $stdplace $fixed if($condition), r 

eststo r14: reg std_div_18_22 $basics $stdemo $stdplace $fixed if($condition), r

eststo r21: reg std_div_6_10 $basics $stdemo $stdplace $fixed std_logcount610 if($condition), r 


eststo r22: reg std_div_10_14 $basics $stdemo $stdplace $fixed std_logcount1014 if($condition), r


eststo r23: reg std_div_14_18 $basics $stdemo $stdplace $fixed std_logcount1418 if($condition), r 

eststo r24: reg std_div_18_22 $basics $stdemo $stdplace $fixed std_logcount1822 if($condition), r

esttab r1* r2* using "${savefile}/TableS2-timevariant.tex", replace booktabs ///
	lab  mgroups("6-10 am" "10am-2pm" "2pm-6pm" "6pm-10pm" "6-10 am" "10am-2pm" "2pm-6pm" "6pm-10pm", pattern(1 1 1 1 1 1 1 1) ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	cells(b(star fmt(%9.3f)) se(par)) stats(N r2 fe_dum, fmt(%7.0f %7.3f) labels("Observations" "R-squared" "Segment Length")) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.005) ///
	drop(std_length)
	
esttab r* using "${savefile}/fig4_st_std_3city_byhourweek_unique20.csv",replace wide plain r2
	



*******************************************************************************
	*Bin Scatter - Fig 1 d,e f*
*******************************************************************************
binscatter expdiv std_incomediversity4adj if(yeargroup==2016), absorb(ncity) controls($basics $stdplace) nq(100) line(lfit) savegraph("${graphic}/fig-1d.eps") replace ///
ytitle("ESM (Street Level)", margin(small) size(small)) ///
xtitle("Residential Diversity (SD)") ///
ysc(r(0.55 0.95)) ///
xsc(r(-3 2)) ///
xsize(2.5) ysize(2) graphregion(fcolor(white)) plotregion(fcolor(white))

binscatter expdiv std_safety, absorb(ncity) controls($basics logpopdensity logpoi std_incomediversity4adj logincome) nq(100) line(qfit) savegraph("${graphic}/fig-1f.eps") replace ///
ytitle("Experienced Diversity Daily (Street-Level)", margin(small) size(small)) ///
xtitle("Street Score") ///
xsize(2.2) ysize(2) graphregion(fcolor(white)) plotregion(fcolor(white))

binscatter expdiv std_logpoi, absorb(ncounty) controls($basics $stdemo std_safety) nq(100) savegraph("${graphic}/fig-1e.eps") replace ///
ytitle("ESM (Street Level)", margin(small) size(small)) ///
xtitle("Log(# POI)") ///
ysc(r(0.65 0.95)) ///
xsc(r(-2 2.5)) ///
xsize(2.5) ysize(2) graphregion(fcolor(white)) plotregion(fcolor(white))



