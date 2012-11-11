C0PSMEDS	  ; ERX/GPL - Utilities for eRx SendMeds; 3/1/11
	;;1.0;C0P;;Apr 25, 2012;Build 103
	;Copyright 2011 George Lilly.  Licensed under the terms of the GNU
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
ADD(RTNXML,G6)	; ADD SENDMEDS TO THE NCSCRIPT XML
	N GEND,ZG1,G5,GBLD
	M ZG1=@RTNXML
	S GEND=$O(ZG1(""),-1)-1
	D QUEUE^C0CXPATH("GBLD","ZG1",1,GEND) ; NCSCRIPT.. UP TO </NCScript>
	D QUEUE^C0CXPATH("GBLD",G6,1,$O(@G6@(""),-1)) ; ADD THE MEDS
	D QUEUE^C0CXPATH("GBLD","ZG1",GEND+1,GEND+1) ;END OF NCSCRIPT
	D BUILD^C0CXPATH("GBLD","G5") ; BUILD THE CONTENTS FROM THE BUILD LIST
	K @RTNXML
	M @RTNXML=G5 ;
	Q
	;
FREETXT(RXML,ZDUZ,ZDFN)	; ADD FREE TEXT MEDS FOR PATIENT ZDFN TO RXML, 
	; PASSED BY NAME; ZDUZ IS PASSED TO RESOLVE THE TEMPLATE
	N ZTID,ZMEDS,ZI,ZN,ZTMP,ZVARS,ZBLD,ZNM
	S ZTID=$$RESTID^C0PWS1(ZDUZ,"FREE TEXT MEDS") ;GET TEMPLATE ID
	D GET^C0PCUR(.ZMEDS,ZDFN) ; GET THE PATIENT'S CURRENT MEDS
	S ZN=$O(ZMEDS(""),-1) ; COUNT OF MEDS
	I +ZN=0 Q  ; NO MEDS, QUIT
	F ZI=1:1:ZN D  ; FOR EACH MED
	. N ZCMT
	. S ZCMT=$G(ZMEDS(ZI,"COMMENTS",1))
	. I ZCMT["E-Rx" Q  ; SKIP eRx MEDS
	. I ZCMT["Received by" Q  ; SKIP eRx Meds
	. I $P(ZMEDS(ZI,0),"^",9)'="ACTIVE" Q  ; ONLY WANT ACTIVE DRUGS
	. ; GET TYPE OF DRUG
	. N ZTYP
	. S ZTYP=$P($P(ZMEDS(ZI,0),"^",1),";",2) ; SHOULD BE AN I OR O
	. I ZTYP="I" Q  ; DON'T WANT INPATIENT MEDS
	. S ZNM=$NA(ZTMP(ZI)) ; PLACE TO PUT THIS MED XML
	. N ZDATE
	. S ZDATE=$G(ZMEDS(ZI,"START"))
	. I ZDATE'="" D  ; TRANSLATE FM DATE TO YYYYMMDD
	. . S ZDATE=$$FMDTOUTC^C0CUTIL(ZDATE,"D")
	. . S ZDATE=$TR(ZDATE,"-") ;REMOVE DASHES FROM DOB
	. I ZDATE="" S ZDATE=""
	. S ZVARS("date")=ZDATE
	. S ZVARS("dispenseNumber")=0
	. S ZVARS("doctorName")=$P($G(ZMEDS(ZI,"P",0)),"^",2)
	. S ZVARS("drug")=$P(ZMEDS(ZI,0),"^",2) ; NAME OF THE MED
	. N ZEXID
	. S ZEXID=$G(ZMEDS(ZI,"NVAIEN"))
	. I ZEXID="" S ZEXID="MED_"_$G(ZMEDS(ZI,"DRUG")) ; THE MED NUMBER
	. S ZVARS("externalId")=ZEXID
	. S ZVARS("prescriptionType")="reconcile"
	. S ZVARS("refillCount")=0
	. S ZVARS("sig")=$G(ZMEDS(ZI,"SIG",1,0))
	. S ZVARS("sig")=$TR(ZVARS("sig"),"'")
	. D MAP^C0PMAIN(ZNM,"ZVARS",ZTID) ; GENERATE XML FOR 1 MED
	. ;B
	. D QUEUE^C0CXPATH("ZBLD",ZNM,1,@ZNM@(0)) ; ADD TO BUILD LIST
	I +$D(ZBLD)=0 Q  ; NO NON-ERX MEDS
	D BUILD^C0CXPATH("ZBLD",RXML) ; BUILD ALL THE MEDS
	Q
	;
