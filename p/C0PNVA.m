C0PNVA	; VEN/SMH - Non-VA Meds Utilities for e-Rx ; 5/8/12 4:32pm
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
FILE(C0PDFN,OR,DRUG,DOSAGE,ROUTE,SCHEDULE,START,C0PDUZ,COMMENT)	; Private Proc - File NVA
	; Input:
	; - C0PDFN: Patient DFN
	; - OR: Pharmacy Orderable Item IEN
	; - DRUG: Drug IEN
	; - DOSAGE: Free Text Dosage
	; - ROUTE: Free Text Route
	; - SCHEDULE: Free Text Schedule
	; - START: Start date in Timson Format
	; - C0PDUZ: Provider documenting NVA DUZ
	; - COMMENT: Free Text Comment
	; NOTE: Right now, does nothing to file in CPRS order file.
	;
	D CLEAN^DILF ; Kill DIERR etc
	; First Create parent file entry if it already doesn't exist
	; 
	; We will handle the case where there are subfile entries but no
	; zero node defined for the record. First, check to see if there is 
	; anything there at all for this patient
	;
	N C0PEXIT S C0PEXIT=0 ; in case of errors
	I '$D(^PS(55,C0PDFN)) D  Q:C0PEXIT  ; if nothing is there for this patient
	. N C0PFDAPT
	. N C0PPTIEN S C0PPTIEN(1)=C0PDFN ; bug? in Update-doesn't honor DINUM
	. S C0PFDAPT(55,"+1,",.01)=C0PDFN
	. D UPDATE^DIE("","C0PFDAPT","C0PPTIEN")
	. I $G(DIERR) D ^%ZTER,CLEAN^DILF S C0PEXIT=1 Q  ; log error and signal q
	E  I '$D(^PS(55,C0PDFN,0)) D  ; is there something there but not a zero node?
	. S ^PS(55,C0PDFN,0)=C0PDFN ; set the zero node
	. N DIK,DA
	. S DIK="^PS(55,"
	. S DA=C0PDFN
	. S DIK(1)=".01"
	. D EN^DIK ; cross reference the .01 field
	;
	N C0PFDA
	N C0PIENS ; Return value of IEN in the NVA multiple in file 55
	;
	; gpl. first, create the NVA subfile if none exists
	; these lines were copied from PSONVNEW, which creates non-VA meds
	N ZIEN ; CREATING A NEW ENTRY, THE FIRST FOR THIS PATIENT
	I '$D(^PS(55,C0PDFN,"NVA",0)) D  ; NO NVA SUBFILE
	. S DFN=C0PDFN
	. S DA(1)=DFN
	. S X=OR
	. S DR="1////"_DRUG
	. S DIC("DR")=DR,DIC(0)="L",DIC="^PS(55,"_DFN_",""NVA"",",DLAYGO=55.05
	. D FILE^DICN S ZIEN=+Y K DR,DIC,DD,DA,DO,DINUM
	. ; I don't know why the following doesn't work
	. ;S C0PFDA(55.05,"+1,"_C0PDFN_",",.01)=OR
	. ;D UPDATE^DIE("","C0PFDA","C0PIENS")
	. ;I $G(DIERR) D ^%ZTER QUIT  ; log error if update fails
	. ;E  D  ; find the ien of the subfile
	. S ZIEN=$O(^PS(55,C0PDFN,"NVA","B",OR,""))
	. I ZIEN="" S ZIEN=1
	. ;
	. S C0PFDA(55.05,"?+"_ZIEN_","_C0PDFN_",",.01)=OR
	. S C0PFDA(55.05,"?+"_ZIEN_","_C0PDFN_",",1)=DRUG
	. S C0PFDA(55.05,"?+"_ZIEN_","_C0PDFN_",",2)=$E(DOSAGE,1,80) ; 80 char max
	. S C0PFDA(55.05,"?+"_ZIEN_","_C0PDFN_",",3)=$E(ROUTE,1,40)
	. S C0PFDA(55.05,"?+"_ZIEN_","_C0PDFN_",",4)=$E(SCHEDULE,1,50)
	. S C0PFDA(55.05,"?+"_ZIEN_","_C0PDFN_",",8)=START ; Start Date
	. S C0PFDA(55.05,"?+"_ZIEN_","_C0PDFN_",",11)=$$NOW^XLFDT()  ; Documentated Date
	. S C0PFDA(55.05,"?+"_ZIEN_","_C0PDFN_",",12)=C0PDUZ
	. ;
	. D UPDATE^DIE("","C0PFDA","C0PIENS")
	. I $G(DIERR) D ^%ZTER QUIT  ; log error if update fails
	. ;
	. D CLEAN^DILF ; Kill DIERR etc.
	. ; File WP field
	. N C0PWP ; comment is multi line
	. M C0PWP=COMMENT
	. ;D WP^DIE(55.05,C0PIENS(1)_","_C0PDFN_",",14,"","C0PWP")
	. D WP^DIE(55.05,C0PIENS(ZIEN)_","_C0PDFN_",",14,"","C0PWP")
	. I $G(DIERR) D ^%ZTER QUIT  ; log error if wp filling fails.
	E  D  ; CREATING A NEW ENTRY, NOT THE FIRST
	. S ZIEN=1 ; GOING TO USE +1 CONVENTION
	. S C0PFDA(55.05,"+"_ZIEN_","_C0PDFN_",",.01)=OR
	. S C0PFDA(55.05,"+"_ZIEN_","_C0PDFN_",",1)=DRUG
	. S C0PFDA(55.05,"+"_ZIEN_","_C0PDFN_",",2)=$E(DOSAGE,1,80) ; 80 char max
	. S C0PFDA(55.05,"+"_ZIEN_","_C0PDFN_",",3)=$E(ROUTE,1,40)
	. S C0PFDA(55.05,"+"_ZIEN_","_C0PDFN_",",4)=$E(SCHEDULE,1,50)
	. S C0PFDA(55.05,"+"_ZIEN_","_C0PDFN_",",8)=START ; Start Date
	. S C0PFDA(55.05,"+"_ZIEN_","_C0PDFN_",",11)=$$NOW^XLFDT()  ; Documentated Date
	. S C0PFDA(55.05,"+"_ZIEN_","_C0PDFN_",",12)=C0PDUZ
	. ;
	. D UPDATE^DIE("","C0PFDA","C0PIENS")
	. ;I $D(GPLTEST) B  ;
	. I $G(DIERR) D ^%ZTER QUIT  ; log error if update fails
	. ;
	. D CLEAN^DILF ; Kill DIERR etc.
	. ; File WP field
	. N C0PWP ;S C0PWP(1)=COMMENT
	. M C0PWP=COMMENT ; comment is passed by reference and has multiple lines
	. ;D WP^DIE(55.05,C0PIENS(1)_","_C0PDFN_",",14,"","C0PWP")
	. D WP^DIE(55.05,C0PIENS(ZIEN)_","_C0PDFN_",",14,"","C0PWP")
	. I $G(DIERR) D ^%ZTER QUIT  ; log error if wp filling fails.
	QUIT
	;
DC(C0PDFN,NVAIEN)	; Private Procedure - D/C Non-VA Med
	; Input:
	; C0PDFN - you should know what this is by now
	; NVAIEN - IEN of Non-VA in the non-VA subfile in file 55
	; Output:
	; None
	; Notes: Does not involve order file right now...
	I $G(^TMP("C0PNODISC")) Q  ; DO NOT DISCONTINUE DRUGS SWITCH
	; FOR TESTING NEW CROP - MAINTAINS VISTA DRUGS
	D CLEAN^DILF ; Kill DIERR etc
	N C0PFDA
	S C0PFDA(55.05,NVAIEN_","_C0PDFN_",",5)=1 ; Status = discontinued
	S C0PFDA(55.05,NVAIEN_","_C0PDFN_",",6)=$$NOW^XLFDT() ; discontinued date
	D UPDATE^DIE("","C0PFDA")
	I $G(DIERR) D ^%ZTER QUIT
	QUIT
