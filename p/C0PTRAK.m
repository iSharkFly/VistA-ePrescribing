C0PTRAK	  ;KBAZ/ZAG/GPL - eRx debugging utilities; 4/1/2012 ; 5/8/12 5:12pm
	;;1.0;C0P;;Apr 25, 2012;Build 84
	;Copyright 2012 George Lilly.  Licensed under the terms of the GNU
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
	QUIT  ;do not call from the top
	;
	;INTRP(JOB) ;send interrupt to an interactive job.
	;
LOG(JOB,TAG)	;send interrupt and log results
	;copied from ZJOB to here for silently interrupting one job.
	N $ET,$ES S $ET="D IRTERR^ZJOB"
	; shouldn't interrupt ourself, but commented out to test
	;I JOB=$JOB Q 0
	;We need a LOCK to guarantee commands from two processes don't conflict
	N X,OLDINTRPT,TMP,ZSYSCMD,ZPATH,%J
	L +^XUTL("XUSYS","COMMAND"):10 Q:'$T 0
	;
	S ^XUTL("XUSYS","COMMAND")="EXAM",^("COMMAND",0)=$J_":"_$H
	K ^XUTL("XUSYS",JOB,"JE")
	S OLDINTRP=$ZINTERRUPT,%J=$J
	S TMP=0,$ZINTERRUPT="S TMP=1"
	;
	;convert PID for VMS systems
	I $ZV["VMS" D
	. S JOB=$$FUNC^%DH(JOB,8)
	. S %J=$$FUNC^%DH(%J,8)
	;
	S ZSYSCMD="mupip intrpt "_JOB_" > /dev/null 2>&1" ; interrupt other job
	I $ZV["VMS" S ZPATH="@gtm$dist:"  ; VMS path
	E  S ZPATH="$gtm_dist/" ;Unix path
	ZSYSTEM ZPATH_ZSYSCMD ; System Request
	;Now send to self
	; wait is too long 60>>30
	H 1 S TMP=1 ; wait for interrupt, will set TMP=1
	;
	; Restore old $ZINTERRPT
	S $ZINTERRUPT=OLDINTRP
	K ^XUTL("XUSYS","COMMAND") ;Cleanup
	L -^XUTL("XUSYS","COMMAND")
	;get values to report back on
	K ^TMP("C0PERXLOG",JOB)
	M ^TMP("C0PERXLOG",JOB)=^XUTL("XUSYS",JOB) ;merge off array for reporting
	S ^TMP("C0PERXLOG",JOB,"LOGPOINT")=$G(TAG)
	;
	;D LOG(JOB) ;create the C0PLOG
	;K ^C0PTRAK(JOB) ;clean up temp log
	;
	QUIT  ;end of INTRP
	;
NEWLOG(JOB,TAG)	;report on JOB interrupted
	; TAG identifies the location creating the log. it is text
	K ^C0PLOG(JOB)
	N VARLOG ;build variable log array for further inspection
	N VARTYP S VARTYP=""
	F  D  Q:VARTYP=""
	. S VARTYP=$O(^KBAZ(JOB,VARTYP)) ;type of variable
	. Q:VARTYP=""  ;exit if no more variable are types found
	. N VARCNT S VARCNT=""
	. F  D  Q:'VARCNT
	. . S VARCNT=$O(^KBAZ(JOB,VARTYP,VARCNT)) ;variable count
	. . Q:'VARCNT  ;exit if no more variables are found
	. . N VAR S VAR=$G(^KBAZ(JOB,VARTYP,VARCNT)) ;get the variable
	. . N VARNM S VARNM=$P(VAR,"=") ;variable name
	. . N VARIABLE S VARIABLE=$P(VAR,"=",2)
	. . S VARIABLE=$TR(VARIABLE,"""") ;remove the extra quotes
	. . S VARLOG(VARNM)=VARIABLE ;variable
	. . N %H S %H=$G(VARLOG("$HOROLOG")) ;current $H
	. . N PC S PC=$G(VARLOG("IO(""CLNM"")")) ;pc/client name
	. . N IP S IP=$G(VARLOG("IO(""GTM-IP"")")) ;pc/client IP address
	. . N USER S USER=$G(VARLOG("DUZ")) ;current user
	. . N CURPAT S CURPAT=$G(VARLOG("VALUE(2)")) ;current patient
	. . ;
	. . ;build the final log
	. . S ^TMP("C0PERXLOG",JOB,"LOGPOINT")=$G(TAG)
	. . S ^TMP("C0PERXLOG",JOB,"TIME")=$$HTE^XLFDT(%H)
	. . S ^TMP("C0PERXLOG",JOB,"CLNM")=PC
	. . S ^TMP("C0PERXLOG",JOB,"IP")=IP
	. . S ^TMP("C0PERXLOG",JOB,"DUZ")=USER
	. . S ^TMP("C0PERXLOG",JOB,"PT")=CURPAT
	;
	QUIT  ;end of LOG
	;
	;
UNLOG(JOB)	; clean up a log entry
	K ^TMP("C0PERXLOG",JOB)
	Q
	;
RUNAWAY	; called from Batch to kill runaway eRx jobs
	; looks at every entry in the table looking for marked jobs to kill
	; if a job is not marked, it will mark it so that next time it 
	; will be killed. 
	; This insures that jobs logged to the table have at least 15 minutes
	; to unlog or they will be killed. 
	; this is implemented to catch and kill runaway eRX webservice calls
	; uses STOP^XVJK($JOB) written by Zach Gonzales to kill jobs in GT.M linux
	; gpl 4/18/2012
	;
	N GN,ZI
	S GN=$NA(^TMP("C0PERXLOG"))
	S GNOLD=$NA(^TMP("C0POLDLOG"))
	S ZI=""
	F  S ZI=$O(@GN@(ZI)) Q:+ZI=0  D  ; for every entry in the table
	. I $D(@GN@(ZI,"KILLED")) Q  ; job already killed
	. I $D(@GN@(ZI,"MARKED")) D  Q  ; found a job to kill then quit
	. . D STOP^XVJK(ZI) ; kill the job
	. . S @GN@(ZI,"KILLED")=$$NOW^XLFDT ; record the kill
	. . S @GN@(ZI,"KILLEDBY")=DUZ
	. . M @GNOLD@(ZI,$H)=@GN@(ZI)
	. . K @GN@(ZI)
	. S @GN@(ZI,"MARKED")=$$NOW^XLFDT ; mark for a kill next time
	Q
	;
EOR	;end of C0PTRAK
