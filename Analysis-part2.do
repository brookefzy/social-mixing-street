set more off
* This code contains analysis for producing fig. 3 b, c
clear all
* Set directory to location of data
global setting "."

global project "${setting}/_data/"
global savefile "${setting}/_table"
cd "${setting}"

global lmg "${setting}/_table/lmg"

global graphic "${setting}/_graphic"


import delimited using "${project}/str_para_3city.csv", clear

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

*******************************************************************************
//////////////// setup Sample Rules ////////////////////
*******************************************************************************

drop if img_count<8 
drop if totalpoi<3
drop if tot_pop_cbgadj<50

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

// gen logcount = log(counts_total+1)
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



****************************************************************************************
****************************************************************************************
	    *2. GET LMG *
****************************************************************************************
****************************************************************************************
eststo clear


global basics std_length std_logdist
global fixed i.ncounty 
global stdemo std_logpopdensity std_logincome std_incomediversity4adj

global controls i.ncounty std_length std_logdist
global d3 std_logpopdensity std_incomediversity4adj std_logpoi std_logincome std_safety std_safety2


****************************************************************************************
***********3. Regression result to generate all LMG  
****************************************************************************************

* All LMG: sequentially drop the number of unique users
summarize unique_total

forval t = 1/20{
    eststo clear
	eststo rg: reg std_expdiv $controls if (totalpoi>=3 & unique_total>`t'*5), r
	eststo rd: reg std_expdiv $d3 if (totalpoi>=3 & unique_total>`t'*5), r
	eststo rc: reg std_expdiv std_logcount if (totalpoi>=3 & unique_total>`t'*5), r

	eststo rgd: reg std_expdiv $controls $d3 if (totalpoi>=3 & unique_total>`t'*5), r
	eststo rgc: reg std_expdiv $controls std_logcount if (totalpoi>=3 & unique_total>`t'*5), r
	eststo rdc: reg std_expdiv $d3 std_logcount if (totalpoi>=3 & unique_total>`t'*5), r
	eststo rgcd: reg std_expdiv $controls $d3 std_logcount if (totalpoi>=3 & unique_total>`t'*5), r
	
	esttab r* using "${lmg}/allday_`t'.csv",replace wide plain r2
}
