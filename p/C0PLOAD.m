C0PLOAD	; VEN/SMH - File Loading Utilties ; 5/8/12 4:53pm
	;;1.0;C0P;;Apr 25, 2012;Build 103
	; (C) Sam Habiel 2012
	;
	;Copyright 2012 Sam Habiel.  Licensed under the terms of the GNU
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
	   ; The routine contains utilities for Reading Files from 
	   ; RxNorm and FDB into Fileman files
	   ; 
	   ; This is a pretty pretty alpha version. Right now it just has FDB.
	   ;
	   ; These files definitions will be existing already. They should
	   ; be installed as part of the KIDS build containing this routine.
	   ;
	   ; The import templates will be also part of KIDS. They should
	   ; already exist by the time you run this routine.
	   ; 
	   ; The drug file is produced by importing a table called 'tblCompositeDrugs' 
	   ; provided in an access database from NewCrop accessed using parameter 
	   ; '1' for desiredData from this webservice: 
	   ; http://preproduction.newcropaccounts.com/V7/WebServices/Update1.asmx?op=GetMostRecentDownloadUrl 
	   ;
	   ; The webservice provides a URL to a zip file; when unzipped, it produces an
	   ; access database with tables for allergies, drugs, pharamcies, healthplans, and
	   ; diagnoses.  
	   ; 
	   ; The following command (from mdb-tools) was used to extract this into an RRF
	   ; format (i.e. '|' delimited).| 
	   ;  
	   ;  mdb-sql -HFp -d'|' -i selecttblCompositeDrug.sql  NCFull-200910.mdb > Drug.rrf 
	   ;
	   ; The SQL was necessary to skip a word-processing field which I couldn't import
	   ; into fileman using the fileman import tool (this is simply a technical
	   ; restriction; if I hand wrote my import I could have used a word processing
	   ; field and used WP^DIE to file it.) That's field's name is 'etc'.  
	        
	   ; The SQL statement is as follows: SELECT MEDID, GCN_SEQNO, MED_NAME_ID, 
	   ; MED_NAME, MED_ROUTED_MED_ID_DESC, MED_ROUTED_DF_MED_ID_DESC, MED_MEDID_DESC, 
	   ; MED_STATUS_CD, MED_ROUTE_ID, ROUTED_MED_ID, ROUTED_DOSAGE_FORM_MED_ID, 
	   ; MED_STRENGTH, MED_STRENGTH_UOM, MED_ROUTE_ABBR, MED_ROUTE_DESC, 
	   ; MED_DOSAGE_FORM_ABBR, MED_DOSAGE_FORM_DESC, GenericDrugName, 
	   ; DosageFormOverride, MED_REF_DEA_CD, MED_REF_DEA_CD_DESC, 
	   ; MED_REF_MULTI_SOURCE_CD, MED_REF_MULTI_SOURCE_CD_DESC, 
	   ; MED_REF_GEN_DRUG_NAME_CD, MED_REF_GEN_DRUG_NAME_CD_DESC, 
	   ; MED_REF_FED_LEGEND_IND, MED_REF_FED_LEGEND_IND_DESC, GENERIC_MEDID, 
	   ; MED_NAME_TYPE_CD, GENERIC_MED_REF_GEN_DRUG_NAME_CD, MED_NAME_SOURCE_CD, 
	   ; DrugInfo, GenericDrugNameOverride, FormularyDrugID, Manufacturer, Status, 
	   ; TouchDate, DrugTypeID FROM tblCompositeDrug 
	   ; 
	   ; The allergies file is produced by importing the tblCompositeAllergy file
	   ;
	   ; Here's the mdb command to extract the file.
	   ; mdb-export -HQ -d "|" NCFull-201203.mdb tblCompositeAllergy > tblCompositeAllergy.rrf
	   ; 
	   ; There is no SQL here.
	   ;
	   ; Once you have both files, you can adjust the routine to where the files are
	   ; and then import them by calling the PEPs below.
	   ;
	   ; Update: I wrote a bash script to automate this: it's called:
	   ;   drug_data_extract.sh
	   ;
FDBIMP	 ; FDB Drug File Import; PEP. Interactive (for now).
	   ;
	   ;
	   N FILEPATH
	   R "Enter RRF FDB Drug File with Full Path: ",FILEPATH:60,!
	   I '$L(FILEPATH) QUIT
	   ;
	   ; NB: The following will only work on Unix
	   N PATH,FILE
	   N PIECES S PIECES=$L(FILEPATH,"/")
	   S PATH=$P(FILEPATH,"/",1,PIECES-1)
	   S FILE=$P(FILEPATH,"/",PIECES)
	   ;
	   ; Kill off the existing file
	   N %1 S %1=^C0P("FDB",0)    ; save zero node
	   S $P(%1,"^",3,4)=""        ; zero last record numbers
	   K ^C0P("FDB")              ; kill file
	   S ^C0P("FDB",0)=%1         ; restore zero node
	   ;
	   ; Import File from text extract (Please I want an ODBC driver!)
	   ; 
	   D CLEAN^DILF
	   N CONTROL
	   S CONTROL("FLAGS")="E"  ; External Values...
	   S CONTROL("MSGS")=""   ; go as normal in ^TMP("DIERR",$J)
	   S CONTROL("MAXERR")="100" ; abort if you can't file a hundred records
	   ; S CONTROL("IOP")="HOME"    ; Send to home device ; smh - don't pass; API no like for HOME output
	   S CONTROL("QTIME")=""  ; Don't Queue
	   N SOURCE
	   S SOURCE("FILE")=FILE               ; File Name
	   S SOURCE("PATH")=PATH               ; Directory
	   N FORMAT
	   S FORMAT("FDELIM")="|"                 ; Delimiter
	   S FORMAT("FIXED")=""                   ; Fixed Width?
	   S FORMAT("QUOTED")=""                  ; Are strings quoted?
	   ;
	   D FILE^DDMP(1130590010,"[C0P FDB TBLCOMPOSITEDRUG]",.CONTROL,.SOURCE,.FORMAT)
	   QUIT
	   ;
FDBAIMP	; FDB Allergies Import; PEP. Interactive (for now)
	   ; 
	   ; 
	   N FILEPATH
	   R "Enter RRF FDB Allergy File with Full Path: ",FILEPATH:60,!
	   I '$L(FILEPATH) QUIT
	   ;
	   ; NB: The following will only work on Unix
	   N PATH,FILE
	   N PIECES S PIECES=$L(FILEPATH,"/")
	   S PATH=$P(FILEPATH,"/",1,PIECES-1)
	   S FILE=$P(FILEPATH,"/",PIECES)
	   ; 
	   ; Kill off the existing file
	   N %1 S %1=^C0PALGY(0)  ; save zero node
	   S $P(%1,"^",3,4)=""    ; zero last record numbers
	   K ^C0PALGY             ; kill file
	   S ^C0PALGY(0)=%1       ; restore zero node
	   ;
	   ; Import file from text extract
	   D CLEAN^DILF
	   N CONTROL
	   S CONTROL("FLAGS")="E"  ; External Values...
	   S CONTROL("MSGS")=""   ; go as normal in ^TMP("DIERR",$J)
	   S CONTROL("MAXERR")="100" ; abort if you can't file a hundred records
	   ; S CONTROL("IOP")="HOME"    ; Send to home device ; smh - don't pass; API no like for HOME output
	   S CONTROL("QTIME")=""  ; Don't Queue
	   N SOURCE
	   S SOURCE("FILE")=FILE                   ; File Name
	   S SOURCE("PATH")=PATH                   ; Directory
	   N FORMAT
	   S FORMAT("FDELIM")="|"                 ; Delimiter
	   S FORMAT("FIXED")=""                   ; Fixed Width?
	   S FORMAT("QUOTED")=""                  ; Are strings quoted?
	   ;
	   D FILE^DDMP(113059005,"[C0P FDB TBLCOMPOSITEALLERGY]",.CONTROL,.SOURCE,.FORMAT)
	   QUIT
RXNIMP	; Import RxNorm Concepts File; Modded from C0CRXNRD
	   N FILEPATH
	   R "Enter RRF RxNorm Conepts File with Full Path: ",FILEPATH:60,!
	   I '$L(FILEPATH) QUIT
	   ;
	   ; NB: The following will only work on Unix
	   N PATH,FILE
	   N PIECES S PIECES=$L(FILEPATH,"/")
	   S PATH=$P(FILEPATH,"/",1,PIECES-1)
	   S FILE=$P(FILEPATH,"/",PIECES)
	   ;
	   N LINES S LINES=$$GETLINES(PATH,FILE)
	   D OPEN^%ZISH("FILE",PATH,FILE,"R")
	   ;
	   IF POP D EN^DDIOL("Error reading file..., Please check...") G EX
	   ;
	   N %1 S %1=^C0P("RXN",0)
	   S $P(%1,"^",3,4)=""
	   K ^C0P("RXN")
	   S ^C0P("RXN",0)=%1
	   ; 
	   N C0CCOUNT
	   F C0CCOUNT=1:1 D  Q:$$STATUS^%ZISH
	   . U IO
	   . N LINE R LINE:1
	   . IF $$STATUS^%ZISH QUIT
	   . I '(C0CCOUNT#1000) U $P W C0CCOUNT," of ",LINES," read ",! U IO ; update every 1000
	   . N RXCUI,RXAUI,SAB,TTY,CODE,STR  ; Fileman fields numbers below
	   . S RXCUI=$P(LINE,"|",1)    ; .01
	   . S RXAUI=$P(LINE,"|",8)    ; 1
	   . S SAB=$P(LINE,"|",12) ; 2
	   . ;
	   . ; Following lines not applicable here:
	   . ; If the source is a restricted source, decide what to do based on what's asked.
	   . ; N SRCIEN S SRCIEN=$$FIND1^DIC(176.003,"","QX",SAB,"B") ; SrcIEN in RXNORM SOURCES file
	   . ; N RESTRIC S RESTRIC=$$GET1^DIQ(176.003,SRCIEN,14,"I") ; 14 is restriction field; values 0-4
	   . ; If RESTRIC is zero, then it's unrestricted. Everything else is restricted.
	   . ; If user didn't ask to include restricted sources, and the source is restricted, then quit
	   . ; I 'INCRES,RESTRIC QUIT
	   . ;
	   . S TTY=$P(LINE,"|",13) ; 3
	   . S CODE=$P(LINE,"|",14)    ; 4
	   . S STR=$P(LINE,"|",15) ; 5
	   . ; Remove embedded "^"
	   . S STR=$TR(STR,"^")
	   . ; Convert STR into an array of 80 characters on each line
	   . N STRLINE S STRLINE=$L(STR)\80+1
	   . ; In each line, chop 80 characters off, reset STR to be the rest
	   . N J F J=1:1:STRLINE S STR(J)=$E(STR,1,80) S STR=$E(STR,81,$L(STR))
	   . ; Now, construct the FDA array
	   . N RXNFDA
	   . S RXNFDA(1130590011.001,"+1,",.01)=RXCUI
	   . S RXNFDA(1130590011.001,"+1,",1)=RXAUI
	   . S RXNFDA(1130590011.001,"+1,",2)=SAB
	   . S RXNFDA(1130590011.001,"+1,",3)=TTY
	   . S RXNFDA(1130590011.001,"+1,",4)=CODE
	   . N RXNIEN S RXNIEN(1)=C0CCOUNT
	   . D UPDATE^DIE("","RXNFDA","RXNIEN")
	   . I $D(^TMP("DIERR",$J)) D EN^DDIOL("ERROR") G EX
	   . ; Now, file WP field STR
	   . D WP^DIE(1130590011.001,C0CCOUNT_",",5,,$NA(STR))
EX	 D CLOSE^%ZISH("FILE")
	   QUIT
GETLINES(PATH,FILENAME)	; Get number of lines in a file
	   D OPEN^%ZISH("FILE",PATH,FILENAME,"R")
	   U IO
	   N I
	   F I=1:1 R LINE:1 Q:$$STATUS^%ZISH
	   D CLOSE^%ZISH("FILE")
	   Q I-1
