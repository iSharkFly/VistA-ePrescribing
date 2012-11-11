C0PEWD4	  ; CCDCCR/GPL - ePrescription utilities; 4/24/09 ; 5/8/12 10:23pm
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
	; TEST Lines below not intended for End Users. Programmers only.
	; BEWARE ZWRITE SYNTAX. It may not work in other M Implementations.
gpltest	; experiment with sending a CCR to an ewd page
	N ZI
	S ZI=""
	W "HELLO WORLD!",!
	Q 1
	F  S ZI=$O(^GPL(ZI)) Q:ZI=""  W ^GPL(ZI)
	Q
	;
TESTSSL	;
	s URL="https://preproduction.newcropaccounts.com/InterfaceV7/NewrxFDB.xml"
	D GET1URL(URL) ;
	Q
	;
TEST2	;
	; httpPOST(url,payload,mimeType,html,headerArray,timeout,test,rawResponse,respHeaders,sslHost,sslPort)
	;
	s URL="http://preproduction.newcropaccounts.com/InterfaceV7/Doctor.xml"
	D GET1URL(URL) ;
	s gpl4(2)="<NCScript xmlns=""http://secure.newcropaccounts.com/interfaceV7"""
	s g1="xmlns:NCStandard="
	s g2="""http://secure.newcropaccounts.com/interfaceV7:NCStandard"""
	s gpl4(2)=gpl4(2)_" "_g1_g2
	s gpl4(2)=gpl4(2)_" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"">"
	k gpl4(0) ; array size node
	s gpl4(3)="<Account ID=""demo"">"
	s gpl4(40)="<Location ID=""DEMOLOC1"">"
	s gpl4(28)="<LicensedPrescriber ID=""DEMOLP1"">"
	s gpl4(55)="<Patient ID=""DEMOPT1"">"
	W $$OUTPUT^C0CXPATH("gpl4(1)","NewCropV7-DOCTOR.xml","/home/dev/CCR/"),!
	S ok=$$httpPOST^%zewdGTM("https://preproduction.newcropaccounts.com/InterfaceV7/RxEntry.aspx",.gpl4,"Content-Type: text/html",.gpl6,"","",.gpl5,.gpl7)
	ZWRITE gpl6
	q
	;
TEST3	;
	; httpPOST(url,payload,mimeType,html,headerArray,timeout,test,rawResponse,respHeaders,sslHost,sslPort)
	;
	s URL="http://preproduction.newcropaccounts.com/InterfaceV7/Doctor.xml"
	D GET1URL(URL) ;
	N I,J
	S J=$O(gpl(""),-1) ; count of things in gpl
	F I=1:1:J S gpl(I)=$$CLEAN^C0PEWDU(gpl(I))
	K gpl(0)
	S gpl(1)="RxInput="_gpl(1)
	S url="https://preproduction.newcropaccounts.com/InterfaceV7/RxEntry.aspx"
	W $$OUTPUT^C0CXPATH("gpl(1)","NewCropV7-DOCTOR2.xml","/home/dev/CCR/"),!
	; S ok=$$httpPOST^%zewdGTM("https://preproduction.newcropaccounts.com/InterfaceV7/RxEntry.aspx",.gpl,"application/x-www-form-urlencoded",.gpl6,"","",.gpl5,.gpl7)
	S ok=$$httpPOST^%zewdGTM("https://preproduction.newcropaccounts.com/InterfaceV7/ComposeRX.aspx",.gpl,"application/x-www-form-urlencoded",.gpl6,"","",.gpl5,.gpl7)
	ZWRITE gpl6
	q
	;
TEST	;
	;s URL="https://preproduction.newcropaccounts.com/InterfaceV7/NewrxFDB.xml"
	  ; D GET1URL(URL) ;
	;Q
	S URL="http://preproduction.newcropaccounts.com/InterfaceV7/NCScript-RegisterLP.xml"
	D GET1URL(URL)
	S URL="http://preproduction.newcropaccounts.com/InterfaceV7/GenTestRenewalFDB.xml"
	D GET1URL(URL)
	S URL="http://preproduction.newcropaccounts.com/InterfaceV7/NewrxFDB.xml"
	D GET1URL(URL)
	S URL="http://preproduction.newcropaccounts.com/InterfaceV7/NewrxRxNorm.xml"
	D GET1URL(URL)
	S URL="http://preproduction.newcropaccounts.com/InterfaceV7/NewrxExternalDrugOpt1.xml"
	D GET1URL(URL)
	S URL="http://preproduction.newcropaccounts.com/InterfaceV7/NewrxExternalDrugOpt2.xml"
	D GET1URL(URL)
	S URL="http://preproduction.newcropaccounts.com/InterfaceV7/RenewalResponseAccept.xml"
	D GET1URL(URL)
	S URL="http://preproduction.newcropaccounts.com/InterfaceV7/RenewalResponseDeny.xml"
	D GET1URL(URL)
	Q
	;
GET1URL0(URL)	; 
	s ok=$$httpGET^%zewdGTM(URL,.gpl)
	D INDEX^C0CXPATH("gpl","gpl2")
	W !,"S URL=""",URL,"""",!
	S G=""
	F  S G=$O(gpl2(G)) Q:G=""  D  ;
	. W " S VDX(""",G,""")=""",gpl2(G),"""",!
	W !
	Q
	;
GET1URL(URL)	;
	s ok=$$httpGET^%zewdGTM(URL,.gpl)
	W "XML retrieved from Web Service:",!
	ZWRITE gpl
	D INDEX^C0CXPATH("gpl","gpl2",-1,"gplTEMP")
	W "VDX array displayed as a prototype Mumps routine:",!
	W !,"S URL=""",URL,"""",!
	S G=""
	F  S G=$O(gpl2(G)) Q:G=""  D  ;
	. W " S VDX(""",G,""")=""",gpl2(G),"""",!
	W !
	D VDX2XPG^C0CXPATH("gpl3","gpl2")
	W "Conversion of VDX array to XPG format:",!
	ZWRITE gpl3
	W "Conversion of XPG array to XML:",!
	D XPG2XML^C0CXPATH("gpl4","gpl3")
	ZWRITE gpl4
	Q
	;
