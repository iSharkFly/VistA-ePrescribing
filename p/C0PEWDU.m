C0PEWDU	; WV/SMH - E-prescription utilities; Mar 3 2009
 ;;0.1;WV EPrescribing;;
 Q
 ;
CLEAN(STR) ; extrinsic function; returns string
 ;; Removes all non printable characters from a string.
 ;; STR by Value
 N TR,I
 F I=0:1:31 S TR=$G(TR)_$C(I)
 S TR=TR_$C(127)
 QUIT $TR(STR,TR)
 ;
GETSOAP(ENTRY,REQUEST,RESULT) ; XML SOAP Spec for NewCrop
 ;; Gets world processing field from Fileman for Parsing
 ;; ENTRY Input by Value
 ;; REQUEST XML Output by Reference
 ;; RESULT XML Output by Reference
 ;; Example call: D GETSOAP^C0PEWDU("DrugAllergyInteraction",.REQ,.RES)
 ;
 N OK,ERR,IEN,F  ; if call is okay, Error, IEN, File
 S F=175.101
 S IEN=$$FIND1^DIC(F,"","",ENTRY,"B")
 S OK=$$GET1^DIQ(F,IEN,2,"","REQUEST","ERR")
 I OK=""!($D(ERR)) S REQUEST=""
 ; M ^CacheTempEWD($j)=REQUEST
 ; K REQUEST
 ; S ok=$$parseDocument^%zewdHTMLParser("REQUEST",0)
 ; S ok=$$outputDOM^%zewdDOM("REQUEST",1,1)
 ; Q  ; remove later
 K OK,ERR
 S OK=$$GET1^DIQ(F,IEN,3,"","RESULT","ERR")
 I OK=""!($D(ERR)) S RESULT=""
 QUIT
 ;
