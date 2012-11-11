C0PRECON	; VEN/SMH - Utilities for Medication Reconciliation; 5/8/12 4:34pm
	;;1.0;C0P;;Apr 25, 2012;Build 103
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
	Q
	;
GETMEDS(C0PDUZ,C0PDFN,ZRTN)	; Public Proc
	; Retreives meds from WebService, matches them against VistA, 
	; compares them with current meds, saves into Non-Va multiple in file 55
	; (pharmacy patient)
	;   
	; Input:
	; - C0PDUZ: DUZ
	; - C0PDFN: DFN
	; 
	I $G(^TMP("C0PNOPULLBACK")) Q  ; TURNS OFF PULLBACK PROCESSING
	; FOR TESTING NEW CROP OPTIONS - KEEPS VISTA ERX DRUGS INTACT AND ADDS NO
	; NEW DRUGS
	N C0PWSMEDS
	D SOAP^C0PWS1("C0PWSMEDS","GETMEDS",C0PDUZ,C0PDFN) ; soap call for WS meds
	I C0PWSMEDS(1,"Status")'="OK" Q  ; bad return from ws call 
	N CURRENTMEDS
	D GET^C0PCUR(.CURRENTMEDS,C0PDFN) ; current meds in VistA
	N ZDUPS ; ARRAY TO KEEP TRACK OF DUPLICATES SO THAT WE CAN
	; DISCONTINUE ERX MEDS THAT ARE NOT IN THE WEB SERVICE LIST
	N I
	FOR I=1:1:C0PWSMEDS(1,"RowCount") DO
	. N MEDTOADD M MEDTOADD=C0PWSMEDS(I)
	. N DUPID S DUPID=$$DUP(MEDTOADD("DrugID"),.CURRENTMEDS) ; check for dups
	. N MEDTXT S MEDTXT=$$FULLNAME^C0PLKUP(MEDTOADD("DrugID"))
	. I 'DUPID S DUPID=$$FREMAT(MEDTXT,.CURRENTMEDS) ;check
	. ; for free text drug match gpl
	. I DUPID S ZDUPS(DUPID,I)="" ; INDEX BY CURRENT MED NUMBER
	. I DUPID D  ; if indeed duplicate, check if WS Drug is newer drug
	. . N RXDATENOTIME
	. . S RXDATENOTIME=$P($$FMDATE(MEDTOADD("PrescriptionDate")),".")
	. . I RXDATENOTIME>CURRENTMEDS(DUPID,"START") D  ; if newer
	. . . ;D DC^C0PNVA(C0PDFN,$P(CURRENTMEDS(DUPID,0),U)) ;dc old one
	. . . D DC^C0PNVA(C0PDFN,CURRENTMEDS(DUPID,"NVAIEN")) ; gpl
	. . . D ADD(.MEDTOADD,C0PDFN,C0PDUZ) ; add new one
	. . E  ; do nothing here: Current med in Vista is newer or equivalent one
	. E  D ADD(.MEDTOADD,C0PDFN,C0PDUZ) ; not a duplicate med
	; NOW LOOK THROUGH CURRENT MEDS TO SEE WHICH NEED TO BE DISCONTINUED
	S I=""
	F  S I=$O(CURRENTMEDS(I)) Q:I=""  D  ; FOR EACH CURRENT MED
	. I $O(ZDUPS(I,""))="" D  ; DUPLICATE DRUG NOT FOUND
	. . I $P(CURRENTMEDS(I,0),U,9)'="ACTIVE" Q  ; might be discontinued
	. . S ZT=$$DRUGNAM^C0PLKUP(.CURRENTMEDS,I)
	. . I ZT="" S ZT=$P(CURRENTMEDS(I,0),U,2)
	. . N ZN S ZN=$P($G(CURRENTMEDS(I,0)),U,1)
	. . S ZT=ZN_" "_ZT
	. . ;S ZT=$P(CURRENTMEDS(I,0),U,1)_" "_$P(CURRENTMEDS(I,0),U,2)
	. . I ZN["N;" D  ; DISCONTINUE THE NONVA MED
	. . . I $G(CURRENTMEDS(I,"COMMENTS",1))["Received from E-Rx Web Service" D  ;
	. . . . D DC^C0PNVA(C0PDFN,CURRENTMEDS(I,"NVAIEN")) ;dc the med
	. . . . S ZT="Discontinued "_ZT
	. . E  S ZT="Can't Discontinue "_ZT
	. . D MAPERR(.ZRTN,"DRUGS",ZT)
	QUIT
ADD(MEDTOADD,C0PDFN,C0PDUZ)	; Private Proc - Add med to VistA
	; Input:
	; - MEDTOADD: WebService Drug information, by Reference
	; - C0PDFN: DFN, by Value
	; - C0PDUZ: DUZ, By Value
	; Output:
	; - None
	N DRUGS S DRUGS=$$DRUG2^C0PLKUP(MEDTOADD("DrugID"))
	N ZR,ZII ; GPL NEED TO FIND A NON-ZERO MATCH 
	F ZII=1:1:10 S ZR=$P(DRUGS,U,ZII) Q:ZR>0  ; $$DRUG2 RETURNS a^b^c FOR MATCHES
	S DRUGS=ZR ; WE WANT THE FIRST NON-ZERO MATCH
	I +DRUGS=0 DO  QUIT
	. D SENDMSG(.MEDTOADD,C0PDFN)
	. D NFADD(.MEDTOADD,C0PDFN,C0PDUZ)
	. N ZT
	. S ZT="Error Mapping Drug: "_MEDTOADD("DrugName")_" ID: "_MEDTOADD("DrugID")
	. D MAPERR(.ZRTN,"DRUGS",ZT) ; CALL ERROR ROUTINE TO RECORD NO MATCH FOR DRUG
	N DRUG S DRUG=+DRUGS ; grab the first entry; as good as any for now
	N ORDIEN S ORDIEN=$$GET1^DIQ(50,DRUG,"PHARMACY ORDERABLE ITEM","I")
	N DOSAGE S DOSAGE=MEDTOADD("DosageNumberDescription")_" "_MEDTOADD("DosageForm")
	; ****** ADDED BY GPL 10/5/10 TO ALWAYS CAPTURE FDB NAME IN SIG
	N MEDTXT S MEDTXT=$$FULLNAME^C0PLKUP(MEDTOADD("DrugID"))
	I MEDTXT="" S MEDTXT=MEDTOADD("DrugName") ; drug not found condition gpl
	S DOSAGE=MEDTXT_"| "_MEDTOADD("DosageNumberDescription")_"  "_MEDTOADD("DosageForm") ; | delimiter added by gpl 2/5/2010
	; ****** END MOD
	N ROUTE S ROUTE=MEDTOADD("Route")
	N SCHEDULE S SCHEDULE=MEDTOADD("DosageFrequencyDescription")
	I MEDTOADD("TakeAsNeeded")="Y" S SCHEDULE=SCHEDULE_" PRN" ; Vista stores PRN in schedule
	N START S START=$$FMDATE(MEDTOADD("PrescriptionDate"))
	N COMMENT
	S COMMENT(1)="Received from E-Rx Web Service" ;todo: move to dialog file
	S COMMENT(2)="Order Guid: "_$G(MEDTOADD("OrderGuid"))
	S COMMENT(3)="Physician Name: "_$G(MEDTOADD("PhysicianName"))
	S COMMENT(4)="Prescription Date: "_$G(MEDTOADD("PrescriptionDate"))
	S COMMENT(5)="Prescription Guid: "_$G(MEDTOADD("PrescriptionGuid"))
	S COMMENT(6)="Notes: "_$G(MEDTOADD("PrescriptionNotes"))
	; add codes for Certification and Free Txt repair processing - gpl
	S COMMENT(7)=$$CODES^C0PLKUP(MEDTOADD("DrugID")) ;
	D FILE^C0PNVA(C0PDFN,ORDIEN,DRUG,DOSAGE,ROUTE,SCHEDULE,START,C0PDUZ,.COMMENT)
	QUIT
MAPERR(ZRTN,ZTYP,ZTXT)	; ZTYP IS THE TYPE OF MAPPING ERROR 
	; (IE DRUGS OR ALLERGY)
	; ZRTN IS PASSED BY REFERENCE AND IS THE ARRAY OF ERROR MESSAGES
	; THIS ROUTINE ADDS THE ERROR MESSAGE TO THE END OF THE ARRAY
	; ZTXT IS THE ERROR MESSAGE
	; 
	N ZI
	I $G(^TMP("C0PDEBUG"))="" Q  ; ONLY SHOW MAPPING ERRORS ON DEBUG
	I '$D(ZRTN) S ZI=1
	E  S ZI=$O(ZRTN(""),-1)+1 ;ONE PASSED THE END OF ZRTN
	S ZRTN(ZI)=ZTXT
	Q
	;
FMDATE(C0PD)	; Public $$ - Get fileman date from dates formatted like 11/7/09 10:22:34 PM
	; Input: Date like 11/7/09 10:22:34 PM
	; Output: Timson date precise up to seconds
	S $E(C0PD,$F(C0PD," ")-1)="@" ; put @ b/n date and time for fm
	N %DT S %DT="TS" ; seconds are required
	N X,Y
	S X=C0PD D ^%DT
	I Y<0 D ^%ZTER ; Problem converting date... wake up programmer
	QUIT Y
	;
DUP(FDBDRUGID,CURRENTMEDS)	; Private $$ - Is Drug already documented for patient?
	; Input: 
	; FDBDRUGID By Value
	; CURRENTMEDS By Reference
	; Output:
	; "" if no duplicate
	; CURRENTMEDS ien if duplicate
	N DRUGS S DRUGS=$$DRUG2^C0PLKUP(FDBDRUGID)
	; add a check for the CODES in Comment(6) - to update if not there
	N C0PCODES S C0PCODES=$$CODES^C0PLKUP(FDBDRUGID)
	N I S I=""
	N FOUND S FOUND=0
	F  Q:FOUND=1  S I=$O(CURRENTMEDS(I)) Q:I=""   D  ; loop through current meds
	. I '$D(CURRENTMEDS(I,"DRUG")) QUIT  ; continue if no drug id
	. I $G(CURRENTMEDS(I,"COMMENTS",1))'["Received from E-Rx Web Service" Q  ;
	. ; DON'T MATCH ON DRUGS THAT ARE NOT ERX
	. ; check for CODES in COMMENTS(6)
	. I $G(CURRENTMEDS(I,"COMMENTS",6))'=C0PCODES D  ; add codes
	. . ;S ^PS(55,C0PDFN,"NVA",I,1,7,0)=C0PCODES ; right into the global
	. I $P(CURRENTMEDS(I,0),U,9)'["ACTIVE" QUIT  ; quit if not active
	. I ("^"_DRUGS_"^")[("^"_CURRENTMEDS(I,"DRUG")_"^") S FOUND=1
	QUIT I  ; entry if Found, "" if not found
	;
FREMAT(FDBDNAME,CURRENTMEDS,ZMED)	;MATCH A FREE TEXT DRUG EXTRINSIC
	; THE DRUG ID HAS BEEN STORED IN THE COMMENT OF EACH ERX NONVA DRUG
	; ZMED IS WHICH DRUG IN CURRENTMEDS WHICH IS PASSED BY REF
	; FDBDNAME IS THE DRUG NAME AND IS PASSED BY VALUE ; GPL
	N I S I=""
	; add a check for the CODES in Comment(6) - to update if not there
	N C0PCODES S C0PCODES=$$CODES^C0PLKUP(MEDTOADD("DrugID"))
	N FOUND S FOUND=0
	F  Q:FOUND=1  S I=$O(CURRENTMEDS(I)) Q:I=""   D  ; loop through current meds
	. I $D(CURRENTMEDS(I,"DRUG")) QUIT  ; SKIP OVER MAPPED DRUGS
	. I $P(CURRENTMEDS(I,0),U,9)'["ACTIVE" QUIT  ; quit if not active
	. I FDBDNAME=$$DRUGNAM^C0PLKUP(.CURRENTMEDS,I) S FOUND=1
	I FOUND=1 D  ;
	. S ZT="Drug Dup Found: "_MEDTOADD("DrugName")_" ID: "_MEDTOADD("DrugID")
	. ; check for CODES in COMMENTS(6)
	. I $G(CURRENTMEDS(I,"COMMENTS",6))'=C0PCODES D  ; add codes
	. . ;S ^PS(55,C0PDFN,"NVA",I,1,7,0)=C0PCODES ; right into the global
	. D MAPERR(.ZRTN,"DRUGS",ZT) ; CALL ERROR ROUTINE TO RECORD NO MATCH FOR DRUG
	Q I  ; entry if Found, "" if not found
	;
SENDMSG(MEDTOADD,C0PDFN)	; Private EP - Send Bulletin saying drug not found
	; Input:
	; - MEDTOADD: WS Med entry By Reference
	; - C0PDFN: DFN by Value
	; Output:
	; - None
	; info: tested 12/14/09
	; todo: move this to a background call - it takes too long!
	N DUZ ; remove old value to make the postmaster the sender
	N XMDUZ S XMDUZ="E-Rx WebService" ; supposed sender
	N XMTEXT ; unused
	N XMY ; unused
	N XMBTMP ; unused
	N XMDF ; unused
	N XMDT ; unused - will send message now
	N XMYBLOB ; unused
	N XMB
	S XMB="C0P EXTERNAL DRUG NOT FOUND" ; bulletin name
	S (XMB(1),XMB(5))=$$GET1^DIQ(2,C0PDFN,"PRIMARY LONG ID") ; chart #
	S (XMB(2),XMB(3))=$$FULLNAME^C0PLKUP(MEDTOADD("DrugID")) ; drug not matched
	S XMB(4)=$$GET1^DIQ(2,C0PDFN,.01) ; patient name
	D ^XMB
	QUIT
	;
NFADD(MEDTOADD,C0PDFN,C0PDUZ)	; Private Proc - Add free text med to VistA
	; Input:
	; - MEDTOADD: WebService Drug information, by Reference
	; - C0PDFN: DFN, by Value
	; - C0PDUZ: DUZ, By Value
	; Output:
	; - None
	; info: tested 12/16/09
	; Stores med along side dosage in dosage field as free text
	N ORDIEN S ORDIEN=$$FIND1^DIC(50.7,"","QX","FREE TXT DRUG","B") ; todo: change to a parameter
	N DOSAGE
	N MEDTXT S MEDTXT=$$FULLNAME^C0PLKUP(MEDTOADD("DrugID"))
	I MEDTXT="" S MEDTXT=MEDTOADD("DrugName") ; drug not found condition gpl
	S DOSAGE=MEDTXT_"| "_MEDTOADD("DosageNumberDescription")_"  "_MEDTOADD("DosageForm") ; | delimiter added by gpl 2/5/2010
	N ROUTE S ROUTE=MEDTOADD("Route")
	N SCHEDULE S SCHEDULE=MEDTOADD("DosageFrequencyDescription")
	I MEDTOADD("TakeAsNeeded")="Y" S SCHEDULE=SCHEDULE_" PRN" ;
	N START S START=$$FMDATE(MEDTOADD("PrescriptionDate"))
	N COMMENT
	S COMMENT(1)="Received from E-Rx Web Service" ;todo: move to dialog file
	S COMMENT(2)="Order Guid: "_$G(MEDTOADD("OrderGuid"))
	S COMMENT(3)="Physician Name: "_$G(MEDTOADD("PhysicianName"))
	S COMMENT(4)="Prescription Date: "_$G(MEDTOADD("PrescriptionDate"))
	S COMMENT(5)="Prescription Guid: "_$G(MEDTOADD("PrescriptionGuid"))
	S COMMENT(6)="Notes: "_$G(MEDTOADD("PrescriptionNotes"))
	; add codes for Certification and Free Txt repair processing - gpl
	S COMMENT(7)=$$CODES^C0PLKUP(MEDTOADD("DrugID")) ;
	D FILE^C0PNVA(C0PDFN,ORDIEN,"",DOSAGE,ROUTE,SCHEDULE,START,C0PDUZ,.COMMENT)
	;N COMMENT ;added DrugID to comment 1/27/2010 gpl
	;S COMMENT="Received from E-Rx Web Service (DrugID:"_MEDTOADD("DrugID")_")"
	;D FILE^C0PNVA(C0PDFN,ORDIEN,"",DOSAGE,ROUTE,SCHEDULE,START,C0PDUZ,COMMENT)
	QUIT
