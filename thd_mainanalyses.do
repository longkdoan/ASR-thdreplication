capture log close
log using thd_mainanalyses.log, replace text

/*
task:		ASR analyses for replication materials
project:	THD
author:		lkd 20211215
*/

version 17
clear all
macro drop _all
set linesize 80

local pgm "thd_mainanalyses"
set scheme cleanplots	// (https://www.trentonmize.com/software/cleanplots)

*** #1: open data ***
/*
The included dataset is a cleaned version of the raw data merging in our
qualitative coding for the open-ended responses.

The raw data are available from the TESS website. If you use the raw data,
this is the link between how we refer to variables and the raw variable names
rename	caseid	mid
rename	weight	svyweight
rename	rnd_01	required
rename	p_over	hlthprof
rename	p_exp	expcond
rename	p_partyid7	polparty
rename	p_ideo	polideol
rename	p_relig	religion
rename	p_attend	relattend
rename	dov_name	vigname
rename	q1	refusetx
rename	q2	refusetxwhy
rename	q3	agrreason
rename	q4a_1	lgbknow
rename	q4a_2	lgbfrd
rename	q4a_3	lgbfam
rename	q4a_4	lgbnone
rename	q4a_dk	lgbdk
rename	q4a_skp	lgbskip
rename	q4a_ref	lgbref
rename	q4b_1	transknow
rename	q4b_2	transfrd
rename	q4b_3	transfam
rename	q4b_4	transnone
rename	q4b_dk	transdk
rename	q4b_skp	transskip
rename	q4b_ref	transref
rename	q5	refer
rename	hl038	lastdoc
rename	hl058a	premium
rename	hl058b	deduct
rename	hl058c	copay
rename	hl058d	coinsur
rename	hl058e	pocket
rename	hl058f	network
rename	hl058g	covserv
rename	employ1	emply
rename	industry	industry
rename	industry_oe	industrytxt
rename	occupy_new	wrktxt
rename	born	born
rename	gender1	sex
rename	gender	sexV2
rename	gender2	gender
rename	lgbt	sexuality
rename	startdt	start
rename	enddt	end
rename	duration	length
rename	surv_mode	mode
rename	device	device
rename	age	age
rename	age4	ageV2
rename	age7	ageV3
rename	racethnicity	race
rename	educ	educ
rename	educ4	educV2
rename	marital	marital
rename	income	hhinc
rename	state	state
rename	region4	region
rename	region9	regionV2
rename	metro	metro
rename	internet	web
rename	housing	housing
rename	home_type	houstyp
rename	phoneservice	phone
rename	hhsize	hhsize
rename	hh01	hhsize01
rename	hh25	hhsize25
rename	hh612	hhsize612
rename	hh1317	hhsize1317
rename	hh18ov	hhsize18

IMPORTANT NOTE: the main outcome "denial" is created by combining the raw
outcome refusetx (q1) with the required (rnd_01) indicator so that higher
scores indicate more support of treatment denial

We also simplified some of the control variables. Code to create these variables
are below.
**	religion 0None 1Protestant 2Christian 3Born 4Other
gen rel = 0 if !missing(religion)
replace rel = 1 if religion==1
replace rel = 2 if religion==2 | religion==3 | religion==4 | ///
	religion==12 | religion==13
replace rel = 4 if religion==5 | religion==6 | religion==7 | ///
	religion==8 | religion==14
replace rel = 3 if born == 1
	
**	knowgay knowtrans 0None 1Someone 2Friend 3Fam
gen knowgay = 0 if lgbskip!=1
replace knowgay = 1 if lgbknow==1
replace knowgay = 2 if lgbfrd==1
replace knowgay = 3 if lgbfam==1

gen knowtrans = 0 if transskip!=1
replace knowtrans = 1 if transknow==1
replace knowtrans = 2 if transfrd==1
replace knowtrans = 3 if transfam==1

**	female
gen female = sexV2==2

**	race 1White 2Black 3Other 4Hispanic
gen raceV2 = race
recode raceV2 (5 6 =3)

**	educ collapse <HS and HS
gen educV3 = educV2
recode educV3 (2=1)

**	married/cohabit vs. not
gen married = (marital==1 | marital==6)

**	inc 50k binary
gen inc50k = 0
replace inc50k = 1 if hhinc>=10 & !missing(hhinc)

**	conditions: gender 0man 1woman
gen congend = (expcon <= 8)

**	race 0white 1black 2latinx 3asian
gen conrace = 0
replace conrace = 1 if expcond==1 | expcond==5 | expcond==9 | expcond==13
replace conrace = 2 if expcond==3 | expcond==7 | expcond==11 | expcond==15
replace conrace = 3 if expcond==4 | expcond==8 | expcond==12 | expcond==16

**	religious denial 0no 1yes
gen conrelig = 0
replace conrelig = 1 if expcond==5 | expcond==6 | expcond==7 | expcond==8 | ///
	expcond==13 | expcond==14 | expcond==15 |expcond==16
	
**	is participant a republican 0no 1yes
gen repub = 0
replace repub = 1 if polpart > 4 & polpart < .
*/
use thd_qualmerged, clear

***	#2: define locals ***
//	controls to be used in models
local controls "female straight i.raceV2 age i.educV3 inc50k married"
local controls "`controls' i.rel i.repub metro i.knowgay i.knowtrans required"
mark sample
markout sample denial `controls'

//	controls to make descriptives table
local controls2 "rel* repub polparty* knowgay* knowtrans* female straight"
local controls2 "`controls2' age raceV2* educV3* married inc50k metro required"

//	qualitative codes
local codes "duty disc lack referral freedom"

***	#3: T1. Descriptives
estpost sum denial* referdenial* agrreason* `controls2' ///
	if sample [aw=svyweight]
esttab using `pgm'_T1.csv, replace ///
    cell("mean sd min max") ///
    nomtitle nonumber noobs plain
eststo clear

***	#4: T2. Main ologits
eststo: ologit denial conrelig##congend##conrace [pw=svyweight] if sample
estimates store m1	// save for figure 1 later


eststo: ologit denial conrelig##congend##conrace `controls' ///
	[pw=svyweight] if sample
estimates store m2 // save for figure 2 later
esttab using `pgm'_T2.rtf, replace ///
    b(%12.2f) nogaps star(+ .10 * 0.05 ** 0.01 *** 0.001)  ///
	se one compress nolz eqlabels(none) nobase
eststo clear

***	#5: T3. Marginal effects of refusal justifcation
estimates restore m2
margins conrace#conrelig, predict(xb) post
qui mlincom 1-2, clear rown(white) stats(e p se)
qui mlincom 3-4, add rown(black) stats(e p se)
qui mlincom 5-6, add rown(latinx) stats(e p se)
qui mlincom 7-8, add rown(asian) stats(e p se)

qui mlincom (1-2)-(3-4), add rown(wvb) stats(e p se)
qui mlincom (1-2)-(5-6), add rown(wvl) stats(e p se)
qui mlincom (1-2)-(7-8), add rown(wva) stats(e p se)

qui mlincom (3-4)-(5-6), add rown(bvl) stats(e p se)
qui mlincom (3-4)-(7-8), add rown(bva) stats(e p se)
qui mlincom (5-6)-(7-8), add rown(lva) stats(e p se)
mlincom, stats(e p se)

***	#6: T4. Distribution of prominent codes
mean `codes' if sample [aw=svy]		// overall prevalence
mean `codes' if sample [aw=svy], over(conrace conrelig)	// by condition

foreach var of varlist `codes' {
	logit `var' conrace##conrelig `controls' if sample [pw=svy]
	margins conrace#conrelig, post
	qui mlincom 1-2, clear rown(white) stats(e p se)
	qui mlincom 3-4, add rown(black) stats(e p se)
	qui mlincom 5-6, add rown(latinx) stats(e p se)
	qui mlincom 7-8, add rown(asian) stats(e p se)
	qui mlincom 1-3, add rown(wvb_rel) stat(e p se)
	qui mlincom 1-5, add rown(wvl_rel) stat(e p se)
	qui mlincom 1-7, add rown(wva_rel) stat(e p se)
	qui mlincom (1-2)-(3-4), add rown(wvb) stats(e p se)
	qui mlincom (1-2)-(5-6), add rown(wvl) stats(e p se)
	qui mlincom (1-2)-(7-8), add rown(wva) stats(e p se)

	qui mlincom (3-4)-(5-6), add rown(bvl) stats(e p se)
	qui mlincom (3-4)-(7-8), add rown(bva) stats(e p se)
	qui mlincom (5-6)-(7-8), add rown(lva) stats(e p se)
	mlincom, stats(e p se)
}

***	#7: F1. Distribution of denial support
estimates restore m1
margins conrelig#conrace#congend
//	export these predicted values and graph. We used Excel.

***	#8: F2. y*
estimates restore m2
margins conrace#conrelig, predict(xb) post
coefplot, ylabel(1 "White Patient Inadequate Training" ///
2 "White Patient Religious Objection" 3 "Black Patient Inadequate Training" ///
4 "Black Patient Religious Objection" 5 "Latinx Patient Inadequate Training" ///
6 "Latinx Patient Religious Objection" 7 "Asian Patient Inadequate Training" ///
8 "Asian Patient Religious Objection") level(68) // plot standard error

graph export `pgm'_2way.png, replace wid(1200)

***	close
log close
exit
