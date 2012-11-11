C0PALGY1	  ; ERX/GPL/SMH - eRx Allergy utilities ; 5/8/12 11:52pm
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
GETRXNS(C0PDUZ,C0PDFN,ZRTN)	; Public Procedure
	; Retrieve allergies from WebService, and store in VistA
	; ART APIs will automatically not file an allergy if it is a duplicate
	; Also, marking pt as NKA won't work if pt already has allergy in VistA
	; That's why there is no check for duplicates in this code
	; Input:
	; - C0PDUZ: DUZ, By Value
	; - C0PDFN: DFN, By Value
	;
	N C0PWSRXNS
	D SOAP^C0PWS1("C0PWSRXNS","GETALLERGIES",C0PDUZ,C0PDFN)
	N C0PI
	F C0PI=1:1:C0PWSRXNS(1,"RowCount") DO
	. N RXN M RXN=C0PWSRXNS(C0PI)
	. ; For certain food allergies, CompositeID is not returned
	. I '$D(RXN("CompositeID")) S RXN("CompositeID")="" ; prevent undef crash
	. I RXN("CompositeID")=11623 QUIT  ; Code for 'No Allergy Information'
	. I (RXN("CompositeID")=231)!(RXN("CompositeID")=232)!(RXN("CompositeID")=14278)!(RXN("CompositeID")=14279) D  QUIT
	. . N ORDFN S ORDFN=C0PDFN  ; Apparently the 'API' uses CPRS variables
	. . D NKA^GMRAGUI1  ; Codes for NKA
	. D FILE(.RXN,C0PDUZ,C0PDFN)
	QUIT  ; /GETRXNS
	;
FILE(RXN,C0PDUZ,C0PDFN)	; Private Proc - File Drug Reaction
	; Input: 
	; - RXN: Merged WS ADR, by Reference
	; - C0PDUZ: DUZ, By Value
	; - C0PDFN: DFN, By Value
	; ConceptTypeIDs: 6 = Generic Name; 2 = Brand Name; 1 = Drug Class
	N C0PRXN
	S:RXN("ConceptTypeID")=6 C0PRXN("GMRAGNT")=$$BASE(RXN("ConceptID"))
	S:RXN("ConceptTypeID")=2 C0PRXN("GMRAGNT")=$$NAME($$UP^XLFSTR(RXN("Name")))
	S:RXN("ConceptTypeID")=1 C0PRXN("GMRAGNT")=$$GROUP(RXN("ConceptID"))
	; Try a free text match on 120.82 (GMRA ALLERGIES) to see if there is a
	; match on a food allergy (ConceptTypeID 9 [free txt] or 10 [other allergies])
	IF $G(C0PRXN("GMRAGNT"))="" D  ; need to handle type 9 or 10 .. gpl
	. S C0PRXN("GMRAGNT")=$$GMRA($$UP^XLFSTR(RXN("Name")))
	IF C0PRXN("GMRAGNT")="" DO  QUIT  ; Agent not found in VistA; TODO mail msg
	. N ZT ; TEXT TO DISPLAY AS ERROR MESSAGE
	. S ZT="Error Mapping Allergy ConceptID: "_$G(RXN("ConceptID"))
	. D MAPERR^C0PRECON(.ZRTN,"Allergy",ZT) ;DISPLAY ERROR
	S C0PRXN("GMRATYPE")=$$TYPE(C0PRXN("GMRAGNT"))
	S C0PRXN("GMRANATR")="U^Unknown"
	S C0PRXN("GMRAORIG")=C0PDUZ
	S C0PRXN("GMRACHT",0)=1
	S C0PRXN("GMRACHT",1)=$$NOW^XLFDT
	S C0PRXN("GMRAORDT")=$$NOW^XLFDT
	S C0PRXN("GMRAOBHX")="h^HISTORICAL"
	I $D(RXN("Notes")) D
	. S C0PRXN("GMRACMTS",0)=1
	. S C0PRXN("GMRACMTS",1)=RXN("Notes")
	D UPDATE^GMRAGUI1("",C0PDFN,"C0PRXN")
	I $G(^TMP("C0PDEBUG"))="" Q  ; ONLY SHOW ALLERGY MESSAGES IN DEBUG
	I $P(ORY,U,1)<0 D MAPERR^C0PRECON(.ZRTN,"Allergies",ORY) ;ERROR MESSAGE
	QUIT
	;
BASE(ID)	; $$ Private - Retrieve GMRAGNT for Generic Name ConceptID
	; Input: ID, By Value
	; Output: Ingreident Name^IEN;File Root for IEN
	; First, match drug to VistA, Look in VA GENERIC first
	N VAGEN S VAGEN=$$VAGEN2^C0PLKUP(ID)
	; if no match, look in DRUG INGREDIENT
	N DRUGING S DRUGING=""
	I '+VAGEN S DRUGING=$$DRUGING2^C0PLKUP(ID)
	Q:+VAGEN $P(VAGEN,U,2)_U_$P(VAGEN,U)_";PSNDF(50.6,"
	Q:+DRUGING $P(DRUGING,U,2)_U_$P(DRUGING,U)_";PS(50.416,"
	QUIT "" ; TODO: Notify somebody that no match found
	;
NAME(BRAND)	 ; $$ Private - Retrieve GMRAGNT for Brand Name
	; Input: Brand Name, By Value
	; Output: Ingreident Name^IEN;File Root for IEN
	N C0POUT,C0PMATCH  ; output variable, # of matches
	S C0PMATCH=$$TGTOG2^PSNAPIS(BRAND,.C0POUT)
	; Output for C0POUT:
	; C0POUT(24)="24^VANCOMYCIN"
	; 24 is IEN of drug in VA GENERIC file
	Q:C0PMATCH $P(@$Q(C0POUT),U,2)_U_$P(@$Q(C0POUT),U)_";PSNDF(50.6,"
	Q "" ; otherwise quit with nothing
	;
GROUP(ID)	; Private Proc - Store drug class allergy
	QUIT "" ; not implemented
GMRA(NAME)	; $$ Private - Retrieve GMRAGNT for food allergy from 120.82
	; Input: Brand Name, By Value
	; Output: Entry Name^IEN;File Root for IEN
	N C0PIEN S C0PIEN=$$FIND1^DIC(120.82,"","O",NAME,"B")
	Q:C0PIEN $$GET1^DIQ(120.82,C0PIEN,.01)_"^"_C0PIEN_";GMRD(120.82,"
	QUIT "" ; no match otherwise
TYPE(GMRAGNT)	; $$ Private - Get allergy Type (Drug, food, or other)
	; Input: Allergen, formatted as Allergen^IEN;File Root
	; Output: Type (internal)^Type (external) e.g. D^Drug
	N C0PIEN S C0PIEN=+$P(GMRAGNT,U,2)
	I GMRAGNT["GMRD(120.82," Q $$GET1^DIQ(120.82,C0PIEN,"ALLERGY TYPE","I")_U_$$GET1^DIQ(120.82,C0PIEN,"ALLERGY TYPE","E")
	Q "D^Drug" ; otherwise, it's a drug
ACCOUNTF()	 Q 113059002  ; file number for account file
F200C0P()	Q 200.113059 ; Subfile number of C0P Subscription Multiple
	;
