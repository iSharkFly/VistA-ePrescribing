C0PEWD2   ; CCDCCR/GPL - ePrescription utilities; 4/24/09
 ;;0.1;CCDCCR;nopatch;noreleasedate
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
TEST ;
 s URL="https://preproduction.newcropaccounts.com/InterfaceV7/NewrxFDB.xml"
 D GET1URL(URL) ;
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
GET1URL(URL) ; 
 s ok=$$httpGET^%zewdGTM(URL,.gpl)
 D INDEX^C0CXPATH("gpl","gpl2")
 W !,"S URL=""",URL,"""",!
 S G=""
 F  S G=$O(gpl2(G)) Q:G=""  D  ;
 . W " S VDX(""",G,""")=""",gpl2(G),"""",!
 W !
 Q
 ;
