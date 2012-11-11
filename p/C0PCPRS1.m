C0PCPRS1	  ; CCDCCR/GPL - ePrescription utilities; 8/1/09 ; 5/8/12 10:18pm
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
	; THESE ROUTINE CONSTITUTE ALL OF THE ENTRY POINTS IN THE ERX PACKAGE
	; THAT ARE USED BY CPRS.
	; ERXRPC IS USED BY CPRS TO LAUNCH THE MEDICATION COMPOSE SCREEN
	;   IT IS ALSO USED BY CPRS TO PROCESS AN INCOMPLETE ORDER ALERT
	; ERXPULL IS USED BY CPRS AFTER A SESSION WITH THE EPRESCRIBING PROVIDER
	;   TO PULL BACK ANY NEW MEDICATIONS AND ALLERGIES FROM THAT SESSION
	;   IT DOES MEDICATION AND ALLERGY RECONCILLIATION
	; ALERTRPC IS USED BY CPRS TO LAUCH THE RENEWAL REQUEST SCREEN IN THE 
	;   EPRECRIBING PROVIDER. AFTER THE RENEWAL SESSION ENDS, ERXPULL IS ALSO 
	;   CALLED
	; GPL JUNE, 2010
	;
	; TEST Lines below not intended for End Users. Programmers only.
	; BEWARE ZWRITE SYNTAX. It may not work in other M Implementations.
TEST1	; TEST ERX RPC FROM COMMAND LINE - RETURN RAW HTTPS POST ARRAY
	;
	N C0PG1
	D ERXRPC(.C0PG1,"135","2")
	W $$OUTPUT^C0CXPATH("C0PG1(1)","Test-RPC-POST1.html","/home/dev/CCR/"),!
	ZWRITE C0PG1
	Q
	;
TEST2	; TEST ERX RPC FROM COMMAND LINE - RETURN CODED HTTPS POST ARRAY
	;
	Q
	;
ERXPULL(RTN,IDUZ,IDFN)	;RPC TO PULL BACK DRUGS AND ALLERGIES
	;
	S ^TMP("GPL","PULLBACKDFN")=IDFN ; debugging
	N UDFN
	S UDFN=IDFN
	I $D(^TMP("C0E",$J,"NEWDFN")) D  ; IF THERE IS A NEW RENEWAL PATIENT
	. I IDFN'=0 Q  ; SHOULD BE ZERO FOR A NO MATCH RENEWAL
	. S UDFN=^TMP("C0E",$J,"NEWDFN") ; GET THE MATCHED PATIENT DFN
	. S ^TMP("GPL","NEWDFN")=UDFN ; debugging
	. K ^TMP("C0E",$J,"NEWDFN") ; ERASE IT NOW THAT IT IS USED
	D GETRXNS^C0PALGY1(IDUZ,UDFN,.RTN) ;PULL BACK ALLERGIES AND ADD TO ALLERGIES
	D GETMEDS^C0PRECON(IDUZ,UDFN,.RTN) ;PULL BACK MEDS AND ADD TO NON-VA MEDS
	I $G(RTN(1))="" S RTN(1)="OK"
	I UDFN'=IDFN S RNT(1)="DFN="_UDFN ; TELL CPRS ABOUT THE NEW DFN
	;D REFILL^C0PREFIL ; PULL BACK REFILL REQUESTS EVERY TIME 
	Q
	;
TESTUC0P	
	S ZA="OR,18,11305;135;3120305.103008"
	D ALERTRPC(.GPL,135,18,1,ZA)
	Q
	;
TESTALRT(GPL,ZDUZ,ZDFN,MODE)	; TEST THE ALERT RPC
	;
	;S G=$O(^XTV(8992,135,"XQA",""),-1)
	;S G=3110102.15081201
	;S ZA="OR,18,11305;135;"_G ;3101223.125521" ; AN ALERT RECORD ID
	;S ZA="OR,0,11305;135;3110103.09324904"
	I $G(MODE)'=1 S MODE=0 ; TEST MODE HERE
	N ZI,ZJ S ZI=0
	F  S ZI=$O(^XTV(8992,ZDUZ,"XQA",ZI)) Q:ZI=""  D  ;
	. S ZJ=^XTV(8992,ZDUZ,"XQA",ZI,0)
	. I ZJ["no match" S G=ZI
	I $G(G)="" W !,"OOPS" Q  ;
	S ZA="OR,18,11305;135;"_G
	;S ZA="OR,18,11305;135;3110810.123002"
	W !,ZA
	D ALERTRPC(.GPL,ZDUZ,ZDFN,1,ZA,MODE)
	Q
	I ZDFN=18 D ALERTRPC(.GPL,135,18,1,ZA)
	E  D  ;
	. ;S ZA="OR,0,11305;1;3101223.125521"
	. D ALERTRPC(.GPL,135,0,1,ZA)
	Q
ALERTRPC(RTN,IDUZ,IDFN,DEST,ISTR,MODE)	;RPC FOR ERX ALERTS
	; MODE IS A MODE SWITCH IF MODE=1 WE ARE USING THE BROWSER REDIRECT
	; METHOD OF CLICKING THROUGH. THIS IS DONE TO COMPLETE NOMATCH RENEWALS
	; FROM EWD
	; IF MODE IS NOT SPECIFIED OR IS NOT 1, WE WILL USE THE CPRS REDIRECT
	; METHOD OF CLICKING THROUGH. 
	; THE MAIN DIFFERENCE BETWEEN THE TWO MODES IS THE HTML PACKAGING
	; SURROUNDING THE NCSCRIPT XML
	;
	I $G(MODE)'=1 S MODE=0 ; MODE IS 0 IF IT'S NOT 1
	S C0PRMODE=1 ; RENEWAL MODE - KILL AT THE END
	;
	; FIRST SEE IF LOOK UP THE RENEWAL GUID 
	N ZGUID,ZALRT,C0PMED,ZDOB,ZSEX
	; USE THE NEW GETALRT^C0PREFIL TO GET THE GUID DIRECTLY FROM
	; THE ALERT TRACKING FILE USING THE RECORDID PASSED IN ISTR
	;D GETALRT^C0PREFIL("ZALRT",ISTR) ; GET THE ENTIRE ALERT
	;S ZGUID=$G(ZALRT("DATA FOR PROCESSING")) ; PULL OUT THE GUID
	; GET THE GUID THE QUICK WAY DIRECTLY FROM THE GLOBAL
	S ZALRT=$P(ISTR,";",3) ;THE TIME PORTION OF THE RECORD ID
	S ZGUID=$G(^XTV(8992,IDUZ,"XQA",ZALRT,1)) ;WHERE THE GUID SHOULD BE
	S ZDOB=$P(ZGUID,"^",2) ; DATE OF BIRTH
	S ZSEX=$P(ZGUID,"^",3) ; GENDER
	S ZGUID=$P(ZGUID,"^",1) ; GUID IS PIECE ONE
	I ZGUID'="" D  ; FOUND THE ALERT
	. N ZNM S ZNM=$G(^XTV(8992,IDUZ,"XQA",ZALRT,0)) ; THE ALERT RECORD
	. S C0PRNM=$P($P(ZNM,"[eRx] ",2)," Renewal",1) ; patient name
	. S C0PMED=$P(ZNM,"request for ",2) ; name of the medication
	;I ZGUID="" S ^G("NOGUID")=ISTR
	;I ZGUID="" M ^G("NOGUID")=^XTV(8992,IDUZ,"XQA")
UC0P1	I ZGUID="" D  Q  ; This is usually a missing Alert due to timing
	. ; of the batch job and the CPRS request to process an error.
	. W "ERROR EXTRACTING ALERT",!
	. I $T(LOG^%ZTER)="" D ^%ZTER Q  ;
	. N C0PERR S C0PERR="UC0P1"
	. S C0PERR("PLACE")="UC0P1^C0PCPRS1"
	. D LOG^%ZTER(.C0PERR)
	;N DONE S DONE=0
	;I ZGUID="" D  ; TRY AND FIND THE GUID ANYWAY
	;. N ZZI S ZZI=0
	;. F  S ZZI=$O(^XTV(8992,IDUZ,"XQA",ZZI)) Q:DONE  Q:ZZI=""  D  ; 
	;. . N ZA S ZA=$G(^XTV(8992,IDUZ,"XQA",ZZI,0))
	;. . ;W !,ZA B  
	;. . I ZA="" Q  ; SHOULDN'T HAPPEN
	;. . I $P(ZA,ZALRT,2)'="" D  ;
	;. . . N ZNM S ZNM=$G(^XTV(8992,IDUZ,"XQA",ZZI,0)) ; THE ALERT RECORD
	;. . . S C0PRNM=$P($P(ZNM,"[eRx] ",2)," Renewal",1) ; patient name
	;. . . S ZGUID=$G(^XTV(8992,IDUZ,"XQA",ZZI,1)) ; THE GUID
	;. . . S ZDOB=$P(ZGUID,"^",2) ; DATE OF BIRTH
	;. . . S ZSEX=$P(ZGUID,"^",3) ; GENDER
	;. . . S ZGUID=$P(ZGUID,"^",1) ; GUID IS PIECE ONE
	;. . . S C0PMED=$P(ZNM,"request for ",2) ; name of the medication
	;. . . S DONE=1
	I ZGUID="" W "ERROR EXTRACTING ALERT",! Q  ;
	;S ZGUID=$P(ZGUID,U,3) ;THE VALUE IS IN P3
	;S ZIEN=$O(^C0PRE("E","A",IDUZ,IDFN,ISTR,"")) ;LOOK FOR AN ACTIVE ALERT 
	;I ZIEN="" D  Q  ; OOPS NO MATCHING ALERT. THIS IS AN ERROR
	;. W "ERROR ALERT NOT FOUND",!
	;S ZGUID=$$GET1^DIQ(113059006,ZIEN_",",.01,"I")
	; BUILD THE NCSRIPT XML FOR RENEWALS
	N ZTID
	S ZTID=$$RESTID^C0PWS1(IDUZ,"RENEWREQ") ;
	N GVOR ; VARIABLE OVERRIDE ARRAY
	S GVOR=""
	S GVOR("REQUESTED-PAGE")="renewal"
	N ZARY,ZURL
	D EN^C0PMAIN("ZARY","ZURL",IDUZ,IDFN,,"GVOR") ; GET THE NCSCRIPT
	I IDFN=0 D DELETE^C0CXPATH("ZARY","//NCScript/Patient") ;delete patient
	I IDFN=0 D  ; GOING TO CALL THE EWD RENEWAL PATIENT MATCHING SCREEN
	. S C0PNONAME=1
	. S C0PSAV("IDUZ")=IDUZ
	. M C0PSAV("DUZ")=DUZ
	. S C0PSAV("DFN")=0
	. S C0PSAV("C0PRenewalName")=C0PRNM ; THE RENEWAL NAME
	. S C0PSAV("RenewalDOB")=ZDOB ; PHARMACY REQUEST DATE OF BIRTH
	. S C0PSAV("RenewalSex")=ZSEX ; PHARMACY REQUEST GENDER
	. S C0PSAV("renewalToken")=ISTR ; CPRS ALERT TOKEN IDENTIFIER
	. S C0PMED=$P(C0PMED,"^",1) ; CLEAN UP THE MEDICATION NAME
	. S C0PSAV("medication")=C0PMED ; MEDICATION BEING RENEWED
	. S C0PSAV("C0PGuid")=ZGUID ; RENEWAL GUID
	. S C0PSAV("dollarJ")=$J ; save the $J of the CPRS session
	. ; PASSING THE SUPERVISING DOCTOR DUZ ALONG TO THE EWD RENEWAL SCREEN
	. S C0PSAV("SUPERVISING-DUZ")=$G(C0PVARS("SUPERVISING-DOCTOR-DUZ")) ;
	N ZTMP
	D GETTEMP^C0PWS1("ZTMP",ZTID)
	N ZV
	S ZV("RENEWAL-GUID")=ZGUID
	S ZV("RESPONSE-CODE")="Undetermined"
	N ZRVAR,ZREXML
	D BIND^C0PMAIN("ZRVAR","ZV",ZTID)
	D MAP^C0CXPATH("ZTMP","ZRVAR","ZREXML")
	K ZREXML(0) ; 
	D INSERT^C0CXPATH("ZARY","ZREXML","//NCScript")
	K ZARY(0)
	D WRAP(.RTN,.ZARY,MODE)
	K C0PRMODE ; TURN OFF THE RENEWAL MODE
	Q
	;
ERXRPC(RTN,IDUZ,IDFN)	; RPC CALL TO RETURN HTTPS POST ARRAY FOR MEDS ORDERING
	;
	;I IDUZ=135 D TESTALRT(.RTN,IDFN) Q  ;GPLTESTING
	N C0PXML,C0PURL
	D EN^C0PMAIN("C0PXML","C0PURL",IDUZ,IDFN,,,1) ;INCLUDE FREEFORM ALLERGIES
	D WRAP(.RTN,.C0PXML) ; WRAP IN HTML FOR PROCESSING IN CPRS
	Q
	;
WRAP(ZRTN,ZINARY,MODE)	;WRAPS AN XML ARRAY (ZINARY) IN HTML FOR PROCESSING
	; BY CPRS - ZINARY AND ZRTN ARE PASSED BY REFERENCE
	; SEE COMMENT ABOVE ABOUT THE MODE SWITCH
	I $G(MODE)'=1 S MODE=0 ; BROWSER REDIRECT MODE IS 0 IF IT IS NOT 1
	;
	I '$D(ZINARY(1)) D  Q  ; NOT SET UP FOR ERX 
	. S ZRTN(1)="ERROR, PROVIDER NOT SUBSCRIBED"
	I MODE'=1 S ZINARY(1)="RxInput="_ZINARY(1)
	; GPL - GET THE URL FROM THE XML TEMPLATE FILE BASED ON PRODUCTION FLAG
	;S url="https://preproduction.newcropaccounts.com/InterfaceV7/RxEntry.aspx"
	D SETUP^C0PMAIN() ;INITALIZE C0PACCT WS ACCOUNT IEN
	S url=$$CTURL^C0PMAIN(C0PACCT) ; PRODUCTION OR TEST URL
	I $G(C0PNONAME)=1 D  ;
	. I MODE Q  ; WE'VE ALREADY BEEN TO EWD. THIS IS SECOND TIME
	. n token s token=$$STORE^C0CEWD("C0PSAV") ; STORE FOR EWD SCREENS
	. N ZT,ZU,ZP
	. S ZT=$O(^C0PX("B","C0P RENEWAL NOMATCH URL","")) ; IEN FOR URL
	. ; EXAMPLE URL: https://viper/dev/eRx/index1.ewd - be sure it matches
	. ; your system
	. S ZU=$$GET1^DIQ(113059001,ZT_",",1) ; URL OF NOMATCH RENEWAL SCREEN
	. I C0PVARS("SUBSCRIBER-USERTYPE")="MidlevelPrescriber" S ZP="midmatch.ewd"
	. E  S ZP="index1.ewd" ; midlevels get their own page
	. S url=ZU_ZP_"?token="""_token_"""" ; ewd interface
	. S C0PNONAME=0
	I MODE D BRSRDR Q  ; BROWSER REDIRCT PACKAGEING INSTEAD OF httpPOST2
	S ok=$$httpPOST2(.ZRTN,url,.ZINARY,"application/x-www-form-urlencoded",.gpl6,"","",.gpl5,.gpl7)
	Q
	;
BRSRDR	; GENERATE BROWSER REDIRECT PACKAGING TO RETURN TO BE SENT TO THE
	; BROWSER
	;
	N ZB,ZTMP,ZTOP,ZBOT,ZTID1,ZTID2,ZVARS
	S ZTID1=$$RESTID^C0PWS1(IDUZ,"C0P RENEWAL BRSRDR TOP") ; TOP XML IEN
	S ZTID2=$$RESTID^C0PWS1(IDUZ,"C0P RENEWAL BRSRDR BOTTOM") ; BOTTOM XML IEN
	D GETXML^C0PWS1("ZTMP",ZTID1) ; TOP XML
	S ZVARS("url")=url
	D MAP^C0CXPATH("ZTMP","ZVARS","ZTOP") ; SET THE URL PROPERLY
	D GETXML^C0PWS1("ZBOT",ZTID2) ; BOTTOM XML
	D QUEUE^C0CXPATH("ZB","ZTOP",1,$O(ZTOP(""),-1)) ; ADD TOP TO BUILD LIST
	D QUEUE^C0CXPATH("ZB","ZINARY",1,$O(ZINARY(""),-1)) ; ADD NCSCRIPT
	D QUEUE^C0CXPATH("ZB","ZBOT",1,$O(ZBOT(""),-1)) ; ADD BOTTOM
	D BUILD^C0CXPATH("ZB","ZRTN") ; BUILD RETURN HTML
	K ZRTN(0) ; KILL LENTGH NODE
	Q
	;
GETPOST1(URL)	;
	;RETRIEVES WSDL SAMPLE XML FROM A WEBSERVICE AT ADDRESS URL PASSED BY VALUE
	;RETURNS THE XML IN ARRAY gpl
	s ok=$$httpGET^%zewdGTM(URL,.gpl)
	;W "XML retrieved from Web Service:",!
	;ZWR gpl
	D INDEX^C0CXPATH("gpl","gpl2",-1,"gplTEMP")
	Q
	;
httpPOST2(ARY,url,payload,mimeType,html,headerArray,timeout,test,rawResponse,respHeaders,sslHost,sslPort)	
	;ORGINALLY THIS ROUTINE WAS FROM zewdGTM.m (thanks Rob!)
	;HACKED BY GPL TO RETURN ITS HTML IN AN ARRAY (ARY PASSED BY REF)
	;INSTEAD OF SENDING IT OUT A TPC PORT
	;THE ARY WILL BE SENT VIA RPC TO CPRS TO LAUNCH A BROWERS
	;USING THIS "POST" HTML AS THE STARTING PAGE (THANKS ART)
	;USES THE ROUTINE gw BELOW TO BUILD THE ARRAY
	; todo: html not used, test not used, rawResponse, respHeaders
	; sam's notes: this routine doesn't actually post anything; it just formats.
	n contentLength,dev,host,HTTPVersion,io,port,rawURL,ssl,urllc
	n zg ; gpl
	;
	k rawResponse,html
	s HTTPVersion="1.0"
	s rawURL=url
	s ssl=0
	s port=80
	s urllc=$$zcvt^%zewdAPI(url,"l")
	i $e(urllc,1,7)="http://" d
	. s url=$e(url,8,$l(url))
	. s sslHost=$p(url,"/",1)
	. s sslPort=80
	e  i $e(urllc,1,8)="https://" d
	. s url=$e(url,9,$l(url))
	. s ssl=1
	. s sslHost=$g(sslHost)
	. i sslHost="" s sslHost="127.0.0.1"
	. s sslPort=$g(sslPort)
	. i sslPort="" s sslPort=89
	e  QUIT "Invalid URL"
	s host=$p(url,"/",1)
	i host[":" d
	. s port=$p(host,":",2)
	. s host=$p(host,":",1)
	s url="/"_$p(url,"/",2,5000)
	i $g(timeout)="" s timeout=20
	;
	;GPL s io=$io
	i $g(test)'=1 d
	. ;GPL s dev=$$openTCP(sslHost,sslPort,timeout)
	;GPL . u dev
	i ssl d
	. ;w "POST "_rawURL_" HTTP/"_HTTPVersion_$c(13,10)
	. s zg="POST "_rawURL_" HTTP/"_HTTPVersion_"^M"
	. d gw(zg)
	e  d
	. ;w "POST "_url_" HTTP/"_HTTPVersion_$c(13,10)
	. s zg="POST "_url_" HTTP/"_HTTPVersion_"^M"
	. d gw(zg)
	;w "Host: "_host
	s zg="Host: "_host
	d gw(zg)
	i port'=80 s zg=":"_port d gw(zg) ;w ":"_port
	s zg=$c(13,10) d gw(zg) ;w $c(13,10)
	s zg="Accept: */*"_$c(13,10) d gw(zg) ;w "Accept: */*"_"^M"
	;
	i $d(headerArray) d
	. n n
	. s n=""
	. f  s n=$o(headerArray(n)) q:n=""  d
	. . ;w headerArray(n)_$c(13,10)
	. . s zg=headerArray(n)_"^M"
	. . d gw(zg)
	;
	s mimeType=$g(mimeType)
	i mimeType="" s mimeType="application/x-www-form-urlencoded"
	s contentLength=0
	i $d(payload) d
	. n no
	. s no=""
	. f  s no=$O(payload(no)) q:no=""  D
	. . s contentLength=contentLength+$l(payload(no))
	. s contentLength=contentLength
	. s zg="Content-Type: "_mimeType ;w "Content-Type: ",mimeType
	. d gw(zg)
	. i $g(charset)'="" d  ;
	. . ;w "; charset=""",charset,""""
	. . s zg="; charset="""_charset_""""
	. . d gw(zg)
	. s zg="^M" d gw(zg) ;w $c(13,10)
	. ;w "Content-Length: ",contentLength,$c(13,10)
	. s zg="Content-Length: "_contentLength_"^M"
	. d gw(zg)
	;
	s zg="^M" d gw(zg) ;w $c(13,10)
	i $D(payload) d
	. n no
	. s no=""
	. f  s no=$O(payload(no)) q:no=""  d
	. . ;w payload(no)
	. . s zg=payload(no)
	. . d gw(zg)
	; 
	s zg="^M" d gw(zg) ;w $c(13,10)
	;w $c(13,10),!  gpl- what does a bang send out????????
	;
	; That's the request sent !
	;
	;g httpResponse
	;
	q ""
	;
gw(LINE)	; Private proc; Adds line to end of array
	;
	I '$D(ARY(1)) S ARY(1)=LINE
	E  D  ;
	. N CNT
	. S CNT=$O(ARY(""),-1)
	. S CNT=CNT+1
	. S ARY(CNT)=LINE
	Q
	;
