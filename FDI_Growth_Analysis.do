* ==============================================================================
* MASTER SCRIPT: FDI & ECONOMIC GROWTH ANALYSIS FOR LATIN-AMERICA (PANEL ARDL)
* Author: Raúl Moreno Aguilera
* Software: Stata 17
* ==============================================================================

* ------------------------------------------------------------------------------
* 0. SETUP
* ------------------------------------------------------------------------------
* NOTE: Set your working directory here
* cd "PATH_TO_YOUR_DIRECTORY"

* Load dataset (Data file not included in repo due to privacy/copyright)
* use "dataset_name.dta", clear

* Generate Panel data settings
xtset id year
xtdescribe

* Summary statistics
local vars gdp fdi cep sch gov dom man
xtsum `vars'
sum `vars'

* ------------------------------------------------------------------------------
* 1. CORRELATION ANALYSIS
* ------------------------------------------------------------------------------
corr `vars'

* ------------------------------------------------------------------------------
* 2. UNIT ROOT TESTS (STATIONARITY)
* ------------------------------------------------------------------------------
* Note: Using AIC for lag selection (max lags 4)

* 2.1 IPS Test (Im-Pesaran-Shin) - Level & First Diff
foreach var in `vars' {
	xtunitroot ips `var', lags(aic 4)
	xtunitroot ips d.`var', lags(aic 4)
}

* 2.3 Fisher-type tests (ADF & Phillips-Perron)
* Based on Choi (2001): Z test recommended considering trade-off between size/power.

foreach var in `vars' {
	* ADF
	xtunitroot fisher `var', dfuller lags(1)
	xtunitroot fisher d.`var', dfuller lags(1)
	* Phillips-Perron
	xtunitroot fisher `var', pperron lags(1)
	xtunitroot fisher d.`var', pperron lags(1)
}

* ------------------------------------------------------------------------------
* 3. CROSS-SECTIONAL DEPENDENCE (CIPS & CADF)
* ------------------------------------------------------------------------------
* Handling missing data in DOM variable via interpolation for testing purposes
ipolate dom year, gen(domi) epolate by(id)

* Note: 'dom' excluded due to gaps; using 'domi' instead.
local cips_vars gdp fdi sch gov man cep domi

foreach var of local cips_vars {
	* CIPS (Level & Diff)
	xtcips `var', maxlag(2) bglag(2)
	xtcips d.`var', maxlag(2) bglag(2)
	
	* CADF (Level & Diff)
	pescadf `var', lags(1)
	pescadf d.`var', lags(1)
}

* ------------------------------------------------------------------------------
* 4. COINTEGRATION
* ------------------------------------------------------------------------------
* Cointegration tests (Kao, Pedroni, Westerlund) for I(1) variables
local coint_vars sch gov man dom

xtcointtest kao `coint_vars'
xtcointtest pedroni `coint_vars'
xtcointtest westerlund `coint_vars'
xtcointtest westerlund `coint_vars', allpanels

* ------------------------------------------------------------------------------
* 5. MULTICOLLINEARITY
* ------------------------------------------------------------------------------
* VIF Test
quietly regress gdp fdi cep sch gov dom man
vif
* Note: VIF < 10 indicates acceptable multicollinearity levels.

* ------------------------------------------------------------------------------
* 6. ESTIMATIONS (PANEL ARDL: MG & PMG)
* ------------------------------------------------------------------------------
* NOTE: Tables are exported to the working directory.
* We loop over control variables to estimate models efficiently.

* Define control variables list
local controls sch gov dom man

* 6.1 Pooled Mean Group (PMG)
foreach var of local controls {
	eststo pmg_`var': xtdcce2 d.gdp d.fdi d.cep d.`var', lr(l.gdp fdi cep `var') pooled(l.gdp fdi cep `var') nocrosssectional cr_lags(2) lr_options(xtpmgnames) recursive
}

* 6.2 PMG with Common Correlated Effects (PMG-CCE)
foreach var of local controls {
	eststo pmgcce_`var': xtdcce2 d.gdp d.fdi d.cep d.`var', lr(l.gdp fdi cep `var') pooled(l.gdp fdi cep `var') crosssectional(d.gdp) cr_lags(2) lr_options(xtpmgnames) recursive
}

* 6.3 Mean Group (MG)
foreach var of local controls {
	eststo mg_`var': xtdcce2 d.gdp d.fdi d.cep d.`var', lr(l.gdp fdi cep `var') nocrosssectional cr_lags(2) lr_options(xtpmgnames) recursive
}

* 6.4 MG with CCE (MG-CCE)
estimates clear
foreach var of local controls {
	eststo mgcce_`var': xtdcce2 d.gdp d.fdi d.cep d.`var', lr(l.gdp fdi cep `var') crosssectional(d.gdp d.fdi) cr_lags(2) lr_options(xtpmgnames) recursive
}

* ------------------------------------------------------------------------------
* 7. POST-ESTIMATION & TABLES
* ------------------------------------------------------------------------------

* Table: PMG vs MG Regressions
* Note: Calling stored estimates from the loops above
esttab pmg_sch pmg_gov pmg_dom pmg_man mg_sch mg_gov mg_dom mg_man using "Table_6_PMG_MG.rtf", replace b(3) not ar2 ///
		compress star(* 0.10 ** 0.05 *** 0.01) ///
		modelwidth(5) se ///
		stats(ar2 cd cdp, fmt(0 3 3)) ///
		mtitles("PMG(sch)" "PMG(gov)" "PMG(dom)" "PMG(man)" "MG(sch)" "MG(gov)" "MG(dom)" "MG(man)" ) ///
		title ("{\b Table} 6. PMG-MG regressions") ///
		nogaps

* Table: PMG-CCE vs MG-CCE
esttab pmgcce_sch pmgcce_gov pmgcce_dom pmgcce_man mgcce_sch mgcce_gov mgcce_dom mgcce_man using "Table_6_CCE.rtf", replace b(3) not ar2 ///
		compress star(* 0.10 ** 0.05 *** 0.01) ///
		modelwidth(5) se ///
		stats(ar2 cd cdp, fmt(0 3 3)) ///
		mtitles("PMG-CCE(sch)" "PMG-CCE(gov)" "PMG-CCE(dom)" "PMG-CCE(man)" "MG-CCE(sch)" "MG-CCE(gov)" "MG-CCE(dom)" "MG-CCE(man)" ) ///
		title ("{\b Table} 6. CCE regressions") ///
		nogaps		

* Hausman Test (Example with Schooling)
estimates clear
eststo pmg: quiet xtdcce2 d.gdp d.fdi d.cep d.sch, lr(l.gdp fdi cep sch) pooled(l.gdp fdi cep sch) crosssectional(d.gdp) cr_lags(2) lr_options(xtpmgnames) recursive
eststo mg: quiet xtdcce2 d.gdp d.fdi d.cep d.sch, lr(l.gdp fdi cep sch) crosssectional(d.gdp d.fdi) cr_lags(2) lr_options(xtpmgnames) recursive
hausman mg pmg, sigmamore

* ------------------------------------------------------------------------------
* 8. ROBUSTNESS: OUTLIER DETECTION
* ------------------------------------------------------------------------------
* Checking for outlier countries affecting negative schooling coefficient

* PMG-CCE Outlier Loop
estimates clear
forvalues co=1/17 {
	quietly eststo: xtdcce2 d.gdp d.fdi d.cep d.sch if id!=`co', lr(l.gdp fdi cep sch) pooled(l.gdp fdi cep sch) crosssectional(d.gdp) cr_lags(2) lr_options(xtpmgnames) recursive
	estadd scalar Obs = e(N)
	estadd scalar Countries = e(N_g)
}
esttab using "Table_Outlier_Schooling_PMG.rtf", replace b(2) not ar2 ///
		compress star(* 0.10 ** 0.05 *** 0.01) ///
		stats(Obs Countries Loglhood, fmt(0 0 3)) ///
		modelwidth(3) ///
		title ("{\b Table} Outlier Schooling PMG-cce")		
		
* MG-CCE Outlier Loop
estimates clear
forvalues co=1/17 {
	quietly eststo: xtdcce2 d.gdp d.fdi d.cep d.sch if id!=`co', lr(l.gdp fdi cep sch) crosssectional(d.gdp d.fdi) cr_lags(2) lr_options(xtpmgnames) recursive
	estadd scalar Obs = e(N)
	estadd scalar Countries = e(N_g)
}
esttab using "Table_Outlier_Schooling_MG.rtf", replace b(2) not ar2 ///
		compress star(* 0.10 ** 0.05 *** 0.01) ///
		stats(Obs Countries Loglhood, fmt(0 0 3)) ///
		modelwidth(3) ///
		title ("{\b Table} Outlier Schooling MG-cce")