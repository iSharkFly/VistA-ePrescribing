C0PLKUP	; VEN/SMH - Extrinsics to map med numbers ; 5/8/12 4:09pm
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
FDBFN()	Q 1130590010 ; First Databank Drugs file number
RXNFN()	Q 1130590011.001 ; RxNorm Concepts file number
FULLNAME(MEDID)	; $$ Public - Get FDB full name for the drug
	; Used in Bulletin
	; Input: MEDID By Value
	; Output: Extrinsic
	N C0PIEN S C0PIEN=$$FIND1^DIC($$FDBFN,"","QX",MEDID,"B")
	Q $$GET1^DIQ($$FDBFN,C0PIEN,"MED MEDID DESC")
GCN(MEDID)	; $$ Public - Get GCN given MEDID
	; Input: MEDID by Value
	; Output: Extrinsic
	; MEDID is the .01 field in the First Databank Drug file
	; GCN is the 1 field = Generic Code Number
	; WS supplies MEDID in return. Need Generic Code Number to map to RxNorm.
	N X,Y,DTOUT,DUOUT,DLAYGO,DIC
	S DIC=$$FDBFN
	S X=MEDID
	S DIC(0)="OXZ" ; One entry only, Exact match, return zero node
	D ^DIC
	I Y<0 Q "" ; Failed match
	Q $P(Y(0),U,2) ; GCN is 2nd piece of zero node
	;
RXNCUI(GCN)	; $$ Public - Get RxNorm CUI using GCN
	; Input: GCN by Value
	; Output: Extrinsic
	; Seach GCN index for an exact match
	; One match, quick lookup, Exact matching
	N C0PIEN S C0PIEN=$$FIND1^DIC($$RXNFN,"","QX",GCN,"GCN")
	Q $$GET1^DIQ($$RXNFN,C0PIEN,.01)
	;
VUID(RXNCUI)	; $$ Public - Get VUID(s) for given RXNCUI for Clinical Drug
	; Input: RXNCUI by Value
	; Output: Caret delimited extrinsic. Should not be more than 2 entries.
	; @;4 means return IEN and VUID.
	N C0POUT,C0PVUID
	I '$D(^DIC($$RXNFN,0,"GL")) Q ""  ; RXNORM UMLS NOT INSTALLED
	D FIND^DIC($$RXNFN,"","@;4","PXQ",RXNCUI,"","VUIDCD","","","C0POUT")
	; Example output:
	; SAM("DILIST",0)="2^*^0^"
	; SAM("DILIST",0,"MAP")="IEN^4"
	; SAM("DILIST",1,0)="112482^4010153"
	; SAM("DILIST",2,0)="112484^4016607"
	I +$G(C0POUT("DILIST",0))=0 Q ""  ; no matches
	N I S I=0
	F  S I=$O(C0POUT("DILIST",I)) Q:I=""  S C0PVUID=$G(C0PVUID)_$P(C0POUT("DILIST",I,0),U,2)_"^"
	S C0PVUID=$E(C0PVUID,1,$L(C0PVUID)-1) ; remove trailing ^
	Q C0PVUID
VUID2(MEDID)	; $$ Public - Get VUID(s) for given MEDID
	Q $$VUID($$RXNCUI($$GCN(MEDID)))
VAPROD(VUID)	; $$ Public - Get VA Product IEN from VUID
	; Input VUID by Value
	; Output: Extrinsic
	Q $$FIND1^DIC(50.68,"","QX",VUID,"AVUID")
DRUG(VAPROD)	; $$ Public - Get Drug(s) using VA Product IEN
	; Input: VA Product IEN By Value
	; OUtput: Caret delimited extrinsic
	N C0POUT,C0PDRUG
	;D FIND^DIC(50,"","@;4","PXQ",VAPROD,"","C0PVAPROD","","","C0POUT")
	;D FIND^DIC(50,"","@;4","PXQ",VAPROD,"","AC0P","","","C0POUT") ;GPL 7/10
	I +VAPROD=0 Q 0 ;
	I '$D(^PSDRUG("AC0P",VAPROD)) Q 0 ;W "AC0P cross reference error" Q 0 ;
	;S C0PDRUG=$O(^PSDRUG("AC0P",VAPROD,"")) ;GPL ABOVE FIND DOESN'T WORK
	N I S I=""
	S C0PDRUG=""
	F  S I=$O(^PSDRUG("AC0P",VAPROD,I)) Q:I=""  D  ;
	. S C0PDRUG=C0PDRUG_I_"^"
	S C0PDRUG=$E(C0PDRUG,1,$L(C0PDRUG)-1) ; remove trailing ^
	Q C0PDRUG
	; Example output:
	; C0POUT("DILIST",0)="2^*^0^"
	; C0POUT("DILIST",0,"MAP")="IEN^4"
	; C0POUT("DILIST",1,0)="1512^"
	; C0POUT("DILIST",2,0)="21632^"
	; or
	; C0POUT("DILIST",0)="0^*^0^"
	; C0POUT("DILIST",0,"MAP")="IEN^4"
	I +$G(C0POUT("DILIST",0))=0 Q ""  ; no matches
	N I S I=0
	F  S I=$O(C0POUT("DILIST",I)) Q:I=""  S C0PDRUG=$G(C0PDRUG)_$P(C0POUT("DILIST",I,0),U)_"^"
	S C0PDRUG=$E(C0PDRUG,1,$L(C0PDRUG)-1) ; remove trailing ^
	Q C0PDRUG
DRUG2(MEDID)	; $$ Public - Get Drugs for a FDB MEDID
	; Input: MEDID by Value
	; Output: Caret delimited extrinsic
	N OUT S OUT=""
	N C0PDRUGS  ; tmp holding space for drugs
	N C0PVUIDS S C0PVUIDS=$$VUID2(MEDID)
	N C0PI
	F C0PI=1:1:$L(C0PVUIDS,U) D  ; for each VUID
	. N C0PVUID S C0PVUID=$P(C0PVUIDS,U,C0PI)
	. N C0PVAPROD S C0PVAPROD=$$VAPROD(C0PVUID) ; get VA Product
	. S C0PDRUGS=$$DRUG(C0PVAPROD)
	. S:$L(C0PDRUGS) OUT=OUT_C0PDRUGS_"^"
	S OUT=$E(OUT,1,$L(OUT)-1) ; rm trailing ^
	Q OUT
RXNCUI2(BASE)	; $$ Public - Get RxNorm CUI for FDB Ingredient/Base
	; Input: BASE By Value
	; Output: RxNorm CUI
	N C0PIEN S C0PIEN=$$FIND1^DIC($$RXNFN,"","QX",BASE,"NDDFBASE")
	Q $$GET1^DIQ($$RXNFN,C0PIEN,.01)
VUIDIN(RXNCUI)	; $$ Public - Get VUID Ingredient for RxNorm CUI
	; Input: RXNCUI By Value
	; Output: VUID
	N C0PIEN S C0PIEN=$$FIND1^DIC($$RXNFN,"","QX",RXNCUI,"VUIDIN")
	Q $$GET1^DIQ($$RXNFN,C0PIEN,"CODE")
VAGEN(VUID)	; $$ Public - Get VA Generic for VUID Ingredient
	; Input: VUID By Value
	; Output: IEN^VA Generic Name (i.e. .01 field value)
	N C0PIEN S C0PIEN=$$FIND1^DIC(50.6,"","QX",VUID,"AVUID")
	N C0P01 S C0P01=$$GET1^DIQ(50.6,C0PIEN,.01)
	Q C0PIEN_"^"_C0P01
VAGEN2(BASE)	; $$ Public - Get VA Generic for FDB Ingredient/Base
	; Input: BASE By Value
	; Output: IEN^VA Generic Name (i.e. .01 field value)
	Q $$VAGEN($$VUIDIN($$RXNCUI2(BASE)))
DRUGING(VUID)	; $$ Public - Get Drug Ingredient for VUID Ingredient
	; Input: VUID By Value
	; Output: IEN^Drug Ingredient Name (i.e. .01 field value)
	N C0PIEN S C0PIEN=$$FIND1^DIC(50.416,"","QX",VUID,"AVUID")
	N C0P01 S C0P01=$$GET1^DIQ(50.416,C0PIEN,.01)
	Q C0PIEN_"^"_C0P01
DRUGING2(BASE)	; $$ Public - Get Drug Ingredient for FDB Ingredient/Base
	; Input: BASE By Value
	; Output: IEN^Drug Ingredient Name (i.e. .01 field value)
	Q $$DRUGING($$VUIDIN($$RXNCUI2(BASE)))
RXNCUI3(VUID)	; $$ Public - Get RXNCUI for VUID (any VUID)
	; Input: VUID By Value
	; Output: RXNCUI
	I $G(VUID)="" Q ""
	N C0PIEN ; S C0PIEN=$$FIND1^DIC($$RXNFN,"","QX",VUID,"VUID")
	S C0PIEN=$O(^C0P("RXN","VUID",VUID,"")) ;GPL FIX FOR MULTIPLES
	Q $$GET1^DIQ($$RXNFN,C0PIEN,.01)
NDDFBASE(RXNCUI)	; $$ Public - Get NDDF Ingredient for RXNCUI
	; Input: RXNCUI By Value
	; Output: NDDF Base code
	N C0PIEN S C0PIEN=$$FIND1^DIC($$RXNFN,"","QX",RXNCUI,"RNDDFBASE")
	Q +$$GET1^DIQ($$RXNFN,C0PIEN,"CODE") ; strip leading zeros
NDDFBAS2(VUID)	; $$ Public - Get NDDF Ingredient for VUID
	; NB: WILL ONLY WORK IF VUID IS AN INGREDIENT VUID, NOT A CLINICAL DRUG
	; Input: VUID By Value
	; Output: NDDF Base code
	Q $$NDDFBASE($$RXNCUI3(VUID))
	;
DRUGNAM(CURRENTMEDS,ZMED)	; EXTRINSIC WHICH RETURNS THE FULL NAME
	; OF THE DRUG FROM CURRENTMEDS, PASSED BY REFERENCE
	; ZMED IS THE NUMBER OF THE MED IN THE ARRAY
	; IF THERE IS A DRUGID, IT IS USED TO LOOKUP THE NAME
	; IF THERE IS NO DRUGID, IT IS A FREETEXT MED AND THE NAME IS
	; PULLED FROM THE SIG, WHERE IS IT STORED WITH A "|" DELIMITER
	N ZD
	I $D(CURRENTMEDS(ZMED,"DRUG")) S ZD=$$FULLNAME(CURRENTMEDS(ZMED,"DRUG"))
	E  D  ; pull the name from the first piece of the sig
	. N ZDSIG
	. S ZDSIG=$G(CURRENTMEDS(ZMED,"SIG",1,0))
	.  S ZD=$P(ZDSIG,"|",1)
	Q ZD
	;
CODES(MEDID)	; EXTRINSIC WHICH RETURNS A LINE OF CODES FOR THE MED
	; FORMAT IS MEDID:XXX GCN:XXX RXNORM:XXX VUID:XXX DRUG:XXX
	N ZL
	S ZL="MEDID:"_MEDID_" "
	N ZG S ZG=$$GCN(MEDID) ; GCN (GENERIC CONCEPT NUMBER)
	S ZL=ZL_"GCN:"_ZG_" "
	N ZR S ZR=$$RXNCUI(ZG) ; RXNORM CONCEPT ID
	S ZL=ZL_"RXNORM:"_ZR_" "
	N ZV S ZV=$$VUID(ZR) ; VUID (VA UNIVERSAL ID)
	S ZL=ZL_"VUID:"_ZV_" "
	N ZD S ZD=$$DRUG2(MEDID) ; VISTA DRUG FILE IEN
	I ZD=0 S ZD=""
	S ZL=ZL_"DRUG:"_ZD_" "
	Q ZL
	;
