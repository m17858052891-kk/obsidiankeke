*! 1.1.0 Ariel Linden 08Nov2026	// fixed factor-variable (i.) covariates: lowest non-base level was omitted
*! 1.0.0 Ariel Linden 05Nov2026

program mmwsmed, eclass
	version 15

	* internal entry point used by -bootstrap- (subprograms are not visible to the prefix)
	gettoken first rest : 0
	if `"`first'"' == "_est" {
		_mmwsmed_est `rest'
		exit
	}
	if `"`first'"' == "_cest" {
		_mmwsmed_cest `rest'
		exit
	}

	if replay() {
		if "`e(cmd)'" != "mmwsmed" error 301
		syntax [, Level(cilevel) LEGend DIAGnostics COEFLegend * ]
		* -bootstrap- may replay before mmwsmed has restored its own e() results
		if "`e(med_type)'" == "" exit
		_mmwsmed_display, level(`level') `legend' `diagnostics' `coeflegend'
		exit
	}

	* split the equations from the rest
	local cmdline `"mmwsmed `0'"'
	local neq 0
	gettoken eq rest : 0, match(paren)
	while "`paren'" == "(" {
		local ++neq
		local eq`neq' `"`eq'"'
		local 0 `"`rest'"'
		gettoken eq rest : 0, match(paren)
	}
	if !inlist(`neq', 3, 4) {
		di as err "mmwsmed requires 3 equations, (ovar ...) (mvar ...) (tvar ...), or 4 with two mediators"
		exit 198
	}

	* heteroskedastic may be given a varlist for the variance: heteroskedastic(varlist)
	local hetvars
	if regexm(`"`0'"', "(^|[ ,])(het[a-z]*)[(]([^)]*)[)]") {
		local hw0 = regexs(0)
		local hw1 = regexs(1)
		local hw  = regexs(2)
		local hwv = regexs(3)
		if strpos("heteroskedastic", "`hw'") == 1 {
			local hetvars `hwv'
			local 0 : subinstr local 0 `"`hw0'"' `"`hw1'`hw'"'
			if "`hetvars'" == "" {
				di as err "heteroskedastic() requires a varlist; specify heteroskedastic without parentheses to use the mediator covariates"
				exit 198
			}
		}
	}
	syntax [if] [in] [pweight] [,										///
		NIE NDE TE PNIE TNDE INT POMeans ALL							/// statistics
		PARallel SEQuential												/// two-mediator designs
		CONtrol(string)													/// control level of tvar
		MWeight(string) OTerms(string)									/// ratio (default) or odds weights
		NONParametric STRata(numlist integer min=2 max=2 >=2)			/// MMWS-based (stratified) RMPW
		COMmon CALiper(real 0.2) NMIN(integer 1) 						/// common support / strata cells
		MODerator(varname numeric)										/// moderated mediation
		HETeroskedastic DIAGnostics										///
		VCE(string) Level(cilevel) LEGend COEFLegend					///
		GENerate(name) REPLace AEQuations NOIsily KNOWNweights ]

	* outcome equation
	_parse comma lhs rhs : eq1
	local om
	if `"`rhs'"' != "" {
		gettoken comma om : rhs, parse(",")
		local om = strtrim(lower(`"`om'"'))
	}
	if "`om'" == "" local om linear
	if inlist("`om'", "lin", "line", "linea", "linear", "reg", "regr", "regre", "regres", "regress") local om linear
	if inlist("`om'", "pois", "poiss", "poisso") local om poisson
	if !inlist("`om'", "linear", "logit", "probit", "poisson") {
		di as err "outcome model must be {bf:linear}, {bf:logit}, {bf:probit}, or {bf:poisson}"
		exit 198
	}
	gettoken depvar indepvars : lhs
	confirm numeric variable `depvar'

	* mediator equation(s)
	local K = `neq' - 2
	local mediator
	local mmodel
	forvalues k = 1/`K' {
		local e = `k' + 1
		_parse comma lhs rhs : eq`e'
		gettoken mv mc : lhs
		confirm numeric variable `mv'
		local mediator `mediator' `mv'
		local mcov`k' `mc'
		gettoken comma mm : rhs, parse(",")
		local mm = strtrim(lower(`"`mm'"'))
		if "`mm'" == "" {
			local mm linear
			capture assert inlist(`mv', 0, 1) if !missing(`mv')
			if !_rc {
				di as txt "note: {bf:`mv'} is a 0/1 variable but no mediator model was specified; the default"
				di as txt "      {bf:linear} model uses a normal density. Specify {bf:logit} or {bf:probit} for a binary mediator."
			}
		}
		if inlist("`mm'", "lin", "line", "linea", "linear", "reg", "regr", "regre", "regres", "regress") local mm linear
		if inlist("`mm'", "pois", "poiss", "poisso") local mm poisson
		if !inlist("`mm'", "logit", "probit", "ologit", "mlogit", "linear", "poisson") {
			di as err "mediator model must be {bf:logit}, {bf:probit}, {bf:ologit}, {bf:mlogit}, {bf:linear}, or {bf:poisson}"
			exit 198
		}
		local mmodel `mmodel' `mm'
	}

	* treatment equation
	_parse comma lhs rhs : eq`neq'
	gettoken treat tcov : lhs
	confirm numeric variable `treat'
	_mmwsmed_teq `rhs'
	local tmethod `s(tmethod)'
	local tstrata `s(tstrata)'
	local tmodel `s(tmodel)'
	local thet `s(thet)'
	local tcont `s(tcont)'
	local bwidth `s(bwidth)'
	local tctrim `s(trim)'
	local lognormal `s(lognormal)'

	* design (parallel or sequential)
	if `K' == 1 {
		if "`parallel'`sequential'" != "" {
			di as err "options {bf:parallel} and {bf:sequential} require two mediator equations"
			exit 198
		}
		local design single
	}
	else {
		if "`parallel'" != "" & "`sequential'" != "" {
			di as err "options {bf:parallel} and {bf:sequential} may not be combined"
			exit 198
		}
		local design = cond("`sequential'" != "", "sequential", "parallel")
	}

	* statistics
	local stats `nie' `nde' `te' `pnie' `tnde' `int' `pomeans'
	if "`all'" != "" local stats all
	if "`stats'" == "" local stats default

	* vce()
	local vcetype robust
	local clustvar
	local bsopts
	if `"`vce'"' != "" {
		gettoken vt vrest : vce, parse(" ,")
		local vt = lower("`vt'")
		if inlist("`vt'", "r", "ro", "rob", "robu", "robus", "robust") {
			local vcetype robust
		}
		else if inlist("`vt'", "cl", "clu", "clus", "clust", "cluste", "cluster") {
			local vcetype cluster
			gettoken clustvar : vrest
			capture confirm numeric variable `clustvar'
			if _rc {
				di as err "vce(cluster {it:clustvar}) requires a numeric cluster variable"
				exit 198
			}
		}
		else if inlist("`vt'", "two", "twos", "twost", "twoste", "twostep") {
			* former name of the default (undocumented synonym)
			local vcetype robust
		}
		else if inlist("`vt'", "boot", "boots", "bootst", "bootstr", "bootstra", "bootstrap") {
			local vcetype bootstrap
			gettoken comma bsopts : vrest, parse(",")
			if "`comma'" != "," local bsopts `comma' `bsopts'
		}
		else {
			di as err "vce() must be {bf:robust}, {bf:cluster} {it:clustvar}, or {bf:bootstrap} [{bf:,} {it:bootstrap_options}]"
			exit 198
		}
	}

	* continuous treatment: GPS weighting
	if "`tcont'" != "" {
		local bad
		if `K' != 1                   local bad `"`bad' "two mediators""'
		if "`indepvars'" != ""        local bad `"`bad' "outcome covariates""'
		if "`moderator'" != ""        local bad `"`bad' "moderator()""'
		if "`nonparametric'" != ""    local bad `"`bad' "nonparametric""'
		if "`mweight'" != ""          local bad `"`bad' "mweight()""'
		if `"`oterms'"' != ""         local bad `"`bad' "oterms()""'
		if "`tmodel'" != ""           local bad `"`bad' "a treatment model""'
		if "`common'" != ""           local bad `"`bad' "common""'
		if "`heteroskedastic'" != ""  local bad `"`bad' "heteroskedastic""'
		if `"`control'"' != ""        local bad `"`bad' "control()""'
		if "`generate'" != ""         local bad `"`bad' "generate()""'
		if `"`bad'"' != "" {
			local msg
			local sep
			foreach b of local bad {
				local msg `"`msg'`sep'`b'"'
				local sep ", "
			}
			di as err `"with {bf:continuous()}, the following are not allowed: `msg'"'
			exit 198
		}
		if !inlist("`vcetype'", "robust", "bootstrap", "cluster") {
			di as err "with {bf:continuous()}, std. err. are bootstrapped: specify vce(bootstrap) or vce(cluster {it:clustvar})"
			exit 198
		}
		if "`diagnostics'" != "" di as txt "note: diagnostics are not available with a continuous treatment"
		* GPS covariates
		local gpscov : list tcov | mcov1
		local mm : word 1 of `mmodel'
		local mterm `mediator'
		if inlist("`mm'", "ologit", "mlogit") local mterm i.`mediator'
		marksample touse, novarlist
		local cvars `depvar' `treat' `mediator' `gpscov' `clustvar'
		local cbase
		foreach v of local cvars {
			fvrevar `v', list
			local cbase `cbase' `r(varlist)'
		}
		markout `touse' `cbase'
		if "`weight'" != "" {
			tempvar cw
			qui gen double `cw' `exp' if `touse'
			markout `touse' `cw'
		}
		else {
			tempvar cw
			qui gen double `cw' = 1 if `touse'
		}
		qui count if `touse'
		if r(N) == 0 error 2000
		if "`lognormal'" != "" {
			capture assert `treat' > 0 if `touse'
			if _rc {
				di as err "option {bf:lognormal} requires a positive treatment"
				exit 459
			}
		}
		* bandwidth: rule of thumb sd(T) x 2.34/n^(1/4) (Epanechnikov kernel), fixed across bootstrap samples
		if `bwidth' <= 0 {
			qui summarize `treat' [aw=`cw'] if `touse'
			local bwidth = r(sd)*2.34/(r(N)^0.25)
		}
		local copt treat(`treat') mterm(`mterm') levels(`tcont') bw(`bwidth') trim(`tctrim') stats(`stats') uwvar(`cw') `lognormal'
		if `"`gpscov'"' != "" local copt `copt' x(`gpscov')
		* point estimates
		_mmwsmed_cest `depvar' if `touse', `copt'
		local ntrim = e(N_trim)
		local ceff `e(stats)'
		local ccop `e(copies)'
		* bootstrap std. err. (vce(cluster) resamples clusters)
		local 0 `", `bsopts'"'
		capture syntax [, Reps(integer 500) SEED(string) NODots DOTS ]
		if !_rc {
			tempname cb CL Lm bb VV BBc
			matrix `cb' = e(b)
			local cnames : colfullnames `cb'
			local C : word count `ccop'
			local p = colsof(`cb')
			matrix `Lm' = J(`C', `p', 0)
			local j 0
			foreach nm of local cnames {
				local ++j
				gettoken eq rest : nm, parse(":")
				local rest = substr("`rest'", 2, .)
				if "`eq'" == "POmeans" {
					local i : list posof "`rest'" in ccop
					matrix `Lm'[`i', `j'] = 1
					continue
				}
				local t = real(regexr(regexr("`rest'", "^r", ""), "vs0[.].*$", ""))
				local itt : list posof "Y`t'M`t'" in ccop
				local it0 : list posof "Y`t'M0" in ccop
				local i00 : list posof "Y0M0" in ccop
				local i0t : list posof "Y0M`t'" in ccop
				if "`eq'" == "NIE"  local pairs `itt' 1 `it0' -1
				if "`eq'" == "NDE"  local pairs `it0' 1 `i00' -1
				if "`eq'" == "TE"   local pairs `itt' 1 `i00' -1
				if "`eq'" == "PNIE" local pairs `i0t' 1 `i00' -1
				if "`eq'" == "TNDE" local pairs `itt' 1 `i0t' -1
				if "`eq'" == "INT"  local pairs `itt' 1 `it0' -1 `i0t' -1 `i00' 1
				while "`pairs'" != "" {
					gettoken i pairs : pairs
					gettoken sg pairs : pairs
					matrix `Lm'[`i', `j'] = `Lm'[`i', `j'] + `sg'
				}
			}
			* plain variables for Mata (factor-variable expansion of the mediator and covariates)
			qui fvrevar `mterm' if `touse'
			local mplain `r(varlist)'
			local xplain
			if `"`gpscov'"' != "" {
				qui fvrevar `gpscov' if `touse'
				local xplain `r(varlist)'
			}
			if "`seed'" != "" set seed `seed'
			local cl
			if "`vcetype'" == "cluster" local cl `clustvar'
			mata: mmw_cont_boot("`touse'", "`depvar'", "`treat'", `="`lognormal'" != ""', "`mplain'", "`xplain'", ///
				"`cw'", strtoreal(tokens("`tcont'")), `bwidth', `tctrim', `reps', "`cl'", `="`nodots'" == ""', ///
				"`Lm'", "`bb'", "`VV'", "`BBc'")
			matrix `bb' = `cb'
			matrix colnames `VV' = `cnames'
			matrix rownames `VV' = `cnames'
			* post through -bstat- (percentile and bias-corrected CIs for estat bootstrap); fall back to ereturn post
			capture _mmwsmed_bsci `bb' `BBc' `mmw_n' `level' `touse'
			if _rc {
				di as txt "note: bootstrap percentile and bias-corrected CIs are not available (r(" _rc "))"
				ereturn post `bb' `VV', esample(`touse') obs(`mmw_n')
			}
			ereturn local prefix "bootstrap"
			ereturn local vce "bootstrap"
			ereturn local vcetype "Bootstrap"
			ereturn scalar N_reps = `mmw_nreps'
			ereturn scalar N_misreps = `mmw_nmis'
			if "`cl'" != "" {
				ereturn scalar N_clust = `mmw_nclust'
				ereturn local clustvar "`cl'"
			}
		}
		else {
			if "`vcetype'" == "cluster" local bsopts cluster(`clustvar') `bsopts'
			local hasreps = strpos(" `bsopts'", " reps(") | strpos(" `bsopts'", " rep(") | strpos(" `bsopts'", " re(")
			if !`hasreps' local bsopts reps(500) `bsopts'
			bootstrap _b, `bsopts' notable noheader nolegend : mmwsmed _cest `depvar' if `touse', `copt'
		}
		ereturn scalar N_trim = `ntrim'
		ereturn scalar bwidth = `bwidth'
		ereturn scalar trim = `tctrim'
		ereturn local tvar "`treat'"
		ereturn local tvartype "continuous"
		ereturn local tlevels "`tcont'"
		local d0 : word 1 of `tcont'
		ereturn local control "`d0'"
		ereturn local depvar "`depvar'"
		ereturn local mvar "`mediator'"
		ereturn local mmodel "gps"
		ereturn local med_type "single"
		ereturn local method "gps"
		ereturn local gpsmodel = cond("`lognormal'" != "", "lognormal", "normal")
		ereturn local gpscov "`gpscov'"
		ereturn local stats "`ceff'"
		ereturn local copies "`ccop'"
		ereturn local title "Causal mediation analysis: GPS weighting"
		if "`weight'" != "" {
			ereturn local wtype "`weight'"
			ereturn local wexp "`exp'"
		}
		ereturn local cmdline `"`cmdline'"'
		ereturn local cmd "mmwsmed"
		_mmwsmed_display, level(`level') `legend' `coeflegend'
		exit
	}

	* options for the estimation engine
	local opts treat(`treat') mediator(`mediator') mmodel(`mmodel') omodel(`om') design(`design') stats(`stats')
	if `"`mcov1'"' != ""    local opts `opts' mcova(`mcov1')
	if `"`mcov2'"' != ""    local opts `opts' mcovb(`mcov2')
	if `"`tcov'"' != ""     local opts `opts' tcov(`tcov') tmethod(`tmethod') tstrata(`tstrata')
	if "`tmodel'" != ""     local opts `opts' tmodel(`tmodel')
	if "`thet'" != ""       local opts `opts' thet(`thet')
	if `"`control'"' != ""  local opts `opts' control(`control')
	if `"`mweight'"' != ""  local opts `opts' mweight(`mweight')
	if `"`oterms'"' != ""   local opts `opts' oterms(`oterms')
	if "`strata'" != ""     local opts `opts' strata(`strata')
	if "`moderator'" != ""  local opts `opts' moderator(`moderator')
	if "`clustvar'" != ""   local opts `opts' clustvar(`clustvar')
	* robust and cluster std. err. account for estimation of the weights (M-estimation sandwich)
	if inlist("`vcetype'", "robust", "cluster") & "`knownweights'" == "" local opts `opts' twostep
	local opts `opts' caliper(`caliper') nmin(`nmin') `nonparametric' `common' `heteroskedastic'
	if "`hetvars'" != ""    local opts `opts' hetvars(`hetvars')
	local genopt
	if "`generate'" != "" local genopt generate(`generate') `replace'
	local noi
	if "`aequations'`noisily'" != "" local noi noisily
	local wgt
	if "`weight'" != "" local wgt [`weight'`exp']

	if "`vcetype'" != "bootstrap" {
		_mmwsmed_est `depvar' `indepvars' `if' `in' `wgt', `opts' `diagnostics' `noi' `genopt'
	}
	else {
		* sampling weights travel with the resampled observations as a variable
		if "`weight'" != "" {
			tempvar bsw
			qui gen double `bsw' `exp'
			local opts `opts' uwvar(`bsw')
		}
		* full-sample run
		_mmwsmed_est `depvar' `indepvars' `if' `in', `opts' `diagnostics' `noi' `genopt'
		local myscalars N_treat N_control N_excl N_excl_tw N_excl_support N_excl_strata N_excl_miss ///
			N_stack k_copies k_levels caliper ctl_df
		local mymacros depvar omodel tvar mvar mvar1 mvar2 mmodel mmodel1 mmodel2 mweight oterms med_type method ///
			strata mcov1 mcov2 indepvars tcov tmethod tmodel thet tlevels control tvartype moderator mlevels ///
			stats copies title heteroskedastic hetvars
		foreach s of local myscalars {
			if !inlist("`e(`s')'", "", ".") local S_`s' = e(`s')
		}
		foreach m of local mymacros {
			local M_`m' `"`e(`m')'"'
		}
		foreach mat in mcheck balance wdiag ctl_b ctl_V {
			tempname H_`mat'
			local has_`mat' 0
			capture confirm matrix e(`mat')
			if !_rc {
				matrix `H_`mat'' = e(`mat')
				local has_`mat' 1
			}
		}

		tempname bobs
		matrix `bobs' = e(b)
		local Nfull = e(N)
		tempvar bsfin bsid
		qui gen byte `bsfin' = e(sample)
		qui gen long `bsid' = _n

		* fast bootstrap replications in Mata
		local if0 `"`if'"'
		local in0 `"`in'"'
		local wt0 `"`weight'"'
		local ex0 `"`exp'"'
		local bsfast 0
		local bsnote
		local 0 `", `bsopts'"'
		capture syntax [, Reps(integer 50) SEED(string) NODots DOTS CLuster(varname numeric) ]
		if _rc local bsnote "bootstrap options"
		else if strpos(" `mmodel' ", " mlogit ") & "`common'" != "" local bsnote "mlogit mediator with common"
		if "`bsnote'" == "" {
			tempname bref VV BBm
			capture _mmwsmed_est `depvar' `indepvars' if `bsfin', `opts' bootrep mbspec
			if _rc local bsnote "engine run on the estimation sample failed (r(`=_rc'))"
			else {
				matrix `bref' = e(b)
				local mmw_bsok 0
				local mmw_bsdif .
				capture mata: mmw_dcheck("`bref'", 1e-6)
				if _rc local bsnote "Mata engine error (r(`=_rc'))"
				else if "`mmw_bsok'" != "1" local bsnote "Mata estimates differ from the ado-file estimates (max. abs. diff. `mmw_bsdif')"
			}
		}
		if "`bsnote'" == "" {
			if "`cluster'" != "" mata: mmw_bs_put("bscl", "`cluster'", "`bsfin'", "`bsid'")
			if "`seed'" != "" set seed `seed'
			capture noisily mata: mmw_dboot(`reps', `="`cluster'" != ""', `="`nodots'" == ""', "`VV'", "`BBm'")
			if _rc local bsnote "Mata engine error during the replications (r(`=_rc'))"
			else local bsfast 1
		}
		local if `"`if0'"'
		local in `"`in0'"'
		local weight `"`wt0'"'
		local exp `"`ex0'"'

		if `bsfast' {
			local cn : colfullnames `bobs'
			matrix colnames `VV' = `cn'
			matrix rownames `VV' = `cn'
			* post through -bstat- (percentile and bias-corrected CIs for estat bootstrap); fall back to ereturn post
			capture _mmwsmed_bsci `bobs' `BBm' `Nfull' `level' `bsfin'
			if _rc {
				di as txt "note: bootstrap percentile and bias-corrected CIs are not available (r(" _rc "))"
				ereturn post `bobs' `VV', esample(`bsfin') obs(`Nfull') depname(`depvar')
			}
			else ereturn local depvar "`depvar'"
			ereturn local prefix "bootstrap"
			ereturn local vce "bootstrap"
			ereturn local vcetype "Bootstrap"
			ereturn scalar N_reps = `mmw_nreps'
			ereturn scalar N_misreps = `mmw_nmis'
			if "`cluster'" != "" {
				ereturn scalar N_clust = `mmw_nclust'
				ereturn local clustvar "`cluster'"
			}
			ereturn local bs_engine "mata"
			ereturn local bs_check "`mmw_bsdif'"
		}
		else {
			bootstrap _b, `bsopts' notable noheader nolegend :	///
				mmwsmed _est `depvar' `indepvars' `if' `in', `opts' bootrep
			ereturn local bs_engine "prefix"
			ereturn local bs_fallback `"`bsnote'"'
		}

		foreach s of local myscalars {
			if "`S_`s''" != "" ereturn scalar `s' = `S_`s''
		}
		foreach m of local mymacros {
			if `"`M_`m''"' != "" ereturn local `m' `"`M_`m''"'
		}
		foreach mat in mcheck balance wdiag ctl_b ctl_V {
			if `has_`mat'' ereturn matrix `mat' = `H_`mat''
		}
	}
	if "`weight'" != "" {
		ereturn local wtype "`weight'"
		ereturn local wexp "`exp'"
	}
	ereturn local cmdline `"`cmdline'"'
	ereturn local cmd "mmwsmed"

	_mmwsmed_display, level(`level') `legend' `diagnostics' `coeflegend'
end


************************************
* options of the treatment equation
************************************
program _mmwsmed_teq, sclass
	version 15
	syntax [, TMethod(string) TSTRata(integer 5) LOGit PRobit HETprobit(varlist numeric fv) MLOGit OLOGit OPRobit ///
		CONTinuous(numlist min=2) BWidth(real -1) TRIM(real 0.1) LOGNormal ]
	* continuous treatment (generalized propensity score weighting; Hsu, Huber, Lee, and Lettry 2020)
	sreturn local tcont `continuous'
	sreturn local bwidth `bwidth'
	sreturn local trim `trim'
	sreturn local lognormal `lognormal'
	if "`continuous'" == "" & ("`lognormal'" != "" | `bwidth' != -1 | `trim' != 0.1) {
		di as err "options {bf:bwidth()}, {bf:trim()}, and {bf:lognormal} require {bf:continuous()}"
		exit 198
	}
	if `trim' <= 0 | `trim' > 1 {
		di as err "trim() must be in (0, 1]"
		exit 198
	}
	* treatment model (binary: logit, probit, hetprobit(); multivalued: mlogit; ordinal: ologit, oprobit)
	local tmodel `logit' `probit' `mlogit' `ologit' `oprobit'
	if "`hetprobit'" != "" local tmodel `tmodel' hetprobit
	if `: word count `tmodel'' > 1 {
		di as err "only one treatment model may be specified: {bf:`tmodel'}"
		exit 198
	}
	sreturn local tmodel `tmodel'
	sreturn local thet `hetprobit'
	if "`tmethod'" == "" local tmethod iptw
	local tmethod = lower("`tmethod'")
	if !inlist("`tmethod'", "iptw", "mmws") {
		di as err "tmethod() must be {bf:iptw} or {bf:mmws}"
		exit 198
	}
	if `tstrata' < 2 {
		di as err "tstrata() must be at least 2"
		exit 198
	}
	sreturn local tmethod `tmethod'
	sreturn local tstrata `tstrata'
end


********************
* estimation engine
********************
program _mmwsmed_est, eclass sortpreserve
	version 15
	syntax varlist(min=1 numeric fv) [if] [in] [pweight],					///
		TReat(varname numeric) MEDiator(varlist numeric min=1 max=2)		///
		MModel(string) DESign(string) STATs(string)							///
		[ OMODel(string)													///
		MCOVA(varlist numeric fv) MCOVB(varlist numeric fv)					///
		TCOV(varlist numeric fv) TMethod(string) TSTRata(integer 5)			///
		TMODel(string) THET(varlist numeric fv)								///
		CONtrol(string) MWeight(string) OTerms(string)						///
		NONParametric STRata(numlist integer min=2 max=2 >=2)				///
		COMmon CALiper(real 0.2) NMIN(integer 1)							///
		MODerator(varname numeric) HETeroskedastic DIAGnostics				///
		CLUSTvar(varname) GENerate(name) REPLace NOIsily TWOSTEP BOOTREP	///
		UWVar(varname) MBSPEC HETVars(varlist numeric fv) ]

	* sampling weights passed as a variable (vce(bootstrap) with pweights)
	if "`uwvar'" != "" {
		local weight pweight
		local exp "= `uwvar'"
	}
	local qui quietly
	local noiopt
	if "`noisily'" != "" & "`bootrep'" == "" {
		local qui noisily
		local noiopt noisily
	}

	gettoken depvar indepvars : varlist
	_fv_check_depvar `depvar'
	if "`omodel'" == "" local omodel linear
	local mcov1 `mcova'
	local mcov2 `mcovb'

	marksample touse
	tempvar obsid
	qui gen long `obsid' = _n
	local covbase
	foreach cl in mcov1 mcov2 tcov thet hetvars {
		local `cl'base
		if "``cl''" != "" {
			fvrevar ``cl'', list
			local `cl'base `r(varlist)'
		}
	}
	markout `touse' `treat' `mediator' `mcov1base' `mcov2base' `tcovbase' `thetbase' `hetvarsbase' `moderator' `clustvar' `uwvar'
	qui count if `touse'
	if r(N) == 0 error 2000
	if inlist("`omodel'", "logit", "probit") {
		capture assert `depvar' >= 0 & `depvar' <= 1 if `touse'
		if _rc {
			di as err "outcome model {bf:`omodel'} requires `depvar' to be a 0/1 (or fractional) variable"
			exit 450
		}
	}
	if "`omodel'" == "poisson" {
		capture assert `depvar' >= 0 if `touse'
		if _rc {
			di as err "outcome model {bf:poisson} requires `depvar' to be nonnegative"
			exit 459
		}
	}

	local K : word count `mediator'
	local m1 : word 1 of `mediator'
	local m2 : word 2 of `mediator'

	* roles
	if `: list treat in mediator' | `: list depvar in mediator' | "`depvar'" == "`treat'" {
		di as err "the outcome, treatment, and mediator variables must be distinct"
		exit 198
	}
	if "`m1'" == "`m2'" {
		di as err "the two mediators must be different variables"
		exit 198
	}
	local ixbase
	if "`indepvars'" != "" {
		fvrevar `indepvars', list
		local ixbase `r(varlist)'
	}
	foreach v in `treat' `mediator' {
		if `: list v in ixbase' {
			di as err "{bf:`v'} may not be included among the outcome-equation covariates"
			exit 198
		}
		if `: list v in mcov1base' | `: list v in mcov2base' | `: list v in tcovbase' {
			di as err "{bf:`v'} may not be included among the mediator- or treatment-equation covariates"
			exit 198
		}
	}
	foreach cl in mcov1base mcov2base tcovbase {
		if `: list depvar in `cl'' {
			di as err "the outcome may not be included among the mediator- or treatment-equation covariates"
			exit 198
		}
	}
	if `K' == 1 & "`mcov1'" == "" | `K' == 2 & ("`mcov1'" == "" | "`mcov2'" == "") {
		di as txt "note: a mediator equation contains no covariates; mediator-outcome confounding is not adjusted"
	}

	* treatment levels
	capture assert `treat' == int(`treat') & `treat' >= 0 if `touse'
	if _rc {
		di as err "treatment variable {bf:`treat'} must contain nonnegative integers"
		exit 450
	}
	qui levelsof `treat' if `touse', local(tlev)
	local L : word count `tlev'
	if `L' < 2 {
		di as err "treatment variable {bf:`treat'} must have at least two levels"
		exit 459
	}
	if `L' > 10 {
		di as err "treatment variable {bf:`treat'} has more than 10 levels"
		exit 459
	}
	* control level: a value or a value label
	if `"`control'"' == "" {
		local cval : word 1 of `tlev'
	}
	else {
		local cval
		if real(`"`control'"') < . {
			local cval = real(`"`control'"')
		}
		else {
			local vl : value label `treat'
			if "`vl'" != "" {
				foreach l of local tlev {
					local lab : label `vl' `l'
					if `"`lab'"' == `"`control'"' local cval `l'
				}
			}
		}
		if "`cval'" == "" | !`: list cval in tlev' {
			di as err "control(`control') is not a level of {bf:`treat'}"
			exit 198
		}
	}
	local cix : list posof "`cval'" in tlev
	tempvar tix tb
	qui gen byte `tix' = . if `touse'
	forvalues i = 1/`L' {
		local v`i' : word `i' of `tlev'
		qui replace `tix' = `i' if `touse' & `treat' == `v`i''
	}
	qui gen byte `tb' = (`tix' != `cix') if `touse'
	local tvartype = cond(`L' == 2, "binary", "multivalued")
	* treatment model
	if "`tmodel'" == "" local tmodel = cond(`L' == 2, "logit", "mlogit")
	if `L' == 2 & !inlist("`tmodel'", "logit", "probit", "hetprobit") {
		di as err "treatment {bf:`treat'} is binary: the treatment model must be {bf:logit}, {bf:probit}, or {bf:hetprobit()}"
		exit 198
	}
	if `L' > 2 & !inlist("`tmodel'", "mlogit", "ologit", "oprobit") {
		di as err "treatment {bf:`treat'} has `L' levels: the treatment model must be {bf:mlogit} (unordered categories)"
		di as err "or {bf:ologit} or {bf:oprobit} (ordinal treatment)"
		exit 198
	}
	if "`tmodel'" == "hetprobit" & "`thet'" == "" {
		di as err "{bf:hetprobit()} requires a variance varlist"
		exit 198
	}
	if "`tcov'" == "" & "`mweight'" != "odds" & !inlist("`tmodel'", "logit", "mlogit") {
		di as txt "note: the treatment model {bf:`tmodel'} is used only with treatment covariates or {bf:mweight(odds)}"
	}
	local tlist
	forvalues i = 1/`L' {
		if `i' != `cix' local tlist `tlist' `i'
	}

	* mediator model
	forvalues k = 1/`K' {
		local mm : word `k' of `mmodel'
		local mtype`k' `mm'
		local mcat`k' = inlist("`mm'", "logit", "probit", "ologit", "mlogit")
		if inlist("`mm'", "logit", "probit") {
			capture assert inlist(`m`k'', 0, 1) if `touse'
			if _rc {
				di as err "mediator {bf:`m`k''} must be coded 0/1 with the `mm' model"
				exit 450
			}
		}
		if inlist("`mm'", "ologit", "mlogit", "poisson") {
			capture assert `m`k'' == int(`m`k'') if `touse'
			if _rc {
				di as err "mediator {bf:`m`k''} must contain integer values with the `mm' model"
				exit 450
			}
		}
		if "`mm'" == "poisson" {
			capture assert `m`k'' >= 0 if `touse'
			if _rc {
				di as err "mediator {bf:`m`k''} must be nonnegative with the poisson model"
				exit 450
			}
		}
		local mlev`k'
		if `mcat`k'' {
			qui levelsof `m`k'' if `touse', local(mlev`k')
			local nlev : word count `mlev`k''
			if `nlev' < 2 {
				di as err "mediator {bf:`m`k''} does not vary"
				exit 459
			}
			if `nlev' > 20 {
				di as err "mediator {bf:`m`k''} has more than 20 levels; consider the linear or poisson model"
				exit 459
			}
		}
	}

	* weighting method and its restrictions
	if "`mweight'" == "" local mweight ratio
	local mweight = lower("`mweight'")
	if !inlist("`mweight'", "ratio", "odds") {
		di as err "mweight() must be {bf:ratio} or {bf:odds}"
		exit 198
	}
	if "`nonparametric'" != "" {
		if `K' > 1 {
			di as err "option {bf:nonparametric} requires a single mediator"
			exit 198
		}
		if !inlist("`mtype1'", "logit", "probit", "ologit") {
			di as err "option {bf:nonparametric} requires a logit, probit, or ologit mediator model"
			exit 198
		}
		if "`mweight'" == "odds" {
			di as err "options {bf:mweight(odds)} and {bf:nonparametric} may not be combined"
			exit 198
		}
		if "`strata'" == "" local strata 3 3
		local s1 : word 1 of `strata'
		local s0 : word 2 of `strata'
		local method nonparametric
	}
	else {
		if "`strata'" != "" {
			di as err "option {bf:strata()} may be specified only with {bf:nonparametric}"
			exit 198
		}
		local method parametric
	}
	if "`heteroskedastic'" != "" & "`mtype1'" != "linear" & "`mtype2'" != "linear" {
		di as err "option {bf:heteroskedastic} requires a linear mediator model"
		exit 198
	}
	if "`mweight'" == "odds" & "`heteroskedastic'" != "" {
		if "`bootrep'" == "" di as txt "note: option {bf:heteroskedastic} has no effect with {bf:mweight(odds)}, which uses no mediator density"
		local heteroskedastic
		local hetvars
	}
	if `"`oterms'"' != "" & "`mweight'" != "odds" {
		di as err "option {bf:oterms()} requires {bf:mweight(odds)}"
		exit 198
	}
	* the M-estimation adjustment needs smooth weights
	local wknown = "`twostep'" == ""
	local wstep 0
	if "`twostep'" != "" & ("`method'" == "nonparametric" | ("`tcov'" != "" & "`tmethod'" == "mmws")) {
		local twostep
		local wknown 1
		local wstep 1
	}
	if `caliper' < 0 {
		di as err "caliper() must be nonnegative"
		exit 198
	}
	if `nmin' < 1 {
		di as err "nmin() must be a positive integer"
		exit 198
	}

	* statistics
	if "`design'" == "single" {
		local e_all   NIE NDE TE PNIE TNDE INT
		local e_def   NIE NDE TE
		local s_nie   NIE
		local s_pnie  PNIE
		local s_tnde  TNDE
		local s_int   INT
	}
	else if "`design'" == "parallel" {
		local e_all   NIE NIE1_0 NIE1_1 NIE2_0 NIE2_1 NDE TE M1xM2
		local e_def   `e_all'
		local s_nie   NIE NIE1_0 NIE1_1 NIE2_0 NIE2_1
		local s_pnie
		local s_tnde
		local s_int   M1xM2
	}
	else {
		local e_all   NIE NIE1 NIE2 NDE TE PNIE1 PNIE2 M1xM2 ZxM1 ZxM2
		local e_def   `e_all'
		local s_nie   NIE NIE1 NIE2
		local s_pnie  PNIE1 PNIE2
		local s_tnde
		local s_int   M1xM2 ZxM1 ZxM2
	}
	local s_nde NDE
	local s_te  TE
	local wantpo 0
	if "`stats'" == "default" {
		local effects `e_def'
	}
	else if "`stats'" == "all" {
		local effects `e_all'
		local wantpo 1
	}
	else {
		local sel
		foreach s of local stats {
			if "`s'" == "pomeans" {
				local wantpo 1
				continue
			}
			if "`s_`s''" == "" {
				di as err "statistic {bf:`s'} is not available with `design' mediation"
				exit 198
			}
			local sel `sel' `s_`s''
		}
		* keep the canonical order
		local effects
		foreach e of local e_all {
			if `: list e in sel' local effects `effects' `e'
		}
	}

	* plain covariate lists (odds weights, two-step scores)
	forvalues k = 1/`K' {
		local XM`k' `mcov`k''
	}
	local XT `tcov'
	if "`mweight'" == "odds" | "`twostep'" != "" {
		forvalues k = 1/`K' {
			local XM`k'
			if "`mcov`k''" != "" {
				_mmwsmed_plain `mcov`k'' if `touse'
				qui fvrevar `r(terms)'
				local XM`k' `r(varlist)'
			}
		}
		if "`tcov'" != "" {
			_mmwsmed_plain `tcov' if `touse'
			qui fvrevar `r(terms)'
			local XT `r(varlist)'
		}
	}
	* variance covariates of hetprobit (plain variables, so that score designs match e(b))
	local XH
	if "`thet'" != "" {
		_mmwsmed_plain `thet' if `touse'
		qui fvrevar `r(terms)'
		local XH `r(varlist)'
	}
	* oterms()
	forvalues k = 1/2 {
		local OTw`k'
		local OTc`k'
	}
	if `"`oterms'"' != "" {
		_mmwsmed_plain `oterms' if `touse'
		foreach t in `r(terms)' {
			qui fvrevar `t'
			local v `r(varlist)'
			local h1 = regexm("`t'", "(^|[.#])`m1'($|#)")
			local h2 = 0
			if `K' == 2 local h2 = regexm("`t'", "(^|[.#])`m2'($|#)")
			if !`h1' & !`h2' {
				local OTc1 `OTc1' `v'
				local OTc2 `OTc2' `v'
			}
			else if `h1' & !`h2' {
				local OTw1 `OTw1' `v'
				if "`design'" == "sequential" local OTc2 `OTc2' `v'
			}
			else if `h2' & !`h1' {
				local OTw2 `OTw2' `v'
			}
			else if "`design'" == "sequential" {
				local OTw2 `OTw2' `v'
			}
			else {
				di as err "oterms(): term {bf:`t'} involves both mediators, which is not allowed with a parallel design"
				exit 198
			}
		}
	}
	if "`mweight'" == "odds" {
		forvalues k = 1/`K' {
			local mterm`k'
			if `mcat`k'' {
				local first : word 1 of `mlev`k''
				foreach l of local mlev`k' {
					if `l' == `first' continue
					tempvar dm
					qui gen byte `dm' = (`m`k'' == `l') if `touse'
					local mterm`k' `mterm`k'' `dm'
				}
			}
			else local mterm`k' `m`k''
		}
	}
	if "`twostep'" != "" mata: mmw_init()

	* moderator
	tempvar grp
	if "`moderator'" != "" {
		if `: list moderator in mediator' | "`moderator'" == "`treat'" | "`moderator'" == "`depvar'" {
			di as err "moderator() must differ from the outcome, treatment, and mediator variables"
			exit 198
		}
		capture assert `moderator' == int(`moderator') & `moderator' >= 0 if `touse'
		if _rc {
			di as err "moderator() variable must contain nonnegative integers"
			exit 450
		}
		qui levelsof `moderator' if `touse', local(glevels)
		if `: word count `glevels'' < 2 {
			di as err "moderator() variable must have at least two levels"
			exit 459
		}
		qui gen double `grp' = `moderator' if `touse'
	}
	else {
		local glevels 1
		qui gen byte `grp' = 1 if `touse'
	}
	local G : word count `glevels'

	* working variables
	tempvar uw tw excl ww
	if "`weight'" != "" {
		qui gen double `uw' `exp' if `touse'
	}
	else {
		qui gen double `uw' = 1 if `touse'
	}
	qui gen double `tw' = 1 if `touse'
	qui gen byte `excl' = 0 if `touse'
	qui gen double `ww' = .
	local nx_tw 0
	local nx_sup 0
	local nx_str 0
	local nx_miss 0
	forvalues k = 1/`K' {
		local fl`k'
		forvalues i = 1/`L' {
			tempvar f`k'_`i'
			qui gen double `f`k'_`i'' = .
			local fl`k' `fl`k'' `f`k'_`i''
		}
	}
	local tother : word 1 of `tlist'
	tempvar strat
	qui gen double `strat' = .
	* linear predictors of the mediator model under every treatment level (nonparametric RMPW)
	local lpalist
	if "`method'" == "nonparametric" {
		forvalues i = 1/`L' {
			tempvar lpa`i'
			qui gen double `lpa`i'' = .
			local lpalist `lpalist' `lpa`i''
		}
	}
	local xw
	if "`weight'`tcov'" != "" local xw [aw=`ww']
	local levidx
	forvalues i = 1/`L' {
		local levidx `levidx' `i'
	}

	* Mata bootstrap: store the data and covariate designs of this sample (expanded factor variables)
	if "`mbspec'" != "" {
		mata: mmw_bs_init()
		foreach bl in mcov1 mcov2 tcov indepvars {
			local B_`bl'
			if "``bl''" != "" {
				_mmwsmed_plain ``bl'' if `touse'
				if "`r(terms)'" != "" {
					qui fvrevar `r(terms)'
					local B_`bl' `r(varlist)'
				}
			}
		}
		local m2b `m2'
		if `K' == 1 local m2b `m1'
		mata: mmw_bs_put("y",    "`depvar'",       "`touse'", "`obsid'")
		mata: mmw_bs_put("tix",  "`tix'",          "`touse'", "`obsid'")
		mata: mmw_bs_put("grp",  "`grp'",          "`touse'", "`obsid'")
		mata: mmw_bs_put("uw",   "`uw'",           "`touse'", "`obsid'")
		mata: mmw_bs_put("m1",   "`m1'",           "`touse'", "`obsid'")
		mata: mmw_bs_put("m2",   "`m2b'",          "`touse'", "`obsid'")
		mata: mmw_bs_put("XT",   "`B_tcov'",       "`touse'", "`obsid'")
		mata: mmw_bs_put("XH",   "`XH'",           "`touse'", "`obsid'")
		mata: mmw_bs_put("XM1",  "`B_mcov1'",      "`touse'", "`obsid'")
		mata: mmw_bs_put("XM2",  "`B_mcov2'",      "`touse'", "`obsid'")
		mata: mmw_bs_put("OTc1", "`OTc1'",         "`touse'", "`obsid'")
		mata: mmw_bs_put("OTc2", "`OTc2'",         "`touse'", "`obsid'")
		mata: mmw_bs_put("OTw1", "`OTw1'",         "`touse'", "`obsid'")
		mata: mmw_bs_put("OTw2", "`OTw2'",         "`touse'", "`obsid'")
		mata: mmw_bs_put("xv",   "`B_indepvars'",  "`touse'", "`obsid'")
		local B_hv
		if "`hetvars'" != "" {
			_mmwsmed_plain `hetvars' if `touse'
			if "`r(terms)'" != "" {
				qui fvrevar `r(terms)'
				local B_hv `r(varlist)'
			}
		}
		mata: mmw_bs_put("HV",   "`B_hv'",         "`touse'", "`obsid'")
	}

	* loop over moderator groups
	foreach g of local glevels {
		local gl
		if `G' > 1 local gl " (`moderator' = `g')"
		tempvar gt fs sx
		qui gen byte `gt' = `touse' & `grp' == `g'
		forvalues i = 1/`L' {
			qui count if `gt' & `tix' == `i'
			if r(N) == 0 {
				di as err "no observations with `treat' == `v`i''`gl'"
				exit 2000
			}
		}

		* treatment-selection weights
		if "`tcov'" != "" {
			if "`qui'" == "noisily" di _n as txt "Treatment model`gl'"
			if `L' == 2 {
				tempvar tps
				local thopt
				if "`tmodel'" == "hetprobit" local thopt het(`thet')
				`qui' `tmodel' `tb' `XT' [pw=`uw'] if `gt', `thopt'
				qui predict double `tps' if `gt', pr
				if "`tmethod'" == "iptw" {
					tempname pz
					qui summarize `tb' [aw=`uw'] if `gt', meanonly
					scalar `pz' = r(mean)
					qui replace `tw' = cond(`tb' == 1, `pz'/`tps', (1 - `pz')/(1 - `tps')) if `gt'
					if "`twostep'" != "" {
						tempvar tsc tsc2
						tempname VT
						_mmwsmed_vmb `VT'
						if "`tmodel'" == "logit" {
							qui predict double `tsc' if `gt', score
							mata: mmw_add(4, 0, 0, "`touse'", "`obsid'", "`gt'", "`gt'", "`tsc'", "`XT'", "`uw'", "`VT'", 0, "`tb'")
						}
						else if "`tmodel'" == "probit" {
							qui predict double `tsc' if `gt', score
							mata: mmw_add_sc(4, 0, 0, "`touse'", "`obsid'", "`gt'", "`gt'", "`tsc'", "`XT'", "1", "`uw'", "`VT'", "")
						}
						else {
							qui predict double `tsc' `tsc2' if `gt', scores
							mata: mmw_add_sc(4, 0, 0, "`touse'", "`obsid'", "`gt'", "`gt'", "`tsc' `tsc2'", "`XT'|`XH'", "1 0", "`uw'", "`VT'", "")
							drop `tsc2'
						}
						mata: mmw_add(5, 0, 0, "`touse'", "`obsid'", "`gt'", "`gt'", "", "", "`uw'", "", `=scalar(`pz')', "`tb'")
						drop `tsc'
					}
				}
				else {
					_mmwsmed_tmmws `tb' if `gt', ps(`tps') nstrata(`tstrata') uw(`uw') tw(`tw') binary `=cond("`weight'" != "", "wtd", "")'
				}
				drop `tps'
			}
			else {
				if "`tmodel'" == "mlogit" `qui' mlogit `tix' `XT' [pw=`uw'] if `gt', baseoutcome(`cix')
				else                      `qui' `tmodel' `tix' `XT' [pw=`uw'] if `gt'
				local pslist
				forvalues i = 1/`L' {
					tempvar ps`i'
					qui predict double `ps`i'' if `gt', pr outcome(`i')
					local pslist `pslist' `ps`i''
				}
				if "`tmethod'" == "iptw" {
					forvalues i = 1/`L' {
						tempvar ind
						qui gen byte `ind' = (`tix' == `i') if `gt'
						qui summarize `ind' [aw=`uw'] if `gt', meanonly
						qui replace `tw' = r(mean)/`ps`i'' if `gt' & `tix' == `i'
						drop `ind'
					}
					if "`twostep'" != "" {
						if "`tmodel'" == "mlogit" {
							mata: mmw_add_ml(8, 0, 0, "`touse'", "`obsid'", "`gt'", "`gt'", "`tix'", "`pslist'", "`XT'", "`uw'", "`levidx'", `cix')
						}
						else {
							* ordinal model: scores for the index and for each cutpoint
							local scl
							local dsg `XT'
							local cns 0
							forvalues q = 1/`L' {
								tempvar sq`q'
								local scl `scl' `sq`q''
								if `q' > 1 {
									local dsg `dsg'|
									local cns `cns' 1
								}
							}
							qui predict double `scl' if `gt', scores
							tempname VT
							_mmwsmed_vmb `VT'
							mata: mmw_add_sc(4, 0, 0, "`touse'", "`obsid'", "`gt'", "`gt'", "`scl'", "`dsg'", "`cns'", "`uw'", "`VT'", "")
							drop `scl'
						}
						mata: mmw_add_marg("`touse'", "`obsid'", "`gt'", "`tix'", "`uw'", `L')
					}
				}
				else {
					_mmwsmed_tmmws `tix' if `gt', ps(`pslist') nstrata(`tstrata') uw(`uw') tw(`tw') `=cond("`weight'" != "", "wtd", "")' ///
						`=cond("`tmodel'" == "mlogit", "", "ordinal")'
				}
				drop `pslist'
			}
			qui count if `gt' & missing(`tw')
			local nx_tw = `nx_tw' + r(N)
			qui replace `excl' = 1 if `gt' & missing(`tw')
		}

		qui gen byte `fs' = `gt' & !`excl'
		qui gen byte `sx' = 0
		qui replace `ww' = `uw'*`tw' if `fs'

		* mediator weights
		if "`mweight'" == "odds" {
			* treatment models given the mediator and covariates, and given covariates only
			forvalues k = 1/`K' {
				local cterms `XM`k''
				if "`design'" == "sequential" & `k' == 2 local cterms `cterms' `mterm1'
				local cterms `cterms' `OTc`k''
				local wterms `mterm`k'' `cterms' `OTw`k''
				tempvar cellk
				if `mcat`k'' qui egen `cellk' = group(`tix' `m`k'') if `fs'
				else qui gen byte `cellk' = `tix' if `fs'
				if `L' == 2 {
					* xbw, xbo: log odds of the treatment given mediator and covariates
					tempvar xbw xbo
					local thopt
					if "`tmodel'" == "hetprobit" local thopt het(`thet')
					foreach wo in w o {
						if "`wo'" == "w" {
							local trm `wterms'
							local rty 6
							if "`qui'" == "noisily" di _n as txt "Treatment model given `m`k'' and covariates`gl'"
						}
						else {
							local trm `cterms'
							local rty 7
							if "`qui'" == "noisily" di _n as txt "Treatment model given covariates`gl'"
						}
						`qui' `tmodel' `tb' `trm' [pw=`uw'] if `fs', `thopt'
						if "`tmodel'" == "logit" {
							qui predict double `xb`wo'' if `fs', xb
							if "`twostep'" != "" {
								tempvar osc
								tempname VO
								qui predict double `osc' if `fs', score
								_mmwsmed_vmb `VO'
								mata: mmw_add(`rty', `k', 0, "`touse'", "`obsid'", "`fs'", "`fs'", "`osc'", "`trm'", "`uw'", "`VO'", 0, "`tb'")
								drop `osc'
							}
						}
						else {
							tempvar pp
							qui predict double `pp' if `fs', pr
							qui gen double `xb`wo'' = ln(`pp'/(1 - `pp')) if `fs'
							if "`twostep'" != "" {
								* d log odds / d eta_j = score_j/(T - p) for each equation j
								tempvar osc osc2 osf
								tempname VO
								_mmwsmed_vmb `VO'
								qui gen double `osf' = 1/(`tb' - `pp') if `fs'
								if "`tmodel'" == "probit" {
									qui predict double `osc' if `fs', score
									mata: mmw_add_sc(`rty', `k', 0, "`touse'", "`obsid'", "`fs'", "`fs'", "`osc'", "`trm'", "1", "`uw'", "`VO'", "`osf'")
								}
								else {
									qui predict double `osc' `osc2' if `fs', scores
									mata: mmw_add_sc(`rty', `k', 0, "`touse'", "`obsid'", "`fs'", "`fs'", "`osc' `osc2'", "`trm'|`XH'", "1 0", "`uw'", "`VO'", "`osf'")
									drop `osc2'
								}
								drop `osc' `osf'
							}
							drop `pp'
						}
					}
					qui replace `f`k'_`cix'' = 1 if `fs'
					qui replace `f`k'_`tother'' = exp(`xbw' - `xbo') if `fs'
					if "`common'" != "" {
						_mmwsmed_suppw `xbw', tix(`tix') mv(`m`k'') mcat(`mcat`k'') sample(`fs') caliper(`caliper') sx(`sx')
						_mmwsmed_supp `xbo', cell(`cellk') sample(`fs') caliper(`caliper') sx(`sx')
					}
					drop `xbw' `xbo'
				}
				else if "`tmodel'" == "mlogit" {
					if "`qui'" == "noisily" di _n as txt "Treatment model given `m`k'' and covariates`gl'"
					`qui' mlogit `tix' `wterms' [pw=`uw'] if `fs', baseoutcome(`cix')
					forvalues i = 1/`L' {
						tempvar xw`i'
						qui predict double `xw`i'' if `fs', xb outcome(`i')
					}
					if "`twostep'" != "" {
						local pwl
						forvalues i = 1/`L' {
							tempvar pw`i'
							qui predict double `pw`i'' if `fs', pr outcome(`i')
							local pwl `pwl' `pw`i''
						}
						mata: mmw_add_ml(10, `k', 0, "`touse'", "`obsid'", "`fs'", "`fs'", "`tix'", "`pwl'", "`wterms'", "`uw'", "`levidx'", `cix')
						drop `pwl'
					}
					if "`qui'" == "noisily" di _n as txt "Treatment model given covariates`gl'"
					`qui' mlogit `tix' `cterms' [pw=`uw'] if `fs', baseoutcome(`cix')
					if "`twostep'" != "" {
						local pwl
						forvalues i = 1/`L' {
							tempvar po`i'
							qui predict double `po`i'' if `fs', pr outcome(`i')
							local pwl `pwl' `po`i''
						}
						mata: mmw_add_ml(11, `k', 0, "`touse'", "`obsid'", "`fs'", "`fs'", "`tix'", "`pwl'", "`cterms'", "`uw'", "`levidx'", `cix')
						drop `pwl'
					}
					forvalues i = 1/`L' {
						tempvar xo`i'
						qui predict double `xo`i'' if `fs', xb outcome(`i')
						qui replace `f`k'_`i'' = exp(`xw`i'' - `xo`i'') if `fs'
						if "`common'" != "" & `i' != `cix' {
							_mmwsmed_suppw `xw`i'', tix(`tix') mv(`m`k'') mcat(`mcat`k'') sample(`fs') caliper(`caliper') sx(`sx')
							_mmwsmed_supp `xo`i'', cell(`cellk') sample(`fs') caliper(`caliper') sx(`sx')
						}
						drop `xw`i'' `xo`i''
					}
				}
				else {
					* ordinal treatment (ologit, oprobit): log odds of level i vs. the control level
					local lnk = cond("`tmodel'" == "ologit", 1, 2)
					foreach wo in w o {
						if "`wo'" == "w" {
							local trm `wterms'
							local rty 10
							if "`qui'" == "noisily" di _n as txt "Treatment model given `m`k'' and covariates`gl'"
						}
						else {
							local trm `cterms'
							local rty 11
							if "`qui'" == "noisily" di _n as txt "Treatment model given covariates`gl'"
						}
						`qui' `tmodel' `tix' `trm' [pw=`uw'] if `fs'
						forvalues i = 1/`L' {
							tempvar p`wo'`i'
							qui predict double `p`wo'`i'' if `fs', pr outcome(`i')
						}
						forvalues i = 1/`L' {
							tempvar x`wo'`i'
							qui gen double `x`wo'`i'' = ln(`p`wo'`i''/`p`wo'`cix'') if `fs'
						}
						if "`twostep'" != "" {
							local np : word count `trm'
							local scl
							forvalues q = 1/`L' {
								tempvar sq`q'
								local scl `scl' `sq`q''
							}
							capture predict double `scl' if `fs', scores
							if _rc {
								* without covariates there is no index equation: cutpoint scores only
								local scl
								forvalues q = 2/`L' {
									local scl `scl' `sq`q''
								}
								qui predict double `scl' if `fs', scores
							}
							tempvar oxb
							tempname VO BO
							capture predict double `oxb' if `fs', xb
							if _rc qui gen double `oxb' = 0 if `fs'
							matrix `BO' = e(b)
							_mmwsmed_vmb `VO'
							mata: mmw_add_ord(`rty', `k', "`touse'", "`obsid'", "`fs'", "`fs'", "`trm'", "`oxb'", "`BO'", `np', `lnk', "`scl'", "`uw'", "`VO'", `L', `cix')
							drop `scl' `oxb'
						}
						forvalues i = 1/`L' {
							drop `p`wo'`i''
						}
					}
					forvalues i = 1/`L' {
						qui replace `f`k'_`i'' = exp(`xw`i'' - `xo`i'') if `fs'
						if "`common'" != "" & `i' != `cix' {
							_mmwsmed_suppw `xw`i'', tix(`tix') mv(`m`k'') mcat(`mcat`k'') sample(`fs') caliper(`caliper') sx(`sx')
							_mmwsmed_supp `xo`i'', cell(`cellk') sample(`fs') caliper(`caliper') sx(`sx')
						}
						drop `xw`i'' `xo`i''
					}
				}
				drop `cellk'
			}
		}
		else {
			forvalues k = 1/`K' {
				local cov `XM`k''
				local subsets `""1""'
				if "`design'" == "sequential" & `k' == 2 {
					if `mcat1' {
						qui levelsof `m1' if `fs', local(j1)
						local subsets
						foreach j of local j1 {
							local subsets `"`subsets' "`m1' == `j'""'
						}
					}
					else {
						local cov `XM`k'' c.`m1'
						if "`twostep'" != "" local cov `XM`k'' `m1'
					}
				}
				local lpo
				if `k' == 1 & "`method'" == "nonparametric" local lpo lpall(`lpalist')
				foreach s of local subsets {
					_mmwsmed_fit `m`k'' if `fs' & (`s'), cov(`cov') tix(`tix') levels(`levidx') ///
						fvars(`fl`k'') ww(`ww') type(`mtype`k'') `lpo' `heteroskedastic'       ///
						`common' caliper(`caliper') sx(`sx') `noiopt' byvar(`moderator') gval(`g') ///
						tlab(`tlev') tname(`treat') `twostep' tsamp(`touse') obsid(`obsid') kidx(`k') `bootrep' ///
							hetvars(`hetvars')
				}
			}
		}

		* common support
		qui count if `fs' & `sx'
		local nx_sup = `nx_sup' + r(N)
		qui replace `excl' = 1 if `fs' & `sx'

		* nonparametric (MMWS-based) mediator probabilities
		if "`method'" == "nonparametric" {
			local lpc : word `cix' of `lpalist'
			foreach t of local tlist {
				local lpt : word `t' of `lpalist'
				tempvar ns g1 bad st
				qui gen byte `ns' = `gt' & !`excl' & inlist(`tix', `t', `cix')
				qui gen double `st' = .
				qui xtile `g1' = `lpt' `xw' if `ns', nq(`s1')
				forvalues j = 1/`s1' {
					tempvar h
					capture xtile `h' = `lpc' `xw' if `ns' & `g1' == `j', nq(`s0')
					if _rc {
						capture drop `h'
						qui gen byte `h' = 1 if `ns' & `g1' == `j'
					}
					qui replace `st' = (`j' - 1)*`s0' + `h' if `ns' & `g1' == `j'
					drop `h'
				}
				foreach i in `t' `cix' {
					tempvar ia na da pf`i'
					qui gen double `ia' = cond(`tix' == `i', `ww', 0) if `ns'
					qui bysort `grp' `st' `m1': egen double `na' = total(`ia') if `ns'
					qui bysort `grp' `st': egen double `da' = total(`ia') if `ns'
					qui gen double `pf`i'' = `na'/`da' if `ns'
					drop `ia' `na' `da'
				}
				* strata lacking any mediator level (fewer than nmin) in either treatment group are excluded
				qui gen byte `bad' = 0
				foreach i in `t' `cix' {
					foreach l of local mlev1 {
						tempvar c
						qui bysort `grp' `st': egen long `c' = total(`ns' & `tix' == `i' & `m1' == `l')
						qui replace `bad' = 1 if `ns' & `c' < `nmin'
						drop `c'
					}
				}
				qui count if `bad'
				local nb = r(N)
				if `nb' > 0 {
					local nx_str = `nx_str' + `nb'
					if "`bootrep'" == "" {
						qui levelsof `st' if `bad', local(bs)
						local tl
						if `L' > 2 local tl " (`treat' = `v`t'' vs. `v`cix'')"
						di as txt "note: strata `bs'`tl'`gl' do not contain at least `nmin' observation(s) of every level of"
						di as txt "      `m1' in both treatment groups; `nb' observation(s) excluded"
					}
				}
				qui replace `excl' = 1 if `bad'
				if `L' == 2 {
					qui replace `f1_`t'' = `pf`t'' if `ns'
					qui replace `f1_`cix'' = `pf`cix'' if `ns'
					qui replace `strat' = `st' if `ns'
				}
				else {
					* units at t: probabilities under t (own) and under control (target)
					qui replace `f1_`t'' = `pf`t'' if `ns' & `tix' == `t'
					qui replace `f1_`cix'' = `pf`cix'' if `ns' & `tix' == `t'
					* control units: the factor for the copy that shifts them to t; own factor 1
					qui replace `f1_`t'' = `pf`t''/`pf`cix'' if `ns' & `tix' == `cix'
					qui replace `f1_`cix'' = 1 if `ns' & `tix' == `cix'
				}
				drop `ns' `g1' `bad' `st' `pf`t'' `pf`cix''
			}
			if `L' > 2 {
				* factors for levels a unit is never compared with are not used
				forvalues i = 1/`L' {
					qui replace `f1_`i'' = 1 if `gt' & !`excl' & `tix' != `cix' & `tix' != `i' & `i' != `cix' & missing(`f1_`i'')
				}
			}
		}
		drop `gt' `fs' `sx'
	}
	* end group loop

	* mediator probability (or density) at the unit's own treatment level
	tempvar fin
	qui gen byte `fin' = `touse' & !`excl'
	forvalues k = 1/`K' {
		tempvar fown`k'
		qui gen double `fown`k'' = .
		forvalues i = 1/`L' {
			qui replace `fown`k'' = `f`k'_`i'' if `tix' == `i' & `fin'
		}
		tempvar okk
		qui gen byte `okk' = `fin' & `fown`k'' > 0 & !missing(`fown`k'')
		forvalues i = 1/`L' {
			qui replace `okk' = 0 if missing(`f`k'_`i'')
		}
		qui count if `fin' & !`okk'
		local nx_miss = `nx_miss' + r(N)
		qui replace `fin' = 0 if !`okk'
		drop `okk'
	}
	qui count if `fin'
	local N = r(N)
	if `N' == 0 error 2000
	qui count if `fin' & `tix' == `cix'
	local N0 = r(N)
	local N1 = `N' - `N0'
	qui count if `touse'
	local Nexcl = r(N) - `N'
	foreach g of local glevels {
		forvalues i = 1/`L' {
			qui count if `fin' & `grp' == `g' & `tix' == `i'
			if r(N) == 0 {
				di as err "no observations with `treat' == `v`i'' remain after exclusions"
				exit 2000
			}
		}
	}

	* generate()
	if "`generate'" != "" & "`bootrep'" == "" {
		local gv
		forvalues k = 1/`K' {
			forvalues i = 1/`L' {
				local gv `gv' `generate'_f`k'_`v`i''
			}
		}
		if "`tcov'" != "" local gv `gv' `generate'_tw
		if "`method'" == "nonparametric" & `L' == 2 local gv `gv' `generate'_strata
		local gv `gv' `generate'_sample
		if "`replace'" != "" {
			foreach v of local gv {
				capture drop `v'
			}
		}
		confirm new variable `gv'
		forvalues k = 1/`K' {
			forvalues i = 1/`L' {
				qui gen double `generate'_f`k'_`v`i'' = `f`k'_`i'' if `touse'
				if "`mweight'" == "odds" {
					label var `generate'_f`k'_`v`i'' "odds-based factor for `m`k'' at `treat'==`v`i''"
				}
				else {
					label var `generate'_f`k'_`v`i'' "pr/density of observed `m`k'' under `treat'==`v`i''"
				}
			}
		}
		if "`tcov'" != "" {
			qui gen double `generate'_tw = `tw' if `touse'
			label var `generate'_tw "treatment-selection weight (`tmethod')"
		}
		if "`method'" == "nonparametric" & `L' == 2 {
			qui gen double `generate'_strata = `strat' if `touse'
			label var `generate'_strata "cross-stratum of mediator propensity scores"
		}
		qui gen byte `generate'_sample = `fin' if `touse'
		label var `generate'_sample "in mmwsmed analytic sample"
	}

	* diagnostics: covariate balance and controlled direct effects
	tempname BAL MC WD CB CV
	local hasbal 0
	local hasctl 0
	if "`diagnostics'" != "" & "`bootrep'" == "" {
		tempvar bwall bwc
		qui gen double `bwall' = `uw'*`tw' if `fin'
		qui gen double `bwc' = `bwall' if `fin'
		local useown = "`mweight'" == "ratio" & !("`method'" == "nonparametric" & `L' > 2)
		local rown
		local mspecs
		forvalues k = 1/`K' {
			tempvar fc fm bwk
			qui gen double `fc' = .
			qui gen double `fm' = .
			if `useown' {
				qui replace `fc' = `fown`k'' if `fin'
			}
			else {
				local dcov `mcov`k''
				if "`design'" == "sequential" & `k' == 2 {
					if `mcat1' local dcov `dcov' i.`m1'
					else       local dcov `dcov' c.`m1'
				}
				local dcmd `mtype`k''
				if "`dcmd'" == "linear" local dcmd regress
				foreach g of local glevels {
					forvalues i = 1/`L' {
						local s `fin' & `grp' == `g' & `tix' == `i'
						capture qui `dcmd' `m`k'' `dcov' [pw=`bwall'] if `s'
						if _rc continue
						if inlist("`mtype`k''", "logit", "probit") {
							tempvar p
							qui predict double `p' if `s', pr
							qui replace `fc' = cond(`m`k'' == 1, `p', 1 - `p') if `s'
							drop `p'
						}
						else if inlist("`mtype`k''", "ologit", "mlogit") {
							foreach l of local mlev`k' {
								tempvar p
								capture qui predict double `p' if `s', pr outcome(`l')
								if !_rc qui replace `fc' = `p' if `s' & `m`k'' == `l'
								capture drop `p'
							}
						}
						else if "`mtype`k''" == "poisson" {
							tempvar p
							qui predict double `p' if `s', xb
							qui replace `fc' = poissonp(exp(`p'), `m`k'') if `s'
							drop `p'
						}
						else {
							tempvar p
							qui predict double `p' if `s', xb
							qui replace `fc' = normalden(`m`k'', `p', e(rmse)) if `s'
							drop `p'
						}
					}
				}
			}
			* stabilizing (marginal) probability or density within treatment group
			foreach g of local glevels {
				forvalues i = 1/`L' {
					local s `fin' & `grp' == `g' & `tix' == `i'
					if `mcat`k'' {
						foreach l of local mlev`k' {
							tempvar ind
							qui gen byte `ind' = (`m`k'' == `l') if `s'
							qui summarize `ind' [aw=`bwall'] if `s', meanonly
							qui replace `fm' = r(mean) if `s' & `m`k'' == `l'
							drop `ind'
						}
					}
					else {
						qui summarize `m`k'' [aw=`bwall'] if `s'
						if "`mtype`k''" == "poisson" qui replace `fm' = poissonp(r(mean), `m`k'') if `s'
						else                         qui replace `fm' = normalden(`m`k'', r(mean), r(sd)) if `s'
					}
				}
			}
			qui gen double `bwk' = `bwall'*`fm'/`fc' if `fin'
			qui count if `fin' & missing(`bwk')
			if r(N) > 0 di as txt "note: balance weights for `m`k'' could not be computed for `r(N)' observation(s)"
			qui replace `bwc' = `bwc'*`fm'/`fc' if `fin'
			if `mcat`k'' local mspec i.`m`k''
			else         local mspec c.`m`k''
			local mspecs `mspecs' `mspec'

			* joint test of the treatment, mediator, and treatment-by-mediator terms for each covariate
			local terms
			if "`mcov`k''" != "" {
				_mmwsmed_plain `mcov`k'' if `fin'
				local terms `r(terms)'
			}
			local coln
			foreach g of local glevels {
				local coln `coln' unweighted_`g' weighted_`g'
			}
			foreach t of local terms {
				qui fvrevar `t'
				local tv `r(varlist)'
				tempname row
				matrix `row' = J(1, 2*`G', .)
				local gi 0
				foreach g of local glevels {
					local ++gi
					local c1 = 2*`gi' - 1
					local c2 = 2*`gi'
					capture qui regress `tv' i.`treat'##`mspec' if `fin' & `grp' == `g'
					if !_rc {
						capture qui testparm i.`treat'##`mspec'
						if !_rc matrix `row'[1, `c1'] = r(p)
					}
					capture qui regress `tv' i.`treat'##`mspec' [pw=`bwk'] if `fin' & `grp' == `g'
					if !_rc {
						capture qui testparm i.`treat'##`mspec'
						if !_rc matrix `row'[1, `c2'] = r(p)
					}
				}
				matrix `BAL' = nullmat(`BAL') \ `row'
				local rown `rown' `m`k'':`t'
			}
			drop `fc' `fm' `bwk'
		}
		if "`rown'" != "" {
			matrix rownames `BAL' = `rown'
			matrix colnames `BAL' = `coln'
			local hasbal 1
		}

		* controlled treatment-by-mediator effects (Hong 2015, Step 5)
		local ctl_df
		foreach g of local glevels {
			tempname bg vg
			preserve
			forvalues k = 1/`K' {
				if !`mcat`k'' {
					qui recast double `m`k''
					qui summarize `m`k'' if `fin' & `grp' == `g', meanonly
					qui replace `m`k'' = `m`k'' - r(mean) if `fin' & `grp' == `g'
				}
			}
			capture qui regress `depvar' i.`treat'##(`mspecs') `indepvars' [pw=`bwc'] if `fin' & `grp' == `g', vce(robust)
			local rc = _rc
			if !`rc' {
				matrix `bg' = e(b)
				matrix `vg' = e(V)
				local ctl_df = e(df_r)
				* base and omitted levels would display as (empty) once moderator groups are stacked
				mata: mmw_dropbase("`bg'", "`vg'")
			}
			restore
			if `rc' {
				di as txt "note: the controlled-effects regression could not be fit"
				continue
			}
			if `G' > 1 {
				matrix coleq `bg' = `moderator'_`g'
				matrix coleq `vg' = `moderator'_`g'
				matrix roweq `vg' = `moderator'_`g'
			}
			if `hasctl' {
				local r1 = rowsof(`CV')
				local r2 = rowsof(`vg')
				tempname cvn
				matrix `cvn' = (`CV', J(`r1', `r2', 0)) \ (J(`r2', `r1', 0), `vg')
				local cn1 : colfullnames `CV'
				local cn2 : colfullnames `vg'
				matrix colnames `cvn' = `cn1' `cn2'
				matrix rownames `cvn' = `cn1' `cn2'
				matrix `CV' = `cvn'
				matrix `CB' = `CB', `bg'
			}
			else {
				matrix `CB' = `bg'
				matrix `CV' = `vg'
			}
			local hasctl 1
		}
		if `G' > 1 local ctl_df
		drop `bwall' `bwc'
	}

	* counterfactual copies
	local C 0
	forvalues i = 1/`L' {
		local ++C
		local carm`C' `i'
		local ctg`C'_1 0
		local ctg`C'_2 0
		if `K' == 1 local cname`C' Y`v`i''M`v`i''
		else local cname`C' Y`v`i''_`v`i''_`v`i''
	}
	local c `cix'
	foreach t of local tlist {
		if "`design'" == "single" {
			local cpy `" "`t' `c' 0" "`c' `t' 0" "'
		}
		else if "`design'" == "parallel" {
			local cpy `" "`t' `c' `c'" "`t' `t' `c'" "`t' `c' `t'" "'
		}
		else {
			local cpy `" "`c' `t' `c'" "`c' `c' `t'" "`t' `c' `c'" "`t' `t' `c'" "`t' `c' `t'" "'
		}
		foreach spec of local cpy {
			local a  : word 1 of `spec'
			local b1 : word 2 of `spec'
			local b2 : word 3 of `spec'
			local ++C
			local carm`C' `a'
			local ctg`C'_1 = cond(`b1' == `a', 0, `b1')
			local ctg`C'_2 = cond(`K' == 1 | `b2' == `a', 0, `b2')
			if `K' == 1 local cname`C' Y`v`a''M`v`b1''
			else local cname`C' Y`v`a''_`v`b1''_`v`b2''
		}
	}
	local cnames
	local carms
	forvalues j = 1/`C' {
		local cnames `cnames' `cname`j''
		local carms `carms' `carm`j''
	}

	* effect definitions for each non-control level t (tokens: +name / -name)
	foreach t of local tlist {
		local vt `v`t''
		local vc `v`c''
		if "`design'" == "single" {
			local d_TE_`t'   +Y`vt'M`vt' -Y`vc'M`vc'
			local d_NDE_`t'  +Y`vt'M`vc' -Y`vc'M`vc'
			local d_NIE_`t'  +Y`vt'M`vt' -Y`vt'M`vc'
			local d_PNIE_`t' +Y`vc'M`vt' -Y`vc'M`vc'
			local d_TNDE_`t' +Y`vt'M`vt' -Y`vc'M`vt'
			local d_INT_`t'  +Y`vt'M`vt' -Y`vt'M`vc' -Y`vc'M`vt' +Y`vc'M`vc'
		}
		else {
			local ttt Y`vt'_`vt'_`vt'
			local ccc Y`vc'_`vc'_`vc'
			local tcc Y`vt'_`vc'_`vc'
			local ttc Y`vt'_`vt'_`vc'
			local tct Y`vt'_`vc'_`vt'
			local d_TE_`t'    +`ttt' -`ccc'
			local d_NDE_`t'   +`tcc' -`ccc'
			local d_NIE_`t'   +`ttt' -`tcc'
			local d_M1xM2_`t' +`ttt' -`ttc' -`tct' +`tcc'
			if "`design'" == "parallel" {
				local d_NIE1_0_`t' +`ttc' -`tcc'
				local d_NIE1_1_`t' +`ttt' -`tct'
				local d_NIE2_0_`t' +`tct' -`tcc'
				local d_NIE2_1_`t' +`ttt' -`ttc'
			}
			else {
				local ctc Y`vc'_`vt'_`vc'
				local cct Y`vc'_`vc'_`vt'
				local d_NIE1_`t'  +`ttc' -`tcc'
				local d_NIE2_`t'  +`tct' -`tcc'
				local d_PNIE1_`t' +`ctc' -`ccc'
				local d_PNIE2_`t' +`cct' -`ccc'
				local d_ZxM1_`t'  +`ttc' -`tcc' -`ctc' +`ccc'
				local d_ZxM2_`t'  +`tct' -`tcc' -`cct' +`ccc'
			}
		}
	}

	* keep only the copies that the requested effects use
	if !`wantpo' & "`indepvars'" == "" {
		local need
		foreach e of local effects {
			foreach t of local tlist {
				foreach tok of local d_`e'_`t' {
					local need `need' `=substr("`tok'", 2, .)'
				}
			}
		}
		local need : list uniq need
		local C0 `C'
		local C 0
		forvalues j = 1/`C0' {
			local nm `cname`j''
			if `j' <= `L' | `: list nm in need' {
				local ++C
				local carm`C' `carm`j''
				local ctg`C'_1 `ctg`j'_1'
				local ctg`C'_2 `ctg`j'_2'
				local cname`C' `nm'
			}
		}
		local cnames
		local carms
		forvalues j = 1/`C' {
			local cnames `cnames' `cname`j''
			local carms `carms' `carm`j''
		}
	}

	* outcome-equation covariates: expand factor variables, drop base levels
	local xv
	if "`indepvars'" != "" {
		_mmwsmed_plain `indepvars' if `fin'
		if "`r(terms)'" != "" {
			qui fvrevar `r(terms)'
			local xv `r(varlist)'
		}
	}

	* stack the copies and fit the weighted outcome model
	tempname B V0 Lm b V Bfull VF
	preserve
	qui keep if `fin'
	tempvar id copy carm w
	qui gen long `id' = _n
	foreach v of local xv {
		qui recast double `v'
		foreach g of local glevels {
			qui summarize `v' [aw=`uw'] if `grp' == `g', meanonly
			qui replace `v' = `v' - r(mean) if `grp' == `g'
		}
	}
	qui expand `C'
	qui bysort `id': gen int `copy' = _n
	qui gen byte `carm' = .
	forvalues j = 1/`C' {
		qui replace `carm' = `carm`j'' if `copy' == `j'
	}
	qui drop if `carm' != `tix'
	qui gen double `w' = `uw'*`tw'
	forvalues j = 1/`C' {
		forvalues k = 1/`K' {
			local tg `ctg`j'_`k''
			if `tg' > 0 qui replace `w' = `w'*`f`k'_`tg''/`fown`k'' if `copy' == `j'
		}
	}

	* mediator distribution check: weighted copy vs. the treatment group whose distribution it targets
	local hasmc 0
	if "`bootrep'" == "" {
		tempvar ind
		foreach g of local glevels {
			forvalues j = 1/`C' {
				forvalues k = 1/`K' {
					local tg `ctg`j'_`k''
					if `tg' == 0 continue
					if "`design'" == "sequential" & `k' == 2 continue
					if `mcat`k'' {
						foreach l of local mlev`k' {
							qui gen byte `ind' = (`m`k'' == `l')
							qui summarize `ind' [aw=`w'] if `copy' == `j' & `grp' == `g', meanonly
							local q1 = r(mean)
							qui summarize `ind' [aw=`w'] if `copy' == `tg' & `grp' == `g', meanonly
							local q2 = r(mean)
							matrix `MC' = nullmat(`MC') \ (`g', `j', `k', `l', `q1', `q2')
							drop `ind'
						}
					}
					else {
						qui summarize `m`k'' [aw=`w'] if `copy' == `j' & `grp' == `g', meanonly
						local q1 = r(mean)
						qui summarize `m`k'' [aw=`w'] if `copy' == `tg' & `grp' == `g', meanonly
						local q2 = r(mean)
						matrix `MC' = nullmat(`MC') \ (`g', `j', `k', ., `q1', `q2')
					}
					local hasmc 1
				}
			}
		}
		if `hasmc' matrix colnames `MC' = group copy mediator level weighted target
	}

	* weight diagnostics: relative maximum, share of the largest weight, Kish effective sample size
	local haswd 0
	local xtreme
	if "`bootrep'" == "" {
		tempvar w2
		qui gen double `w2' = `w'^2
		foreach g of local glevels {
			forvalues j = 1/`C' {
				qui summarize `w' if `copy' == `j' & `grp' == `g'
				local nc = r(N)
				local sw = r(sum)
				local mx = r(max)
				qui summarize `w2' if `copy' == `j' & `grp' == `g', meanonly
				local ess = (`sw')^2/r(sum)
				matrix `WD' = nullmat(`WD') \ (`g', `j', `nc', `mx'/(`sw'/`nc'), 100*`mx'/`sw', `ess', 100*`ess'/`nc')
				if (100*`ess'/`nc' < 5 | 100*`mx'/`sw' > 10) & `ess' >= 2 {
					local gl
					if `G' > 1 {
						_mmwsmed_vl `moderator' `g'
						local gl " (`moderator' = `r(lab)')"
					}
					local s1 = string(`ess', "%9.1f")
					local s2 = string(100*`ess'/`nc', "%9.1f")
					local s3 = string(100*`mx'/`sw', "%9.1f")
					local xtreme `"`xtreme' "`cname`j''`gl': Kish ESS = `s1' (`s2'%), largest weight = `s3'% of the total""'
				}
			}
		}
		matrix colnames `WD' = group copy n max_mean maxshare ess ess_pct
		local haswd 1
		drop `w2'
		if `"`xtreme'"' != "" {
			di as txt "note: extreme weights in"
			foreach x of local xtreme {
				di as txt "      `x'"
			}
			di as txt "      Estimates for these copies rest on few observations; see {bf:diagnostics}."
		}
	}

	* degenerate weights: a copy whose weight is concentrated on a single observation
	foreach g of local glevels {
		forvalues j = 1/`C' {
			tempvar w2
			qui gen double `w2' = `w'^2 if `copy' == `j' & `grp' == `g'
			qui summarize `w' if `copy' == `j' & `grp' == `g', meanonly
			local sw = r(sum)
			local mx = r(max)
			qui summarize `w2', meanonly
			local ess = (`sw')^2/r(sum)
			drop `w2'
			if `ess' < 2 | missing(`ess') {
				local gl
				if `G' > 1 local gl " (`moderator' = `g')"
				if "`bootrep'" != "" exit 459            // bootstrap replication: counted as failed, no message
				di as err "weights for copy `cname`j''`gl' are degenerate: one observation carries " %4.1f 100*`mx'/`sw' "% of the weight"
				di as err "(Kish effective sample size = " %4.2f `ess' "). The mediator model cannot reproduce the target"
				di as err "mediator distribution in this treatment group, typically because of extreme mediator values or"
				di as err "limited overlap. Inspect the mediator distribution by treatment group, consider {bf:mweight(odds)}"
				di as err "or a different mediator model, or restrict the sample."
				exit 459
			}
		}
	}

	local dlist
	local xlist
	foreach g of local glevels {
		forvalues j = 1/`C' {
			tempvar d
			qui gen byte `d' = (`grp' == `g' & `copy' == `j')
			local dlist `dlist' `d'
		}
		if `G' > 1 {
			foreach v of local xv {
				tempvar xg
				qui gen double `xg' = `v'*(`grp' == `g')
				local xlist `xlist' `xg'
			}
		}
	}
	if `G' == 1 local xlist `xv'
	local cl `id'
	if "`clustvar'" != "" local cl `clustvar'
	local nd = `G'*`C'
	if "`omodel'" == "linear" {
		qui regress `depvar' `dlist' `xlist' [pw=`w'], noconstant vce(cluster `cl')
		local df_r = e(df_r)
	}
	else {
		local fam = cond("`omodel'" == "poisson", "poisson", "binomial")
		local lnk = cond("`omodel'" == "poisson", "log", "`omodel'")
		capture `qui' glm `depvar' `dlist' `xlist' [pw=`w'], family(`fam') link(`lnk') ///
			noconstant vce(cluster `cl')
		if _rc {
			local rc = _rc
			di as err "the weighted `omodel' outcome model could not be fit"
			exit `rc'
		}
		if !e(converged) {
			di as err "the weighted `omodel' outcome model did not converge"
			exit 430
		}
	}
	* a copy indicator dropped by the outcome model means its mean could not be estimated
	tempname vchk
	matrix `vchk' = vecdiag(e(V))
	forvalues r = 1/`nd' {
		if `vchk'[1, `r'] == 0 | missing(`vchk'[1, `r']) {
			local j = mod(`r' - 1, `C') + 1
			di as err "the potential-outcome mean for copy `cname`j'' could not be estimated (dropped from the outcome"
			di as err "model); check its weights with {bf:diagnostics}"
			exit 459
		}
	}
	matrix `Bfull' = e(b)
	matrix `B' = e(b)
	matrix `B' = `B'[1, 1..`nd']
	matrix `VF' = e(V)
	matrix `V0' = `VF'[1..`nd', 1..`nd']
	local Nstack = e(N)
	local Nclust = e(N_clust)
	restore

	* nonlinear outcome models: potential-outcome means are the copy-specific predictions averaged
	local omc = cond("`omodel'" == "linear", 1, cond("`omodel'" == "logit", 2, cond("`omodel'" == "probit", 3, 4)))
	if `omc' > 1 {
		tempname GLs JD
		matrix `GLs' = J(1, `G', .)
		local gi 0
		foreach g of local glevels {
			local ++gi
			matrix `GLs'[1, `gi'] = `g'
		}
		mata: mmw_std("`fin'", "`xv'", "`uw'", "`grp'", "`GLs'", "`Bfull'", `C', `omc', "`B'", "`JD'")
		matrix `V0' = `JD'*`VF'*`JD''
	}

	* analytic two-step variance (accounts for estimation of the weights)
	if "`twostep'" != "" {
		tempname GL CA TG VTS
		matrix `GL' = J(1, `G', .)
		local gi 0
		foreach g of local glevels {
			local ++gi
			matrix `GL'[1, `gi'] = `g'
		}
		matrix `CA' = J(1, `C', .)
		matrix `TG' = J(`C', `K', 0)
		forvalues j = 1/`C' {
			matrix `CA'[1, `j'] = `carm`j''
			forvalues k = 1/`K' {
				matrix `TG'[`j', `k'] = `ctg`j'_`k''
			}
		}
		local fall
		forvalues k = 1/`K' {
			local fall `fall' `fl`k''
		}
		* influence functions are summed by individual, or by clustvar with vce(cluster clustvar)
		local tscl `obsid'
		if "`clustvar'" != "" local tscl `clustvar'
		mata: mmw_vce("`touse'", "`obsid'", "`depvar'", "`tix'", "`grp'", "`fin'", "`uw'", "`tw'", ///
			"`fall'", `L', `cix', "`xv'", "`tscl'", "`GL'", "`CA'", "`TG'", "`Bfull'", `omc', "`VTS'")
		if `omc' == 1 matrix `V0' = `VTS'[1..`nd', 1..`nd']
		else          matrix `V0' = `JD'*`VTS'*`JD''
		local Nclust = `N'
		if "`clustvar'" != "" {
			tempvar ctag
			qui egen byte `ctag' = tag(`clustvar') if `fin'
			qui count if `ctag' == 1
			local Nclust = r(N)
			drop `ctag'
		}
	}

	* linear combinations: potential-outcome means, effects, moderator differences
	local ne : word count `effects'
	local nt : word count `tlist'
	local npo = cond(`wantpo', `C', 0)
	local nr = `G'*`npo' + `G'*`ne'*`nt' + (`G' - 1)*`ne'*`nt'
	matrix `Lm' = J(`nr', `nd', 0)
	local r 0
	local stripe
	local first : word 1 of `glevels'
	* potential-outcome means
	if `wantpo' {
		local gi 0
		foreach g of local glevels {
			local ++gi
			local off = (`gi' - 1)*`C'
			local eqp POmeans
			if `G' > 1 local eqp POmeans_`g'
			forvalues j = 1/`C' {
				local ++r
				local col = `off' + `j'
				matrix `Lm'[`r', `col'] = 1
				local stripe `stripe' `eqp':`cname`j''
			}
		}
	}
	* effects, equation by equation
	foreach e of local effects {
		local gi 0
		foreach g of local glevels {
			local ++gi
			local off = (`gi' - 1)*`C'
			foreach t of local tlist {
				local ++r
				foreach tok of local d_`e'_`t' {
					local sg = cond(substr("`tok'", 1, 1) == "+", 1, -1)
					local nm = substr("`tok'", 2, .)
					local ci : list posof "`nm'" in cnames
					local col = `off' + `ci'
					matrix `Lm'[`r', `col'] = `Lm'[`r', `col'] + `sg'
				}
				local cn r`v`t''vs`v`c''.`treat'
				if `G' > 1 local cn `cn'#`g'.`moderator'
				local stripe `stripe' `e':`cn'
			}
		}
		local gi 0
		foreach g of local glevels {
			local ++gi
			if `gi' == 1 continue
			local off = (`gi' - 1)*`C'
			foreach t of local tlist {
				local ++r
				foreach tok of local d_`e'_`t' {
					local sg = cond(substr("`tok'", 1, 1) == "+", 1, -1)
					local nm = substr("`tok'", 2, .)
					local ci : list posof "`nm'" in cnames
					local col = `off' + `ci'
					matrix `Lm'[`r', `col'] = `Lm'[`r', `col'] + `sg'
					matrix `Lm'[`r', `ci'] = `Lm'[`r', `ci'] - `sg'
				}
				local stripe `stripe' `e'_diff:r`v`t''vs`v`c''.`treat'#`g'.`moderator'
			}
		}
	}
	matrix `b' = `B'*`Lm''
	matrix `V' = `Lm'*`V0'*`Lm''
	matrix colnames `b' = `stripe'
	matrix colnames `V' = `stripe'
	matrix rownames `V' = `stripe'

	* Mata bootstrap: settings, copies, and the map from copy means to e(b)
	if "`mbspec'" != "" {
		tempname BCA BTG BGL
		matrix `BCA' = J(1, `C', .)
		matrix `BTG' = J(`C', `K', 0)
		forvalues j = 1/`C' {
			matrix `BCA'[1, `j'] = `carm`j''
			forvalues k = 1/`K' {
				matrix `BTG'[`j', `k'] = `ctg`j'_`k''
			}
		}
		matrix `BGL' = J(1, `G', .)
		local gi 0
		foreach g of local glevels {
			local ++gi
			matrix `BGL'[1, `gi'] = `g'
		}
		local mcodes logit probit ologit mlogit linear poisson
		local B_mt
		forvalues k = 1/2 {
			local q 0
			if "`mtype`k''" != "" local q : list posof "`mtype`k''" in mcodes
			local B_mt `B_mt', `q'
		}
		local tcodes logit probit hetprobit mlogit ologit oprobit
		local B_tm : list posof "`tmodel'" in tcodes
		local B_ds = cond("`design'" == "single", 1, cond("`design'" == "parallel", 2, 3))
		local B_s1 0
		local B_s0 0
		if "`method'" == "nonparametric" {
			local B_s1 : word 1 of `strata'
			local B_s0 : word 2 of `strata'
		}
		local B_cal = string(`caliper', "%21.15f")
		mata: mmw_bs_putm("set", (`L', `cix', `K', `B_ds', `B_tm', `="`tcov'" != ""', `="`tmethod'" == "mmws"', ///
			`tstrata', `="`weight'" != ""', `="`mweight'" == "odds"', `="`method'" == "nonparametric"', `B_s1', `B_s0', ///
			`nmin', `="`common'" != ""', `B_cal', `="`heteroskedastic'" != ""', `omc', `C' `B_mt', `="`hetvars'" != ""'))
		mata: mmw_bs_putm("glev", st_matrix("`BGL'"))
		mata: mmw_bs_putm("CA",   st_matrix("`BCA'"))
		mata: mmw_bs_putm("TG",   st_matrix("`BTG'"))
		mata: mmw_bs_putm("Lm",   st_matrix("`Lm'"))
	}

	* post
	if "`twostep'" != "" | "`omodel'" != "linear" {
		ereturn post `b' `V', esample(`fin') obs(`N') depname(`depvar')
	}
	else {
		ereturn post `b' `V', esample(`fin') obs(`N') depname(`depvar') dof(`df_r')
	}
	ereturn scalar N_treat = `N1'
	ereturn scalar N_control = `N0'
	ereturn scalar N_excl = `Nexcl'
	ereturn scalar N_excl_tw = `nx_tw'
	ereturn scalar N_excl_support = `nx_sup'
	ereturn scalar N_excl_strata = `nx_str'
	ereturn scalar N_excl_miss = `nx_miss'
	ereturn scalar N_stack = `Nstack'
	ereturn scalar N_clust = `Nclust'
	ereturn scalar k_copies = `C'
	ereturn scalar k_levels = `L'
	if "`common'" != "" ereturn scalar caliper = `caliper'
	ereturn local tvar "`treat'"
	ereturn local tlevels "`tlev'"
	ereturn local control "`v`c''"
	ereturn local tvartype "`tvartype'"
	if `K' == 1 {
		ereturn local mvar "`m1'"
		ereturn local mmodel "`mtype1'"
	}
	else {
		ereturn local mvar1 "`m1'"
		ereturn local mvar2 "`m2'"
		ereturn local mmodel1 "`mtype1'"
		ereturn local mmodel2 "`mtype2'"
	}
	ereturn local med_type "`design'"
	ereturn local omodel "`omodel'"
	ereturn local mweight "`mweight'"
	ereturn local oterms `"`oterms'"'
	ereturn local method "`method'"
	if "`method'" == "nonparametric" ereturn local strata "`s1' `s0'"
	ereturn local mcov1 "`mcov1'"
	ereturn local mcov2 "`mcov2'"
	ereturn local indepvars "`indepvars'"
	ereturn local tcov "`tcov'"
	if "`heteroskedastic'" != "" {
		ereturn local heteroskedastic "heteroskedastic"
		ereturn local hetvars "`hetvars'"
	}
	if "`tcov'" != "" ereturn local tmethod "`tmethod'"
	if "`tcov'" != "" | "`mweight'" == "odds" {
		ereturn local tmodel "`tmodel'"
		if "`thet'" != "" ereturn local thet "`thet'"
	}
	ereturn local moderator "`moderator'"
	ereturn local mlevels "`glevels'"
	ereturn local stats "`effects'"
	ereturn local copies "`cnames'"
	ereturn local clustvar "`clustvar'"
	if "`clustvar'" != "" ereturn local vce "cluster"
	else                  ereturn local vce "robust"
	ereturn local vcetype "Robust"
	if `wstep'        ereturn local vceweights "known (step-function weights)"
	else if `wknown'  ereturn local vceweights "known"
	else              ereturn local vceweights "estimated"
	ereturn local title "Causal mediation analysis: RMPW"
	if `hasmc'  ereturn matrix mcheck = `MC'
	if `hasbal' ereturn matrix balance = `BAL'
	if `hasctl' {
		ereturn matrix ctl_b = `CB'
		ereturn matrix ctl_V = `CV'
		if "`ctl_df'" != "" ereturn scalar ctl_df = `ctl_df'
	}
	if `haswd'  ereturn matrix wdiag = `WD'
	ereturn local cmd "mmwsmed"
end


***********************************************
* mediator model within each treatment level
***********************************************
program _mmwsmed_fit
	version 15
	syntax varname [if], tix(varname) levels(numlist) fvars(varlist)				///
		ww(varname) type(string) [ cov(string) LPAll(varlist)						///
		HETeroskedastic common caliper(real 0.2) sx(varname)						///
		NOIsily byvar(string) gval(string) tlab(string) tname(string)				///
		TWOSTEP tsamp(string) obsid(string) kidx(integer 0) BOOTREP HETVars(string) ]

	marksample sub, novarlist
	* heteroskedastic linear mediator: plain (expanded) designs for the mean and the log variance
	local XP
	local ZP
	if "`heteroskedastic'" != "" & "`type'" == "linear" {
		if "`cov'" != "" {
			_mmwsmed_plain `cov' if `sub'
			if "`r(terms)'" != "" {
				qui fvrevar `r(terms)'
				local XP `r(varlist)'
			}
		}
		local ZP `XP'
		if "`hetvars'" != "" {
			local ZP
			_mmwsmed_plain `hetvars' if `sub'
			if "`r(terms)'" != "" {
				qui fvrevar `r(terms)'
				local ZP `r(varlist)'
			}
		}
	}
	local mv `varlist'
	local qui quietly
	if "`noisily'" != "" local qui noisily
	local gl
	if "`byvar'" != "" local gl " (`byvar' = `gval')"
	local cat = inlist("`type'", "logit", "probit", "ologit", "mlogit")
	local cmd `type'
	if "`type'" == "linear" local cmd regress

	tempvar cell
	if `cat' {
		qui levelsof `mv' if `sub', local(levs)
		foreach a of local levels {
			local va : word `a' of `tlab'
			foreach l of local levs {
				qui count if `sub' & `tix' == `a' & `mv' == `l'
				if r(N) == 0 {
					di as err "mediator {bf:`mv'} = `l' is not observed among `tname' == `va'`gl'"
					di as err "the mediator model cannot predict this level; consider collapsing categories"
					exit 459
				}
			}
		}
		qui egen `cell' = group(`tix' `mv') if `sub'
	}
	else {
		qui gen byte `cell' = `tix' if `sub'
	}

	foreach a of local levels {
		local fa : word `a' of `fvars'
		local va : word `a' of `tlab'
		if "`noisily'" != "" di _n as txt "Mediator model for `mv', `tname' == `va'`gl'"
		* -bootstrap- requires baseoutcome() with mlogit: the most frequent level, as mlogit's default
		local bopt
		if "`type'" == "mlogit" & "`bootrep'" != "" {
			tempname fr lv
			qui tabulate `mv' if `sub' & `tix' == `a', matcell(`fr') matrow(`lv')
			local bmax 1
			forvalues r = 2/`=rowsof(`fr')' {
				if `fr'[`r', 1] > `fr'[`bmax', 1] local bmax `r'
			}
			local bopt baseoutcome(`=`lv'[`bmax', 1]')
		}
		`qui' `cmd' `mv' `cov' [pw=`ww'] if `sub' & `tix' == `a', `bopt'
		local lplist
		if inlist("`type'", "logit", "probit") {
			tempvar p lp
			qui predict double `p' if `sub', pr
			qui predict double `lp' if `sub', xb
			qui replace `fa' = cond(`mv' == 1, `p', 1 - `p') if `sub'
			drop `p'
			local lplist `lp'
		}
		else if inlist("`type'", "ologit", "mlogit") {
			local plist
			foreach l of local levs {
				tempvar pl
				qui predict double `pl' if `sub', pr outcome(`l')
				qui replace `fa' = `pl' if `sub' & `mv' == `l'
				local plist `plist' `pl'
			}
			if "`type'" == "ologit" {
				tempvar lp
				qui predict double `lp' if `sub', xb
				local lplist `lp'
			}
			else {
				local base = e(baseout)
				foreach l of local levs {
					if `l' == `base' continue
					tempvar lpl
					qui predict double `lpl' if `sub', xb outcome(`l')
					local lplist `lplist' `lpl'
				}
			}
		}
		else if "`type'" == "poisson" {
			* count mediator: Poisson probability of the observed count
			tempvar lp
			qui predict double `lp' if `sub', xb
			qui replace `fa' = poissonp(exp(`lp'), `mv') if `sub'
			local lplist `lp'
		}
		else {
			* continuous mediator: normal density with level-specific mean and variance
			* with heteroskedastic: the mean and ln(variance) are linear in the covariates and fitted jointly using -hetregress-
			tempvar lp s2
			local s2v = e(rmse)^2
			if "`heteroskedastic'" == "" {
				qui predict double `lp' if `sub', xb
				qui gen double `s2' = e(rmse)^2 if `sub'
			}
			else {
				tempvar hfit
				qui gen byte `hfit' = `sub' & `tix' == `a'
				qui gen double `lp' = .
				qui gen double `s2' = .
				local mmw_hok 0
				mata: mmw_hreg_st("`mv'", "`XP'", "`ZP'", "`ww'", "`hfit'", "`sub'", "`lp'", "`s2'")
				if "`mmw_hok'" != "1" {
					di as err "heteroskedastic: the model for {bf:`mv'} among `tname' == `va'`gl' did not converge"
					exit 430
				}
				if "`twostep'" != "" {
					mata: mmw_add_hreg(`kidx', `a', "`tsamp'", "`obsid'", "`sub'", "`hfit'", "`mv'", "`lp'", "`s2'", "`XP'", "`ZP'", "`ww'")
				}
				drop `hfit'
			}
			qui replace `fa' = normalden(`mv', `lp', sqrt(`s2')) if `sub'
			drop `s2'
			local lplist `lp'
		}
		local lpf : word 1 of `lplist'
		if "`lpall'" != "" {
			local lpv : word `a' of `lpall'
			qui replace `lpv' = `lpf' if `sub'
		}

		* two-step variance: register this model's scores (e() still holds it)
		if "`twostep'" != "" {
			tempvar fitv
			tempname Vm
			qui gen byte `fitv' = `sub' & `tix' == `a'
			if inlist("`type'", "logit", "probit", "poisson") {
				tempvar sc
				qui predict double `sc' if `sub', score
				_mmwsmed_vmb `Vm'
				mata: mmw_add(1, `kidx', `a', "`tsamp'", "`obsid'", "`sub'", "`fitv'", "`sc'", "`cov'", "`ww'", "`Vm'", 0, "`tix'")
				drop `sc'
			}
			else if "`type'" == "ologit" {
				local nl : word count `levs'
				local scl
				forvalues q = 1/`nl' {
					tempvar sq`q'
					local scl `scl' `sq`q''
				}
				qui predict double `scl' if `sub', scores
				_mmwsmed_vmb `Vm'
				mata: mmw_add(2, `kidx', `a', "`tsamp'", "`obsid'", "`sub'", "`fitv'", "`scl'", "`cov'", "`ww'", "`Vm'", 0, "`tix'")
				drop `scl'
			}
			else if "`type'" == "mlogit" {
				mata: mmw_add_ml(12, `kidx', `a', "`tsamp'", "`obsid'", "`sub'", "`fitv'", "`mv'", "`plist'", "`cov'", "`ww'", "`levs'", `=e(baseout)')
			}
			else if "`type'" == "linear" & "`heteroskedastic'" == "" {
				tempvar res
				qui gen double `res' = `mv' - `lp' if `sub'
				mata: mmw_add(3, `kidx', `a', "`tsamp'", "`obsid'", "`sub'", "`fitv'", "`res'", "`cov'", "`ww'", "", `s2v', "`tix'")
				drop `res'
			}
			drop `fitv'
		}

		if "`common'" != "" {
			foreach v of local lplist {
				_mmwsmed_supp `v', cell(`cell') sample(`sub') caliper(`caliper') sx(`sx')
			}
		}
		drop `lplist'
		if "`plist'" != "" drop `plist'
		local plist
	}
end


*************************************
* treatment-selection weights by MMWS
*************************************
program _mmwsmed_tmmws
	version 15
	syntax varname [if], ps(varlist) nstrata(integer) uw(varname) tw(varname) [ binary ordinal wtd ]
	marksample s, novarlist
	local xwt
	if "`wtd'" != "" local xwt [aw=`uw']
	local z `varlist'
	tempvar st ns nz cz ok
	if "`binary'" != "" {
		* one stratification on pr(z = 1); a stratum must contain both groups
		tempvar n1 n0 c1 c0
		qui xtile `st' = `ps' `xwt' if `s', nq(`nstrata')
		qui bysort `st': egen double `n1' = total(`uw'*(`z' == 1)*`s')
		qui bysort `st': egen double `n0' = total(`uw'*(`z' == 0)*`s')
		qui bysort `st': egen long `c1' = total((`z' == 1)*`s')
		qui bysort `st': egen long `c0' = total((`z' == 0)*`s')
		qui summarize `z' [aw=`uw'] if `s', meanonly
		local p1 = r(mean)
		qui replace `tw' = . if `s'
		qui replace `tw' = ((`n1' + `n0')/`n1')*`p1'       if `s' & `z' == 1 & `c1' >= 1 & `c0' >= 1 & !missing(`st')
		qui replace `tw' = ((`n1' + `n0')/`n0')*(1 - `p1') if `s' & `z' == 0 & `c1' >= 1 & `c0' >= 1 & !missing(`st')
		exit
	}
	if "`ordinal'" != "" {
		* ordinal treatment
		gettoken p0 : ps
		qui summarize `uw' if `s', meanonly
		local sw = r(sum)
		qui levelsof `z' if `s', local(zlev)
		local nlev : word count `zlev'
		tempvar nl first
		qui xtile `st' = `p0' `xwt' if `s', nq(`nstrata')
		qui bysort `st' `z': gen byte `first' = (_n == 1) & `s'
		qui bysort `st': egen long `nl' = total(`first')
		qui bysort `st': egen double `ns' = total(`uw'*`s')
		qui replace `tw' = . if `s'
		foreach i of local zlev {
			qui summarize `uw' if `s' & `z' == `i', meanonly
			local pi = r(sum)/`sw'
			qui bysort `st': egen double `nz' = total(`uw'*`s'*(`z' == `i'))
			qui replace `tw' = (`ns'/`nz')*`pi' if `s' & `z' == `i' & `nl' == `nlev' & !missing(`st')
			drop `nz'
		}
		exit
	}
	* nominal treatment
	qui replace `tw' = . if `s'
	qui summarize `uw' if `s', meanonly
	local sw = r(sum)
	local i 0
	foreach p of local ps {
		local ++i
		qui summarize `uw' if `s' & `z' == `i', meanonly
		local pi = r(sum)/`sw'
		qui xtile `st' = `p' `xwt' if `s', nq(`nstrata')
		qui bysort `st': egen double `ns' = total(`uw'*`s')
		qui bysort `st': egen double `nz' = total(`uw'*`s'*(`z' == `i'))
		qui replace `tw' = (`ns'/`nz')*`pi' if `s' & `z' == `i' & !missing(`st')
		drop `st' `ns' `nz'
	}
end


***********************************************************
* common support on a linear predictor (Hong 2015, Step 3)
***********************************************************
program _mmwsmed_supp
	version 15
	syntax varname, cell(varname) sample(varname) caliper(real) sx(varname)
	tempname lo hi sd
	qui summarize `varlist' if `sample'
	scalar `sd' = r(sd)
	scalar `lo' = -c(maxdouble)
	scalar `hi' = c(maxdouble)
	qui levelsof `cell' if `sample', local(cells)
	foreach c of local cells {
		qui summarize `varlist' if `sample' & `cell' == `c', meanonly
		scalar `lo' = max(`lo', r(min) - `caliper'*`sd')
		scalar `hi' = min(`hi', r(max) + `caliper'*`sd')
	}
	qui replace `sx' = 1 if `sample' & (`varlist' < `lo' | `varlist' > `hi')
end


********************************************************************************
* common support for a treatment model that includes the mediator (odds weights)
********************************************************************************
program _mmwsmed_suppw
	version 15
	syntax varname, tix(varname) mv(varname) mcat(integer) sample(varname) caliper(real) sx(varname)
	if !`mcat' {
		_mmwsmed_supp `varlist', cell(`tix') sample(`sample') caliper(`caliper') sx(`sx')
		exit
	}
	qui levelsof `mv' if `sample', local(mlev)
	foreach v of local mlev {
		tempvar sk
		qui gen byte `sk' = `sample' & `mv' == `v'
		_mmwsmed_supp `varlist', cell(`tix') sample(`sk') caliper(`caliper') sx(`sx')
		drop `sk'
	}
end


********************************************************************
* expand a factor-variable list into its non-base, non-omitted terms
********************************************************************
program _mmwsmed_plain, rclass
	version 15
	syntax varlist(numeric fv) [if]
	marksample tu, novarlist
	qui fvexpand `varlist' if `tu'
	local terms
	foreach t in `r(varlist)' {
		if regexm("`t'", "[0-9]+b\.") | regexm("`t'", "o\.") continue
		local tt
		local parts : subinstr local t "#" " ", all
		foreach p of local parts {
			if regexm("`p'", "^([0-9]+)\.(.+)$") local p = regexs(1) + "bn." + regexs(2)
			if "`tt'" == "" local tt `p'
			else local tt `tt'#`p'
		}
		local terms `terms' `tt'
	}
	return local terms `terms'
end


************************************************************
* inverse of the negative Hessian of the model just fitted
***********************************************************
program _mmwsmed_vmb
	version 15
	args name
	capture confirm matrix e(V_modelbased)
	if !_rc matrix `name' = e(V_modelbased)
	else matrix `name' = e(V)
end


**********************************************************************
* value label of a value of a variable (the value itself if unlabeled)
**********************************************************************
program _mmwsmed_vl, rclass
	version 15
	args var val
	local l `val'
	capture confirm numeric variable `var', exact
	if !_rc & "`val'" != "" {
		local vl : value label `var'
		if "`vl'" != "" local l : label `vl' `val'
	}
	return local lab `"`l'"'
end


*********************************************************************
* coefficient table with value labels and a stub fitted to the labels
*********************************************************************
program _mmwsmed_ctab
	version 15
	syntax , b(name) v(name) [ dep(string) df(real -1) Level(cilevel) vtitle(string) ///
		BOOT COEFLegend MAIN mod(string) mlev(string) note(string) notesmcl(string) clev(string) ]

	local cn : colfullnames `b'
	local nc = colsof(`b')
	local g0 : word 1 of `mlev'
	local s = max(12, udstrlen("`dep'"))
	forvalues j = 1/`nc' {
		local full : word `j' of `cn'
		local cp = strpos("`full'", ":")
		local eq = cond(`cp', substr("`full'", 1, `cp' - 1), "")
		local nm = substr("`full'", `cp' + 1, .)
		* equation label
		local eql "`eq'"
		if "`mod'" != "" {
			if regexm("`eq'", "^POmeans_([0-9]+)$") {
				local gg = regexs(1)
				_mmwsmed_vl `mod' `gg'
				local eql `"POmeans (`mod' = `r(lab)')"'
			}
			else if regexm("`eq'", "^`mod'_([0-9]+)$") {
				local gg = regexs(1)
				_mmwsmed_vl `mod' `gg'
				local eql `"`mod' = `r(lab)'"'
			}
		}
		local key
		local lab "`nm'"
		local lev 0
		* effect names r#vs#.tvar or r#vs#.tvar#g.moderator
		local isef 0
		local gg
		local mv
		if "`main'" != "" & regexm("`nm'", "^r([0-9]+)vs([0-9]+)[.]([A-Za-z0-9_]+)$") {
			local isef 1
			local t  = regexs(1)
			local c  = regexs(2)
			local tv = regexs(3)
		}
		else if "`main'" != "" & regexm("`nm'", "^r([0-9]+)vs([0-9]+)[.]([A-Za-z0-9_]+)#([0-9]+)[a-z]*[.]([A-Za-z0-9_]+)$") {
			local isef 1
			local t  = regexs(1)
			local c  = regexs(2)
			local tv = regexs(3)
			local gg = regexs(4)
			local mv = regexs(5)
		}
		if `isef' {
			if "`clev'" != "" {
				* continuous treatment: indices refer to the evaluation values in clev (control first)
				local lt : word `=`t'+1' of `clev'
				local lc : word `=`c'+1' of `clev'
				local lab `"(`lt' vs `lc')"'
			}
			else {
				_mmwsmed_vl `tv' `t'
				local lt `"`r(lab)'"'
				_mmwsmed_vl `tv' `c'
				local lab `"(`lt' vs `r(lab)')"'
			}
			local key `tv'
			if "`gg'" != "" {
				local key `tv'#`mv'
				_mmwsmed_vl `mv' `gg'
				local lg `"`r(lab)'"'
				if regexm("`eq'", "_diff$") {
					_mmwsmed_vl `mv' `g0'
					local lab `"`lab' (`lg' vs `r(lab)')"'
				}
				else local lab `"`lab' (`lg')"'
			}
			local lev 1
		}
		else if "`main'" == "" & strpos("`nm'", ".") {
			local pieces = subinstr("`nm'", "#", " ", .)
			local key
			local lab
			local nf 0
			foreach p of local pieces {
				if regexm("`p'", "^([0-9]+)[a-z]*[.](.+)$") {
					local pv = regexs(1)
					local pn = regexs(2)
					_mmwsmed_vl `pn' `pv'
					local lab `"`lab' (`r(lab)')"'
					local key `key'#`pn'
					local ++nf
				}
				else local key `key'#`p'
			}
			local key = substr("`key'", 2, .)
			local lab = strtrim(`"`lab'"')
			if `nf' == 0 {
				local lab = subinstr("`nm'", "c.", "", .)
				local key
			}
			else {
				if `nf' == 1 local lab = substr(`"`lab'"', 2, udstrlen(`"`lab'"') - 2)
				local lev 1
			}
		}
		local eq`j' "`eq'"
		local eql`j' `"`eql'"'
		local key`j' "`key'"
		local lab`j' `"`lab'"'
		local lev`j' `lev'
		local s = max(`s', udstrlen(`"`eql'"'), udstrlen("`key'"), udstrlen(`"`lab'"') + `lev')
	}
	local s = min(`s', 40)
	local B = `s' + 2

	* header
	local stat = cond(`df' > 0, "t", "z")
	local lv = strofreal(`level')
	if `"`note'"' != "" {
		if `"`notesmcl'"' == "" local notesmcl `"`note'"'
		di as txt _col(`=max(1, `s' + 67 - udstrlen(`"`note'"'))') `"`notesmcl'"'
	}
	di as txt "{hline `=`s'+1'}{c TT}{hline 64}"
	if "`coeflegend'" != "" {
		di as txt %`s's abbrev("`dep'", `s') " {c |} Coefficient  Legend"
	}
	else if "`boot'" != "" {
		di as txt _col(`B') "{c |}" _col(`=`B'+4') "Observed" _col(`=`B'+15') "Bootstrap" _col(`=`B'+53') "Normal-based"
		di as txt %`s's abbrev("`dep'", `s') " {c |} coefficient  std. err.      `stat'    P>|`stat'|     [`lv'% conf. interval]"
	}
	else {
		local se "Std. err."
		if "`vtitle'" != "" {
			di as txt _col(`B') "{c |}" _col(`=`B'+15') "{center 9:`vtitle'}"
			local se "std. err."
		}
		di as txt %`s's abbrev("`dep'", `s') " {c |} Coefficient  `se'      `stat'    P>|`stat'|     [`lv'% conf. interval]"
	}
	di as txt "{hline `=`s'+1'}{c +}{hline 64}"

	* rows
	if `df' > 0 local cr = invttail(`df', (100 - `level')/200)
	else        local cr = invnormal(1 - (100 - `level')/200)
	local lasteq "__none__"
	local lastkey "__none__"
	forvalues j = 1/`nc' {
		if "`eq`j''" != "`lasteq'" {
			if `j' > 1 di as txt "{hline `=`s'+1'}{c +}{hline 64}"
			if "`eq`j''" != "" di as res substr(`"`eql`j''"', 1, `s') as txt _col(`B') "{c |}"
			local lasteq "`eq`j''"
			local lastkey "__none__"
		}
		if "`key`j''" != "" & "`key`j''" != "`lastkey'" {
			di as txt %`s's abbrev("`key`j''", `s') " {c |}"
		}
		local lastkey "`key`j''"
		if `lev`j'' di as txt %`=`s'-1's substr(`"`lab`j''"', 1, `s' - 1) "  {c |}" _c
		else        di as txt %`s's substr(`"`lab`j''"', 1, `s') " {c |}" _c
		local bj = `b'[1, `j']
		local sj = sqrt(`v'[`j', `j'])
		if "`coeflegend'" != "" {
			local full : word `j' of `cn'
			di as res _col(`=`B'+3') %9.0g `bj' as txt "  _b[`full']"
			continue
		}
		if `bj' == 0 & (`sj' == 0 | missing(`sj')) {
			di as res _col(`=`B'+3') %9.0g 0 as txt "  (omitted)"
			continue
		}
		if missing(`sj') | `sj' == 0 {
			di as res _col(`=`B'+3') %9.0g `bj' as txt _col(`=`B'+22') "."
			continue
		}
		local z = `bj'/`sj'
		if `df' > 0 local p = 2*ttail(`df', abs(`z'))
		else        local p = 2*normal(-abs(`z'))
		di as res _col(`=`B'+3') %9.0g `bj' _col(`=`B'+14') %9.0g `sj' _col(`=`B'+24') %8.2f `z' ///
			_col(`=`B'+35') %5.3f `p' _col(`=`B'+44') %9.0g `bj' - `cr'*`sj' _col(`=`B'+56') %9.0g `bj' + `cr'*`sj'
	}
	di as txt "{hline `=`s'+1'}{c BT}{hline 64}"
end


**********
* display
**********
program _mmwsmed_display
	version 15
	syntax [, Level(cilevel) LEGend DIAGnostics COEFLegend ]
	* nothing to show under -quietly-
	if !c(noisily) exit

	local design `e(med_type)'
	local meth parametric
	if "`e(mweight)'" == "odds" local meth "parametric (treatment odds ratio)"
	if "`e(method)'" == "nonparametric" {
		local sa : word 1 of `e(strata)'
		local sb : word 2 of `e(strata)'
		local meth "nonparametric (`sa' x `sb' strata)"
	}
	if "`design'" == "single" {
		local mline "`e(mvar)' (`e(mmodel)')"
		local mlab Mediator:
	}
	else {
		local mline "`e(mvar1)' (`e(mmodel1)'), `e(mvar2)' (`e(mmodel2)'); `design'"
		local mlab Mediators:
	}
	if "`e(heteroskedastic)'" != "" local mline : subinstr local mline "(linear)" "(linear, heteroskedastic)", all

	local iscont = "`e(tvartype)'" == "continuous"
	if `iscont' {
		local tl `e(tlevels)'
		gettoken d0 drest : tl
		local drest = strtrim(subinstr(strtrim("`drest'"), " ", ", ", .))
		di _n as txt "`e(title)'" _col(49) "Number of obs" _col(67) "= " as res %10.0fc e(N)
		di as txt "Weighting:  " as res "GPS (`e(gpsmodel)'), Epanechnikov kernel" _col(49) as txt "Trimmed" _col(67) "= " as res %10.0fc e(N_trim)
		di as txt "Outcome:    " as res "`e(depvar)'" _col(49) as txt "Bandwidth" _col(67) "= " as res %10.0g e(bwidth)
		di as txt "Mediator:   " as res "`e(mvar)'" as txt " (in the GPS model)" _col(49) "Trim cutoff" _col(67) "= " as res %10.0g e(trim)
		di as txt "Treatment:  " as res "`e(tvar)'" as txt " (continuous; control = `d0'; evaluated at `drest')"
		if "`e(gpscov)'" != "" di as txt "GPS covariates: " as res "`e(gpscov)'"
		local clab `d0'
	}
	else {
		di _n as txt "`e(title)'" _col(49) "Number of obs" _col(67) "= " as res %10.0fc e(N)
		di as txt "Weighting:  " as res "`meth'" _col(49) as txt "  Control" _col(67) "= " as res %10.0fc e(N_control)
		di as txt "Outcome:    " as res "`e(depvar)'" _col(49) as txt "  Other levels" _col(67) "= " as res %10.0fc e(N_treat)
		di as txt "`mlab'" _col(13) as res "`mline'" _col(49) as txt "Excluded" _col(67) "= " as res %10.0fc e(N_excl)
		_mmwsmed_vl `e(tvar)' `e(control)'
		local clab `"`r(lab)'"'
		di as txt "Treatment:  " as res "`e(tvar)'" as txt " (`e(tvartype)'; control = `clab')" ///
			_col(49) "Stacked obs" _col(67) "= " as res %10.0fc e(N_stack)
		if "`e(omodel)'" != "" & "`e(omodel)'" != "linear" {
			di as txt "Outcome model: " as res "`e(omodel)'" as txt " (effects are differences in potential-outcome means)"
		}
		local tml "`e(tmodel)'"
		if "`e(thet)'" != "" local tml "`tml'; variance: `e(thet)'"
		if "`e(tcov)'" != "" di as txt "Treatment selection: " as res "`e(tmethod)'" as txt " (" as res "`tml'" as txt ") on " as res "`e(tcov)'"
		else if "`e(mweight)'" == "odds" & "`e(tmodel)'" != "" & !inlist("`e(tmodel)'", "logit", "mlogit") {
			di as txt "Treatment model (odds weights): " as res "`tml'"
		}
		if "`e(moderator)'" != "" {
			local mlabs
			local sep
			foreach g in `e(mlevels)' {
				_mmwsmed_vl `e(moderator)' `g'
				local mlabs `"`mlabs'`sep'`r(lab)'"'
				local sep ", "
			}
			di as txt "Moderator:  " as res "`e(moderator)'" as txt " (levels: `mlabs')"
		}
		if "`e(caliper)'" != "" | `e(N_excl)' > 0 {
			di as txt "Exclusions: support = " as res e(N_excl_support) as txt ", strata = " as res e(N_excl_strata) ///
				as txt ", treatment weights = " as res e(N_excl_tw) as txt ", undefined weights = " as res e(N_excl_miss)
		}
	}

	di
	* standard-error note, right-aligned above the table as in -regress-
	local senote
	local sesmcl
	if "`e(prefix)'" != "bootstrap" {
		local nclu = strtrim(string(e(N_clust), "%12.0fc"))
		* std. err. that account for the estimated weights are labeled two-step
		local ts
		if "`e(vceweights)'" == "estimated" local ts "Two-step std. err."
		else                                local ts "Std. err."
		if "`e(clustvar)'" != "" {
			local senote "(`ts' adjusted for `nclu' clusters in `e(clustvar)')"
			local sesmcl "(`ts' adjusted for {res:`nclu'} clusters in {res:`e(clustvar)'})"
		}
		else {
			local senote "(`ts' adjusted for `nclu' obs)"
			local sesmcl "(`ts' adjusted for {res:`nclu'} obs)"
		}
	}
	local dfr = e(df_r)
	if missing(`dfr') local dfr -1
	tempname eb eV
	matrix `eb' = e(b)
	matrix `eV' = e(V)
	local boot
	if "`e(prefix)'" == "bootstrap" | "`e(vce)'" == "bootstrap" local boot boot
	_mmwsmed_ctab, b(`eb') v(`eV') dep(`e(depvar)') df(`dfr') level(`level') vtitle(`e(vcetype)') ///
		`boot' `coeflegend' main mod(`e(moderator)') mlev(`e(mlevels)') note(`senote') notesmcl(`sesmcl') ///
		`=cond(`iscont', `"clev(`e(tlevels)')"', "")'

	if "`legend'" != "" {
		local st `e(stats)'
		local c c
		if "`design'" == "single" {
			if `: list posof "NIE" in st'  di as txt "NIE   natural indirect effect          = E[Y(t,M(t))] - E[Y(t,M(c))]"
			if `: list posof "NDE" in st'  di as txt "NDE   natural direct effect            = E[Y(t,M(c))] - E[Y(c,M(c))]"
			if `: list posof "TE" in st'   di as txt "TE    total effect                     = E[Y(t,M(t))] - E[Y(c,M(c))]"
			if `: list posof "PNIE" in st' di as txt "PNIE  pure natural indirect effect     = E[Y(c,M(t))] - E[Y(c,M(c))]"
			if `: list posof "TNDE" in st' di as txt "TNDE  total natural direct effect      = E[Y(t,M(t))] - E[Y(c,M(t))]"
			if `: list posof "INT" in st'  di as txt "INT   treatment-by-mediator interaction = NIE - PNIE = TNDE - NDE"
			if `iscont' {
				local dl
				local j 0
				foreach d of local tl {
					local dl `dl' d`j' = `d'`=cond(`j' == 0, " (control)", "")',
					local ++j
				}
				di as txt "POmeans: YaMb = E[Y(d_a,M(d_b))]; " substr("`dl'", 1, length("`dl'") - 1)
			}
			else di as txt "POmeans: YaMb = E[Y(a,M(b))]"
		}
		else if "`design'" == "parallel" {
			di as txt "Y(z,a,b) = E[Y(z, M1(a), M2(b))], M1 = `e(mvar1)', M2 = `e(mvar2)'; POmeans: Yz_a_b"
			if `: list posof "NIE" in st'    di as txt "NIE     natural indirect effect (M1 and M2)    = Y(t,t,t) - Y(t,c,c)"
			if `: list posof "NIE1_0" in st' di as txt "NIE1_0  indirect effect via M1, M2 at control  = Y(t,t,c) - Y(t,c,c)"
			if `: list posof "NIE1_1" in st' di as txt "NIE1_1  indirect effect via M1, M2 at t        = Y(t,t,t) - Y(t,c,t)"
			if `: list posof "NIE2_0" in st' di as txt "NIE2_0  indirect effect via M2, M1 at control  = Y(t,c,t) - Y(t,c,c)"
			if `: list posof "NIE2_1" in st' di as txt "NIE2_1  indirect effect via M2, M1 at t        = Y(t,t,t) - Y(t,t,c)"
			if `: list posof "NDE" in st'    di as txt "NDE     natural direct effect                  = Y(t,c,c) - Y(c,c,c)"
			if `: list posof "TE" in st'     di as txt "TE      total effect                           = Y(t,t,t) - Y(c,c,c)"
			if `: list posof "M1xM2" in st'  di as txt "M1xM2   indirect effect via M1-by-M2 interaction = NIE2_1 - NIE2_0"
		}
		else {
			di as txt "Y(z,a,b) = E[Y(z, M1(a), M2(b, M1(a)))], M1 = `e(mvar1)', M2 = `e(mvar2)'; POmeans: Yz_a_b"
			if `: list posof "NIE" in st'   di as txt "NIE    natural indirect effect (M1 and M2)     = Y(t,t,t) - Y(t,c,c)"
			if `: list posof "NIE1" in st'  di as txt "NIE1   indirect effect via M1                  = Y(t,t,c) - Y(t,c,c)"
			if `: list posof "NIE2" in st'  di as txt "NIE2   indirect effect via M2                  = Y(t,c,t) - Y(t,c,c)"
			if `: list posof "NDE" in st'   di as txt "NDE    natural direct effect                   = Y(t,c,c) - Y(c,c,c)"
			if `: list posof "TE" in st'    di as txt "TE     total effect                            = Y(t,t,t) - Y(c,c,c)"
			if `: list posof "PNIE1" in st' di as txt "PNIE1  pure indirect effect via M1             = Y(c,t,c) - Y(c,c,c)"
			if `: list posof "PNIE2" in st' di as txt "PNIE2  pure indirect effect via M2             = Y(c,c,t) - Y(c,c,c)"
			if `: list posof "M1xM2" in st' di as txt "M1xM2  indirect effect via M1-by-M2 interaction = Y(t,t,t) - Y(t,t,c) - Y(t,c,t) + Y(t,c,c)"
			if `: list posof "ZxM1" in st'  di as txt "ZxM1   treatment-by-M1 interaction             = NIE1 - PNIE1"
			if `: list posof "ZxM2" in st'  di as txt "ZxM2   treatment-by-M2 interaction             = NIE2 - PNIE2"
		}
		di as txt `"t = treatment level being compared; c = control level (`clab')"'
		if "`e(indepvars)'" != "" di as txt "Potential-outcome means average the outcome-model predictions over the sample covariates."
		if "`e(moderator)'" != "" di as txt "Equations ending in _diff give the effect at each level of `e(moderator)' minus the effect at its first level."
		if "`e(prefix)'" != "bootstrap" & "`e(vceweights)'" == "estimated" {
			di as txt "Std. err. account for estimation of the models that produce the weights."
		}
	}
	* std. err. that treat the weights as known are always flagged
	if "`e(prefix)'" != "bootstrap" {
		if strpos("`e(vceweights)'", "step") {
			di as txt "Note: std. err. treat the weights as known, because nonparametric and MMWS weights are step functions"
			di as txt "      of estimated propensity scores; vce(bootstrap) accounts for their estimation."
		}
		else if "`e(vceweights)'" == "known" di as txt "Note: std. err. treat the weights as known."
	}

	if "`diagnostics'" == "" exit
	if `iscont' {
		di _n as txt "note: diagnostics are not available with a continuous treatment"
		exit
	}

	* controlled treatment-by-mediator effects (balance weights; Hong 2015, Step 5)
	capture confirm matrix e(ctl_b)
	if !_rc {
		tempname cb cv
		matrix `cb' = e(ctl_b)
		matrix `cv' = e(ctl_V)
		local ctldf = e(ctl_df)
		if missing(`ctldf') local ctldf -1
		local mtypes `e(mmodel)' `e(mmodel1)' `e(mmodel2)'
		di _n as txt "Controlled treatment-by-mediator effects (balance weights; robust std. err.)"
		if strpos(" `mtypes' ", " linear ") | strpos(" `mtypes' ", " poisson ") {
			di as txt "(continuous and count mediators are centered at their means)"
		}
		_mmwsmed_ctab, b(`cb') v(`cv') dep(`e(depvar)') df(`ctldf') level(`level') mod(`e(moderator)')
	}

	* labels of the moderator levels (balance, mediator check, and weight tables)
	local mod `e(moderator)'
	local mw 0
	if "`mod'" != "" {
		local mw = udstrlen("`mod'")
		foreach g in `e(mlevels)' {
			_mmwsmed_vl `mod' `g'
			local glab`g' `"`r(lab)'"'
			local mw = max(`mw', udstrlen(`"`r(lab)'"'))
		}
		local mw = `mw' + 3
	}

	* covariate balance across treatment-by-mediator cells (Hong 2015, Step 4)
	capture confirm matrix e(balance)
	if !_rc {
		tempname BAL
		matrix `BAL' = e(balance)
		local glevels `e(mlevels)'
		local G : word count `glevels'
		if `G' == 0 local G 1
		local req : roweq `BAL'
		local rnm : rownames `BAL'
		local meds : list uniq req
		local ncol = 2*`G'
		local nrow = rowsof(`BAL')
		* stub fitted to the longest covariate name; group columns fitted to the moderator labels
		local sw = udstrlen("Covariate")
		foreach t of local rnm {
			local sw = max(`sw', udstrlen("`t'"))
		}
		local gw 22
		if `G' > 1 {
			foreach g of local glevels {
				local gw = max(`gw', udstrlen(`"`mod' = `glab`g''"') + 3)
			}
		}
		local wd = `gw'*`G'
		foreach md of local meds {
			di _n as txt "Covariate balance across `e(tvar)'-by-`md' (p-values, joint test of `e(tvar)', `md', and interaction)"
			di as txt "{hline `=`sw'+1'}{c TT}{hline `wd'}"
			if `G' > 1 {
				di as txt _col(`=`sw'+2') "{c |}" _c
				foreach g of local glevels {
					di as txt %`gw's `"`mod' = `glab`g''"' _c
				}
				di
			}
			di as txt %`sw's "Covariate" " {c |}" _c
			forvalues gi = 1/`G' {
				di as txt %`=`gw'-10's "unweighted" %10s "weighted" _c
			}
			di
			di as txt "{hline `=`sw'+1'}{c +}{hline `wd'}"
			forvalues i = 1/`nrow' {
				local q : word `i' of `req'
				if "`q'" != "`md'" continue
				local t : word `i' of `rnm'
				di as txt %`sw's "`t'" " {c |}" _c
				forvalues j = 1/`ncol' {
					if mod(`j', 2) di as res %`=`gw'-10'.4f `BAL'[`i', `j'] _c
					else           di as res %10.4f `BAL'[`i', `j'] _c
				}
				di
			}
			di as txt "{hline `=`sw'+1'}{c BT}{hline `wd'}"
		}
		if "`e(method)'" == "nonparametric" & `: word count `e(tlevels)'' == 2 {
			di as txt "Weights: MMWS for mediator value selection within each treatment group"
		}
		else {
			di as txt "Weights: stabilized inverse probability (categorical mediator) or density (continuous or count"
			di as txt "         mediator) of the observed mediator value within each treatment group"
		}
	}

	* copy-name stub shared by the two tables below
	local cw = udstrlen("Copy")
	foreach c in `e(copies)' {
		local cw = max(`cw', udstrlen("`c'"))
	}

	* mediator distribution check
	local mnames `e(mvar)'
	if "`mnames'" == "" local mnames `e(mvar1)' `e(mvar2)'
	capture confirm matrix e(mcheck)
	if !_rc {
		tempname MC
		matrix `MC' = e(mcheck)
		local nr = rowsof(`MC')
		* column widths fitted to the mediator names and level labels
		local mdw = udstrlen("Mediator")
		foreach mn of local mnames {
			local mdw = max(`mdw', udstrlen("`mn'"))
		}
		local lw = udstrlen("Level")
		forvalues i = 1/`nr' {
			local k = `MC'[`i', 3]
			local mn : word `k' of `mnames'
			local l = `MC'[`i', 4]
			if missing(`l') local lev`i' mean
			else {
				_mmwsmed_vl `mn' `l'
				local lev`i' `"`r(lab)'"'
			}
			local lw = max(`lw', udstrlen(`"`lev`i''"'))
		}
		local lw = `lw' + 2
		local rw = 1 + `mdw' + `lw' + 22 + `mw'
		di _n as txt "Mediator distribution check: weighted copy vs. target treatment group"
		di as txt "{hline `=`cw'+1'}{c TT}{hline `rw'}"
		di as txt %`cw's "Copy" " {c |} " %-`mdw's "Mediator" %`lw's "Level" %11s "Weighted" %11s "Target" _c
		if "`mod'" != "" di as txt %`mw's "`mod'" _c
		di
		di as txt "{hline `=`cw'+1'}{c +}{hline `rw'}"
		forvalues i = 1/`nr' {
			local cc = `MC'[`i', 2]
			local cn : word `cc' of `e(copies)'
			local k = `MC'[`i', 3]
			local mn : word `k' of `mnames'
			di as txt %`cw's "`cn'" " {c |} " %-`mdw's "`mn'" %`lw's `"`lev`i''"' as res %11.4f `MC'[`i', 5] %11.4f `MC'[`i', 6] _c
			if "`mod'" != "" {
				local g = `MC'[`i', 1]
				di as txt %`mw's `"`glab`g''"' _c
			}
			di
		}
		di as txt "{hline `=`cw'+1'}{c BT}{hline `rw'}"
	}

	* weight diagnostics
	capture confirm matrix e(wdiag)
	if !_rc {
		tempname WD
		matrix `WD' = e(wdiag)
		local nr = rowsof(`WD')
		local rw = 56 + `mw'
		di _n as txt "Weight diagnostics"
		di as txt "{hline `=`cw'+1'}{c TT}{hline `rw'}"
		di as txt %`cw's "Copy" " {c |}        n   Max/mean  Max share (%)   Kish ESS   ESS (%)" _c
		if "`mod'" != "" di as txt %`mw's "`mod'" _c
		di
		di as txt "{hline `=`cw'+1'}{c +}{hline `rw'}"
		forvalues i = 1/`nr' {
			local cc = `WD'[`i', 2]
			local cn : word `cc' of `e(copies)'
			di as txt %`cw's "`cn'" " {c |}" as res %9.0f `WD'[`i', 3] %11.2f `WD'[`i', 4] ///
				%15.2f `WD'[`i', 5] %11.1f `WD'[`i', 6] %10.1f `WD'[`i', 7] _c
			if "`mod'" != "" {
				local g = `WD'[`i', 1]
				di as txt %`mw's `"`glab`g''"' _c
			}
			di
		}
		di as txt "{hline `=`cw'+1'}{c BT}{hline `rw'}"
	}
end


***********************
* continuous treatment
***********************
program _mmwsmed_cest, eclass
	version 15
	syntax varname(numeric) [if], treat(varname numeric) mterm(string) levels(numlist min=2) bw(real) ///
		trim(real) stats(string) uwvar(varname) [ x(string) LOGNormal ]
	marksample touse
	local y `varlist'
	tempvar g w e1 e2 xb1 xb2 keep
	if "`lognormal'" != "" qui gen double `g' = ln(`treat') if `touse'
	else                   qui gen double `g' = `treat' if `touse'
	qui gen double `w' = `uwvar' if `touse'
	* GPS models
	qui regress `g' `x' [aw=`w'] if `touse'
	qui predict double `xb1' if `touse', xb
	qui gen double `e1' = (`g' - `xb1')^2 if `touse'
	qui summarize `e1' [aw=`w'] if `touse', meanonly
	local s1 = sqrt(r(mean))
	qui regress `g' `mterm' `x' [aw=`w'] if `touse'
	qui predict double `xb2' if `touse', xb
	qui gen double `e2' = (`g' - `xb2')^2 if `touse'
	qui summarize `e2' [aw=`w'] if `touse', meanonly
	local s2 = sqrt(r(mean))
	* densities and kernels at each evaluation value (index 0 = control)
	local nl : word count `levels'
	local K = `nl' - 1
	forvalues j = 0/`K' {
		local d : word `=`j'+1' of `levels'
		local gd = cond("`lognormal'" != "", ln(`d'), `d')
		tempvar f1`j' f2`j' k`j'
		qui gen double `f1`j'' = normalden(`gd', `xb1', `s1') if `touse'
		qui gen double `f2`j'' = normalden(`gd', `xb2', `s2') if `touse'
		qui gen double `k`j'' = cond(abs((`treat' - `d')/`bw') < 1, 0.75*(1 - ((`treat' - `d')/`bw')^2), 0) if `touse'
	}
	* weights for every copy: Y0M0, Y1M1, ..., YKMK, then Y1M0, Y0M1, ..., YKM0, Y0MK
	local cn
	local wl
	forvalues j = 0/`K' {
		tempvar w`j'`j'
		qui gen double `w`j'`j'' = `w'*`k`j''/`f1`j'' if `touse'
		local cn `cn' Y`j'M`j'
		local wl `wl' `w`j'`j''
	}
	forvalues t = 1/`K' {
		tempvar w`t'0 w0`t'
		qui gen double `w`t'0' = `w'*`k`t''*`f20'/(`f2`t''*`f10') if `touse'
		qui gen double `w0`t'' = `w'*`k0'*`f2`t''/(`f20'*`f1`t'') if `touse'
		local cn `cn' Y`t'M0 Y0M`t'
		local wl `wl' `w`t'0' `w0`t''
	}
	* trimming: drop units whose normalized weight exceeds trim in any mean
	qui gen byte `keep' = `touse'
	foreach v of local wl {
		qui summarize `v' if `touse', meanonly
		if r(sum) <= 0 {
			di as err "no observations with treatment within the bandwidth of an evaluation value; increase bwidth()"
			exit 2000
		}
		qui replace `keep' = 0 if `touse' & `v'/r(sum) > `trim'
	}
	qui count if `touse' & !`keep'
	local ntrim = r(N)
	* potential-outcome means
	local C : word count `cn'
	tempname mu
	matrix `mu' = J(1, `C', .)
	local j 0
	foreach v of local wl {
		local ++j
		tempvar wy
		qui gen double `wy' = `v'*`y' if `keep'
		qui summarize `wy' if `keep', meanonly
		local num = r(sum)
		qui summarize `v' if `keep', meanonly
		if r(sum) <= 0 {
			di as err "no observations remain after trimming for a potential-outcome mean; increase bwidth() or trim()"
			exit 2000
		}
		matrix `mu'[1, `j'] = `num'/r(sum)
		drop `wy'
	}
	matrix colnames `mu' = `cn'
	* statistics
	local wantpo 0
	if "`stats'" == "default"  local eff NIE NDE TE
	else if "`stats'" == "all" {
		local eff NIE NDE TE PNIE TNDE INT
		local wantpo 1
	}
	else {
		local eff
		foreach e in nie nde te pnie tnde int {
			if `: list e in stats' local eff `eff' `=upper("`e'")'
		}
		if `: list posof "pomeans" in stats' local wantpo 1
	}
	tempname b
	local stripe
	if `wantpo' {
		matrix `b' = `mu'
		foreach c of local cn {
			local stripe `stripe' POmeans:`c'
		}
	}
	foreach e of local eff {
		forvalues t = 1/`K' {
			local ctt = el(`mu', 1, colnumb(`mu', "Y`t'M`t'"))
			local ct0 = el(`mu', 1, colnumb(`mu', "Y`t'M0"))
			local c00 = el(`mu', 1, colnumb(`mu', "Y0M0"))
			local c0t = el(`mu', 1, colnumb(`mu', "Y0M`t'"))
			if "`e'" == "NIE"  local v = `ctt' - `ct0'
			if "`e'" == "NDE"  local v = `ct0' - `c00'
			if "`e'" == "TE"   local v = `ctt' - `c00'
			if "`e'" == "PNIE" local v = `c0t' - `c00'
			if "`e'" == "TNDE" local v = `ctt' - `c0t'
			if "`e'" == "INT"  local v = (`ctt' - `ct0') - (`c0t' - `c00')
			matrix `b' = nullmat(`b'), `v'
			local stripe `stripe' `e':r`t'vs0.`treat'
		}
	}
	matrix colnames `b' = `stripe'
	* the estimation sample includes trimmed units, so that -bootstrap- resamples them and re-trims each sample
	qui count if `touse'
	local N = r(N)
	ereturn post `b', esample(`touse') obs(`N')
	ereturn scalar N_trim = `ntrim'
	ereturn local stats "`eff'"
	ereturn local copies "`cn'"
end

*****************************************************************
* _mmwsmed_bsci: post the Mata bootstrap results through -bstat-
*****************************************************************
program _mmwsmed_bsci, eclass
	args bobs BB N level touse
	local cn : colfullnames `bobs'
	local k = colsof(`bobs')
	if colsof(`BB') != `k' | rowsof(`BB') < 2 exit 503
	local names
	forvalues j = 1/`k' {
		local names `names' _mmwbs`j'
	}
	tempname b0 R
	mata: st_matrix("`b0'", st_matrix("`bobs'"))
	mata: st_matrix("`R'", st_matrix("`BB'"))
	matrix colnames `b0' = `names'
	matrix colnames `R' = `names'
	preserve
	quietly {
		drop _all
		svmat double `R', names(col)
		bstat `names', stat(`b0') n(`N') level(`level')
	}
	restore
	tempname m bn Vn
	local mats : e(matrices)
	foreach mat of local mats {
		if inlist("`mat'", "b", "V") continue
		matrix `m' = e(`mat')
		if colsof(`m') == `k' {
			matrix colnames `m' = `cn'
			ereturn matrix `mat' = `m'
		}
	}
	matrix `bn' = e(b)
	matrix `Vn' = e(V)
	matrix colnames `bn' = `cn'
	matrix colnames `Vn' = `cn'
	matrix rownames `Vn' = `cn'
	* the statistics are the coefficients (_b) of a multiple-equation model, not separate expressions
	local eqs : coleq `bn'
	local eqs : list uniq eqs
	local neq : word count `eqs'
	ereturn scalar k_eq = `neq'
	ereturn scalar k_exp = 0
	ereturn scalar k_eexp = `k'
	* last step: -ereturn repost- moves the matrices and the sample marker
	ereturn repost b = `bn' V = `Vn', rename esample(`touse')
end



**********************************************************************
* Mata: two-step (M-estimation) variance for the stacked outcome model
**********************************************************************
version 15
mata:

struct mmw_rec {
	real scalar type, k, arm
	real matrix G, Psi, Vb
}

void mmw_init()
{
	pointer(transmorphic) scalar p
	if ((p = findexternal("mmw_A")) == NULL) p = crexternal("mmw_A")
	*p = asarray_create("real")
	if ((p = findexternal("mmw_n")) == NULL) p = crexternal("mmw_n")
	*p = 0
}

void mmw_add(real scalar type, real scalar k, real scalar arm,
	string scalar touse, string scalar obsid, string scalar subv, string scalar fitv,
	string scalar scv, string scalar xv, string scalar wv, string scalar Vname,
	real scalar par, string scalar treatv)
{
	struct mmw_rec scalar R
	real colvector id, o, sub, fit, w, T, s
	real matrix X, S, Zd
	real scalar n

	id  = st_data(., obsid, touse)
	o   = order(id, 1)
	n   = rows(id)
	sub = editmissing(st_data(., subv, touse)[o], 0)
	fit = editmissing(st_data(., fitv, touse)[o], 0)
	w   = editmissing(st_data(., wv, touse)[o], 0)
	T   = st_data(., treatv, touse)[o]
	if (xv != "") {
		X = editmissing(st_data(., xv, touse)[o, .], 0)
	}
	else {
		X = J(n, 0, .)
	}
	Zd = (X, J(n, 1, 1))
	R.type = type
	R.k    = k
	R.arm  = arm
	if (type == 1 | type == 4) {
		s     = editmissing(st_data(., scv, touse)[o], 0) :* sub
		R.G   = Zd :* s
		R.Psi = Zd :* (s :* w :* fit)
		R.Vb  = st_matrix(Vname)
	}
	else if (type == 6 | type == 7) {
		s     = editmissing(st_data(., scv, touse)[o], 0) :* sub
		R.G   = Zd :* sub
		R.Psi = Zd :* (s :* w :* fit)
		R.Vb  = st_matrix(Vname)
	}
	else if (type == 2) {
		S     = editmissing(st_data(., scv, touse)[o, .], 0) :* sub
		R.G   = (X :* S[., 1], S[|1, 2 \ n, cols(S)|])
		R.Psi = R.G :* (w :* fit)
		R.Vb  = st_matrix(Vname)
	}
	else if (type == 3) {
		s     = editmissing(st_data(., scv, touse)[o], 0) :* sub
		R.G   = (Zd :* (s :/ par), (-1/(2*par) :+ (s:^2) :/ (2*par^2)) :* sub)
		R.Psi = (Zd :* (s :* w :* fit), (s:^2 :- par) :* w :* fit)
		R.Vb  = blockdiag(invsym(quadcross(Zd, w :* fit, Zd)), 1/quadsum(w :* fit))
	}
	else if (type == 5) {
		R.G   = (T :/ par - (1 :- T) :/ (1 - par)) :* sub
		R.Psi = (T :- par) :* w :* fit
		R.Vb  = 1/quadsum(w :* fit)
	}
	mmw_reg(R)
}

void mmw_reg(struct mmw_rec scalar R)
{
	pointer(transmorphic) scalar pA, pn
	if (rows(R.Vb) != cols(R.Psi) | cols(R.Vb) != cols(R.G)) {
		errprintf("mmwsmed: internal dimension mismatch in two-step variance (model type %f)\n", R.type)
		exit(498)
	}
	pA = findexternal("mmw_A")
	pn = findexternal("mmw_n")
	*pn = *pn + 1
	asarray(*pA, *pn, R)
}

/*  drop base-level and omitted columns from a coefficient vector and its variance matrix */
void mmw_dropbase(string scalar bn, string scalar vn)
{
	string matrix cs
	real rowvector keep
	real scalar j

	cs   = st_matrixcolstripe(bn)
	keep = J(1, 0, .)
	for (j = 1; j <= rows(cs); j++) {
		if (!regexm(cs[j, 2], "(^|#)[0-9]+b[.]") & !regexm(cs[j, 2], "(^|#)[0-9]*o[.]")) keep = (keep, j)
	}
	st_matrix(bn, st_matrix(bn)[., keep])
	st_matrixcolstripe(bn, cs[keep', .])
	st_matrix(vn, st_matrix(vn)[keep, keep])
	st_matrixcolstripe(vn, cs[keep', .])
	st_matrixrowstripe(vn, cs[keep', .])
}

/*  multinomial models */
void mmw_add_ml(real scalar type, real scalar k, real scalar arm,
	string scalar touse, string scalar obsid, string scalar subv, string scalar fitv,
	string scalar yv, string scalar pv, string scalar xv, string scalar wv,
	string scalar levs, real scalar base)
{
	struct mmw_rec scalar R
	real colvector id, o, sub, fit, w, y, c
	real matrix X, Zd, P, S, Psi, H, Vb
	real rowvector lv, nb
	real scalar n, p, q, j, l

	id  = st_data(., obsid, touse)
	o   = order(id, 1)
	n   = rows(id)
	sub = editmissing(st_data(., subv, touse)[o], 0)
	fit = editmissing(st_data(., fitv, touse)[o], 0)
	w   = editmissing(st_data(., wv, touse)[o], 0)
	y   = st_data(., yv, touse)[o]
	P   = editmissing(st_data(., pv, touse)[o, .], 0)
	if (xv != "") X = editmissing(st_data(., xv, touse)[o, .], 0)
	else          X = J(n, 0, .)
	Zd  = (X, J(n, 1, 1))
	p   = cols(Zd)
	lv  = strtoreal(tokens(levs))
	nb  = selectindex(lv :!= base)
	q   = cols(nb)
	S   = J(n, q, 0)
	for (j = 1; j <= q; j++) S[., j] = editmissing(y :== lv[nb[j]], 0) - P[., nb[j]]
	Psi = J(n, q*p, 0)
	for (j = 1; j <= q; j++) Psi[|1, (j - 1)*p + 1 \ n, j*p|] = Zd :* (S[., j] :* w :* fit)
	H = J(q*p, q*p, 0)
	for (j = 1; j <= q; j++) {
		for (l = 1; l <= q; l++) {
			c = w :* fit :* P[., nb[j]] :* ((j == l) :- P[., nb[l]])
			H[|(j - 1)*p + 1, (l - 1)*p + 1 \ j*p, l*p|] = quadcross(Zd, c, Zd)
		}
	}
	Vb = invsym(H)
	for (j = 1; j <= q; j++) {
		R.type = type
		R.k    = k
		R.arm  = (type == 12 ? arm : lv[nb[j]])
		R.Psi  = Psi
		R.Vb   = Vb[|1, (j - 1)*p + 1 \ rows(Vb), j*p|]
		if (type == 8 | type == 12) R.G = Zd :* (S[., j] :* sub)
		else                        R.G = Zd :* sub
		mmw_reg(R)
	}
}

/*  marginal treatment proportions of a multivalued treatment (IPTW numerators) */
void mmw_add_marg(string scalar touse, string scalar obsid, string scalar subv,
	string scalar tv, string scalar wv, real scalar L)
{
	struct mmw_rec scalar R
	real colvector id, o, sub, w, T, iz
	real matrix G, Psi
	real scalar n, z, pz, sw

	id  = st_data(., obsid, touse)
	o   = order(id, 1)
	n   = rows(id)
	sub = editmissing(st_data(., subv, touse)[o], 0)
	w   = editmissing(st_data(., wv, touse)[o], 0)
	T   = editmissing(st_data(., tv, touse)[o], 0)
	sw  = quadsum(w :* sub)
	R.type = 9
	R.k    = 0
	R.arm  = 0
	G      = J(n, L, 0)
	Psi    = J(n, L, 0)
	for (z = 1; z <= L; z++) {
		iz = (T :== z) :* sub
		pz = quadsum(w :* iz)/sw
		G[., z]   = iz :/ pz
		Psi[., z] = (iz :- pz) :* w :* sub
	}
	R.G   = G
	R.Psi = Psi
	R.Vb  = I(L) :/ sw
	mmw_reg(R)
}

/*  heteroskedastic normal mediator (ML, as -hetregress-) */
void mmw_add_hreg(real scalar k, real scalar arm, string scalar touse, string scalar obsid,
	string scalar subv, string scalar fitv, string scalar mv, string scalar xbv, string scalar s2v,
	string scalar xv, string scalar zv, string scalar wv)
{
	struct mmw_rec scalar R
	real colvector id, o, sub, fit, w, r, s2, a, c
	real matrix X, Z, Hbg
	real scalar n

	id  = st_data(., obsid, touse)
	o   = order(id, 1)
	n   = rows(id)
	sub = editmissing(st_data(., subv, touse)[o], 0)
	fit = editmissing(st_data(., fitv, touse)[o], 0)
	w   = editmissing(st_data(., wv, touse)[o], 0)
	r   = editmissing(st_data(., mv, touse)[o] - st_data(., xbv, touse)[o], 0)
	s2  = editmissing(st_data(., s2v, touse)[o], 1)
	if (xv != "") X = (editmissing(st_data(., xv, touse)[o, .], 0), J(n, 1, 1))
	else          X = J(n, 1, 1)
	if (zv != "") Z = (editmissing(st_data(., zv, touse)[o, .], 0), J(n, 1, 1))
	else          Z = J(n, 1, 1)
	a   = r :/ s2
	c   = (r:^2 :/ s2 :- 1)/2
	R.type = 13
	R.k    = k
	R.arm  = arm
	R.G    = (X :* (a :* sub), Z :* (c :* sub))
	R.Psi  = (X :* (a :* w :* fit), Z :* (c :* w :* fit))
	Hbg    = quadcross(X, w :* fit :* a, Z)
	R.Vb   = invsym((quadcross(X, w :* fit :/ s2, X), Hbg \ Hbg', quadcross(Z, w :* fit :* r:^2 :/ (2*s2), Z)))
	mmw_reg(R)
}

/*  split s at every ch, keeping empty pieces */
string rowvector mmw_split(string scalar s, string scalar ch)
{
	string rowvector out
	real scalar p
	out = J(1, 0, "")
	while ((p = strpos(s, ch)) > 0) {
		out = (out, strtrim(substr(s, 1, p - 1)))
		s = substr(s, p + 1, .)
	}
	return((out, strtrim(s)))
}

void mmw_add_sc(real scalar type, real scalar k, real scalar arm,
	string scalar touse, string scalar obsid, string scalar subv, string scalar fitv,
	string scalar scvs, string scalar designs, string scalar conss, string scalar wv,
	string scalar Vname, string scalar scalev)
{
	struct mmw_rec scalar R
	real colvector id, o, sub, fit, w, sc
	real matrix S, Z, G, Psi
	real rowvector cs
	string rowvector dl
	real scalar n, j

	id  = st_data(., obsid, touse)
	o   = order(id, 1)
	n   = rows(id)
	sub = editmissing(st_data(., subv, touse)[o], 0)
	fit = editmissing(st_data(., fitv, touse)[o], 0)
	w   = editmissing(st_data(., wv, touse)[o], 0)
	S   = editmissing(st_data(., scvs, touse)[o, .], 0)
	if (scalev != "") sc = editmissing(st_data(., scalev, touse)[o], 0)
	else              sc = J(n, 1, 1)
	dl  = mmw_split(designs, "|")
	cs  = strtoreal(tokens(conss))
	G   = J(n, 0, .)
	Psi = J(n, 0, .)
	for (j = 1; j <= cols(S); j++) {
		if (dl[j] != "") Z = editmissing(st_data(., dl[j], touse)[o, .], 0)
		else             Z = J(n, 0, .)
		if (cs[j]) Z = (Z, J(n, 1, 1))
		G   = (G, Z :* (S[., j] :* sc :* sub))
		Psi = (Psi, Z :* (S[., j] :* w :* fit))
	}
	R.type = type
	R.k    = k
	R.arm  = arm
	R.G    = G
	R.Psi  = Psi
	R.Vb   = st_matrix(Vname)
	mmw_reg(R)
}

void mmw_add_ord(real scalar type, real scalar k, string scalar touse, string scalar obsid,
	string scalar subv, string scalar fitv, string scalar xv, string scalar xbv, string scalar Bname,
	real scalar p, real scalar lnk, string scalar scvs, string scalar wv, string scalar Vname,
	real scalar L, real scalar cix)
{
	struct mmw_rec scalar R
	real colvector id, o, sub, fit, w, eta, up, lo, Fu, Fl, fu, fl, P
	real matrix X, S, Psi, Vb, Dl
	real rowvector B, kap
	real scalar n, l, m
	pointer(real matrix) rowvector D

	id  = st_data(., obsid, touse)
	o   = order(id, 1)
	n   = rows(id)
	sub = editmissing(st_data(., subv, touse)[o], 0)
	fit = editmissing(st_data(., fitv, touse)[o], 0)
	w   = editmissing(st_data(., wv, touse)[o], 0)
	eta = editmissing(st_data(., xbv, touse)[o], 0)
	S   = editmissing(st_data(., scvs, touse)[o, .], 0)
	if (p > 0) X = editmissing(st_data(., xv, touse)[o, .], 0)
	else       X = J(n, 0, .)
	B   = st_matrix(Bname)
	kap = B[|1, p + 1 \ 1, p + L - 1|]
	if (p > 0) Psi = (X :* (S[., 1] :* w :* fit), S[|1, 2 \ n, L|] :* (w :* fit))
	else       Psi = S[|1, cols(S) - L + 2 \ n, cols(S)|] :* (w :* fit)     // cutpoint scores only
	Vb  = st_matrix(Vname)
	D   = J(1, L, NULL)
	for (l = 1; l <= L; l++) {
		if (l < L) {
			up = kap[l] :- eta
			Fu = (lnk == 1 ? invlogit(up) : normal(up))
			fu = (lnk == 1 ? Fu :* (1 :- Fu) : normalden(up))
		}
		else {
			Fu = J(n, 1, 1)
			fu = J(n, 1, 0)
		}
		if (l > 1) {
			lo = kap[l - 1] :- eta
			Fl = (lnk == 1 ? invlogit(lo) : normal(lo))
			fl = (lnk == 1 ? Fl :* (1 :- Fl) : normalden(lo))
		}
		else {
			Fl = J(n, 1, 0)
			fl = J(n, 1, 0)
		}
		P = Fu - Fl
		if (p > 0) Dl = (X :* (-(fu - fl) :/ P), J(n, L - 1, 0))
		else       Dl = J(n, L - 1, 0)
		for (m = 1; m <= L - 1; m++) {
			if (m == l)     Dl[., p + m] = Dl[., p + m] + fu :/ P
			if (m == l - 1) Dl[., p + m] = Dl[., p + m] - fl :/ P
		}
		D[l] = &(Dl :+ 0)
	}
	for (l = 1; l <= L; l++) {
		if (l == cix) continue
		R.type = type
		R.k    = k
		R.arm  = l
		R.G    = editmissing((*D[l] - *D[cix]) :* sub, 0)
		R.Psi  = Psi
		R.Vb   = Vb
		mmw_reg(R)
	}
}

real rowvector mmw_cont_est(real colvector y, real colvector T, real colvector g, real matrix Mz,
	real matrix X, real colvector w, real rowvector lev, real rowvector gl, real scalar bw,
	real scalar trim, real scalar ntrim)
{
	real matrix Z1, Z2, F1, F2, KK, Wm, Wk
	real colvector xb1, xb2, u, keep, sel
	real rowvector cs, mu
	real scalar n, s1, s2, K, j, t, c, C

	n   = rows(y)
	Z1  = (X, J(n, 1, 1))
	Z2  = (Mz, X, J(n, 1, 1))
	xb1 = Z1*(invsym(quadcross(Z1, w, Z1))*quadcross(Z1, w, g))
	xb2 = Z2*(invsym(quadcross(Z2, w, Z2))*quadcross(Z2, w, g))
	s1  = sqrt(quadsum(w:*(g - xb1):^2)/quadsum(w))
	s2  = sqrt(quadsum(w:*(g - xb2):^2)/quadsum(w))
	K   = cols(lev) - 1
	F1  = J(n, K + 1, .)
	F2  = J(n, K + 1, .)
	KK  = J(n, K + 1, .)
	for (j = 1; j <= K + 1; j++) {
		F1[., j] = normalden(gl[j], xb1, s1)
		F2[., j] = normalden(gl[j], xb2, s2)
		u        = (T :- lev[j]):/bw
		KK[., j] = (abs(u) :< 1):*(0.75:*(1 :- u:^2))
	}
	C  = 3*K + 1
	Wm = J(n, C, .)
	for (j = 1; j <= K + 1; j++) Wm[., j] = w:*KK[., j]:/F1[., j]
	c = K + 1
	for (t = 2; t <= K + 1; t++) {
		Wm[., ++c] = w:*KK[., t]:*F2[., 1]:/(F2[., t]:*F1[., 1])
		Wm[., ++c] = w:*KK[., 1]:*F2[., t]:/(F2[., 1]:*F1[., t])
	}
	cs = colsum(Wm)
	if (any(cs :<= 0)) {
		ntrim = .
		return(J(1, C, .))
	}
	// a unit is trimmed if its normalized weight exceeds trim (or is undefined) in any mean
	keep = rowsum((Wm:/cs) :> trim) :== 0
	ntrim = n - sum(keep)
	sel = selectindex(keep)
	Wk  = Wm[sel, .]
	cs  = colsum(Wk)
	if (any(cs :<= 0)) return(J(1, C, .))
	mu  = colsum(Wk:*y[sel]):/cs
	return(mu)
}

void mmw_cont_boot(string scalar touse, string scalar yv, string scalar tv, real scalar lognorm,
	string scalar mv, string scalar xv, string scalar wv, real rowvector lev, real scalar bw,
	real scalar trim, real scalar R, string scalar clv, real scalar dots, string scalar Lname,
	string scalar bname, string scalar Vname, string scalar BBname)
{
	real colvector y, T, g, w, cl, idx, o
	real matrix Mz, X, L, MU, info, B
	real rowvector gl, mu, b
	real scalar n, nt, ntr, r, G, k, bad, ng

	y  = st_data(., yv, touse)
	T  = st_data(., tv, touse)
	g  = (lognorm ? ln(T) : T)
	gl = (lognorm ? ln(lev) : lev)
	w  = st_data(., wv, touse)
	Mz = st_data(., mv, touse)
	if (xv != "") X = st_data(., xv, touse)
	else          X = J(rows(y), 0, .)
	L  = st_matrix(Lname)
	n  = rows(y)
	nt = .
	mu = mmw_cont_est(y, T, g, Mz, X, w, lev, gl, bw, trim, nt)
	if (hasmissing(mu)) {
		errprintf("no observations with treatment within the bandwidth of an evaluation value (or none remain after\n")
		errprintf("trimming); increase bwidth() or trim()\n")
		exit(2000)
	}
	b = mu*L
	if (clv != "") {
		cl   = st_data(., clv, touse)
		o    = order(cl, 1)
		info = panelsetup(cl[o], 1)
		G    = rows(info)
	}
	MU  = J(R, cols(mu), .)
	bad = 0
	if (dots) {
		printf("{txt}\nBootstrap replications ({res}%f{txt})\n", R)
		displayflush()
	}
	for (r = 1; r <= R; r++) {
		if (clv == "") {
			idx = runiformint(n, 1, 1, n)
		}
		else {
			idx = J(0, 1, .)
			for (k = 1; k <= G; k++) {
				ng  = runiformint(1, 1, 1, G)
				idx = idx \ o[|info[ng, 1] \ info[ng, 2]|]
			}
		}
		ntr = .
		MU[r, .] = mmw_cont_est(y[idx], T[idx], g[idx], Mz[idx, .], X[idx, .], w[idx], lev, gl, bw, trim, ntr)
		if (hasmissing(MU[r, .])) bad++
		if (dots) {
			printf(hasmissing(MU[r, .]) ? "{err}x{txt}" : ".")
			if (mod(r, 50) == 0) printf("%6.0f\n", r)
			displayflush()
		}
	}
	if (dots & mod(R, 50) != 0) printf("\n")
	MU = select(MU, rowmissing(MU) :== 0)
	if (rows(MU) < 2) {
		errprintf("too few successful bootstrap replications\n")
		exit(2000)
	}
	B = MU*L
	st_matrix(bname, b)
	st_matrix(Vname, variance(B))
	st_matrix(BBname, B)
	st_local("mmw_ntrim", strofreal(nt))
	st_local("mmw_nreps", strofreal(rows(MU)))
	st_local("mmw_nmis", strofreal(bad))
	st_local("mmw_n", strofreal(n))
	if (clv != "") st_local("mmw_nclust", strofreal(G))
}

real colvector mmw_h(struct mmw_rec scalar R, real scalar c, real rowvector CA,
	real matrix TG, real scalar cix, real scalar n)
{
	real scalar tg
	if (R.type == 4 | R.type == 8) return(J(n, 1, -1))
	if (R.type == 5 | R.type == 9) return(J(n, 1, 1))
	tg = TG[c, R.k]
	if (tg == 0) return(J(n, 1, 0))
	if (R.type <= 3 | R.type == 12 | R.type == 13) return(J(n, 1, (R.arm == tg) - (R.arm == CA[c])))
	if (R.type == 6)  return(J(n, 1, (tg != cix) - (CA[c] != cix)))
	if (R.type == 7)  return(J(n, 1, (CA[c] != cix) - (tg != cix)))
	if (R.type == 10) return(J(n, 1, (R.arm == tg) - (R.arm == CA[c])))
	return(J(n, 1, (R.arm == CA[c]) - (R.arm == tg)))
}

void mmw_vce(string scalar touse, string scalar obsid, string scalar yv, string scalar tv,
	string scalar gv, string scalar finv, string scalar uwv, string scalar twv,
	string scalar fv, real scalar L, real scalar cix, string scalar xv, string scalar clv,
	string scalar glevname, string scalar carmname, string scalar tgname,
	string scalar bname, real scalar om, string scalar Vout)
{
	struct mmw_rec scalar Rj, Rt
	real colvector id, o, Y, T, grp, fin, uw, tw, cl, sel, app, w, e, we, h, p, rk
	real colvector eta, mu, a, hp, da
	real matrix F, Fown, X, glev, CA, TG, gam, Mm, psig, A, U, IF, B, Mi, V, info, Pc
	real scalar n, Gn, C, K, px, nd, q, g, gi, c, k, i, j, t, off, nm, tg
	real rowvector m
	pointer(real matrix) rowvector D
	pointer(transmorphic) scalar pA, pn

	id   = st_data(., obsid, touse)
	o    = order(id, 1)
	n    = rows(id)
	Y    = st_data(., yv, touse)[o]
	T    = st_data(., tv, touse)[o]
	grp  = st_data(., gv, touse)[o]
	fin  = editmissing(st_data(., finv, touse)[o], 0)
	uw   = st_data(., uwv, touse)[o]
	tw   = editmissing(st_data(., twv, touse)[o], 0)
	F    = editmissing(st_data(., fv, touse)[o, .], 0)
	cl   = st_data(., clv, touse)[o]
	glev = st_matrix(glevname)
	CA   = st_matrix(carmname)
	TG   = st_matrix(tgname)
	gam  = st_matrix(bname)'
	Gn   = cols(glev)
	C    = cols(CA)
	K    = cols(TG)

	// mediator factor at the unit's own treatment level
	Fown = J(n, K, 0)
	for (k = 1; k <= K; k++) {
		for (i = 1; i <= L; i++) Fown[., k] = Fown[., k] + (T :== i) :* F[., (k - 1)*L + i]
	}

	px = 0
	if (xv != "") {
		X  = st_data(., xv, touse)[o, .]
		px = cols(X)
		for (g = 1; g <= Gn; g++) {
			sel = (grp :== glev[g]) :* fin
			m   = quadcolsum(X :* (sel :* uw)) :/ quadsum(sel :* uw)
			X   = X - (grp :== glev[g]) * m
		}
		X = editmissing(X, 0)
	}
	nd = Gn*C
	q  = nd + (Gn > 1 ? Gn*px : px)
	if (q != rows(gam)) {
		errprintf("mmwsmed: internal dimension mismatch in two-step variance\n")
		exit(498)
	}

	pA = findexternal("mmw_A")
	pn = findexternal("mmw_n")
	nm = *pn
	D  = J(1, nm, NULL)
	for (j = 1; j <= nm; j++) {
		Rj   = asarray(*pA, j)
		D[j] = &(J(q, cols(Rj.G), 0))
	}

	Mm   = J(q, q, 0)
	psig = J(n, q, 0)
	for (gi = 1; gi <= Gn; gi++) {
		for (c = 1; c <= C; c++) {
			app = (grp :== glev[gi]) :* fin :* (T :== CA[c])
			w   = app :* uw :* tw
			for (k = 1; k <= K; k++) {
				tg = TG[c, k]
				if (tg > 0) {
					rk = editmissing(F[., (k - 1)*L + tg] :/ Fown[., k], 0)
					w  = w :* rk
				}
			}
			A = J(n, q, 0)
			A[., (gi - 1)*C + c] = app
			if (px > 0) {
				off = nd + (Gn > 1 ? (gi - 1)*px : 0)
				A[|1, off + 1 \ n, off + px|] = X :* app
			}
			eta  = A*gam
			mmw_link(eta, om, mu, a, hp, da)
			e    = editmissing((Y - mu) :* a, 0) :* app
			we   = w :* e
			psig = psig + A :* we
			Mm   = Mm + quadcross(A, w :* editmissing(hp :* a - (Y - mu) :* da, 0) :* app, A)
			for (j = 1; j <= nm; j++) {
				Rj    = asarray(*pA, j)
				h     = mmw_h(Rj, c, CA, TG, cix, n)
				*D[j] = *D[j] + quadcross(A, we :* h, Rj.G)
			}
		}
	}

	U = psig
	for (j = 1; j <= nm; j++) {
		Rj = asarray(*pA, j)
		IF = Rj.Psi
		// mediator models are weighted by the treatment weights: add the treatment models' influence
		if (Rj.type <= 3 | Rj.type == 12 | Rj.type == 13) {
			for (t = 1; t <= nm; t++) {
				Rt = asarray(*pA, t)
				if (Rt.type == 4 | Rt.type == 8) IF = IF + (Rt.Psi*Rt.Vb) * (quadcross(Rj.Psi, -Rt.G))'
				if (Rt.type == 5 | Rt.type == 9) IF = IF + (Rt.Psi*Rt.Vb) * (quadcross(Rj.Psi,  Rt.G))'
			}
		}
		IF = IF * Rj.Vb
		U  = U + IF * (*D[j])'
	}

	p    = order(cl, 1)
	info = panelsetup(cl[p], 1)
	Pc   = panelsum(U[p, .], info)
	B    = quadcross(Pc, Pc)
	Mi   = invsym(Mm)
	V    = Mi * B * Mi
	st_matrix(Vout, V)
}

void mmw_link(real colvector eta, real scalar om, mu, a, hp, da)
{
	real colvector ph, D
	if (om == 1) {
		mu = eta
		a  = J(rows(eta), 1, 1)
		hp = a
		da = J(rows(eta), 1, 0)
	}
	else if (om == 2) {
		mu = invlogit(eta)
		a  = J(rows(eta), 1, 1)
		hp = mu :* (1 :- mu)
		da = J(rows(eta), 1, 0)
	}
	else if (om == 3) {
		mu = normal(eta)
		ph = normalden(eta)
		D  = mu :* (1 :- mu)
		a  = ph :/ D
		hp = ph
		da = (-eta :* ph :* D - ph:^2 :* (1 :- 2*mu)) :/ (D:^2)
	}
	else {
		mu = exp(eta)
		a  = J(rows(eta), 1, 1)
		hp = mu
		da = J(rows(eta), 1, 0)
	}
}

void mmw_std(string scalar finv, string scalar xv, string scalar uwv, string scalar gv,
	string scalar glevname, string scalar bname, real scalar C, real scalar om,
	string scalar muname, string scalar Jname)
{
	real colvector uw, grp, sel, eta, mu, a, hp, da
	real matrix X, glev, Jm
	real rowvector gam, m, MU
	real scalar Gn, px, nd, q, gi, c, r, off, nw

	uw   = st_data(., uwv, finv)
	grp  = st_data(., gv, finv)
	glev = st_matrix(glevname)
	gam  = st_matrix(bname)
	Gn   = cols(glev)
	nd   = Gn*C
	q    = cols(gam)
	px   = 0
	if (xv != "") {
		X  = st_data(., xv, finv)
		px = cols(X)
		for (gi = 1; gi <= Gn; gi++) {
			sel = (grp :== glev[gi])
			m   = quadcolsum(X :* (sel :* uw)) :/ quadsum(sel :* uw)
			X   = X - sel * m
		}
	}
	MU = J(1, nd, 0)
	Jm = J(nd, q, 0)
	for (gi = 1; gi <= Gn; gi++) {
		sel = (grp :== glev[gi]) :* uw
		nw  = quadsum(sel)
		off = nd + (Gn > 1 ? (gi - 1)*px : 0)
		for (c = 1; c <= C; c++) {
			r   = (gi - 1)*C + c
			eta = J(rows(uw), 1, gam[r])
			if (px > 0) eta = eta + X*gam[|off + 1 \ off + px|]'
			mmw_link(eta, om, mu, a, hp, da)
			MU[r]    = quadsum(sel :* mu)/nw
			Jm[r, r] = quadsum(sel :* hp)/nw
			if (px > 0) Jm[|r, off + 1 \ r, off + px|] = quadcolsum(X :* (sel :* hp))/nw
		}
	}
	st_matrix(muname, MU)
	st_matrix(Jname, Jm)
}

end


********************************************************************************
* Mata: bootstrap engine for binary and multivalued treatments (vce(bootstrap))
********************************************************************************
version 15
mata:

struct mmw_bset {
	real scalar L, cix, G, K, design, tm, hasT, mmws, tstrata, wtd, odds, np, s1, s0, nmin
	real scalar common, caliper, het, om, C, hv
	real rowvector glev, mt, CA
	real matrix TG, Lm
}

struct mmw_bd {
	real colvector y, tix, grp, uw, m1, m2
	real matrix XT, XH, XM1, XM2, OTc1, OTc2, OTw1, OTw2, xv, HV
}

struct mmw_mdl {
	real scalar type, nc, base
	real colvector y, w
	real matrix X, Z
}

void mmw_bs_init()
{
	pointer(transmorphic) scalar p
	if ((p = findexternal("mmw_BS")) == NULL) p = crexternal("mmw_BS")
}

void mmw_bs_put(string scalar key, string scalar vars, string scalar touse, string scalar idv)
{
	pointer(transmorphic) scalar p
	real colvector id
	real matrix X

	p  = findexternal("mmw_BS")
	id = st_data(., idv, touse)
	if (strtrim(vars) == "") X = J(rows(id), 0, .)
	else                     X = st_data(., vars, touse)
	if (cols(X) > 0) X = X[order(id, 1), .]
	asarray(*p, key, X)
}

void mmw_bs_putm(string scalar key, real matrix M)
{
	pointer(transmorphic) scalar p
	p = findexternal("mmw_BS")
	asarray(*p, key, M)
}

struct mmw_bset scalar mmw_bs_set()
{
	struct mmw_bset scalar S
	pointer(transmorphic) scalar p
	real rowvector s

	p = findexternal("mmw_BS")
	s = asarray(*p, "set")
	S.L       = s[1]
	S.cix     = s[2]
	S.K       = s[3]
	S.design  = s[4]
	S.tm      = s[5]
	S.hasT    = s[6]
	S.mmws    = s[7]
	S.tstrata = s[8]
	S.wtd     = s[9]
	S.odds    = s[10]
	S.np      = s[11]
	S.s1      = s[12]
	S.s0      = s[13]
	S.nmin    = s[14]
	S.common  = s[15]
	S.caliper = s[16]
	S.het     = s[17]
	S.om      = s[18]
	S.C       = s[19]
	S.mt      = (s[20], s[21])
	S.hv      = s[22]
	S.glev    = asarray(*p, "glev")
	S.CA      = asarray(*p, "CA")
	S.TG      = asarray(*p, "TG")
	S.Lm      = asarray(*p, "Lm")
	S.G       = cols(S.glev)
	return(S)
}

struct mmw_bd scalar mmw_bs_data()
{
	struct mmw_bd scalar D
	pointer(transmorphic) scalar p

	p = findexternal("mmw_BS")
	D.y    = asarray(*p, "y")
	D.tix  = asarray(*p, "tix")
	D.grp  = asarray(*p, "grp")
	D.uw   = asarray(*p, "uw")
	D.m1   = asarray(*p, "m1")
	D.m2   = asarray(*p, "m2")
	D.XT   = asarray(*p, "XT")
	D.XH   = asarray(*p, "XH")
	D.XM1  = asarray(*p, "XM1")
	D.XM2  = asarray(*p, "XM2")
	D.OTc1 = asarray(*p, "OTc1")
	D.OTc2 = asarray(*p, "OTc2")
	D.OTw1 = asarray(*p, "OTw1")
	D.OTw2 = asarray(*p, "OTw2")
	D.xv   = asarray(*p, "xv")
	D.HV   = asarray(*p, "HV")
	return(D)
}

/* rows idx of X (X may have no columns) */
real matrix mmw_r(real matrix X, real colvector idx)
{
	if (cols(X) == 0 | rows(idx) == 0) return(J(rows(idx), cols(X), .))
	return(X[idx, .])
}

/* elements of ii where cond is true */
real colvector mmw_si(real colvector ii, real colvector cond)
{
	if (!any(cond)) return(J(0, 1, .))
	return(ii[selectindex(cond)])
}

/* n x nc indicators of y == 1, ..., nc */
real matrix mmw_ind(real colvector y, real scalar nc)
{
	real matrix Yi
	real scalar j
	Yi = J(rows(y), nc, 0)
	for (j = 1; j <= nc; j++) Yi[., j] = (y :== j)
	return(Yi)
}

struct mmw_bd scalar mmw_dsub(struct mmw_bd scalar D, real colvector idx)
{
	struct mmw_bd scalar E
	E.y    = D.y[idx]
	E.tix  = D.tix[idx]
	E.grp  = D.grp[idx]
	E.uw   = D.uw[idx]
	E.m1   = D.m1[idx]
	E.m2   = D.m2[idx]
	E.XT   = mmw_r(D.XT, idx)
	E.XH   = mmw_r(D.XH, idx)
	E.XM1  = mmw_r(D.XM1, idx)
	E.XM2  = mmw_r(D.XM2, idx)
	E.OTc1 = mmw_r(D.OTc1, idx)
	E.OTc2 = mmw_r(D.OTc2, idx)
	E.OTw1 = mmw_r(D.OTw1, idx)
	E.OTw2 = mmw_r(D.OTw2, idx)
	E.xv   = mmw_r(D.xv, idx)
	E.HV   = mmw_r(D.HV, idx)
	return(E)
}

real scalar mmw_ev(struct mmw_mdl scalar M, real colvector b, real colvector g, real matrix H, real scalar todo)
{
	real colvector xb, p, tm, l1, l0, ld, u1, u0, s, sg, mu, mx, lse, eta, ke, up, lo, Fu, Fl, fu, fl, Pk, top, bot
	real colvector lv, s2, r, du2, dl2, de, hee
	real matrix E, P, Yi, C, Sd, T, Hbg
	real scalar n, k, kx, kz, j, l, q, qj, ql, m

	n = rows(M.y)
	if (M.type == 1) {
		xb = M.X*b
		p  = invlogit(xb)
		tm = M.y :* (-ln(1 :+ exp(-xb))) + (1 :- M.y) :* (-ln(1 :+ exp(xb)))
		if (hasmissing(tm)) return(.)
		if (todo >= 1) g = quadcross(M.X, M.w :* (M.y - p))
		if (todo >= 2) H = quadcross(M.X, M.w :* p :* (1 :- p), M.X)
		return(quadsum(M.w :* tm))
	}
	if (M.type == 2 | M.type == 3) {
		if (M.type == 2) {
			xb = M.X*b
			sg = J(n, 1, 1)
		}
		else {
			k  = cols(M.X)
			kz = cols(M.Z)
			sg = exp(M.Z*b[|k + 1 \ k + kz|])
			xb = (M.X*b[|1 \ k|]) :/ sg
		}
		l1 = lnnormal(xb)
		l0 = lnnormal(-xb)
		tm = M.y :* l1 + (1 :- M.y) :* l0
		if (hasmissing(tm)) return(.)
		if (todo >= 1) {
			ld = lnnormalden(xb)
			u1 = exp(ld - l1)
			u0 = exp(ld - l0)
			s  = M.y :* u1 - (1 :- M.y) :* u0
			if (M.type == 2) {
				g = quadcross(M.X, M.w :* s)
				if (todo >= 2) H = quadcross(M.X, M.w :* (M.y :* u1 :* (xb + u1) + (1 :- M.y) :* u0 :* (u0 - xb)), M.X)
			}
			else {
				g = quadcross(M.X, M.w :* s :/ sg) \ quadcross(M.Z, M.w :* s :* (-xb))
				if (todo >= 2) H = mmw_numh(M, b)
			}
		}
		return(quadsum(M.w :* tm))
	}
	if (M.type == 7) {
		xb = M.X*b
		mu = exp(xb)
		tm = M.y :* xb - mu - lngamma(M.y :+ 1)
		if (hasmissing(tm)) return(.)
		if (todo >= 1) g = quadcross(M.X, M.w :* (M.y - mu))
		if (todo >= 2) H = quadcross(M.X, M.w :* mu, M.X)
		return(quadsum(M.w :* tm))
	}
	if (M.type == 4) {
		k = cols(M.X)
		E = J(n, M.nc, 0)
		q = 0
		for (j = 1; j <= M.nc; j++) {
			if (j == M.base) continue
			q++
			E[., j] = M.X*b[|(q - 1)*k + 1 \ q*k|]
		}
		mx  = rowmax(E)
		lse = mx + ln(rowsum(exp(E :- mx)))
		Yi  = mmw_ind(M.y, M.nc)
		tm  = rowsum(E :* Yi) - lse
		if (hasmissing(tm)) return(.)
		if (todo >= 1) {
			P = exp(E :- lse)
			g = J((M.nc - 1)*k, 1, 0)
			q = 0
			for (j = 1; j <= M.nc; j++) {
				if (j == M.base) continue
				q++
				g[|(q - 1)*k + 1 \ q*k|] = quadcross(M.X, M.w :* (Yi[., j] - P[., j]))
			}
			if (todo >= 2) {
				H  = J((M.nc - 1)*k, (M.nc - 1)*k, 0)
				qj = 0
				for (j = 1; j <= M.nc; j++) {
					if (j == M.base) continue
					qj++
					ql = 0
					for (l = 1; l <= M.nc; l++) {
						if (l == M.base) continue
						ql++
						H[|(qj - 1)*k + 1, (ql - 1)*k + 1 \ qj*k, ql*k|] = quadcross(M.X, M.w :* P[., j] :* ((j == l) :- P[., l]), M.X)
					}
				}
			}
		}
		return(quadsum(M.w :* tm))
	}
	if (M.type == 8) {
		k  = cols(M.X)
		kz = cols(M.Z)
		xb = M.X*b[|1 \ k|]
		lv = M.Z*b[|k + 1 \ k + kz|]
		s2 = exp(lv)
		r  = M.y - xb
		tm = -0.5*(ln(2*pi()) :+ lv :+ r:^2 :/ s2)
		if (hasmissing(tm)) return(.)
		if (todo >= 1) g = quadcross(M.X, M.w :* r :/ s2) \ quadcross(M.Z, M.w :* (r:^2 :/ s2 :- 1)/2)
		if (todo >= 2) {
			Hbg = quadcross(M.X, M.w :* r :/ s2, M.Z)
			H   = (quadcross(M.X, M.w :/ s2, M.X), Hbg \ Hbg', quadcross(M.Z, M.w :* r:^2 :/ (2*s2), M.Z))
		}
		return(quadsum(M.w :* tm))
	}
	kx = cols(M.X)
	if (kx > 0) eta = M.X*b[|1 \ kx|]
	else        eta = J(n, 1, 0)
	ke  = (0 \ b[|kx + 1 \ kx + M.nc - 1|] \ 0)
	top = (M.y :== M.nc)
	bot = (M.y :== 1)
	up  = ke[M.y :+ 1] - eta
	lo  = ke[M.y] - eta
	if (M.type == 5) {
		Fu = invlogit(up)
		Fl = invlogit(lo)
		fu = Fu :* (1 :- Fu)
		fl = Fl :* (1 :- Fl)
	}
	else {
		Fu = normal(up)
		Fl = normal(lo)
		fu = normalden(up)
		fl = normalden(lo)
	}
	Fu = Fu :* (1 :- top) + top
	fu = fu :* (1 :- top)
	Fl = Fl :* (1 :- bot)
	fl = fl :* (1 :- bot)
	Pk = Fu - Fl
	if (any(Pk :<= 0)) return(.)
	tm = ln(Pk)
	if (hasmissing(tm)) return(.)
	if (todo >= 1) {
		s = -(fu - fl) :/ Pk
		g = J(kx + M.nc - 1, 1, 0)
		if (kx > 0) g[|1 \ kx|] = quadcross(M.X, M.w :* s)
		for (j = 1; j <= M.nc - 1; j++) {
			g[kx + j] = quadsum(M.w :* ((M.y :== j) :* fu - (M.y :== j + 1) :* fl) :/ Pk)
		}
		if (todo >= 2) {
			if (M.type == 5) {
				du2 = fu :* (1 :- 2*Fu)
				dl2 = fl :* (1 :- 2*Fl)
			}
			else {
				du2 = -up :* fu
				dl2 = -lo :* fl
			}
			de  = -(fu - fl)
			hee = du2 - dl2
			C   = J(n, M.nc - 1, 0)
			Sd  = J(n, M.nc - 1, 0)
			T   = J(n, M.nc - 1, 0)
			for (m = 1; m <= M.nc - 1; m++) {
				C[., m]  = (M.y :== m) :* fu  - (M.y :== m + 1) :* fl
				Sd[., m] = (M.y :== m) :* du2 - (M.y :== m + 1) :* dl2
				T[., m]  = (M.y :== m + 1) :* dl2 - (M.y :== m) :* du2
			}
			H = J(kx + M.nc - 1, kx + M.nc - 1, 0)
			if (kx > 0) {
				H[|1, 1 \ kx, kx|] = quadcross(M.X, M.w :* (-hee :/ Pk + de:^2 :/ Pk:^2), M.X)
				for (m = 1; m <= M.nc - 1; m++) {
					H[|1, kx + m \ kx, kx + m|] = quadcross(M.X, M.w :* (-T[., m] :/ Pk + de :* C[., m] :/ Pk:^2))
					H[|kx + m, 1 \ kx + m, kx|] = H[|1, kx + m \ kx, kx + m|]'
				}
			}
			for (m = 1; m <= M.nc - 1; m++) {
				for (q = 1; q <= M.nc - 1; q++) {
					H[kx + m, kx + q] = quadsum(M.w :* (C[., m] :* C[., q] :/ Pk:^2))
					if (m == q) H[kx + m, kx + q] = H[kx + m, kx + q] - quadsum(M.w :* Sd[., m] :/ Pk)
				}
			}
		}
	}
	return(quadsum(M.w :* tm))
}

real matrix mmw_numh(struct mmw_mdl scalar M, real colvector b)
{
	real colvector gp, gm, bb
	real matrix H, Hd
	real scalar j, h, k, llp, llm

	k = rows(b)
	H = J(k, k, 0)
	for (j = 1; j <= k; j++) {
		h  = 1e-5*(abs(b[j]) + 1e-2)
		bb = b
		bb[j] = b[j] + h
		llp = mmw_ev(M, bb, gp, Hd, 1)
		bb[j] = b[j] - h
		llm = mmw_ev(M, bb, gm, Hd, 1)
		if (missing(llp) | missing(llm)) return(J(k, k, .))
		H[., j] = -(gp - gm) :/ (2*h)
	}
	return((H + H') :/ 2)
}

real scalar mmw_nr(struct mmw_mdl scalar M, real colvector b)
{
	real colvector g, gn, d, bn
	real rowvector ev
	real matrix H, Hn
	real scalar ll, lln, it, st, hs, dec, acc, cnc

	g  = J(0, 1, .)
	H  = J(0, 0, .)
	ll = mmw_ev(M, b, g, H, 2)
	if (missing(ll)) return(0)
	for (it = 1; it <= 300; it++) {
		if (hasmissing(H)) return(0)
		ev  = symeigenvalues(H)
		cnc = (min(ev) < -1e-8*max((max(abs(ev)), 1e-300)))
		if (cnc) d = invsym(H + (1.5*abs(min(ev)) + 1e-6*max(abs(ev)))*I(rows(H)))*g
		else     d = invsym(H)*g
		dec = quadcross(g, d)
		if (missing(dec)) return(0)
		if (!cnc & dec < 1e-18) {
			b = b + d
			return(1)
		}
		st  = 1
		acc = 0
		for (hs = 1; hs <= 50; hs++) {
			bn  = b + st*d
			lln = mmw_ev(M, bn, gn, Hn, 0)
			if (!missing(lln)) {
				if (lln >= ll - 1e-12*(abs(ll) + 1)) {
					acc = 1
					break
				}
			}
			st = st/2
		}
		if (!acc) return(!cnc & dec < 1e-10)
		b  = bn
		ll = mmw_ev(M, b, g, H, 2)
		if (missing(ll)) return(0)
	}
	return(0)
}

real scalar mmw_fbin(real scalar tm, real colvector y, real matrix X, real matrix Z, real colvector w,
	real colvector b, real scalar chk)
{
	struct mmw_mdl scalar M
	real colvector p, rk, ck, nz, bs, ri, ci
	real scalar j, nr

	nr = rows(y)
	if (nr == 0) return(0)
	if (chk & tm <= 2) {
		rk = J(nr, 1, 1)
		ck = J(cols(X), 1, 1)
		for (j = 1; j <= cols(X) - 1; j++) {
			nz = rk :* (X[., j] :!= 0)
			if (any(nz) & sum(nz) < sum(rk)) {
				if (all(select(y, nz) :== 1) | all(select(y, nz) :== 0)) {
					ck[j] = 0
					rk    = rk :* (1 :- nz)
				}
			}
		}
		if (!all(rk)) {
			ri = selectindex(rk)
			ci = selectindex(ck)
			if (!mmw_fbin(tm, y[ri], X[ri, ci'], Z, w[ri], bs, chk)) return(0)
			b = J(cols(X), 1, 0)
			b[ci] = bs
			return(1)
		}
	}
	M.type = (tm == 1 ? 1 : 2)
	M.y    = y
	M.X    = X
	M.Z    = Z
	M.w    = w
	b = J(cols(X), 1, 0)
	if (!mmw_nr(M, b)) return(0)
	if (tm == 3) {
		M.type = 3
		b = b \ J(cols(Z), 1, 0)
		if (!mmw_nr(M, b)) return(0)
	}
	if (chk & tm <= 2) {
		p = mmw_pbin(tm, X, Z, b)
		if (min(abs(y - p)) < 1e-14) return(0)
	}
	return(1)
}

real colvector mmw_pbin(real scalar tm, real matrix X, real matrix Z, real colvector b)
{
	real scalar k
	if (tm == 1) return(invlogit(X*b))
	if (tm == 2) return(normal(X*b))
	k = cols(X)
	return(normal((X*b[|1 \ k|]) :/ exp(Z*b[|k + 1 \ rows(b)|])))
}

real scalar mmw_fml(real colvector yc, real matrix X, real colvector w, real scalar nc, real scalar base,
	real colvector b)
{
	struct mmw_mdl scalar M
	real matrix P, E

	if (rows(yc) == 0) return(0)
	M.type = 4
	M.y    = yc
	M.X    = X
	M.w    = w
	M.nc   = nc
	M.base = base
	b = J((nc - 1)*cols(X), 1, 0)
	if (!mmw_nr(M, b)) return(0)
	P = mmw_pml(X, b, nc, base, E)
	if (min(1 :- rowsum(P :* mmw_ind(yc, nc))) < 1e-14) return(0)
	return(1)
}

real matrix mmw_pml(real matrix X, real colvector b, real scalar nc, real scalar base, real matrix E)
{
	real colvector mx, lse
	real scalar j, q, k

	k = cols(X)
	E = J(rows(X), nc, 0)
	q = 0
	for (j = 1; j <= nc; j++) {
		if (j == base) continue
		q++
		E[., j] = X*b[|(q - 1)*k + 1 \ q*k|]
	}
	mx  = rowmax(E)
	lse = mx + ln(rowsum(exp(E :- mx)))
	return(exp(E :- lse))
}

real scalar mmw_ford(real scalar lnk, real colvector yc, real matrix X, real colvector w, real scalar nc,
	real colvector b)
{
	struct mmw_mdl scalar M
	real colvector cp
	real matrix P
	real scalar j

	if (rows(yc) == 0) return(0)
	cp = J(nc - 1, 1, .)
	for (j = 1; j <= nc - 1; j++) {
		cp[j] = quadsum(w :* (yc :<= j))/quadsum(w)
		if (lnk == 1) cp[j] = logit(cp[j])
		else          cp[j] = invnormal(cp[j])
	}
	M.type = (lnk == 1 ? 5 : 6)
	M.y    = yc
	M.X    = X
	M.w    = w
	M.nc   = nc
	b = J(cols(X), 1, 0) \ cp
	if (!mmw_nr(M, b)) return(0)
	P = mmw_pord(lnk, X, b, nc)
	if (min(1 :- rowsum(P :* mmw_ind(yc, nc))) < 1e-14) return(0)
	return(1)
}

real matrix mmw_pord(real scalar lnk, real matrix X, real colvector b, real scalar nc)
{
	real colvector eta, Fp, Fc
	real matrix P
	real scalar kx, j

	kx = cols(X)
	if (kx > 0) eta = X*b[|1 \ kx|]
	else        eta = J(rows(X), 1, 0)
	P  = J(rows(X), nc, .)
	Fp = J(rows(X), 1, 0)
	for (j = 1; j <= nc; j++) {
		if (j < nc) {
			if (lnk == 1) Fc = invlogit(b[kx + j] :- eta)
			else          Fc = normal(b[kx + j] :- eta)
		}
		else Fc = J(rows(X), 1, 1)
		P[., j] = Fc - Fp
		Fp = Fc
	}
	return(P)
}

real scalar mmw_fpois(real colvector y, real matrix X, real colvector w, real colvector b)
{
	struct mmw_mdl scalar M

	if (rows(y) == 0) return(0)
	M.type = 7
	M.y    = y
	M.X    = X
	M.w    = w
	b = J(cols(X), 1, 0)
	b[cols(X)] = ln(max((quadsum(w :* y)/quadsum(w), 1e-8)))
	return(mmw_nr(M, b))
}

real scalar mmw_fhet(real colvector y, real matrix X, real matrix Z, real colvector w, real colvector b)
{
	struct mmw_mdl scalar M
	real colvector b0, r
	real scalar rk

	if (rows(y) == 0) return(0)
	b0 = mmw_wls(y, X, w, rk)
	r  = y - X*b0
	M.type = 8
	M.y    = y
	M.X    = X
	M.Z    = Z
	M.w    = w
	b = b0 \ J(cols(Z) - 1, 1, 0) \ ln(quadsum(w :* r:^2)/quadsum(w))
	return(mmw_nr(M, b))
}

void mmw_hreg_st(string scalar mv, string scalar xv, string scalar zv, string scalar wv, string scalar fitv,
	string scalar subv, string scalar lpv, string scalar s2v)
{
	real colvector y, w, b
	real matrix X, Z, Xs, Zs
	real scalar kx

	y = st_data(., mv, fitv)
	w = st_data(., wv, fitv)
	if (xv != "") X = (st_data(., xv, fitv), J(rows(y), 1, 1))
	else          X = J(rows(y), 1, 1)
	if (zv != "") Z = (st_data(., zv, fitv), J(rows(y), 1, 1))
	else          Z = J(rows(y), 1, 1)
	if (!mmw_fhet(y, X, Z, w, b)) {
		st_local("mmw_hok", "0")
		return
	}
	kx = cols(X)
	Xs = st_data(., mv, subv)
	if (xv != "") Xs = (st_data(., xv, subv), J(rows(Xs), 1, 1))
	else          Xs = J(rows(Xs), 1, 1)
	if (zv != "") Zs = (st_data(., zv, subv), J(rows(Xs), 1, 1))
	else          Zs = J(rows(Xs), 1, 1)
	st_store(., lpv, subv, Xs*b[|1 \ kx|])
	st_store(., s2v, subv, exp(Zs*b[|kx + 1 \ rows(b)|]))
	st_local("mmw_hok", "1")
}

real colvector mmw_wls(real colvector y, real matrix X, real colvector w, real scalar rk)
{
	real matrix A
	A  = invsym(quadcross(X, w, X))
	rk = rows(A) - diag0cnt(A)
	return(A*quadcross(X, w, y))
}

real colvector mmw_xtile(real colvector x, real scalar nq, real colvector w, real scalar wtd)
{
	real colvector o, xs, cw
	real rowvector cuts
	real scalar n, j, P, i, W

	n = rows(x)
	if (n == 0) return(J(0, 1, .))
	o  = order(x, 1)
	xs = x[o]
	if (wtd) cw = runningsum(w[o])
	else     cw = (1::n)
	W    = cw[n]
	cuts = J(1, nq - 1, .)
	for (j = 1; j <= nq - 1; j++) {
		P = W*j/nq
		i = sum(cw :<= P + 1e-9*W)
		if (i >= 1 & i < n) {
			if (abs(cw[i] - P) < 1e-9*W) cuts[j] = (xs[i] + xs[i + 1])/2
			else                         cuts[j] = xs[i + 1]
		}
		else if (i < 1) cuts[j] = xs[1]
		else            cuts[j] = xs[n]
	}
	o = J(n, 1, 1)
	for (j = 1; j <= nq - 1; j++) o = o + (x :> cuts[j])
	return(o)
}

void mmw_supp(real colvector x, real colvector c, real colvector sel, real scalar cal, real colvector sx)
{
	real colvector uc, xx
	real scalar sd, lo, hi, j

	if (rows(sel) == 0) return
	sd = sqrt(variance(x))
	lo = -maxdouble()
	hi = maxdouble()
	uc = uniqrows(c)
	for (j = 1; j <= rows(uc); j++) {
		xx = select(x, c :== uc[j])
		lo = max((lo, min(xx) - cal*sd))
		hi = min((hi, max(xx) + cal*sd))
	}
	sx[sel] = (sx[sel] + (x :< lo) + (x :> hi)) :> 0
}

void mmw_suppw(real colvector x, real colvector t, real colvector mv, real scalar cat, real colvector sel,
	real scalar cal, real colvector sx)
{
	real colvector lv, ii
	real scalar j

	if (!cat) {
		mmw_supp(x, t, sel, cal, sx)
		return
	}
	lv = uniqrows(mv)
	for (j = 1; j <= rows(lv); j++) {
		ii = selectindex(mv :== lv[j])
		mmw_supp(x[ii], t[ii], sel[ii], cal, sx)
	}
}

real scalar mmw_tsel(struct mmw_bset scalar S, struct mmw_bd scalar D, real colvector gt, real colvector tw)
{
	real colvector sel, u, z, b, ps, st, ii, i1, i0
	real matrix X, Zh, PS, E
	real scalar ns, pz, s, n1, n0, c1, c0, i, pr, sw, nsum, nz, lnk, nlv, nlk

	sel = selectindex(gt)
	ns  = rows(sel)
	u   = D.uw[sel]
	X   = (mmw_r(D.XT, sel), J(ns, 1, 1))
	Zh  = mmw_r(D.XH, sel)
	if (S.L == 2) {
		z = (D.tix[sel] :!= S.cix)
		if (!mmw_fbin(S.tm, z, X, Zh, u, b, 1)) return(0)
		ps = mmw_pbin(S.tm, X, Zh, b)
		pz = quadsum(u :* z)/quadsum(u)
		if (!S.mmws) {
			i1 = selectindex(z)
			i0 = selectindex(z :== 0)
			tw[sel[i1]] = pz :/ ps[i1]
			tw[sel[i0]] = (1 - pz) :/ (1 :- ps[i0])
		}
		else {
			st = mmw_xtile(ps, S.tstrata, u, S.wtd)
			tw[sel] = J(ns, 1, .)
			for (s = 1; s <= S.tstrata; s++) {
				if (!any(st :== s)) continue
				ii = selectindex(st :== s)
				n1 = quadsum(u[ii] :* z[ii])
				n0 = quadsum(u[ii] :* (1 :- z[ii]))
				c1 = sum(z[ii])
				c0 = rows(ii) - c1
				if (c1 >= 1 & c0 >= 1) {
					i1 = mmw_si(ii, z[ii])
					i0 = mmw_si(ii, z[ii] :== 0)
					tw[sel[i1]] = J(rows(i1), 1, ((n1 + n0)/n1)*pz)
					tw[sel[i0]] = J(rows(i0), 1, ((n1 + n0)/n0)*(1 - pz))
				}
			}
		}
		return(1)
	}
	z = D.tix[sel]
	if (S.tm == 4) {
		if (!mmw_fml(z, X, u, S.L, S.cix, b)) return(0)
		PS = mmw_pml(X, b, S.L, S.cix, E)
	}
	else {
		lnk = (S.tm == 5 ? 1 : 2)
		if (!mmw_ford(lnk, z, mmw_r(D.XT, sel), u, S.L, b)) return(0)
		PS = mmw_pord(lnk, mmw_r(D.XT, sel), b, S.L)
	}
	if (!S.mmws) {
		for (i = 1; i <= S.L; i++) {
			ii = selectindex(z :== i)
			pr = quadsum(u :* (z :== i))/quadsum(u)
			tw[sel[ii]] = pr :/ PS[ii, i]
		}
	}
	else if (S.tm != 4) {
		sw = quadsum(u)
		tw[sel] = J(ns, 1, .)
		st = mmw_xtile(PS[., 1], S.tstrata, u, S.wtd)
		nlv = 0
		for (i = 1; i <= S.L; i++) nlv = nlv + any(z :== i)
		for (s = 1; s <= S.tstrata; s++) {
			if (!any(st :== s)) continue
			ii   = selectindex(st :== s)
			nlk  = 0
			for (i = 1; i <= S.L; i++) nlk = nlk + any(z[ii] :== i)
			if (nlk < nlv) continue
			nsum = quadsum(u[ii])
			for (i = 1; i <= S.L; i++) {
				i1 = mmw_si(ii, z[ii] :== i)
				if (rows(i1) == 0) continue
				pr = quadsum(u :* (z :== i))/sw
				nz = quadsum(u[ii] :* (z[ii] :== i))
				tw[sel[i1]] = J(rows(i1), 1, (nsum/nz)*pr)
			}
		}
	}
	else {
		sw = quadsum(u)
		tw[sel] = J(ns, 1, .)
		for (i = 1; i <= S.L; i++) {
			pr = quadsum(u :* (z :== i))/sw
			st = mmw_xtile(PS[., i], S.tstrata, u, S.wtd)
			for (s = 1; s <= S.tstrata; s++) {
				if (!any(st :== s)) continue
				ii   = selectindex(st :== s)
				nsum = quadsum(u[ii])
				nz   = quadsum(u[ii] :* (z[ii] :== i))
				i1   = mmw_si(ii, z[ii] :== i)
				if (rows(i1) > 0) tw[sel[i1]] = J(rows(i1), 1, (nsum/nz)*pr)
			}
		}
	}
	return(1)
}

real matrix mmw_mterm(real colvector m, real colvector lev, real scalar cat)
{
	real matrix T
	real scalar l

	if (!cat) return(m)
	T = J(rows(m), rows(lev) - 1, .)
	for (l = 2; l <= rows(lev); l++) T[., l - 1] = (m :== lev[l])
	return(T)
}

real scalar mmw_oddsw(struct mmw_bset scalar S, struct mmw_bd scalar D, real colvector fs, real matrix F,
	real colvector sx, real scalar k, real matrix MT1, real matrix MT2)
{
	real colvector sel, u, mvk, cell, cs, z, b, pw, po, xbw, xbo
	real matrix Cm, Wm, Xc, Xw, Zh, XW, XO, PW, PO, Ew, Eo
	real scalar ns, off, other, i, lnk

	sel = selectindex(fs)
	ns  = rows(sel)
	if (ns == 0) return(0)
	u   = D.uw[sel]
	off = (k - 1)*S.L
	if (k == 1) {
		mvk = D.m1
		Cm  = (D.XM1, D.OTc1)
		Wm  = (MT1, Cm, D.OTw1)
	}
	else {
		mvk = D.m2
		Cm  = D.XM2
		if (S.design == 3) Cm = (Cm, MT1)
		Cm  = (Cm, D.OTc2)
		Wm  = (MT2, Cm, D.OTw2)
	}
	if (S.mt[k] <= 4) cell = D.tix + 11*mvk
	else              cell = D.tix
	cs = cell[sel]
	Xc = (mmw_r(Cm, sel), J(ns, 1, 1))
	Xw = (mmw_r(Wm, sel), J(ns, 1, 1))
	Zh = mmw_r(D.XH, sel)
	if (S.L == 2) {
		z = (D.tix[sel] :!= S.cix)
		if (!mmw_fbin(S.tm, z, Xw, Zh, u, b, 1)) return(0)
		if (S.tm == 1) xbw = Xw*b
		else {
			pw  = mmw_pbin(S.tm, Xw, Zh, b)
			xbw = ln(pw :/ (1 :- pw))
		}
		if (!mmw_fbin(S.tm, z, Xc, Zh, u, b, 1)) return(0)
		if (S.tm == 1) xbo = Xc*b
		else {
			po  = mmw_pbin(S.tm, Xc, Zh, b)
			xbo = ln(po :/ (1 :- po))
		}
		other = (S.cix == 1 ? 2 : 1)
		F[sel, off + S.cix] = J(ns, 1, 1)
		F[sel, off + other] = exp(xbw - xbo)
		if (S.common) {
			mmw_suppw(xbw, D.tix[sel], mvk[sel], S.mt[k] <= 4, sel, S.caliper, sx)
			mmw_supp(xbo, cs, sel, S.caliper, sx)
		}
		return(1)
	}
	if (S.tm == 4) {
		if (!mmw_fml(D.tix[sel], Xw, u, S.L, S.cix, b)) return(0)
		PW = mmw_pml(Xw, b, S.L, S.cix, Ew)
		if (!mmw_fml(D.tix[sel], Xc, u, S.L, S.cix, b)) return(0)
		PO = mmw_pml(Xc, b, S.L, S.cix, Eo)
	}
	else {
		lnk = (S.tm == 5 ? 1 : 2)
		XW  = mmw_r(Wm, sel)
		XO  = mmw_r(Cm, sel)
		if (!mmw_ford(lnk, D.tix[sel], XW, u, S.L, b)) return(0)
		PW  = mmw_pord(lnk, XW, b, S.L)
		if (!mmw_ford(lnk, D.tix[sel], XO, u, S.L, b)) return(0)
		PO  = mmw_pord(lnk, XO, b, S.L)
		Ew  = ln(PW :/ PW[., S.cix])
		Eo  = ln(PO :/ PO[., S.cix])
	}
	for (i = 1; i <= S.L; i++) {
		F[sel, off + i] = exp(Ew[., i] - Eo[., i])
		if (S.common & i != S.cix) {
			mmw_suppw(Ew[., i], D.tix[sel], mvk[sel], S.mt[k] <= 4, sel, S.caliper, sx)
			mmw_supp(Eo[., i], cs, sel, S.caliper, sx)
		}
	}
	return(1)
}

real scalar mmw_mfit(struct mmw_bset scalar S, struct mmw_bd scalar D, real scalar k, real colvector sub,
	real matrix cov, real colvector ww, real matrix F, real matrix LPA, real scalar dolp, real colvector sx)
{
	real colvector ssel, mv, mvs, tx, levs, cell, yc, idx, wa, b, lp, p, r, s2
	real matrix Xs, Zs, CV, P, E, LP
	real scalar ns, mt, cat, off, nl, a, l, nf, rk, sw, s2v, j

	ssel = selectindex(sub)
	ns   = rows(ssel)
	if (ns == 0) return(0)
	mt   = S.mt[k]
	if (k == 1) mv = D.m1
	else        mv = D.m2
	cat  = (mt <= 4)
	mvs  = mv[ssel]
	tx   = D.tix[ssel]
	off  = (k - 1)*S.L
	nl   = 0
	if (cat) {
		levs = uniqrows(mvs)
		nl   = rows(levs)
		for (a = 1; a <= S.L; a++) {
			for (l = 1; l <= nl; l++) {
				if (!any((tx :== a) :& (mvs :== levs[l]))) return(0)
			}
		}
		cell = tx + 11*mvs
		yc   = J(ns, 1, .)
		for (l = 1; l <= nl; l++) yc[selectindex(mvs :== levs[l])] = J(sum(mvs :== levs[l]), 1, l)
	}
	else cell = tx
	CV = mmw_r(cov, ssel)
	Xs = (CV, J(ns, 1, 1))
	for (a = 1; a <= S.L; a++) {
		if (!any(tx :== a)) return(0)
		idx = selectindex(tx :== a)
		nf  = rows(idx)
		wa  = ww[ssel[idx]]
		if (mt == 1 | mt == 2) {
			if (!mmw_fbin(mt, mvs[idx], Xs[idx, .], J(nf, 0, .), wa, b, 1)) return(0)
			lp = Xs*b
			if (mt == 1) p = invlogit(lp)
			else         p = normal(lp)
			F[ssel, off + a] = mvs :* p + (1 :- mvs) :* (1 :- p)
			LP = lp
		}
		else if (mt == 3) {
			if (!mmw_ford(1, yc[idx], mmw_r(CV, idx), wa, nl, b)) return(0)
			P = mmw_pord(1, CV, b, nl)
			F[ssel, off + a] = rowsum(P :* mmw_ind(yc, nl))
			if (cols(CV) > 0) LP = CV*b[|1 \ cols(CV)|]
			else              LP = J(ns, 1, 0)
		}
		else if (mt == 4) {
			if (!mmw_fml(yc[idx], Xs[idx, .], wa, nl, 1, b)) return(0)
			P  = mmw_pml(Xs, b, nl, 1, E)
			F[ssel, off + a] = rowsum(P :* mmw_ind(yc, nl))
			LP = J(ns, 0, .)
		}
		else if (mt == 6) {
			if (!mmw_fpois(mvs[idx], Xs[idx, .], wa, b)) return(0)
			LP = Xs*b
			F[ssel, off + a] = poissonp(exp(LP), mvs)
		}
		else {
			if (!S.het) {
				b   = mmw_wls(mvs[idx], Xs[idx, .], wa, rk)
				lp  = Xs*b
				r   = mvs[idx] - lp[idx]
				sw  = quadsum(wa)
				s2v = quadsum(wa :* r:^2)*(nf/sw)/(nf - rk)
				s2  = J(ns, 1, s2v)
			}
			else {
				/* variance model ln(sigma^2) = z'g on hetvars() (default: the mean covariates) */
				if (S.hv) Zs = (mmw_r(D.HV, ssel), J(ns, 1, 1))
				else      Zs = Xs
				if (!mmw_fhet(mvs[idx], Xs[idx, .], Zs[idx, .], wa, b)) return(0)
				lp = Xs*b[|1 \ cols(Xs)|]
				s2 = exp(Zs*b[|cols(Xs) + 1 \ rows(b)|])
			}
			F[ssel, off + a] = normalden(mvs, lp, sqrt(s2))
			LP = lp
		}
		if (dolp) LPA[ssel, a] = LP[., 1]
		if (S.common) {
			for (j = 1; j <= cols(LP); j++) mmw_supp(LP[., j], cell, ssel, S.caliper, sx)
		}
	}
	return(1)
}

real scalar mmw_npw(struct mmw_bset scalar S, struct mmw_bd scalar D, real colvector gt, real colvector ww,
	real matrix LPA, real matrix F, real colvector excl, real colvector mlev)
{
	real colvector ns, nsel, tx, mx, wv, g1, st, jj, h, us, ii, iu, pft, pfc, bad
	real scalar xw, t, j, s, l, dt, dc, cix, i

	xw  = (S.wtd | S.hasT)
	cix = S.cix
	for (t = 1; t <= S.L; t++) {
		if (t == cix) continue
		ns = gt :& (excl :== 0) :& ((D.tix :== t) :| (D.tix :== cix))
		if (!any(ns)) return(0)
		nsel = selectindex(ns)
		tx   = D.tix[nsel]
		mx   = D.m1[nsel]
		wv   = ww[nsel]
		g1   = mmw_xtile(LPA[nsel, t], S.s1, wv, xw)
		st   = J(rows(nsel), 1, .)
		for (j = 1; j <= S.s1; j++) {
			if (!any(g1 :== j)) continue
			jj = selectindex(g1 :== j)
			h  = mmw_xtile(LPA[nsel[jj], cix], S.s0, wv[jj], xw)
			st[jj] = (j - 1)*S.s0 :+ h
		}
		pft = J(rows(nsel), 1, .)
		pfc = J(rows(nsel), 1, .)
		bad = J(rows(nsel), 1, 0)
		us  = uniqrows(st)
		for (s = 1; s <= rows(us); s++) {
			ii = selectindex(st :== us[s])
			dt = quadsum(wv[ii] :* (tx[ii] :== t))
			dc = quadsum(wv[ii] :* (tx[ii] :== cix))
			for (l = 1; l <= rows(mlev); l++) {
				iu = mmw_si(ii, mx[ii] :== mlev[l])
				if (rows(iu) == 0) {
					bad[ii] = J(rows(ii), 1, 1)
					continue
				}
				pft[iu] = J(rows(iu), 1, quadsum(wv[iu] :* (tx[iu] :== t))/dt)
				pfc[iu] = J(rows(iu), 1, quadsum(wv[iu] :* (tx[iu] :== cix))/dc)
				if (sum(tx[iu] :== t) < S.nmin | sum(tx[iu] :== cix) < S.nmin) bad[ii] = J(rows(ii), 1, 1)
			}
		}
		if (any(bad)) excl[nsel[selectindex(bad)]] = J(sum(bad), 1, 1)
		if (S.L == 2) {
			F[nsel, t]   = pft
			F[nsel, cix] = pfc
		}
		else {
			if (any(tx :== t)) {
				iu = selectindex(tx :== t)
				F[nsel[iu], t]   = pft[iu]
				F[nsel[iu], cix] = pfc[iu]
			}
			if (any(tx :== cix)) {
				iu = selectindex(tx :== cix)
				F[nsel[iu], t]   = pft[iu] :/ pfc[iu]
				F[nsel[iu], cix] = J(rows(iu), 1, 1)
			}
		}
	}
	if (S.L > 2) {
		for (i = 1; i <= S.L; i++) {
			if (i == cix) continue
			iu = gt :& (excl :== 0) :& (D.tix :!= cix) :& (D.tix :!= i) :& (rowmissing(F[., i]) :> 0)
			if (any(iu)) {
				ii = selectindex(iu)
				F[ii, i] = J(rows(ii), 1, 1)
			}
		}
	}
	return(1)
}

real rowvector mmw_outc(struct mmw_bset scalar S, struct mmw_bd scalar D, real colvector fin, real colvector tw,
	real matrix F, real matrix Fown)
{
	struct mmw_mdl scalar M
	real colvector fsel, y, uw, tx, grp, sel, ii, w, rw, rc, ws, ys, gr, pos, gam, b0, eta, mu, a, hp, da, cl
	real matrix X, Fr, Fo, A
	real rowvector fail, B, m
	real scalar C, G, nd, px, gi, c, k, tg, sw, ess, r, q, off, rk, ym

	fail = J(1, rows(S.Lm), .)
	fsel = selectindex(fin)
	y    = D.y[fsel]
	uw   = D.uw[fsel]
	tx   = D.tix[fsel]
	grp  = D.grp[fsel]
	Fr   = F[fsel, .]
	Fo   = Fown[fsel, .]
	C    = S.C
	G    = S.G
	nd   = G*C
	px   = cols(D.xv)
	if (px > 0) {
		X = D.xv[fsel, .]
		for (gi = 1; gi <= G; gi++) {
			cl = (grp :== S.glev[gi])
			m  = quadcolsum(X :* (cl :* uw)) :/ quadsum(cl :* uw)
			X  = X - cl*m
		}
	}
	rw = J(0, 1, .)
	rc = J(0, 1, .)
	ws = J(0, 1, .)
	for (c = 1; c <= C; c++) {
		if (!any(tx :== S.CA[c])) return(fail)
		ii = selectindex(tx :== S.CA[c])
		w  = uw[ii] :* tw[fsel[ii]]
		for (k = 1; k <= S.K; k++) {
			tg = S.TG[c, k]
			if (tg > 0) w = w :* Fr[ii, (k - 1)*S.L + tg] :/ Fo[ii, k]
		}
		rw = rw \ ii
		rc = rc \ J(rows(ii), 1, c)
		ws = ws \ w
	}
	gr = grp[rw]
	ys = y[rw]
	for (gi = 1; gi <= G; gi++) {
		for (c = 1; c <= C; c++) {
			if (!any((rc :== c) :& (gr :== S.glev[gi]))) return(fail)
			sel = selectindex((rc :== c) :& (gr :== S.glev[gi]))
			sw  = quadsum(ws[sel])
			ess = sw^2/quadsum(ws[sel]:^2)
			if (missing(ess)) return(fail)
			if (ess < 2) return(fail)
		}
	}
	B = J(1, nd, .)
	if (px == 0) {
		for (gi = 1; gi <= G; gi++) {
			for (c = 1; c <= C; c++) {
				sel = selectindex((rc :== c) :& (gr :== S.glev[gi]))
				r   = (gi - 1)*C + c
				B[r] = quadsum(ws[sel] :* ys[sel])/quadsum(ws[sel])
				if (S.om == 1) {
					pos = select(ys[sel], ws[sel] :> 0)
					if (max(pos) == min(pos)) return(fail)
				}
				else if (S.om <= 3) {
					if (B[r] <= 0 | B[r] >= 1) return(fail)
				}
				else if (B[r] <= 0) return(fail)
			}
		}
	}
	else {
		q = nd + (G > 1 ? G*px : px)
		A = J(rows(rw), q, 0)
		for (gi = 1; gi <= G; gi++) {
			for (c = 1; c <= C; c++) {
				sel = selectindex((rc :== c) :& (gr :== S.glev[gi]))
				A[sel, (gi - 1)*C + c] = J(rows(sel), 1, 1)
			}
			off = nd + (G > 1 ? (gi - 1)*px : 0)
			sel = selectindex(gr :== S.glev[gi])
			A[sel, (off + 1)..(off + px)] = X[rw[sel], .]
		}
		if (S.om == 1) {
			gam = mmw_wls(ys, A, ws, rk)
			B   = gam[|1 \ nd|]'
		}
		else {
			b0 = J(q, 1, 0)
			for (gi = 1; gi <= G; gi++) {
				for (c = 1; c <= C; c++) {
					sel = selectindex((rc :== c) :& (gr :== S.glev[gi]))
					ym  = quadsum(ws[sel] :* ys[sel])/quadsum(ws[sel])
					if (S.om <= 3 & (ym <= 0 | ym >= 1)) return(fail)
					if (S.om == 4 & ym <= 0) return(fail)
					if (S.om == 2)      b0[(gi - 1)*C + c] = logit(ym)
					else if (S.om == 3) b0[(gi - 1)*C + c] = invnormal(ym)
					else                b0[(gi - 1)*C + c] = ln(ym)
				}
			}
			M.type = (S.om == 2 ? 1 : (S.om == 3 ? 2 : 7))
			M.y    = ys
			M.X    = A
			M.w    = ws
			gam    = b0
			if (!mmw_nr(M, gam)) return(fail)
			for (gi = 1; gi <= G; gi++) {
				cl  = (grp :== S.glev[gi])
				sel = selectindex(cl)
				off = nd + (G > 1 ? (gi - 1)*px : 0)
				for (c = 1; c <= C; c++) {
					r   = (gi - 1)*C + c
					eta = gam[r] :+ X[sel, .]*gam[|off + 1 \ off + px|]
					mmw_link(eta, S.om, mu, a, hp, da)
					B[r] = quadsum(uw[sel] :* mu)/quadsum(uw[sel])
				}
			}
		}
	}
	return(B*S.Lm')
}

real rowvector mmw_dest(struct mmw_bset scalar S, struct mmw_bd scalar D)
{
	real colvector tw, excl, ww, sx, gt, fs, fo, fin, ok, own, ml1, ml2, j1, sub, ii
	real matrix F, LPA, MT1, MT2, cov, Fown
	real rowvector fail
	real scalar n, L, K, gi, i, k, j

	n    = rows(D.y)
	L    = S.L
	K    = S.K
	fail = J(1, rows(S.Lm), .)
	tw   = J(n, 1, 1)
	excl = J(n, 1, 0)
	ww   = J(n, 1, .)
	F    = J(n, K*L, .)
	LPA  = J(n, L, .)
	ml1  = uniqrows(D.m1)
	if (S.mt[1] <= 4 & rows(ml1) < 2) return(fail)
	MT1  = mmw_mterm(D.m1, ml1, S.mt[1] <= 4)
	MT2  = J(n, 0, .)
	if (K == 2) {
		ml2 = uniqrows(D.m2)
		if (S.mt[2] <= 4 & rows(ml2) < 2) return(fail)
		MT2 = mmw_mterm(D.m2, ml2, S.mt[2] <= 4)
	}
	for (gi = 1; gi <= S.G; gi++) {
		gt = (D.grp :== S.glev[gi])
		for (i = 1; i <= L; i++) {
			if (!any(gt :& (D.tix :== i))) return(fail)
		}
		if (S.hasT) {
			if (!mmw_tsel(S, D, gt, tw)) return(fail)
			excl = (excl + gt :* (rowmissing(tw) :> 0)) :> 0
		}
		fs = gt :& (excl :== 0)
		if (!any(fs)) return(fail)
		fo = selectindex(fs)
		ww[fo] = D.uw[fo] :* tw[fo]
		sx = J(n, 1, 0)
		if (S.odds) {
			for (k = 1; k <= K; k++) {
				if (!mmw_oddsw(S, D, fs, F, sx, k, MT1, MT2)) return(fail)
			}
		}
		else {
			for (k = 1; k <= K; k++) {
				if (k == 1) cov = D.XM1
				else        cov = D.XM2
				if (S.design == 3 & k == 2 & S.mt[1] <= 4) {
					j1 = uniqrows(D.m1[fo])
					for (j = 1; j <= rows(j1); j++) {
						sub = fs :& (D.m1 :== j1[j])
						if (!mmw_mfit(S, D, k, sub, cov, ww, F, LPA, 0, sx)) return(fail)
					}
				}
				else {
					if (S.design == 3 & k == 2) cov = (cov, D.m1)
					if (!mmw_mfit(S, D, k, fs, cov, ww, F, LPA, (k == 1 & S.np), sx)) return(fail)
				}
			}
		}
		excl = (excl + fs :* sx) :> 0
		if (S.np) {
			if (!mmw_npw(S, D, gt, ww, LPA, F, excl, ml1)) return(fail)
		}
	}
	fin  = (excl :== 0)
	Fown = J(n, K, .)
	for (k = 1; k <= K; k++) {
		own = J(n, 1, .)
		for (i = 1; i <= L; i++) {
			if (!any(D.tix :== i)) continue
			ii = selectindex(D.tix :== i)
			own[ii] = F[ii, (k - 1)*L + i]
		}
		Fown[., k] = own
		ok  = (rowmissing(own) :== 0) :& (editmissing(own, 0) :> 0) :& (rowmissing(F[|1, (k - 1)*L + 1 \ n, k*L|]) :== 0)
		fin = fin :& ok
	}
	if (!any(fin)) return(fail)
	for (gi = 1; gi <= S.G; gi++) {
		for (i = 1; i <= L; i++) {
			if (!any(fin :& (D.grp :== S.glev[gi]) :& (D.tix :== i))) return(fail)
		}
	}
	return(mmw_outc(S, D, fin, tw, F, Fown))
}

void mmw_dcheck(string scalar bref, real scalar tol)
{
	struct mmw_bset scalar S
	struct mmw_bd scalar D
	real rowvector b0, ref
	real scalar dif

	S   = mmw_bs_set()
	D   = mmw_bs_data()
	b0  = mmw_dest(S, D)
	ref = st_matrix(bref)
	if (cols(b0) != cols(ref) | hasmissing(b0)) {
		st_local("mmw_bsok", "0")
		st_local("mmw_bsdif", ".")
		return
	}
	dif = max(abs(b0 - ref))
	st_local("mmw_bsdif", strofreal(dif, "%9.2e"))
	st_local("mmw_bsok", strofreal(dif <= tol*(1 + max(abs(ref)))))
}

void mmw_dboot(real scalar R, real scalar usecl, real scalar dots, string scalar Vname, string scalar BBname)
{
	struct mmw_bset scalar S
	struct mmw_bd scalar D, Db
	pointer(transmorphic) scalar p
	real colvector cl, o, idx
	real matrix info, BB
	real rowvector bb
	real scalar n, r, G, k, ng, bad

	S = mmw_bs_set()
	D = mmw_bs_data()
	n = rows(D.y)
	G = .
	if (usecl) {
		p    = findexternal("mmw_BS")
		cl   = asarray(*p, "bscl")
		o    = order(cl, 1)
		info = panelsetup(cl[o], 1)
		G    = rows(info)
	}
	BB  = J(R, rows(S.Lm), .)
	bad = 0
	if (dots) {
		printf("{txt}\nBootstrap replications ({res}%f{txt})\n", R)
		displayflush()
	}
	for (r = 1; r <= R; r++) {
		if (!usecl) idx = runiformint(n, 1, 1, n)
		else {
			idx = J(0, 1, .)
			for (k = 1; k <= G; k++) {
				ng  = runiformint(1, 1, 1, G)
				idx = idx \ o[|info[ng, 1] \ info[ng, 2]|]
			}
		}
		Db = mmw_dsub(D, idx)
		bb = mmw_dest(S, Db)
		BB[r, .] = bb
		if (hasmissing(bb)) bad++
		if (dots) {
			printf(hasmissing(bb) ? "{err}x{txt}" : ".")
			if (mod(r, 50) == 0) printf("%6.0f\n", r)
			displayflush()
		}
	}
	if (dots & mod(R, 50) != 0) printf("\n")
	BB = select(BB, rowmissing(BB) :== 0)
	if (rows(BB) < 2) {
		errprintf("too few successful bootstrap replications\n")
		exit(2000)
	}
	st_matrix(Vname, variance(BB))
	st_matrix(BBname, BB)
	st_local("mmw_nreps", strofreal(rows(BB)))
	st_local("mmw_nmis", strofreal(bad))
	st_local("mmw_n", strofreal(n))
	if (usecl) st_local("mmw_nclust", strofreal(G))
}

end
