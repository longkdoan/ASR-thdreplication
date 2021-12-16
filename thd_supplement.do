capture log close
log using thd_supplement.log, replace text

/*
task:		ASR analyses for replication materials
project:	THD
author:		lkd 20211215
*/

version 17
clear all
macro drop _all
set linesize 80

local pgm "thd_supplement"
set scheme cleanplots	// (https://www.trentonmize.com/software/cleanplots)

*** #1: open data *** see notes in main do file
use thd_qualmerged, clear

***	#2: define locals ***
//	controls to be used in models
local controls "female straight i.raceV2 age i.educV3 inc50k married"
local controls "`controls' i.rel i.repub metro i.knowgay i.knowtrans required"
mark sample
markout sample denial `controls'

//	qualitative codes
local codes "charge disc docbias duty freedom hormones irrelevant lacktrain"
local codes "`codes' liability market moreinfo nonemer nonrelig patient"
local codes "`codes' interest referral religious right sexualitycode transphobic urgent"

***	#3: TS1. unweighted models without controls
eststo: ologit denial conrelig##congend##conrace if sample

***	#4: TS2. unweighted models with controls
eststo: ologit denial conrelig##congend##conrace `controls' if sample

esttab using `pgm'_T1-2.rtf, replace ///
    b(%12.2f) nogaps star(+ .10 * 0.05 ** 0.01 *** 0.001)  ///
	se one compress nolz eqlabels(none) nobase
eststo clear

***	#5: FS3. 3-way y*
qui ologit denial conrelig##congend##conrace `controls' [pw=svyweight] if sample
margins conrace#conrelig#congend, predict(xb) post

coefplot, xline(0) omitted ylabel(1 "White Trans Man Inadequate Training" ///
2 "White Trans Woman Inadequate Training" 3 "White Trans Man Religious Objection" ///
4 "White Trans Woman Religious Objection" 5 "Black Trans Man Inadequate Training" ///
6 "Black Trans Woman Inadequate Training" 7 "Black Trans Man Religious Objection" ///
8 "Black Trans Woman Religious Objection" 9 "Latino Trans Man Inadequate Training" ///
10 "Latina Trans Woman Inadequate Training" 11 "Latino Trans Man Religious Objection" ///
12 "Latina Trans Woman Religious Objection" 13 "Asian Trans Man Inadequate Training" ///
14 "Asian Trans Woman Inadequate Training" 15 "Asian Trans Man Religious Objection" ///
16 "Asian Trans Woman Religious Objection") level(68) // plot standard errors

graph export `pgm'_3way.png, replace wid(1200)

***	#6: TS4. full qualitative codes
mean `codes' if sample [aw=svy]		// overall prevalence

***	#7: TS5. promninent codes by denial support
gen denialB = (denial>2 & !missing(denial))

local codes "charge disc docbias duty freedom hormones irrelevant lacktrain"
local codes "`codes' liability market moreinfo nonemer nonrelig patient"
local codes "`codes' interest referral religious right sexualitycode transphobic urgent"

mean `codes' if sample [aw=svyweight], over(denialB)

***	close
log close
exit
