C0PKIDS	; VEN/SMH - eRx KIDS Utilities ; 5/4/12 4:26pm
	   ;;1.0;C0P;;Apr 25, 2012;Build 7
	   ; (C) Sam Habiel 2012
	      ; Licensed under GPL.
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
	      ;
	   ; This routine contains utilities for KIDS distribution of E-Rx.
	   ;
	   ; PEPs:
	   ; For RxNorm dist: RXNTRAN,RXNPOST
	   ; For FDB files: FDBTRAN,FDBPOST
	   ;
	   ;
ENV	; Environment Check
	   ; If EWD version is less than 800, don't install
	   I $$TRIM^XLFSTR($G(^%zewd("version")))<800 DO  QUIT
	   . W "A recent version of EWD must be installed before installing ",!
	   . W "e-Prescribing. Installation cannot continue.",!
	   . S XPDQUIT=1
	   ; Check if C0C 1.1 is installed
	   QUIT
POST	; Main Post Installation routine
	   ;
	   ; KIDS will file the modified RPs ORWPS COVER and ORWPS DETAIL
	   ; KIDS will install the Mail Group ERX HELP DESK
	   ;
	   D MES^XPDUTL("Adding E-Prescribing RPCs to CPRS Broker Context")
	   D REGNMSP("C0P","OR CPRS GUI CHART") ; Register C0P RPs to the Broker Context
	   ;
	   ; Add two alerts to the OE/RR Notifications file
	   D MES^XPDUTL("Adding E-Prescribing Notifications to the OE/RR Notification File")
	   ;
	   N C0PFDA
	   ; Entry 1                                                                   
	   S C0PFDA(100.9,"?+1,",.001)=11305                       ; NUMBER            
	   S C0PFDA(100.9,"?+1,",.01)="C0P ERX REFILL REQUEST"     ; NAME              
	   ; .02 is not filled out, but triggered by the .01                           
	   S C0PFDA(100.9,"?+1,",.03)="ERX REFILL REQUEST"         ; MESSAGE TEXT      
	   S C0PFDA(100.9,"?+1,",.04)="PKG"                        ; MESSAGE TYPE      
	   S C0PFDA(100.9,"?+1,",.05)="R"                          ; ACTION FLAG       
	   S C0PFDA(100.9,"?+1,",.06)="RUN"                        ; ENTRY POINT       
	   S C0PFDA(100.9,"?+1,",.07)="C0PREFIL"                   ; ROUTINE NAME      
	   S C0PFDA(100.9,"?+1,",1.5)="OR"                         ; RELATED PACKAGE   
	   S C0PFDA(100.9,"?+1,",4)="Used by the C0P eRx package for eRx Refill Requests"
	   ;                                                                           
	   ; Entry 2                                                                   
	   S C0PFDA(100.9,"?+2,",.001)=11306                       ; NUMBER            
	   S C0PFDA(100.9,"?+2,",.01)="C0P ERX INCOMPLETE ORDER"   ; NAME              
	   ; .02 is not filled out, but triggered by the .01                           
	   S C0PFDA(100.9,"?+2,",.03)="ERX INCOMPLETE ORDER"       ; MESSAGE TEXT      
	   S C0PFDA(100.9,"?+2,",.04)="PKG"                        ; MESSAGE TYPE      
	   S C0PFDA(100.9,"?+2,",.05)="R"                          ; ACTION FLAG       
	   S C0PFDA(100.9,"?+2,",.06)="STATUS"                     ; ENTRY POINT       
	   S C0PFDA(100.9,"?+2,",.07)="C0PREFIL"                   ; ROUTINE NAME      
	   S C0PFDA(100.9,"?+2,",1.5)="OR"                         ; RELATED PACKAGE   
	   S C0PFDA(100.9,"?+2,",4)="Used by the C0P eRx package for eRx Incomplete Order Alerts"
	   ;                                                                           
	   N C0PERR           ; Errors go here.                                                         
	   D UPDATE^DIE("","C0PFDA","","C0PERR") ; no flags, FDA, ien_root, msg_root   
	   ;
	   ; ew ew ew I hate $Q... still don't understand it.
	   I $D(C0PERR) D
	   . D MES^XPDUTL("WARNING: Updating the OE/RR Notification file failed.")
	   . S C0PERR=$Q(C0PERR)
	   . F  S C0PERR=$Q(@C0PERR) Q:C0PERR=""  D MES^XPDUTL(C0PERR_": "_@C0PERR)
	   ;
	   ; Done with that; now add the x-ref to file 200 on the NPI field.
	   ; Thank you to D ^DIKCBLD for writing this for me!
	   ;
	   D MES^XPDUTL("Adding NPI Cross Reference to New Person File")
	   N C0PXR,C0PRES,C0POUT,C0PERR
	   S C0PXR("FILE")=200
	   S C0PXR("NAME")="C0PNPI"
	   S C0PXR("TYPE")="R"
	   S C0PXR("USE")="LS"
	   S C0PXR("EXECUTION")="F"
	   S C0PXR("ACTIVITY")="IR"
	   S C0PXR("SHORT DESCR")="Regular index on NPI for eRx"
	   S C0PXR("VAL",1)=41.99
	   S C0PXR("VAL",1,"SUBSCRIPT")=1
	   S C0PXR("VAL",1,"LENGTH")=30
	   S C0PXR("VAL",1,"COLLATION")="F"
	   D CREIXN^DDMOD(.C0PXR,"S",.C0PRES,"C0POUT","C0PERR")
	   I $D(C0PERR) D MES^XPDUTL("NPI Cross-Reference Creation on File 200 failed")
	   ;
	   ; Ditto: Add the x-ref to file 50 on the PSNDF VA PRODUCT NAME ENTRY
	   D MES^XPDUTL("Adding PSNDF VA PRODUCT NAME ENTRY xref to Drug File")
	   N C0PXR,C0PRES,C0POUT,C0PERR
	   S C0PXR("FILE")=50
	   S C0PXR("NAME")="AC0P"
	   S C0PXR("TYPE")="R"
	   S C0PXR("USE")="S"
	   S C0PXR("EXECUTION")="F"
	   S C0PXR("ACTIVITY")="IR"
	   S C0PXR("SHORT DESCR")="For eRx - a sort only index on the VAPRODUCT number"
	   S C0PXR("DESCR",1)="This index is used for the VISTA e-Rx project. This index enables a "
	   S C0PXR("DESCR",2)="programmer to search for a drug using the VA Product. This index will"
	   S C0PXR("DESCR",3)="be used to match drugs received from the remote service to the local drug"
	   S C0PXR("DESCR",4)="file. Drugs received using the remote service are received using RxNorm"
	   S C0PXR("DESCR",5)="CUI or First Databank MEDID. Either one of those will be translated to a"
	   S C0PXR("DESCR",6)="VUID, which is matched against the VA Product file, which then is matched"
	   S C0PXR("DESCR",7)="to the local drug pointing to the VA Product. "
	   S C0PXR("VAL",1)=22
	   S C0PXR("VAL",1,"SUBSCRIPT")=1
	   S C0PXR("VAL",1,"COLLATION")="F"
	   D CREIXN^DDMOD(.C0PXR,"S",.C0PRES,"C0POUT","C0PERR")
	   I $D(C0PERR) D MES^XPDUTL("PSNDF VA PRODUCT NAME ENTRY xref Creation failed")
	   ;
	   ; Add Free Txt Entry to Pharmacy Orderable Item
	   ; Again... this time file the Free Text Drug into Pharmacy Orderablem Items
	   ; if it isn't already there!
	      D MES^XPDUTL("Adding Free Txt Entry to Pharmacy Orderable Item file")
	      ;
	   N PSEDITNM S PSEDITNM=1                      ; Fileman gatekeeper for adding entries
	   N C0PFDA
	   S C0PFDA(50.7,"?+1,",.01)="FREE TXT DRUG"    ; Name
	   S C0PFDA(50.7,"?+1,",.02)=40                 ; DOSAGE FORM: MISCELANEOUS
	   S C0PFDA(50.7,"?+1,",.04)=3110428            ; INACTIVE DATE: (any value would do!)
	   ;
	   N C0PERR           ; Errors go here.                                                         
	   D UPDATE^DIE("","C0PFDA","","C0PERR") ; no flags, FDA, ien_root, msg_root   
	   ;
	   I $D(C0PERR) D
	   . D MES^XPDUTL("Couldn't add FREE TXT DRUG to Pharmacy Orderable Item File")
	   . S C0PERR=$Q(C0PERR)
	   . F  S C0PERR=$Q(@C0PERR) Q:C0PERR=""  D MES^XPDUTL(C0PERR_": "_@C0PERR)
	   ;
	      D MES^XPDUTL("")
	      D MES^XPDUTL("Remember to install the following patches: ")
	      D MES^XPDUTL("They may be legally protected; see documentation on how to")
	      D MES^XPDUTL("acquire them. Contact Geroge Lilly at glilly@glilly.net for questions")
	      D MES^XPDUTL(" - C0P*1.0*1 -> New Crop WebServices Data")
	      D MES^XPDUTL(" - C0P*1.0*2 -> RxNorm Data 2012-04 Release")
	      D MES^XPDUTL(" - C0P*1.0*3 -> First Databank Data 2012-03 Release")
	      D MES^XPDUTL("")
	      D MES^XPDUTL("Make sure to set-up the following after installation: ")
	      D MES^XPDUTL(" - Account Info in C0P WS ACCT")
	      D MES^XPDUTL(" - Institution address fields in file 4")
	      D MES^XPDUTL(" - Hospital Location E-Rx fields")
	      D MES^XPDUTL(" - New Person E-Rx fields")
	      D MES^XPDUTL(" - Mail users to mail group: ERX HELP DESK")
	      D MES^XPDUTL(" - Schedule C0P ERX BATCH to run every 15 min using an eRx user")
	      ;
	   ; I think we are done!
	   QUIT
	   ; --> RxNorm Files
RXNTRAN	; Transportation Routine for RxNorm Files, PEP
	   M @XPDGREF@("C0P","RXN")=^C0P("RXN")
	   QUIT
RXNPOST	; Post Install Routine for RxNorm Files, PEP
	   D MES^XPDUTL("Installing RxNorm Concepts File")
	   K ^C0P("RXN")
	   M ^C0P("RXN")=@XPDGREF@("C0P","RXN")
	   QUIT
	   ; <-- RxNorm Files
	   ;
	   ; --> FDB Files
FDBTRAN	; Unified Transportation EP for FDB Files, PEP
	   D FDBDTRAN,FDBATRAN,IMPTRAN ; Drugs, Allergies, Import Templates
	   QUIT
FDBPOST	; Unified Post Install Routine for FDB Files, PEP
	   D FDBDPOST,FDBAPOST,IMPPOST ; Drugs, Allergies, Import Templates
	   QUIT
	   ; <-- FDB Files
	   ; 
	   ; Rest is private
FDBDTRAN	   ; Transportation Routine for FDB Drug File, private
	   M @XPDGREF@("C0P","FDBD")=^C0P("FDB")
	   QUIT
FDBDPOST	   ; Post Install Routine for FDB Drug File, private
	   D MES^XPDUTL("Installing FDB Drug File")
	   K ^C0P("FDB") ; Kill original file
	   M ^C0P("FDB")=@XPDGREF@("C0P","FDBD") ; Merge from Global
	   QUIT
FDBATRAN	   ; Transportation Routine for FDB Allergies File, private
	   M @XPDGREF@("C0P","FDBA")=^C0PALGY
	   QUIT
FDBAPOST	   ; Post Install Routine for FDB Allergies File, private
	   D MES^XPDUTL("Installing FDB Allergy File")
	   K ^C0PALGY ; Kill original file
	   M ^C0PALGY=@XPDGREF@("C0P","FDBA") ; Merge from Global
	   QUIT
	   ;
	   ; --> Import Templates
IMPTRAN	; Transport Import Template for loading FDB files, private
	   ;
	   ; Get the IEN of the import templates to transport off...
	   N FDBDIEN S FDBDIEN=$O(^DIST(.46,"B","C0P FDB TBLCOMPOSITEDRUG",""))
	   N FDBAIEN S FDBAIEN=$O(^DIST(.46,"B","C0P FDB TBLCOMPOSITEALLERGY",""))
	   ;
	   ; Put in transport global, remove creator DUZ (can't guarantee in dest sys)
	   M @XPDGREF@("C0P","IMPFDBD")=^DIST(.46,FDBDIEN) ; Get first template
	   S $P(@XPDGREF@("C0P","IMPFDBD",0),U,5)="" ; Remove Creator
	   M @XPDGREF@("C0P","IMPFDBA")=^DIST(.46,FDBAIEN) ; Get second template
	   S $P(@XPDGREF@("C0P","IMPFDBA",0),U,5)="" ; Remove Creator
	   ;
	   QUIT
	   ;
IMPPOST	; Post init for Import Templates, private
	   ; TODO: Before using as a general KIDS utility, this does not 
	   ; check if the destination fields exist. Destination fields are 
	   ; FREE TEXT fields in the Import Template.
	   ;
	   D MES^XPDUTL("Installing FDB Files' Import Templates")
	   ; Part 1: Delete old entries if they already exist.
	   ;
	   ; Get IENs
	   N FDBDIEN S FDBDIEN=$O(^DIST(.46,"B","C0P FDB TBLCOMPOSITEDRUG",""))
	   N FDBAIEN S FDBAIEN=$O(^DIST(.46,"B","C0P FDB TBLCOMPOSITEALLERGY",""))
	   ; 
	   ; Kill off: Indexes first, then record. Lock before you do.
	   N C0PNAME
	   F C0PNAME="FDBDIEN","FDBAIEN" D  ; For each variable
	   . I @C0PNAME D  ; If that entry is found (see $O above)
	   . . L +^DIST(.46,@C0PNAME):0 ; Lock
	   . . ; IX2: Fire all Kill x-refs for one record.
	   . . N DIK,DA S DIK="^DIST(.46,",DA=@C0PNAME D IX2^DIK ; Kill Logic
	   . . K ^DIST(.46,@C0PNAME) ; Remove record
	   . . L -^DIST(.46,@C0PNAME) ; Unlock
	   ;
	   ; Part 2: Update New Entries into File
	   ; Get next available IEN in Import Template File
	   N LASTIEN S LASTIEN=$O(^DIST(.46," "),-1)          ; Last internal entry number in file
	   ;
	   N NEXTIEN S NEXTIEN=LASTIEN                        ; Use below... incrementer!
	   ;
	   ; Merge data into the next IEN for each of the refs in the transported global
	   ; Block below gets next IEN available.
	   ; Lock on ^DIST(.46,NEXTIEN) acquired below.
	   F C0PNAME="IMPFDBD","IMPFDBA" DO
	   . ;
	   . ; Loop below to get an IEN for our new record number
	   . N DONE ; control variable for mini loop below
	   . F  D  Q:$G(DONE)  ; loop until done
	   . . S NEXTIEN=NEXTIEN+1 ; Next IEN available, we guess
	   . . L +^DIST(.46,NEXTIEN):0 ELSE  QUIT  ; Can we lock it? If not quit and try the next
	   . . I $D(^DIST(.46,NEXTIEN)) L -^DIST(.46,NEXTIEN) QUIT  ; if we locked it, is it really empty? If not, unlock and try next
	   . . S DONE=1 QUIT  ; ok. we are sure we got it. Tell the loop we are done.
	   . ;
	   . M ^DIST(.46,NEXTIEN)=@XPDGREF@("C0P",C0PNAME) ; Merge entry
	   . ;
	   . ; Fire off xrefs (IX1 fires SET for xrefs for one record)
	   . N DIK,DA S DIK="^DIST(.46,",DA=NEXTIEN D IX1^DIK
	   . ;
	   . ; Update zero node
	   . S $P(^DIST(.46,0),U,3)=NEXTIEN ; most recently assigned internal entry number
	   . S $P(^DIST(.46,0),U,4)=NEXTIEN ; current total number of entries
	   . ;
	   . L -^DIST(.46,NEXTIEN) ; Unlock it
	   QUIT
	   ; <-- Import Templates
	; 
	; SMH: All Code below comes from FOIA RPMS from routine CIAURPC
	; Written by Doug Martin.
	;
	; Register/unregister RPCs within a given namespace to a context
REGNMSP(NMSP,CTX,DEL)	;EP
	N RPC,IEN,LEN
	S LEN=$L(NMSP),CTX=+$$GETOPT(CTX)
	I $G(DEL) D
	.S IEN=0
	.F  S IEN=$O(^DIC(19,CTX,"RPC","B",IEN)) Q:'IEN  D
	..I $E($G(^XWB(8994,IEN,0)),1,LEN)=NMSP,$$REGRPC(IEN,CTX,1)
	E  D
	.Q:LEN<2
	.S RPC=NMSP
	.F  D:$L(RPC)  S RPC=$O(^XWB(8994,"B",RPC)) Q:NMSP'=$E(RPC,1,LEN)
	..F IEN=0:0 S IEN=$O(^XWB(8994,"B",RPC,IEN)) Q:'IEN  I $$REGRPC(IEN,.CTX)
	Q
	; Register/unregister an RPC to/from a context
	; RPC = IEN or name of RPC
	; CTX = IEN or name of context
	; DEL = If nonzero, the RPC is unregistered (defaults to 0)
	; Returns -1 if already registered; 0 if failed; 1 if succeeded
REGRPC(RPC,CTX,DEL)	;EP
	S RPC=+$$GETRPC(RPC)
	Q $S(RPC<1:0,1:$$REGMULT(19.05,"RPC",RPC,.CTX,.DEL))
	; Add/remove a context to/from the ITEM multiple of another context.
REGCTX(SRC,DST,DEL)	;EP
	S SRC=+$$GETOPT(SRC)
	Q $S('SRC:0,1:$$REGMULT(19.01,10,SRC,.DST,.DEL))
	; Add/delete an entry to/from a specified OPTION multiple.
	; SFN = Subfile #
	; NOD = Subnode for multiple
	; ITM = Item IEN to add
	; CTX = Option to add to
	; DEL = Delete flag (optional)
REGMULT(SFN,NOD,ITM,CTX,DEL)	;
	N FDA,IEN
	S CTX=+$$GETOPT(CTX)
	S DEL=+$G(DEL)
	S IEN=+$O(^DIC(19,CTX,NOD,"B",ITM,0))
	Q:'IEN=DEL -1
	K ^TMP("DIERR",$J)
	I DEL S FDA(SFN,IEN_","_CTX_",",.01)="@"
	E  S FDA(SFN,"+1,"_CTX_",",.01)=ITM
	D UPDATE^DIE("","FDA")
	S FDA='$D(^TMP("DIERR",$J)) K ^($J)
	Q FDA
	; Register a protocol to an extended action protocol
	; Input: P-Parent protocol
	;        C-Child protocol
REGPROT(P,C,ERR)	;EP
	N IENARY,PIEN,AIEN,FDA
	D
	.I '$L(P)!('$L(C)) S ERR="Missing input parameter" Q
	.S IENARY(1)=$$FIND1^DIC(101,"","",P)
	.S AIEN=$$FIND1^DIC(101,"","",C)
	.I 'IENARY(1)!'AIEN S ERR="Unknown protocol name" Q
	.S FDA(101.01,"?+2,"_IENARY(1)_",",.01)=AIEN
	.D UPDATE^DIE("S","FDA","IENARY","ERR")
	Q:$Q $G(ERR)=""
	Q
	; Remove nonexistent RPCs from context
CLNRPC(CTX)	;EP
	N IEN
	S CTX=+$$GETOPT(CTX)
	F IEN=0:0 S IEN=$O(^DIC(19,CTX,"RPC","B",IEN)) Q:'IEN  D:'$D(^XWB(8994,IEN)) REGRPC(IEN,CTX,1)
	Q
	; Return IEN of option
GETOPT(X)	;EP
	N Y
	Q:X=+X X
	S Y=$$FIND1^DIC(19,"","X",X)
	W:'Y "Cannot find option "_X,!!
	Q Y
	; Return IEN of RPC
GETRPC(X)	;EP
	N Y
	Q:X=+X X
	S Y=$$FIND1^DIC(8994,"","X",X)
	W:'Y "Cannot find RPC "_X,!!
	Q Y
