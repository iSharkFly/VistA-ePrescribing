C0PEREW	  ; eRx/GPL - ePrescription ewd utilities; 1/3/11
	;;1.0;C0P;;Apr 25, 2012;Build 103
	;Copyright 2009 George Lilly.  Licensed under the terms of the GNU
	;General Public License See attached copy of the License.
	;
	;This program is free software; you can redistribute it and/or modify
	;it under the terms of the GNU General Public License as published by
	;the Free Software Foundation; either version 2 of the License, or
	;(at your option) any later version.
	;
	;This program is distributed in the hope that it will be useful,
	;but WITHOUT ANY WARRANTY; without even the implied warranty of
	;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	;GNU General Public License for more details.
	;
	;You should have received a copy of the GNU General Public License along
	;with this program; if not, write to the Free Software Foundation, Inc.,
	;51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
	;
	Q
	;
test1(sessid)	;
	d setSessionValue^%zewdAPI("testing","ZZ",sessid)
	q 0
	;
cbTestMethod(prefix,seedValue,lastSeedValue,optionNo,options)	
	;
	n maxNo,noFound,dfn,dob,sex
	;
	s maxNo=50
	s noFound=0
	f  s seedValue=$o(^DPT("B",seedValue)) q:seedValue=""  q:noFound=maxNo  d
	. s lastSeedValue=seedValue
	. i prefix'="",$e(seedValue,1,$l(prefix))'=prefix q
	. s optionNo=optionNo+1
	. s noFound=noFound+1
	. s options(optionNo)=seedValue
	. s dfn=$o(^DPT("B",seedValue,"")) ; dfn of the patient
	. s dob=$$GET1^DIQ(2,dfn,.03) ; date of birth
	. s sex=$$GET1^DIQ(2,dfn,.02,"I") ; sex M or F
	. s options(optionNo)=seedValue_"  "_dob_" "_sex ; complete patient
	QUIT
	;
set1	;
	s ^zewd("comboPlus","methodMap","test")="cbTestMethod^C0PEREW"
	; THIS THE SHELL SCRIPT WHICH CREATED THE EWD PAGES IN THE C0P NAMESPACE
	;cp ../w/ewdWLerxewdajaxerror.m C0PE001.m
	;cp ../w/ewdWLerxewdajaxerrorredirect.m C0PE002.m
	;cp ../w/ewdWLerxewderrorredirect.m C0PE003.m
	;cp ../w/ewdWLerxindex1.m C0PE004.m
	;cp ../w/ewdWLerxmatch.m C0PE005.m
	;cp ../w/ewdWLerxnomatch.m C0PE006.m
	; WE NEED TO ADD THIS CONFIGURATION ONE TIME TO ^zewd
	;s ^zewd("routineMap","eRx","ewdajaxerror")="C0PE001"
	;s ^zewd("routineMap","eRx","ewdajaxerrorredirect")="C0PE002"
	;s ^zewd("routineMap","eRx","ewderrorredirect")="C0PE003"
	;s ^zewd("routineMap","eRx","index1")="C0PE004"
	;s ^zewd("routineMap","eRx","match")="C0PE005"
	;s ^zewd("routineMap","eRx","nomatch")="C0PE006"
	; unfortunately, the global map doesn't really work for now.. but
	; we will keep trying in future releases
	q
	;
INITSES(sessid)	; INITIALIZE AN EWD SESSION BY PULLING "VISTA" VARIABLES 
	; INTO THE SESSION FROM WHERE THEY HAVE BEEN STORED. THEY ARE INDEXED
	; BY A UNIQUE RANDOM TOKEN WHICH IS PASSED WITH THE URL
	; FOR EXAMPLE https//example.com/ewd/myApp/index.ewd?token="12345"
	N ZTOKEN,C0EARY
	S ZTOKEN=$$URLTOKEN^C0CEWD(sessid) ; get the token passed on the url
	D GET^C0CEWD("C0EARY",ZTOKEN,1) ; GET THE ARRAY OF VALUES
	S C0EARY("TOKEN")=ZTOKEN
	M ^TMP("GPL")=C0EARY
	d mergeArrayToSession^%zewdAPI(.C0EARY,"VistA",sessid)
	; ALL VISTA VARIABLES ARE IN THE "VistA" section of the session
	Q
	;
INITREW(sessid)	; initialze the eRx Renewal Patient Matching screen
	;
	N C0PSES,ZDJ,ZDOB,ZSEX
	D INITSES(sessid) ; add the VistA Variables to the session
	D mergeArrayFromSession^%zewdAPI(.C0PSES,"VistA",sessid) ; get them back
	N ZNAME,ZMED,ZSV
	S ZNAME=$G(C0PSES("C0PRenewalName"))
	I ZNAME="" Q "" ;OOPS
	S ZDOB=$G(C0PSES("RenewalDOB")) ; date of birth
	I ZDOB'="" S ZDOB=$E(ZDOB,5,6)_"/"_$E(ZDOB,7,8)_"/"_$E(ZDOB,1,4) ; REFORMAT
	d setSessionValue^%zewdAPI("RenewalDOB",ZDOB,sessid) ; save in session
	S ZSEX=$G(C0PSES("RenewalSex")) ; gender
	d setSessionValue^%zewdAPI("RenewalSex",ZSEX,sessid) ; save in session
	s ZNAME=ZNAME_"  "_ZDOB_" "_ZSEX ; ADD DOB AND SEX TO PATIENT NAME
	d setSessionValue^%zewdAPI("C0PRenewalName",ZNAME,sessid) ;the whole name
	d setSessionValue^%zewdAPI("pat4",$e(ZNAME,1,4),sessid) ;first part of name
	S ZMED=$G(C0PSES("medication")) ; pull med from VistA part of session
	d setSessionValue^%zewdAPI("medication",ZMED,sessid) ;the med
	S ZDJ=$G(C0PSES("dollarJ")) ; job number of CPRS session
	d setSessionValue^%zewdAPI("CPRSdollarJ",ZDJ,sessid) ; save in the session 
	S ZSV=$G(C0PSES("SUPERVISING-DUZ")) ; supervising doctor DUZ
	d setSessionValue^%zewdAPI("supervisor",ZSV,sessid) ; save 
	d clearList^%zewdAPI("supervisor",sessid) ; make sure no list is there
	M DUZ=C0PSES("DUZ") ; PASS LOG ON AUTHORITY
	n svlist ; list of licensed prescribers
	d SVLIST("svlist") ; generate the list
	n zi,zn
	s zi=""
	f  s zi=$o(svlist(zi)) q:zi=""  d  ; for each licensed prescriber
	. s zn=$o(svlist(zi,"")) ; DUZ of prescriber
	. d appendToList^%zewdAPI("supervisor",zi,zn,sessid) ;add to list
	Q ""
	;
MATCH(sessid)	; process submit after matching
	S ^TMP("GPL","MATCH",sessid)=""
	N ZRTN,ZNAME,ZDFN
	S ZNAME=$$getSessionValue^%zewdAPI("patient",sessid) ; current match
	S ZNAME=$P(ZNAME,"  ",1) ; GET JUST THE NAME - NOT DOB OR SEX
	S ZDFN=$O(^DPT("B",ZNAME,""))
	S ZRTN=""
	I ZDFN="" S ZRTN="Please select a patient"
	D setSessionValue^%zewdAPI("selectedDFN",ZDFN,sessid) ; record selection
	Q ZRTN
	;
NOMATCH(sessid)	; process submit after matching
	S ^TMP("GPL","NOMATCH",sessid)=""
	Q ""
	;
MTCHPG(sessid)	; process the match clickthrough page
	N GDFN,ZDJ
	S GDFN=$$getSessionValue^%zewdAPI("selectedDFN",sessid) ; THE PATIENT SELECTED
	S ZDJ=$$getSessionValue^%zewdAPI("CPRSdollarJ",sessid) ; CPRS job number
	S ^TMP("C0E",ZDJ,"NEWDFN")=GDFN ; PASS THE NEW DFN TO CPRS
	D BRSRDR(GDFN,sessid) ; GENERATE THE RENEWAL BROWSER REDIRECT PAGE
	Q ""
	;
NOMTCHPG(sessid)	; process the nomatch clickthrough page
	D BRSRDR(0,sessid) ; BOTH MATCH AND NOMATCH DO THE SAME THING FOR NOW
	Q ""
	;
BRSRDR(ZDFN,sessid)	; GENERATE RENEWAL BROWSER REDIRCT HTML/XML TO CLICK THRU
	; TO ERX RENEWAL
	N ZISTR,ZDUZ,ZHTML,C0PSES
	D mergeArrayFromSession^%zewdAPI(.C0PSES,"VistA",sessid) ; get SESSION VARS
	S ZDUZ=$G(C0PSES("DUZ"))
	M DUZ=C0PSES("DUZ") ; PASS LOG ON AUTHORITY
	S ZISTR=$G(C0PSES("renewalToken"))
	S C0PSPRV=$$getSessionValue^%zewdAPI("supervisor",sessid) ;supervisor selected
	I C0PSPRV="" S C0PSVRV=$G(C0PSES("SUPERVISOR-DUZ")) ; SUPERVISING DOCTOR DUZ
	D ALERTRPC^C0PCPRS1(.ZHTML,ZDUZ,ZDFN,1,ZISTR,1) ; CALL WITH MODE=1
	d mergeArrayToSession^%zewdAPI(.ZHTML,"eRxRenew",sessid)
	Q
	;
SVLIST(ZLIST)	; GENERATE A LIST OF LICENSED PRESCRIBERS FOR THE
	; MIDLEVEL SUPERVISING DOCTOR PULLDOWN; ZLIST IS PASSED BY NAME
	N ZI,ZA
	S ZA=$NA(^VA(200,"C0P","ERX")) ; INDEX TO USE
	S ZI=""
	F  S ZI=$O(@ZA@(ZI)) Q:ZI=""  D  ; FOR EACH SUBSCRIBER
	. N ZS
	. D SETACCT^C0PSUB("ZS",ZI) ; GET SUBSCRIPTION INFO
	. I $G(ZS("SUBSCRIBER-USERTYPE"))="LicensedPrescriber" D  ; USE IT
	. . N ZN
	. . S ZN=$$GET1^DIQ(200,ZI,.01,"E") ; NAME OF SUBSCRIBER
	. . S @ZLIST@(ZN,ZI)="" ; RETURN THIS SUBSCRIBER
	. K ZS
	Q
	;
