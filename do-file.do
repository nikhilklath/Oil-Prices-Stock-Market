*****************************************************
* Candidate Name: Nikhil Kumar			    *
* Date: 7/12/2020				    *
* Stata Version Used: Stata 16 SE	            *
*****************************************************

/*
Last year, Dr. Bernanke wrote a blog post that tried to shed light on what was driving the
change in oil prices, with the goal of explaining at least part of the puzzling co-movement in oil prices
(WTI crude) and the stock market.I recreate one of the figures from that analysis, which drew heavily on a
blog post by James Hamilton at UCSD. 
*/

clear all

* How can you run this file?
* Just change the path of the working folder in the next line
global projdir "C:\Users\nikhi\Downloads\Stata"

* raw data folder
global raw "$projdir\Raw Data"

* folder where clean data is saved
global final "$projdir\Clean Data"

* folder where ouptut graphs and tables are saved
global output "$projdir\Output"

*****************************************************
* 			TASK #1			    *
*****************************************************

import delimited "$raw\3 RAassignmentdata.csv" // import the dataset
gen date2 = date(date, "MDY") // set date into Stata readable format
format date2 %td
drop date
rename date2 date

tsset date // set date as the time varibale 

// generate the log of releavant variables
gen logoil = log(wti)
gen logcopper = log(copper)
gen logdollar = log(dollar)

gen insample = inrange(date,td(1jun2011), td(1jun2014))
// label the variables
label var tenyear "10 year Treasury Rate"
label var sp500 "S&P 500 Index"
label var dollar "Copper Price"
label var dollar "Value of Dollar"
label var wti "WTI Crude Oil Index"
label var logoil "Log of Oil Price"
label var logcopper "Log of Copper Price"
label var logdollar "Log of Value of Dollar"

// generate the required differences of above variables
gen diff_logoil = logoil[_n] - logoil[_n-1]
gen diff_logcopper = logcopper[_n] - logcopper[_n - 1]
gen diff_logdollar = logdollar[_n] - logdollar[_n - 1]
gen diff_tenyear = tenyear[_n] - tenyear[_n-1] 

* Dr. Bernanke in Appendix I runs the regression with t-statistics
*  calculated using a Newey-West adjustment with 5 lags

ssc install newey2
newey2 diff_logoil diff_logcopper diff_logdollar diff_tenyear insample, nocon lag(5) force 

* predict the difference in log of oil price for all the observations
predict diff_logoil_pred 

* for the first observation which is out of sample, use the previous day WTI 
* to predict the oil price
gen wti_pred = wti[_n - 1]*exp(diff_logoil_pred) if date == td(2jun2014)

* then predict prices on all subsequent days
replace wti_pred = wti_pred[_n - 1]*exp(diff_logoil_pred)  if date > td(2jun2014)

line wti wti_pred date, yscale(range(0 120)) title("WTI Crude Estimated Demand Effect") ytitle("Dollars per barrel") note("Source: Bloomberg(WTI); Author's calculations," "Note: Demand component estimated by applying regression coefficients" "over 6/2011-6/2014 to subsequent copper, dollar and ten-year data") legend(label(1 "WTI") label(2 "Oil Demand Only") ring(0) position(6)) tlabel(01jun2011(60)01feb2016, format(%tdMon-YY) angle(vertical)) lcolor(navy ltblue)
graph export "$output/task1.png", replace

save "$output/task1_data", replace
