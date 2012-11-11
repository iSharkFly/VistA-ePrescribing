C0PEWDU	; WV/SMH - E-prescription utilities; Mar 3 2009 ; 5/4/12 4:25pm
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
	;
	Q
	;
CLEAN(STR)	; extrinsic function; returns string
	;; Removes all non printable characters from a string.
	;; STR by Value
	N TR,I
	F I=0:1:31 S TR=$G(TR)_$C(I)
	S TR=TR_$C(127)
	QUIT $TR(STR,TR)
	;
GETSOAP(ENTRY,REQUEST,RESULT)	; XML SOAP Spec for NewCrop
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
