C0PWPS	  ; ERX/GPL - eRx CPRS RPCs ; 2/8/10 ; 5/8/12 5:24pm
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
	; These routines are substitutes for COVER^ORWPS and DETAIL^ORWPS to
	; display eRx and CCR/CCD medication lists accurately
	;
COVER(LST,DFN)	 ; retrieve meds for cover sheet
	K ^TMP("PS",$J)
	D OCL^PSOORRL(DFN,"","")  ;DBIA #2400
	N ILST,ITMP,X S ILST=0
	S ITMP="" F  S ITMP=$O(^TMP("PS",$J,ITMP)) Q:'ITMP  D
	. S X=^TMP("PS",$J,ITMP,0)
	. I '$L($P(X,U,2)) S X="??"  ; show something if drug empty
	. I $D(^TMP("PS",$J,ITMP,"CLINIC",0)) S LST($$NXT^ORWPS)=$P(X,U,1,2)_U_$P(X,U,8,9)_U_"C"
	. E  S LST($$NXT^ORWPS)=$P(X,U,1,2)_U_$P(X,U,8,9)
	K ^TMP("PS",$J)
	; BEGIN NEW PROCESSING (EVERYTHING ABOVE WAS COPIED FROM COVER^0RWPS
	N ZCUR
	D GET^C0PCUR(.ZCUR,DFN) ; GET THE DETAIL FOR THE SAME MEDS LIST
	N ZI S ZI=""
	F  S ZI=$O(LST(ZI)) Q:ZI=""  D  ;FOR EACH MED IN THE LIST
	. I $P(LST(ZI),U,2)["FREE TXT" D  ; IS AN ERX UNMAPPED DRUG
	. . N ZD
	. . S ZD=$P(ZCUR(ZI,"SIG",1,0),"|",1) ; REAL DRUG NAME SHOULD BE IN SIG
	. . ; SEPARATED BY "|"
	. . I ZD'="" S $P(LST(ZI),U,2)=ZD ; IF SO, USE THE REAL NAME
	; BEGIN VISTACOM MOD -
	; SAVE THE DUZ OFF TO THE VISTACOM TMP GLOBAL
	S ^TMP("ZEWD",$J,"DUZ")=DUZ ; TO BE PICKED UP AND DELETED LATER BY VISTACOM
	Q
COVER2(LST,DFN)	 ; retrieve meds for cover sheet ;
	; THIS VERSION WILL DISPLAY THE DRUG NAME FROM THE PHARMACY ORDERABLE
	; ITEMS FILE FOR ERX DRUGS. THIS ALLOWS THE DRUG TO APPEAR AS GENERIC(BRAND)
	; FOR CERTAIN DRUGS - GPL 10/5/10
	K ^TMP("PS",$J)
	D OCL^PSOORRL(DFN,"","")  ;DBIA #2400
	N ILST,ITMP,X S ILST=0
	S ITMP="" F  S ITMP=$O(^TMP("PS",$J,ITMP)) Q:'ITMP  D
	. S X=^TMP("PS",$J,ITMP,0)
	. I '$L($P(X,U,2)) S X="??"  ; show something if drug empty
	. I $D(^TMP("PS",$J,ITMP,"CLINIC",0)) S LST($$NXT^ORWPS)=$P(X,U,1,2)_U_$P(X,U,8,9)_U_"C"
	. E  S LST($$NXT^ORWPS)=$P(X,U,1,2)_U_$P(X,U,8,9)
	K ^TMP("PS",$J)
	; BEGIN NEW PROCESSING (EVERYTHING ABOVE WAS COPIED FROM COVER^0RWPS
	N ZCUR
	D GET^C0PCUR(.ZCUR,DFN) ; GET THE DETAIL FOR THE SAME MEDS LIST
	N ZI S ZI=""
	F  S ZI=$O(LST(ZI)) Q:ZI=""  D  ;FOR EACH MED IN THE LIST
	. I $P(LST(ZI),U,2)["FREE TXT" D  ; IS AN ERX UNMAPPED DRUG
	. . N ZD
	. . S ZD=$P(ZCUR(ZI,"SIG",1,0),"|",1) ; REAL DRUG NAME SHOULD BE IN SIG
	. . ; SEPARATED BY "|"
	. . I ZD'="" S $P(LST(ZI),U,2)=ZD ; IF SO, USE THE REAL NAME
	. E  I $P(LST(ZI),U,1)["N" D  ; THIS IS A NONVA DRUG
	. . N ZD,ZDIEN
	. . I $G(ZCUR(ZI,"COMMENTS",1))["E-Rx" D  ; IS AN ERX DRUG
	. . . S ZDIEN=$G(ZCUR(ZI,"DRUG")) ; IEN IN THE DRUG FILE
	. . . S ZD=$$GET1^DIQ(50,ZDIEN,2.1) ; THE PHARMACY ORDERABLE ITEM
	. . . I ZD'="" S $P(LST(ZI),U,2)=ZD ; USE THIS DRUG NAME
	; BEGIN VISTACOM MOD -
	; SAVE THE DUZ OFF TO THE VISTACOM TMP GLOBAL
	S ^TMP("ZEWD",$J,"DUZ")=DUZ ; TO BE PICKED UP AND DELETED LATER BY VISTACOM
	Q
COVER3(LST,DFN)	 ; retrieve meds for cover sheet ;
	; THIS VERSION WILL DISPLAY THE FIRST DATA BANK DRUG NAME WHERE AVAILABLE
	;  - GPL 10/6/10
	K ^TMP("PS",$J)
	D OCL^PSOORRL(DFN,"","")  ;DBIA #2400
	N ILST,ITMP,X S ILST=0
	S ITMP="" F  S ITMP=$O(^TMP("PS",$J,ITMP)) Q:'ITMP  D
	. S X=^TMP("PS",$J,ITMP,0)
	. I '$L($P(X,U,2)) S X="??"  ; show something if drug empty
	. I $D(^TMP("PS",$J,ITMP,"CLINIC",0)) S LST($$NXT^ORWPS)=$P(X,U,1,2)_U_$P(X,U,8,9)_U_"C"
	. E  S LST($$NXT^ORWPS)=$P(X,U,1,2)_U_$P(X,U,8,9)
	K ^TMP("PS",$J)
	; BEGIN NEW PROCESSING (EVERYTHING ABOVE WAS COPIED FROM COVER^0RWPS
	N ZCUR
	D GET^C0PCUR(.ZCUR,DFN) ; GET THE DETAIL FOR THE SAME MEDS LIST
	N ZI S ZI=""
	F  S ZI=$O(LST(ZI)) Q:ZI=""  D  ;FOR EACH MED IN THE LIST
	. I $P(LST(ZI),U,2)["FREE TXT" D  ; IS AN ERX UNMAPPED DRUG
	. . N ZD
	. . S ZD=$P(ZCUR(ZI,"SIG",1,0),"|",1) ; REAL DRUG NAME SHOULD BE IN SIG
	. . ; SEPARATED BY "|"
	. . I ZD'="" S $P(LST(ZI),U,2)=ZD ; IF SO, USE THE REAL NAME
	. E  I $P(LST(ZI),U,1)["N" D  ; THIS IS A NONVA DRUG
	. . N ZD,ZDSIG
	. . S ZDSIG=ZCUR(ZI,"SIG",1,0) ; THE SIG (CHECK THIS PLEASE)
	. . I ZDSIG["|" D  ; THERE ARE TWO PARTS TO THE SIG
	. . . S ZD=$P(ZDSIG,"|",1) ; FDB DRUG NAME SHOULD BE IN SIG
	. . . I ZD'="" S $P(LST(ZI),U,2)=ZD ; IF SO, USE THE FDB NAME
	; BEGIN VISTACOM MOD -
	; SAVE THE DUZ OFF TO THE VISTACOM TMP GLOBAL
	S ^TMP("ZEWD",$J,"DUZ")=DUZ ; TO BE PICKED UP AND DELETED LATER BY VISTACOM
	Q
DETAIL(ROOT,DFN,ID)	; -- show details for a med order
	K ^TMP("ORXPND",$J)
	N ZID
	S ZID=ID
	N LCNT,ORVP
	S LCNT=0,ORVP=DFN_";DPT("
	D MEDS^ORCXPND1
	S ROOT=$NA(^TMP("ORXPND",$J))
	I @ROOT@(11,0)="Order #0" D ERXDET
	Q
ERXDET	; BUILD ERX MED DETAIL
	N ZMEDS
	D GET^C0PCUR(.ZMEDS,DFN)
	N ZI,FOUND
	S FOUND=0 S ZI=""
	F  Q:FOUND'=0  S ZI=$O(ZMEDS(ZI)) Q:ZI=""  D  ; SEARCH FOR THE ID
	. I $P(ZMEDS(ZI,0),U,1)=ZID S FOUND=1 ; ID MATCHES THE MED
	I FOUND=0 Q  ; NO MATCH FOR THE MED
	K @ROOT ; CLEAR OUT THE NULL DETAIL
	;W !,"MED FOUND ",ZI," ",ZID
	N ZNAME,ZSIG,ZCOM,ZFDBN
	S ZNAME=$P(ZMEDS(ZI,0),U,2)
	S ZSIG=$G(ZMEDS(ZI,"SIG",1,0))
	M ZCOM=ZMEDS(ZI,"COMMENTS")
	I ZNAME["FREE TXT" D  ;
	. S ZNAME=$P(ZSIG,"|",1)
	. S ZSIG=$P(ZSIG,"| ",2)
	E  I ZSIG["|" D  ; NEED TO PULL OUT THE DRUG NAME FROM THE SIG
	. S ZFDBN=$P(ZSIG,"|",1)
	. S ZSIG=$P(ZSIG,"| ",2)
	N ZN S ZN=1
	S @ROOT@(ZN,0)=" Medication: "_ZNAME S ZN=ZN+1
	I $G(ZFDBN)'="" D  ; IF FIRST DATA BANK NAME IS KNOWN
	. S @ROOT@(ZN,0)="                                     " S ZN=ZN+1
	. S @ROOT@(ZN,0)="   FDB Name: "_ZFDBN S ZN=ZN+1
	. S @ROOT@(ZN,0)="                                     " S ZN=ZN+1
	E  S @ROOT@(ZN,0)="                                     " S ZN=ZN+1
	S @ROOT@(ZN,0)="        Sig: "_ZSIG S ZN=ZN+1
	S @ROOT@(ZN,0)=""  S ZN=ZN+1
	S @ROOT@(ZN,0)="     Status: "_$P(ZMEDS(ZI,0),U,9) S ZN=ZN+1
	S @ROOT@(ZN,0)="" S ZN=ZN+1
	S @ROOT@(ZN,0)="   Schedule: "_$G(ZMEDS(ZI,"SCH",1,0)) S ZN=ZN+1
	S @ROOT@(ZN,0)="                " S ZN=ZN+1
	S @ROOT@(ZN,0)=" Start Date: "_$$FMTE^XLFDT($G(ZMEDS(ZI,"START"))) S ZN=ZN+1
	S @ROOT@(ZN,0)="                " S ZN=ZN+1
	S @ROOT@(ZN,0)="    Source:  ePrescribing          " S ZN=ZN+1
	S @ROOT@(ZN,0)="                " S ZN=ZN+1
	N ZI S ZI=""
	F  S ZI=$O(ZCOM(ZI)) Q:ZI=""  D   ;
	. S @ROOT@(12+ZI,0)=ZCOM(ZI) ;COMMENT LINE
	Q
	;
