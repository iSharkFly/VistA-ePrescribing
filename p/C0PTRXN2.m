C0PTRXN   ; ERX/GPL - Med file eRx analysis routines ; 7/10/10
 ;;0.1;C0P;nopatch;noreleasedate;Build 77
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
 ; gpl 7/2010 - these routines are to test the Drug file mappings 
 ; to see how well they will work for eRx. None of this code is needed
 ; for operation of the eRx Package. It is for analysis, debugging and future
 ; development
 ;
FDBFN() Q 1130590010 ; First Databank Drugs file number
RXNFN() Q 1130590011.001 ; RxNorm Concepts file number
T1 ; TEST1
 N ZI
 S ZI=""
 F  S ZI=$O(^C0P("FDB","B",ZI)) Q:ZI=""  D  ;
 . N ZGCN,ZRXNCUI,ZNAME,ZVAIEN,ZDRUGIEN
 . S (ZGCN,ZRXNCUI,ZNAME,ZVAIEN,ZDRUGIEN)=""
 . S ZGCN=$$GCN^C0PLKUP(ZI)
 . S ZRXNCUI=$$RXNCUI^C0PLKUP(ZGCN)
 . I ZRXNCUI'="" S ZVUID=$$VUID^C0PLKUP(ZRXNCUI)
 . E  S ZRXNCUI="NONE"
 . S ZNAME=$$FULLNAME^C0PLKUP(ZI)
 . I ZVUID'="" S ZVAIEN=$$VAPROD^C0PLKUP(ZVUID)
 . I ZVAIEN'="" S ZDRUGIEN=$$DRUG^C0PLKUP(ZVAIEN)
 . E  S ZDRUGIEN="N/A"
 . W !,ZI," ",ZGCN," ",ZRXNCUI," ",ZVUID," ",ZVAIEN," ",ZDRUGIEN," ",ZNAME
 Q
 ; OK, T1 IS JUST SOME EXPLORITORY WORK. TIME TO GET ORGANIZED
 ;
TEST ;
 ;
 S GARY=$NA(^TMP("C0PRXN","TYPE2"))
 S GOUT=$NA(^TMP("C0POUT"))
 K @GOUT
 D RNF2CSV^C0CRNF(GOUT,GARY,"VN") ; TURN TYPE 2 INTO A CSV 
 D FILEOUT^C0CRNF(GOUT,"TYPE2_TEST.csv")
 Q
 ;
INDEX2 ; ADD AN INDEX TO TYPE2 DRUGS OF THE VUID
 ; FOR USE IN FINDING THE CURRENT VA->FDB MAPPING STATUS
 N ZI S ZI=""
 N ZBASE
 S ZBASE=$NA(^TMP("C0PRXN","TYPE2","V")) ; TYPE2 DRUGS ARE HERE
 S ZINDEX=$NA(^TMP("C0PRXN","TYPE2","INDEX")) ; PUT THE INDEX HERE
 F  S ZI=$O(@ZBASE@(ZI)) Q:ZI=""  D  ;
 . N ZVUIDS,ZVUID
 . S ZVUIDS=@ZBASE@(ZI,"VUID",1) ; LIST OF VUIDS ^ SEPARATED
 . N ZN S ZN=@ZBASE@(ZI,"VANAME",1)_"^"_@ZBASE@(ZI,"FDBNAME",1)
 . I ZVUIDS["^" D  ;
 . . N ZJ S ZJ=""
 . . F  S ZJ=$P(ZVUIDS,"^",1) Q:ZJ=""  D  ; FOR EACH VUID
 . . . S ZVUID(ZJ)=ZN ;SET INDEX TO NAME
 . . . S ZVUIDS=$P(ZVUIDS,"^",2) ; DROP THE FIRST IN THE LIST
 . E  S ZVUID(ZVUIDS)=ZN ;SET INDEX TO VA NAME
 . S ZJ=""
 . F  S ZJ=$O(ZVUID(ZJ)) Q:ZJ=""  D  ; FOR EACH VUID
 . . ;S @ZINDEX@(ZJ,ZI)=ZVUID(ZJ) ;SET THE INDEX
 . . W !,$NA(@ZINDEX@(ZJ,ZI))_"="_ZVUID(ZJ) ;SET THE INDEX
 Q
EN ; ENTRY POINT TO CREATE THE ERX DRUG ANALYSIS SPREADSHEETS
 ; SEE BELOW FOR DOCUMENTATION
 N GARY
 S GARY=$NA(^TMP("C0PRXN","ALL")) ; PLACE TO PUT THE ENTIRE ARRAY
 K @GARY
 D BLDARY(GARY) ; BUILD THE ENTIRE ARRAY
 D IDXARY(GARY) ; INDEX THE ARRAY BY TYPE AND DRUG NAME
 D TYPES
 Q
 ;
TYPES ; BUILD AN ARRAY FOR EACH TYPE
 I '$D(GARY) S GARY=$NA(^TMP("C0PRXN","ALL"))
 N C0PN,ZTYPE
 F C0PN=1:1:4 D  ; FOR EACH ANALYSIS TYPE
 . S ZTYPE=$NA(^TMP("C0PRXN","TYPE"_C0PN))
 . K @ZTYPE
 . D BLDTYPE(GARY,ZTYPE,C0PN) ; BUILD AN EXTRACTED ARRAY ACCORDING TO TYPE
 . S GOUT=$NA(^TMP("C0POUT"))
 . K @GOUT
 . D RNF2CSV^C0CRNF(GOUT,ZTYPE,"VN") ; TURN TYPE 2 INTO A CSV 
 . W !
 . D FILEOUT^C0CRNF(GOUT,"eRx_mapping__Type"_C0PN_".csv")
 Q
 ;
IDXARY(INARY) ; INDEX THE ARRAY BY TYPE AND NAME
 ;
 N ZI
 S ZI=""
 F  S ZI=$O(@INARY@("V",ZI)) Q:ZI=""  D  ; FOR EACH ELEMENT OF THE ARRAY
 . S @INARY@("INDEX",@INARY@("V",ZI,"TYPE"),@INARY@("V",ZI,"FDBNAME"),ZI)="" 
 D COUNT
 Q
 ;
COUNT ; COUNT AND REPORT HOW MANY ARE IN EACH TYPE
 I '$D(INARY) S INARY=$NA(^TMP("C0PRXN","ALL"))
 N ZN,ZI,ZJ,ZCOUNT
 S ZN=""
 F  S ZN=$O(@INARY@("INDEX",ZN)) Q:ZN=""  D  ; FOR EACH TYPE
 . S ZCOUNT=0
 . S ZI=""
 . F  S ZI=$O(@INARY@("INDEX",ZN,ZI)) Q:ZI=""  D  ; FOR EACH INDEX ENTRY
 . . S ZCOUNT=ZCOUNT+1
 . W !,"COUNT FOR TYPE "_ZN_" = "_ZCOUNT
 Q
 ;
BLDTYPE(INARY,OARY,ITYPE) ; EXTRACT A TYPE ARRAY
 ;
 N C0PI,C0PJ
 S C0PI=""
 F  S C0PI=$O(@INARY@("INDEX",ITYPE,C0PI)) Q:C0PI=""  D  ; FOR EACH OF TYPE
 . S C0PJ=$O(@INARY@("INDEX",ITYPE,C0PI,"")) ; SET RECORD NUMBER
 . N C0PROW
 . M C0PROW=@INARY@("V",C0PJ) ; CONTENTS OF ROW
 . D RNF1TO2B^C0CRNF(OARY,"C0PROW") ; USING THE "B" VERSION TO BE ABLE TO
 . ; TO CONVERT TO A CSV
 Q
 ;
BLDARY(ZARY) ; BUILDS AN RNF2 ARRAY; ZARY IS PASSED BY NAME 
 ; (SEE C0CRNF.m FOR DOCUMENTATION OF RNF2 FORMAT)
 ; 
 ; FIRST DATA BANK DRUGS ARE MATCHED TO VISTA DRUGS THROUGH A MULTI-STEP
 ; PROCESS. THE MEDID IS THE FIRST DATA BANK NUMBER USED TO REFER TO THEIR
 ; DRUGS. EACH MEDID HAS A GCN (GENERIC CODE NUMBER) WHICH CAN BE USED TO
 ; LOOK UP THE DRUG IN THE RXNORM UMLS DATABASE. THE GCN IS USED TO FIND
 ; THE RXNORM CONCEPT NUMBER (RXNCUI). THE RXNCUI IS USED TO FIND THE VUID
 ; USING THE RXNORM UMLS DATABASE. THE VUID IS USED TO FIND THE IEN OF THE
 ; DRUG IN THE VA PRODUCTS FILE (ALSO KNOWN AS THE NDF - NATIONAL DRUG FILE).
 ; THE VAPROD IEN IS THEN USED TO LOOK UP THE DRUG IN THE VA DRUG FILE
 ; (FILE 50) USING A NEW CROSS REFERENCE (AC0P) CREATED FOR THIS PURPOSE.
 ; THE RESULT OF THIS CHAIN IS A DRUG MAPPED FROM THE FDB MEDID TO A
 ; VA DRUG FILE IEN. TO SUMMARIZE:
 ; 
 ; MEDID->GCN->RXNCUI->VUID->VAPROD->DRUGIEN
 ;
 ; (NOTE: THIS PROCESS WILL CHANGE - BE IMPROVED - WHEN THE VERIFIED 
 ; MEDID->RXNORM MAPPING BECOMES AVAILABLE. THIS ANALYSIS WILL ESTABLISH
 ; A BASELINE WITH WHICH TO COMPARE THE RESULT OF USING THAT MAPPING)
 ;
 ; (THE PROCESS IS ACTUALLY MORE COMPLEX THAT THIS, BECAUSE WE ALSO TRY
 ; AND MATCH DRUGS BY LOOKING AT THEIR CHEMICAL COMPONENTS BUT THIS ANALYSIS
 ; IGNORES THIS MORE COMPLEX PROCESS.)
 ; 
 ; NOT ALL DRUGS MAKE IT ALL THE WAY THROUGH THIS MAPPING. IN ADDITION, THERE
 ; MAY BE DRUGS THAT ARE IN THE DRUG FILE THAT ARE NOT IN THE FDB FILE
 ; THIS ROUTINE WILL CREATE A SPREADSHEET THAT WILL SHOW THE UNMAPPED DRUGS
 ; IN BOTH DIRECTIONS (MEDID->...>DRUGIEN AND DRUGIEN->...>MEDID)
 ; IT WILL ALSO SHOW THE DRUG NAME AS IT APPEARS IN FIRST DATA BANK
 ; AND THE NAME THAT WILL BE USED FOR THAT DRUG IN VISTA (ERX). OFTEN
 ; THEY WILL BE DIFFERENT. IF THE FDB DRUG IS NOT A GENERIC, THE GENERIC NAME
 ; WILL BY USED BY ERX TO LIST THE DRUG IN THE PATIENT'S DRUG LIST IN VISTA
 ;
 ; WE ARE GOING TO ORGANIZE AN ARRAY WITH DRUGS BY TYPE. HERE ARE THE TYPES:
 ; 
 ; TYPE 1 - FDB DRUGS THAT MAP EXACTLY TO THE DRUG FILE, WITH NAMES THAT
 ;  MATCH EXACTLY
 ;
 ; TYPE 2 - FDB DRUGS THAT MAP TO THE DRUG FILE, BUT WITH DIFFERENT NAMES.
 ;  THIS CATEGORY INCLUDES DRUGS THAT ARE SHOWN IN VISTA AS GENERICS BUT
 ;  ON FDB AS BRAND NAME DRUGS
 ; 
 ; TYPE 3 - FDB DRUGS THAT DO NOT MAP TO THE DRUG FILE, BUT DO MAP TO THE
 ;  VA PRODUCT FILE (NDF). IF ANY OF THESE DRUGS MIGHT BE ORDERED VIA ERX,
 ;  IT MIGHT BE A GOOD IDEA TO ADD THEM TO THE DRUG FILE.
 ; NOTE: FOR TYPE 3 AND ABOVE DRUGS, ERX WILL STILL FUNCTION PROPERLY BUT
 ; INSTEAD OF MAPPING THE DRUG TO THE DRUG FILE, WILL MAP IT AS A FREE TEXT
 ; DRUG AND WILL SEND A MAIL MESSAGE ABOUT THE MAPPING ERROR SO THAT THE
 ; DRUG CAN BE CONSIDERED FOR ADDING TO THE DRUG FILE
 ; 
 ; TYPE 4 - FDB DRUGS THAT DO NOT MAP TO THE DRUG FILE AND ARE ALSO NOT
 ;  FOUND IN THE NDF. THIS MIGHT BE THE CASE FOR NEWER DRUGS. ERX WILL
 ;  STILL FUNCTION, BUT THESE WILL BE FREE TEXT DRUGS. THE REMEDY IS AN
 ;  UPDATE FROM THE VA OF THE NDF OR ADDING THE DRUGS TO THE NDF AND THE
 ;  DRUG FILE. (THERE ARE COMPLEXITIES IN ADDING DRUGS TO THE NDF BECAUSE
 ;  OF HOW TO THEN HANDLE AN UPDATE FROM THE VA)
 ;
 ; TYPE 5 - DRUGS IN THE DRUG FILE THAT ARE NOT FOUND IN THE FDB DRUG DATABASE
 ;  MAPPING. THIS MIGHT INCLUDE BRAND NAME DRUGS IN THE DRUG FILE THAT HAVE
 ;  BEEN MAPPED TO GENERICS WHEN COMING FROM FDB. IN ANY CASE, THESE ARE DRUGS
 ;  FOR WHICH THERE IS NO PATH TO MAP FROM THEM TO FDB. (REDUCING THE NUMBER
 ;  OF DRUGS IN THIS TYPE TO ZERO WILL BE A GOAL BEFORE IMPLEMENTING PHASE II
 ;  OF ERX WHERE DRUGS WILL BE ORDERED ON VISTA AND SENT TO THE ERX 
 ;  SERVICE.
 ;
 N ZI
 S ZI=""
 F  S ZI=$O(^C0P("FDB","B",ZI)) Q:ZI=""  D  ;
 . N ZGCN,ZRXNCUI,ZNAME,ZVAIEN,ZDRUGIEN,ZROW,ZIEN,ZVANAME
 . S (ZGCN,ZRXNCUI,ZNAME,ZVAIEN,ZDRUGIEN,ZVANAME)=""
 . S ZROW("MEDID")=ZI ; FDB MEDID
 . S ZIEN=$O(^C0P("FDB","B",ZI,"")) ; IEN OF THE FDB MED
 . S ZROW("FDBNAME")=$$FULLNAME^C0PLKUP(ZI) ; FDB MED NAME
 . S ZGCN=$$GCN^C0PLKUP(ZI)
 . I ZGCN=0 D  Q  ; NO GCN, CAN'T MAP 
 . . S ZROW("TYPE")=4
 . . D RNF1TO2^C0CRNF(ZARY,"ZROW")
 . S ZROW("GCN")=ZGCN
 . S ZRXNCUI=$$RXNCUI^C0PLKUP(ZGCN) ; RETRIEVE THE RXNORM CONCEPT ID
 . I ZRXNCUI="" W !,"ERROR, NO RXNCUI "_ZGCN B  ; SHOULDN'T HAPPEN
 . S ZROW("RXNCUI")=ZRXNCUI
 . S ZVUID=$$VUID^C0PLKUP(ZRXNCUI) ; FETCH THE VUID
 . I ZVUID="" D  Q  ; NO VUID FOUND
 . . S ZROW("TYPE")=4
 . . D RNF1TO2^C0CRNF(ZARY,"ZROW")
 . S ZROW("VUID")=ZVUID
 . I ZVUID["^" S ZVUID=$P(ZVUID,"^",1) ; USE THE FIRST ONE
 . S ZVAIEN=$$VAPROD^C0PLKUP(ZVUID) ; IEN IN VA PRODUCTS (NDF)
 . I ZVAIEN=0 D  Q  ; NOT FOUND IN NDF
 . . S ZROW("TYPE")=4
 . . D RNF1TO2^C0CRNF(ZARY,"ZROW")
 . S ZDRUGIEN=$$DRUG^C0PLKUP(ZVAIEN) ; IEN IN DRUG FILE
 . I ZDRUGIEN=0 D  Q  ;
 . . S ZROW("TYPE")=3
 . . S ZROW("VANDFNAME")=$$GET1^DIQ(50.68,ZVAIEN_",",.01) ;NDF NAME
 . . D RNF1TO2^C0CRNF(ZARY,"ZROW")
 . S ZVANAME=$$GET1^DIQ(50,ZDRUGIEN_",",.01) ; VA DRUG NAME
 . S ZROW("VANAME")=ZVANAME ; 
 . I ZVANAME=$$UP^XLFSTR(ZNAME) S ZROW("TYPE")=1
 . E  S ZROW("TYPE")=2
 . D RNF1TO2^C0CRNF(ZARY,"ZROW")
 . ;B
 Q
 ;
BLDFILE() ; BUILDS THE C0P RXNORM FDB VUID MAPPING FILE #113059010.002
 ; 
 ; FIRST DATA BANK DRUGS ARE MATCHED TO VISTA DRUGS THROUGH A MULTI-STEP
 ; PROCESS. THE MEDID IS THE FIRST DATA BANK NUMBER USED TO REFER TO THEIR
 ; DRUGS. EACH MEDID HAS A GCN (GENERIC CODE NUMBER) WHICH CAN BE USED TO
 ; LOOK UP THE DRUG IN THE RXNORM UMLS DATABASE. THE GCN IS USED TO FIND
 ; THE RXNORM CONCEPT NUMBER (RXNCUI). THE RXNCUI IS USED TO FIND THE VUID
 ; USING THE RXNORM UMLS DATABASE. THE VUID IS USED TO FIND THE IEN OF THE
 ; DRUG IN THE VA PRODUCTS FILE (ALSO KNOWN AS THE NDF - NATIONAL DRUG FILE).
 ; THE VAPROD IEN IS THEN USED TO LOOK UP THE DRUG IN THE VA DRUG FILE
 ; (FILE 50) USING A NEW CROSS REFERENCE (AC0P) CREATED FOR THIS PURPOSE.
 ; THE RESULT OF THIS CHAIN IS A DRUG MAPPED FROM THE FDB MEDID TO A
 ; VA DRUG FILE IEN. TO SUMMARIZE:
 ; 
 ; MEDID->GCN->RXNCUI->VUID->VAPROD->DRUGIEN
 ;
 ; (NOTE: THIS PROCESS WILL CHANGE - BE IMPROVED - WHEN THE VERIFIED 
 ; MEDID->RXNORM MAPPING BECOMES AVAILABLE. THIS ANALYSIS WILL ESTABLISH
 ; A BASELINE WITH WHICH TO COMPARE THE RESULT OF USING THAT MAPPING)
 ;
 ; (THE PROCESS IS ACTUALLY MORE COMPLEX THAT THIS, BECAUSE WE ALSO TRY
 ; AND MATCH DRUGS BY LOOKING AT THEIR CHEMICAL COMPONENTS BUT THIS ANALYSIS
 ; IGNORES THIS MORE COMPLEX PROCESS.)
 ; 
 ; NOT ALL DRUGS MAKE IT ALL THE WAY THROUGH THIS MAPPING. IN ADDITION, THERE
 ; MAY BE DRUGS THAT ARE IN THE DRUG FILE THAT ARE NOT IN THE FDB FILE
 ; THIS ROUTINE WILL CREATE A SPREADSHEET THAT WILL SHOW THE UNMAPPED DRUGS
 ; IN BOTH DIRECTIONS (MEDID->...>DRUGIEN AND DRUGIEN->...>MEDID)
 ; IT WILL ALSO SHOW THE DRUG NAME AS IT APPEARS IN FIRST DATA BANK
 ; AND THE NAME THAT WILL BE USED FOR THAT DRUG IN VISTA (ERX). OFTEN
 ; THEY WILL BE DIFFERENT. IF THE FDB DRUG IS NOT A GENERIC, THE GENERIC NAME
 ; WILL BY USED BY ERX TO LIST THE DRUG IN THE PATIENT'S DRUG LIST IN VISTA
 ;
 ; WE ARE GOING TO ORGANIZE AN ARRAY WITH DRUGS BY TYPE. HERE ARE THE TYPES:
 ; 
 ; TYPE 1 - FDB DRUGS THAT MAP EXACTLY TO THE DRUG FILE, WITH NAMES THAT
 ;  MATCH EXACTLY
 ;
 ; TYPE 2 - FDB DRUGS THAT MAP TO THE DRUG FILE, BUT WITH DIFFERENT NAMES.
 ;  THIS CATEGORY INCLUDES DRUGS THAT ARE SHOWN IN VISTA AS GENERICS BUT
 ;  ON FDB AS BRAND NAME DRUGS
 ; 
 ; TYPE 3 - FDB DRUGS THAT DO NOT MAP TO THE DRUG FILE, BUT DO MAP TO THE
 ;  VA PRODUCT FILE (NDF). IF ANY OF THESE DRUGS MIGHT BE ORDERED VIA ERX,
 ;  IT MIGHT BE A GOOD IDEA TO ADD THEM TO THE DRUG FILE.
 ; NOTE: FOR TYPE 3 AND ABOVE DRUGS, ERX WILL STILL FUNCTION PROPERLY BUT
 ; INSTEAD OF MAPPING THE DRUG TO THE DRUG FILE, WILL MAP IT AS A FREE TEXT
 ; DRUG AND WILL SEND A MAIL MESSAGE ABOUT THE MAPPING ERROR SO THAT THE
 ; DRUG CAN BE CONSIDERED FOR ADDING TO THE DRUG FILE
 ; 
 ; TYPE 4 - FDB DRUGS THAT DO NOT MAP TO THE DRUG FILE AND ARE ALSO NOT
 ;  FOUND IN THE NDF. THIS MIGHT BE THE CASE FOR NEWER DRUGS. ERX WILL
 ;  STILL FUNCTION, BUT THESE WILL BE FREE TEXT DRUGS. THE REMEDY IS AN
 ;  UPDATE FROM THE VA OF THE NDF OR ADDING THE DRUGS TO THE NDF AND THE
 ;  DRUG FILE. (THERE ARE COMPLEXITIES IN ADDING DRUGS TO THE NDF BECAUSE
 ;  OF HOW TO THEN HANDLE AN UPDATE FROM THE VA)
 ;
 ; TYPE 5 - DRUGS IN THE DRUG FILE THAT ARE NOT FOUND IN THE FDB DRUG DATABASE
 ;  MAPPING. THIS MIGHT INCLUDE BRAND NAME DRUGS IN THE DRUG FILE THAT HAVE
 ;  BEEN MAPPED TO GENERICS WHEN COMING FROM FDB. IN ANY CASE, THESE ARE DRUGS
 ;  FOR WHICH THERE IS NO PATH TO MAP FROM THEM TO FDB. (REDUCING THE NUMBER
 ;  OF DRUGS IN THIS TYPE TO ZERO WILL BE A GOAL BEFORE IMPLEMENTING PHASE II
 ;  OF ERX WHERE DRUGS WILL BE ORDERED ON VISTA AND SENT TO THE ERX 
 ;  SERVICE.
 ;
 N FN S FN=1130590010.002 ;FILE NUMBER FOR C0P RXNORM FDB VUID MAPPING FILE
 N C0PFDA 
 N ZI
 S ZI=""
 F  S ZI=$O(^C0P("FDB","B",ZI)) Q:ZI=""  D  ;
        . W !,ZI
 . D DOONE(.C0PFDA,ZI) ;BUILD AN FDA
 . D UPDIE ;WRITE TO FILE
        . K C0PDFA
 Q
 ;
DOONE(C0PFDA,ZI) ; RETURN FDA FOR MEDID ZI
 N FN S FN=1130590010.002 ;FILE NUMBER FOR C0P RXNORM FDB VUID MAPPING FILE
 N ZGCN,ZRXNCUI,ZNAME,ZVAIEN,ZDRUGIEN,ZROW,ZIEN,ZVANAME,ZRXNIEN,ZRXNTXT
 S (ZGCN,ZRXNCUI,ZNAME,ZVAIEN,ZDRUGIEN,ZVANAME)=""
 ;S ZROW("MEDID")=ZI ; FDB MEDID
 S C0PFDA(FN,"?+1,",.02)=ZI ; FDB MEDID
 S ZIEN=$O(^C0P("FDB","B",ZI,"")) ; IEN OF THE FDB MED
 S C0PFDA(FN,"?+1,",1.02)=ZIEN ;POINTER TO FDB MED
 ;S ZROW("FDBNAME")=$$FULLNAME^C0PLKUP(ZI) ; FDB MED NAME
 S ZNAME=$$FULLNAME^C0PLKUP(ZI) ; FDB MED NAME
 S C0PFDA(FN,"?+1,",2.02)=ZNAME ; FDB MED NAME
 S ZGCN=$$GCN^C0PLKUP(ZI)
 I ZGCN=0 D  Q  ; NO GCN, CAN'T GO FURTHER 
 . ;S ZROW("TYPE")=4
 . S C0PFDA(FN,"?+1,",3)=4 ;TYPE 4, CAN'T MAP FDB TO RXN
 . S C0PFDA(FN,"?+1,",.01)="MISSING RXN" ;NEED TO HAVE A .01
 . ;D RNF1TO2^C0CRNF(ZARY,"ZROW")
 ;S ZROW("GCN")=ZGCN
 S C0PFDA(FN,"?+1,",.04)=$$GCN^C0PLKUP(ZI) ;GENERIC CATEGORY NUMBER
 S ZRXNCUI=$$RXNCUI^C0PLKUP(ZGCN) ; RETRIEVE THE RXNORM CONCEPT ID
 I ZRXNCUI="" W !,"ERROR, NO RXNCUI "_ZGCN B  ; SHOULDN'T HAPPEN
 S C0PFDA(FN,"?+1,",.01)=ZRXNCUI ; RXN CONCEPT
 S ZRXNIEN=$O(^C0P("RXN","B",ZRXNCUI,"")) ; RXN CONCEPT IEN
 S C0PFDA(FN,"?+1,",1.01)=ZRXNIEN ; POINTER TO RXN CONCEPT
 S ZRXNTXT=$G(^C0P("RXN",ZRXNIEN,1,1,0)) ; FIRST LINE OF RXN TEXT
 S C0PFDA(FN,"?+1,",2.01)=ZRXNTXT ; RXN CONCEPT LABEL
 ;S ZROW("RXNCUI")=ZRXNCUI
 S ZVUID=$$VUID^C0PLKUP(ZRXNCUI) ; FETCH THE VUID
 I ZVUID="" D  Q  ; NO VUID FOUND
 . ;S ZROW("TYPE")=4
 . S C0PFDA(FN,"?+1,",3)=4 ;TYPE 4, CAN'T MAP RXNCUI TO VUID
 . ;D RNF1TO2^C0CRNF(ZARY,"ZROW")
 ;S ZROW("VUID")=ZVUID
 S ZVUID=$TR(ZVUID,"^","|") ; CAN'T HAVE ^ IN FIELDS
 S C0PFDA(FN,"?+1,",.03)=ZVUID ;SET OF VUIDS
 I ZVUID["|" S ZVUID=$P(ZVUID,"|",1) ; USE THE FIRST ONE
 S ZVAIEN=$$VAPROD^C0PLKUP(ZVUID) ; IEN IN VA PRODUCTS (NDF)
 I +ZVAIEN=0 D  Q  ; NOT FOUND IN NDF
 . ;S ZROW("TYPE")=4
 . S C0PFDA(FN,"?+1,",3)=4 ;TYPE 4, CAN'T MAP VUID TO NDF
 . ;D RNF1TO2^C0CRNF(ZARY,"ZROW")
 S ZDRUGIEN=$$DRUG^C0PLKUP(ZVAIEN) ; IEN IN DRUG FILE
 I ZDRUGIEN["^" S ZDRUGIEN=$P(ZDRUGIEN,"^",1) ; USE THE FIRST ONE
 I +ZDRUGIEN=0 D  Q  ;
 . S ZROW("TYPE")=3
 . S C0PFDA(FN,"?+1,",3)=3 ;TYPE 3, CAN'T MAP VUID TO DRUG FILE
 . ;S ZROW("VANDFNAME")=$$GET1^DIQ(50.68,ZVAIEN_",",.01) ;NDF NAME
 . S C0PFDA(FN,"?+1,",1.04)=ZVAIEN ;POINTER TO NDF
 . S C0PFDA(FN,"?+1,",2.04)=$$GET1^DIQ(50.68,ZVAIEN_",",.01) ;NDF NAME
 . ;D RNF1TO2^C0CRNF(ZARY,"ZROW")
 S ZVANAME=$$GET1^DIQ(50,ZDRUGIEN_",",.01) ; VA DRUG NAME
 S C0PFDA(FN,"?+1,",2.03)=ZVANAME ; VA DRUG FILE NAME
 S C0PFDA(FN,"?+1,",1.03)=$G(ZDRUGIEN) ; VA DRUG FILE IEN
 ;S ZROW("VANAME")=ZVANAME ; 
 I ZVANAME=$$UP^XLFSTR(ZNAME) S ZROW("TYPE")=1
 E  S ZROW("TYPE")=2
 S C0PFDA(FN,"?+1,",3)=ZROW("TYPE") ; MATCHING TYPE 1 OR 2
 ;D RNF1TO2^C0CRNF(ZARY,"ZROW")
 ;B
 Q
 ;
UPDIE   ; INTERNAL ROUTINE TO CALL UPDATE^DIE AND CHECK FOR ERRORS
 ;Q  ;//SMH don't want an update
 ;I C0PFDA(FN,"+1,",3)'=3 Q  ;
        ;I C0PFDA(FN,"+1,",1.02)=1 Q  ;
 ;ZWR C0PFDA ;
 K ZERR
 D CLEAN^DILF
 D UPDATE^DIE("","C0PFDA","","ZERR")
 ;I $D(ZERR) D  ;
 ;. W "ERROR",!
 ;. ZWR ZERR
 ;. B
 K C0PFDA
 Q
 ;
