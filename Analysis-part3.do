set more off

clear all
* Set directory to location of data

global setting "D:\Dropbox (MIT)\2020_Rentify_Business\submission\ESM_PNAS\code"

global project "${setting}/_data/"
global savefile "${setting}/_table"
cd "${setting}"

global lmg "${setting}/_table/lmg"

global graphic "${setting}/_graphic"

import delimited using "${project}/boston_2y_balanced.csv", clear

describe

*******************************************************************************
//////////////// Meta Data /////////////////////
*******************************************************************************
* newid： Unique Street Segment ID

* incomediversity4adj: Residential Diversity (Census Block Group Level)

* counts_total: Average number of unique people (adjusted by same \tau) visit each street segment per day

* num_bldg_change: Number of Building Changed between 2016 - 2018
* size_bldg_cha: Size of Building Changed between 2016 - 2018
* newbusinessref: New business from Reference USA
* facade: facade detection from GSV

tabulate yeargroup, summ(unique_total)

*******************************************************************************
//////////////// setup Sample Rules /////////////////////
*******************************************************************************
//
// drop if totalpoi<=3 // For robustness, we also test total_poi<5, 10, 15

drop if unique_total<20


*******************************************************************************
//////////////// Controls ////////////////////////////
*******************************************************************************
gen logpoi = log(totalpoi +1)
gen logincome = log(mhincomeadj)
gen logpop = log(tot_pop_cbgadj)
gen logpopdensity = log(pop_density_c)
gen logdist = log(dist_center)

gen logbldgchange = log(num_bldg_change+1)
gen logsizechange = log(size_bldg_cha+1)

egen yearnum = group(yeargroup)
egen countynum = group(county)

gen logcounts = log(counts_total+1)
gen logtime = log(timevisit +1)
gen loguser = log(unique_total +1)

gen storechange = open-closed



****************************************************************************
	*** Data summary ****
*******************************************************************************

label var bachelor "\% Bachelor"
label var mhincomeadj "MH Income."
label var expdiv "ESM"
label var incomediversity4adj "Resi. Diversity"
label var safety "Street Score"
label var pop_density_cb "Pop. Den."
label var open "$\#$ Restaurant Opened"
label var closed "$\#$ Restaurant Closed"
label var newbusinessref "Business Established"
label var facade "Facade"
label var planting "Planting"
label var unique_total "$\#$ Unique Users"


global comp pop_density_cb mhincomeadj bachelor incomediversity4adj safety expdiv

tabulate yeargroup
eststo clear
eststo pre: estpost summarize $comp if (yeargroup == 2016)
eststo after: estpost summarize $comp if (yeargroup == 2018)

eststo groupdiff: estpost ttest $comp, by(yeargroup) unequal
esttab pre after groupdiff using "${savefile}/summary2boston.tex", replace booktabs label ///
cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") mtitle("Year 2016" "Year 2018" "Difference 2016 - 2018") nogaps compress

****************************************************************************
	* Create Difference in Difference Variables
*******************************************************************************

* only use original data instead of normalized data
gen safety2 = safety*safety

by newid  (yeargroup), sort: gen diffsafety = safety - safety[_n-1]

by newid (yeargroup), sort: gen diffsafety2 = safety2 - safety2[_n-1]

by newid (yeargroup), sort: gen diffpopdensity = logpopdensity - logpopdensity[_n-1]
by newid  (yeargroup), sort: gen diffpop = logpop - logpop[_n-1]

by newid (yeargroup), sort: gen diffincome = logincome -  logincome[_n-1]

by newid (yeargroup), sort: gen diffbachelor = bachelor -  bachelor[_n-1]

by newid (yeargroup), sort: gen diffresidiv = incomediversity4adj - incomediversity4adj[_n-1]

by newid (yeargroup), sort: gen diffexpdiv = expdiv - expdiv[_n-1]


//
by newid (yeargroup), sort: gen diffdiv1014 = div_10_14 - div_10_14[_n-1]
by newid (yeargroup), sort: gen diffdiv610 = div_6_10 - div_6_10[_n-1]
by newid (yeargroup), sort: gen diffdiv1418 = div_14_18 - div_14_18[_n-1]
by newid (yeargroup), sort: gen diffdiv1822 = div_18_22 - div_18_22[_n-1]

by newid (yeargroup), sort: gen diffopen = open - open[_n-1]
by newid (yeargroup), sort: gen diffclosed = closed - closed[_n-1]
by newid (yeargroup), sort: gen diffcount = counts_total - counts_total[_n-1]
by newid (yeargroup), sort: gen difflogcount = logcounts - logcounts[_n-1]

by newid (yeargroup), sort: gen difffacade = facade - facade[_n-1]
by newid (yeargroup), sort: gen diffplanting = planting - planting[_n-1]
by newid (yeargroup), sort: gen diffnewbusinessref = newbusinessref - newbusinessref[_n-1]

//
by newid (yeargroup), sort: gen div_6_1016 = div_6_10[_n-1]
by newid (yeargroup), sort: gen div_10_1416 = div_10_14[_n-1]
by newid (yeargroup), sort: gen div_14_1816 = div_14_18[_n-1]
by newid (yeargroup), sort: gen div_18_2216 = div_18_22[_n-1]
by newid (yeargroup), sort: gen diffstore = storechange - storechange[_n-1]

by newid (yeargroup), sort: gen diffuser = loguser - loguser[_n-1]
by newid (yeargroup), sort: gen difftime = logtime - logtime[_n-1]

// Generate Trend Control use 2016 data
global trend length logdist logpop station_dist_m logpopdensity logpoi expdiv loguser logtime logcounts

foreach v of varlist $trend{
	by newid (yeargroup), sort: gen `v'_16 = `v'[_n-1]
}






*******************************************************************************
	*label all standardized variables  *
*******************************************************************************

****** 1.1Basics: time variant variables from demographics *******
**** keep the 2018 only from here
// drop if total_poi<=5
drop if diffbachelor==.
drop if diffincome==.
drop if diffpop ==.
drop if logpoi_16 ==.
drop if diffresidiv ==.

global basics diffpop diffpopdensity diffincome diffbachelor diffresidiv 

foreach v of varlist $basics { 
    egen std_`v' = std(`v')
}

egen std_diffsafety2 = std(diffsafety2)
// egen std_diffnewbusinessref = std(diffnewbusinessref)
// egen std_difffacade = std(difffacade)
// egen std_diffplanting = std(diffplanting)

****** 1.2 Built Environment Changes ******

global newvaris diffclosed diffopen diffsafety logbldgchange diffstore diffnewbusinessref difffacade diffplanting difflogcount difftime diffuser

foreach v of varlist $newvaris { 
    egen std_`v' = std(`v')
}

****** 1.3 label all ******
global trend16 length_16 logdist_16 logpop_16 station_dist_m_16 logpopdensity_16 logpoi_16 expdiv_16 logcounts_16 div_18_2216
foreach v of varlist $trend16 { 
    egen std_`v' = std(`v')
}


global std_basics std_diffpopdensity std_diffincome std_diffbachelor std_diffresidiv 

global std_new std_diffclosed std_diffopen std_diffsafety std_logbldgchange std_difffacade std_diffnewbusinessref std_diffplanting

global std_trends std_length_16 std_logpopdensity_16 std_logpoi_16 std_expdiv_16

label var std_logdist_16 "Log(Dist CBD)"
label var std_length_16 "Segment Length"
label var std_logpop_16 "Log(Pop)"
label var std_logpoi_16 "Log($\#$ POI)"
label var std_logpopdensity_16 "Log(Pop. Den)"
label var std_expdiv_16 "ESM. 2016"

label var std_diffpop "$\Delta$ Population"
label var std_diffpopdensity "$\Delta$ Pop Den"
label var std_diffincome "$\Delta$ MH Income"
label var std_diffbachelor "$\Delta \%$ Bachelor"
label var std_diffresidiv "$\Delta$ Resi. Diversity"

label var std_diffclosed "$\#$ Closed"
label var std_diffopen "$\#$ Open"
label var std_diffsafety "$\Delta$ Street Score"
label var std_logbldgchange "Log(New Built)"
label var std_diffstore "$\Delta$ Stores"
label var std_diffnewbusinessref "$\Delta$ New Business"
label var std_difffacade "$\Delta$ Facade"
label var std_diffplanting "$\Delta$ planting"

label var std_difflogcount "$\Delta$ Log(Visitors)" // this includes expansion factor already
label var std_difftime "$\Delta$ Log(Time Daily)"
label var std_diffuser "$\Delta$ Log(Unique User)"
label var std_diffsafety2 "$\Delta$ Street Score (sq)"





*****************************************************
 *************** Margin Plot DID
*****************************************************


// Check correlation
corr length $std_trends $std_basics


corr std_diffnewbusinessref std_diffstore
eststo clear
// Trend only

// histogram diffexpdiv
drop if totalpoi<=3 // Uncommand this for robustness
// drop if counts_total<60/84
eststo m00:reg diffexpdiv $std_trends i.countynum if(expdiv_16>0) , r


eststo m0:reg diffexpdiv $std_trends $std_basics i.countynum if(expdiv_16>0), r

// Change of stores only
eststo m1:reg diffexpdiv $std_trends std_diffstore i.countynum if(expdiv_16>0) , r

// change of stores and change of residential and change of residential

eststo m12:reg diffexpdiv $std_trends $std_basics std_diffstore i.countynum if(expdiv_16>0), r

// change of stores and change of residential and change of street score
eststo m2:reg diffexpdiv $std_trends $std_basics std_diffstore std_diffsafety std_diffsafety2 i.countynum if(expdiv_16>0), r

//interaction term: store changes x expdiv16
eststo m22:reg diffexpdiv $std_trends $std_basics std_diffstore c.std_diffstore#c.std_expdiv_16 i.countynum if(expdiv_16>0), r

eststo m23:reg diffexpdiv $std_trends $std_basics std_diffstore i.countynum std_difflogcount  if(expdiv_16>0), r

eststo m3:reg diffexpdiv $std_trends $std_basics std_diffopen i.countynum if(expdiv_16>0), r


eststo m4:reg diffexpdiv $std_trends $std_basics std_diffnewbusinessref i.countynum if(expdiv_16>0), r



**** Export Tables**** **** 
esttab m0 m1 m12 m22 m23 using "${savefile}/Table1_Boston_Change_ST_oneday_short.tex", replace booktabs label ///
 cells(b(star fmt(%9.3f)) se(par)) stats(N r2, fmt(%7.0f %7.4f) labels("Observations" "R-squared")) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.005) 

esttab m0 m1 m2 m22 m23 m3 m4 using "${savefile}/TableS4_Boston_Change_ST_oneday_long.tex", replace booktabs label ///
 cells(b(star fmt(%9.3f)) se(par)) stats(N r2, fmt(%7.0f %7.4f) labels("Observations" "R-squared")) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.005) 
 