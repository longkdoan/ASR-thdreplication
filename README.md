# Replication Materials for "Factors Affecting Public Opinion on the Denial of Healthcare to Transgender Persons"
This page contains necessary files to replicate the findings presented in “Factors Affecting Public Opinion on the Denial of Healthcare to Transgender Persons,” and in the online supplement to the article. Feel free to contact longdoan (at) umd (dot) edu with questions.

[Data](thd_qualmerged.dta)

We use Stata 17 for the analyses. The dataset provided here includes merged in qualitative coding we did on the open-ended responses. The raw data without these codes and data cleaning we did will be available from the TESS website in SPSS format. The included do-files contain instructions on cleaning the original dataset once it is converted to Stata format.

[Main analysis](thd_mainanalyses.do)

This is a do-file for the main analyses presented in the paper. It requires the following user-written commands. Use the ```findit``` command to download these user-written packages:
- ```esttab```
- ```spost13```
- ```coefplot```

[Online supplement](thd_supplement.do)

This is a do-file for the online supplement for the paper. It requires the following user-written commands. Use the ```findit``` command to download these user-written packages:
- ```esttab```
- ```spost13```
- ```coefplot```

We use the graphic scheme ```cleanplots``` by [Trent Mize](https://www.trentonmize.com/software/cleanplots). It's not required to run the do-files, but the graphs will look better than the default graphing scheme.
