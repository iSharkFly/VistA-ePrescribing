C0PCUR	; VEN/SMH - Get current medications ; 5/8/12 9:24pm
	;;1.0;C0P;;Apr 25, 2012;Build 103
	;
	;Copyright 2009 Sam Habiel.  Licensed under the terms of the GNU
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
GET(C0PMEDS,C0PDFN)	; Private Proc - Get Current C0PMEDS
	; Input: 
	; C0PMEDS by reference
	; C0PDFN by Value
	; Output: (modified PSOORRL output)
	; C0PMEDS(D0,0): Order#_File;Pkg^Drug Name^Infusion Rate^Stop Date ^Refills Remaining^Total Dose^Units per Dose^Placer#^Status^Last Filldate^Days Supply^Qty^NOT TO BE GIVEN^Pending Renewal (1 or 0)
	; C0PMEDS(D0,"DRUG"): Drug IEN
	; C0PMEDS(D0,"A",0)      = # of lines
	; C0PMEDS(D0,"A",D1,0)   = Additive Name^Amount^Bottle
	; C0PMEDS(D0,"ADM",0)    = # of lines
	; C0PMEDS(D0,"ADM",D1,0) = Administration Times
	; C0PMEDS(D0,"B",0)      = # of lines
	; C0PMEDS(D0,"B",D1,0)   = Solution Name^Amount
	; C0PMEDS(D0,"MDR",0)    = # of lines
	; C0PMEDS(D0,"MDR",D1,0) = Medication Route abbreviation
	; C0PMEDS(D0,"P",0)      = IEN^Name of Ordering Provider (#200)
	; C0PMEDS(D0,"SCH",0)    = # of lines
	; C0PMEDS(D0,"SCH",D1,0) = Schedule Name
	; C0PMEDS(D0,"SIG",0)    = # of lines
	; C0PMEDS(D0,"SIG",D1,0) = Sig (outpatient) or Instructions (inpatient)
	; C0PMEDS(D0,"SIO",0)    = # of lines
	; C0PMEDS(D0,"SIO",D1,0) = Special Instructions/Other Print Info
	; C0PMEDS(D0,"START"): Start Date (timson)
	; added by gpl
	; C0PMEDS(D0,"NVAIEN")   = IEN of the drug in the NVA subfile
	; C0PMEDS(D0,"COMMENTS") = First line of the comment WP field in NVA
	K ^TMP("PS",$J)
	N BEG,END,CTX
	S (BEG,END,CTX)=""
	S CTX=$$GET^XPAR("ALL","ORCH CONTEXT C0PMEDS") ; PSOORRL defaults to 120d
	I CTX=";" D DEL^XPAR("USR.`"_DUZ,"ORCH CONTEXT C0PMEDS")
	S CTX=$$GET^XPAR("ALL","ORCH CONTEXT C0PMEDS")
	S BEG=$$DT($P(CTX,";")),END=$$DT($P(CTX,";",2))
	D OCL^PSOORRL(C0PDFN,BEG,END)  ;DBIA #2400
	M C0PMEDS=^TMP("PS",$J)
	N C0PI S C0PI="" ; THIS IS THE RETURNED LIST OF MEDS
	N ZI S ZI=0 ; THIS WILL BE THE MATCHING IEN IN THE NVA MULTIPLE
	F  S C0PI=$O(C0PMEDS(C0PI)) Q:C0PI=""  D
	. K ^TMP("PS",$J) ; again
	. N LSIEN S LSIEN=$P(C0PMEDS(C0PI,0),U,1) ; LIST IEN xN;O OR xR;O gpl
	. D OEL^PSOORRL(C0PDFN,LSIEN)
	. S C0PMEDS(C0PI,"START")=$P(^TMP("PS",$J,0),U,5) ; Start Date in fm
	. S:+$G(^TMP("PS",$J,"DD",1,0)) C0PMEDS(C0PI,"DRUG")=+^(0) ; Drug IEN
	. ;I '$D(GPLTEST) Q  ; let me test and others still work
	. ; now go look for the NVAIEN in the subfile - gpl
	. ;W !,"LSIEN "_LSIEN_"C0PI "_C0PI
	. I $P(LSIEN,";",1)["N" D  ; only for NVA drugs
	. . ;N ZI S ZI=0 
	. . N FOUND S FOUND=0
	. . ;F  Q:FOUND=1  S ZI=$O(^PS(55,C0PDFN,"NVA",ZI)) Q:+ZI=0  D  ;EACH NVA
	. . S ZI=$O(^PS(55,C0PDFN,"NVA",ZI)) D  ; NEXT NVA IEN (MAKE SURE IT MATCHES)
	. . . N ZN S ZN=$NA(^PS(55,C0PDFN,"NVA",ZI))
	. . . I '$D(@ZN@(0)) Q  ; BAD NVA NODE
	. . . I $P(@ZN@(0),U,2)=$G(C0PMEDS(C0PI,"DRUG")) S FOUND=1 ;DRUG NUMBERS MATCH
	. . . E  D  ; CHECK FOR FREE TEXT DRUG MATCH
	. . . . N Z1 S Z1=$P($P(@ZN@(0),U,3),"|",1) ; free txt drug from NVA
	. . . . N Z2 S Z2=$P(C0PMEDS(C0PI,"SIG",1,0),"|",1) ; free txt from list
	. . . . I Z1=Z2 S FOUND=1
	. . . I FOUND=1 D  ; found the NVA subfile entry
	. . . . S C0PMEDS(C0PI,"NVAIEN")=ZI ; NVA ien
	. . . . ;S C0PMEDS(C0PI,"COMMENTS")=$G(@ZN@(1,1,0)) ; first line of comments
	. . . . N ZC ; to store the comment wp field
	. . . . N ZM S ZM=$$GET1^DIQ(55.05,ZI_","_C0PDFN,14,,"ZC")
	. . . . M C0PMEDS(C0PI,"COMMENTS")=ZC ; the comments
	. . . . ;N ZC S ZC=0
	. . . . ;F  S ZC=$G(@ZN@(1,ZC)) Q:+ZC=0  D  ; pull out the comments
	. . . . ;. S C0PMEDS(C0PI,"COMMENTS",ZC)=$G(@ZN@(1,ZC,0)) ;line of comment
	. . . . ;M C0PMEDS(C0PI,"COMMENTS")=@ZN@(1) ; all the lines of comments
	. . . E  D  ; ERROR .. THESE SHOULD MATCH. There is a bug.
	. . . . D ERROR^C0PMAIN(",U113059007,",$ST($ST,"PLACE"),"ERX-NVA","Non-VA Meds Error") QUIT
	QUIT
DT(X)	; -- Returns FM date for X
	N Y,%DT S %DT="T",Y="" D:X'="" ^%DT
	Q Y
	;
MEDLIST(ZMLIST,ZDFN,ZPARMS,NOERX,SUMMARY)	; RETURNS THE MEDLIST FOR PATIENT DFN
	; USES C0C PACKAGE ROUTINES TO PULL ALL MEDS FOR THE PATIENT
	; IF NOERX=1 IT WILL FILTER OUT EPRESCRIBING MEDS FROM THE LIST
	; SUMMARY IS PASSED BY NAME AND IS THE PLACE TO PUT A SUMMARY IF PROVIDED
	N ZCCRT,ZCCRR
	D INITXPF^C0PWS1("C0PF") ; SET FILE NUMBER AND PARAMATERS 
	D GETTEMP^C0CMXP("ZCCRT","CCRMEDS","C0PF")
	K ^TMP("C0CRIM","VARS",ZDFN) ; KILL RIM VARIABLES TO MAKE SURE THEY ARE FRESH
	I '$D(ZPARMS) S ZPARMS="MEDALL"
	D SET^C0CPARMS(ZPARMS) ; SET PARAMATER TO PULL ALL MEDS
	I '$D(DEBUG) S DEBUG=0
	D EXTRACT^C0CMED("ZCCRT",ZDFN,"ZCCRR")
	M @ZMLIST=^TMP("C0CRIM","VARS",ZDFN,"MEDS")
	I $G(SUMMARY)="" Q  ; NO SUMMARY NEEDED
	S ZI=""
	F  S ZI=$O(@ZMLIST@(ZI)) Q:ZI=""  D  ;
	. S @SUMMARY@(ZI,"MED")=$G(@ZMLIST@(ZI,"MEDPRODUCTNAMETEXT"))
	. ;W @SUMMARY@(ZI,"MED")
	. S @SUMMARY@(ZI,"STATUS")=$G(@ZMLIST@(ZI,"MEDSTATUSTEXT"))
	. S @SUMMARY@(ZI,"CODESYSTEM")=$G(@ZMLIST@(ZI,"MEDPRODUCTNAMECODINGINGSYSTEM"))
	. S @SUMMARY@(ZI,"CODE")=$G(@ZMLIST@(ZI,"MEDPRODUCTNAMECODEVALUE"))
	. S @SUMMARY@(ZI,"COMMENT")=$G(@ZMLIST@(ZI,"MEDFULLFILLMENTINSTRUCTIONS"))
	Q
	;
ANALYZE(ZSTR,ZNUM)	; ANALYZE MED LISTS FOR ZNUM PATIENTS STARTING AT
	; PATIENT ZSTR. IF ZSTR="" START WHERE WE LEFT OFF
	; FIRST TIME, START WITH THE FIRST PATIENT
	N C0PZI
	I ZSTR="" D  ; WANT TO START WHERE WE LEFT OFF OR AT THE FIRST PATIENT
	. S C0PZI=$G(^TMP("C0PAMED","LAST"))
	. I C0PZI="" S C0PZI=0
	. S C0PZI=$O(^DPT(C0PZI)) ; FIRST PATIENT TO DO
	E  S C0PZI=ZSTR ; STARTING PATIENT IS SPECIFIED
	N SUMM
	N ZN S ZN=0
	N DONE S DONE=0
	F ZN=1:1:ZNUM Q:DONE  D  ; TRY AND DO ZNUM PATIENTS
	. W !,"C0PZI=",C0PZI
	. I +C0PZI=0 S DONE=1 Q  ; OUT OF PATIENTS
	. S SUMM=$NA(^TMP("C0PAMED",C0PZI)) ; PLACE TO PUT SUMMARY
	. W "SUMM ",SUMM
	. K G ; MED LIST RETURN VARIABLE
	. D MEDLIST("G",C0PZI,"MEDACTIVE",,SUMM) ; PULL THE MEDS FOR THIS PATIENT
	. S ^TMP("C0PAMED","LAST")=C0PZI ; SAVE WHERE WE ARE
	. S C0PZI=$O(^DPT(C0PZI)) ; NEXT PATIENT
	Q
	;
RESET	; CLEAR OUT THE ANALYZE ARRAY
	K ^TMP("C0PAMED")
	Q
	;
INDEX	; INDEX THE ANALYSES
	N ZI,ZJ
	S (ZI,ZJ)=""
	F  S ZI=$O(^TMP("C0PAMED",ZI)) Q:ZI=""  D  ;
	. S ZJ=""
	. F  S ZJ=$O(^TMP("C0PAMED",ZI,ZJ)) Q:ZJ=""  D  ;
	. . N ZMED
	. . S ZMED=$G(^TMP("C0PAMED",ZI,ZJ,"MED"))
	. . I ZMED'="" S ^TMP("C0PAMED","MED",ZMED,ZI)=""
	. . N ZCODE
	. . S ZCODE=$G(^TMP("C0PAMED",ZI,ZJ,"CODE"))
	. . I ZCODE'="" S ^TMP("C0PAMED","CODE",ZCODE,ZI)=""
	D COUNT
	Q
	;
COUNT	; COUNT THE MEDS AND THE CODES
	N ZI,ZN S ZN=0
	S ZI=""
	F  S ZI=$O(^TMP("C0PAMED","MED",ZI)) Q:ZI=""  D  ;
	. S ZN=ZN+1
	W !,"MED COUNT: ",ZN
	S ZN=0
	S ZI=""
	F  S ZI=$O(^TMP("C0PAMED","CODE",ZI)) Q:ZI=""  D  ;
	. S ZN=ZN+1
	W !,"CODE COUNT: ",ZN
	Q
	;
	; NB: EP below not used in C0P 1.0 --smh 5/9/2012
OUTSIDE(ZRTN,ZMEDS)	; WRAP THE MEDS IN THE OUTSIDEPRESRIPTION XML
	; Here's what the xml looks like. It's stored in the Template field
	; of the OUTSIDEPRESCRIPTION record in file C0P XML TEMPLATE file
	;<OutsidePrescription>
	; <externalId>@@PRESCRIPTIONID@@</externalId>
	; <date>@@MEDDATE@@</date>
	; <doctorName>@@DOCTORNAME@@</doctorName>
	; <drug>@@MEDTEXT@@</drug>
	; <dispenseNumber>@@DISPENSENUMBER@@</dispenseNumber>
	; <sig>@@SIG@@</sig>
	; <refillCount>@@REFILLCOUNT@@</refillCount>
	; <prescriptionType>@@PRESCRIPTIONTYPE@@</prescriptionType>
	;</OutsidePrescription>
	N C0PZI,ZTEMP,C0PF
	S C0PZI=""
	D INITXPF^C0PWS1("C0PF") ; SET UP FILE POINTERS
	D GETTEMP^C0CMXP("ZTEMP","OUTSIDEPRESCRIPTION","C0PF")
	; BREAK
	Q
