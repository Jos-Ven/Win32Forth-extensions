[DEFINED] -ComList.f  [IF]  100 ms bye [then]

\ March 13th, 2010
\ By J.v.d.Ven for Win32forth version 6.15
\ To list usable guids, interfaces and methods from the registry to Interfaces.txt

aNew -ComList.f

Needs toolset.f
Needs fcomPatch.f \ Only added NoPeek to make this work.

also hidden

: OpenRegKey ( hkey$ adr len -- Hndl )
    asciiz KEY_READ (RegOpenKey)
    dup INVALID_HANDLE_VALUE = abort" Can't open key."
 ;

create TypeLib$ ," TypeLib"

: OpenTypeLibReg ( hkey$ - Hndl ) TypeLib$  count OpenRegKey  ;

\ 0 value dwIndex	   \ index of subkey to enumerate
string: lpName	           \ address of buffer for subkey name
variable lpcbName	   \ address for size of subkey buffer
variable lpReserved	   \ reserved
string: lpClass	           \ address of buffer for class string
variable lpcbClass         \ address for size of class buffer
string: lpftLastWriteTime  \ address for time key last written to


: EnumKey (  hkey dwIndex -- ior )
  maxcounted lpcbName !  maxcounted lpcbClass !
   2>r lpftLastWriteTime  lpcbClass  lpClass  lpReserved @
   lpcbName lpName 2r> swap
   call RegEnumKeyEx
 ;

: +temp$ ( adr cnt -- ) temp$ +place ;

: OpenNextSubKey  ( adr cnt -- hndl )
   TypeLib$ count temp$ place s" \" +temp$ +temp$
   HKEY_CLASSES_ROOT temp$ count
     OpenRegKey
 ;

: _typelib  { guid$ cnt -- } ( major minor guid$ cnt -- f ) \ load a type library into the list
   here typelibhead dup @ , !
  here dup >r 0 , here 0 , 2swap swap here
  guid$ cnt  (Guid,) LoadRegTypeLib
  if   r>drop false
  else r> dup cell+ swap UCOM ITypeLib GetTypeComp abort" Error Getting TypeComp"
       true
  then
;

: VersionNumber ( adr len - n )
  (number?)
     if     d>s
     else   2drop 0
     then
 ;

: FindVersion ( adr len - major minor ) \ 0 0 = No version
   2dup ascii . scan  2>r r@ - VersionNumber
   2r> 1 /string VersionNumber
 ;

: HighestVersion 0 0  { major minor } ( adr cnt -- major minor )
   OpenNextSubKey -1
       begin  1+ 2dup EnumKey ERROR_SUCCESS =
       while  lpName lpcbName @ FindVersion
              over major >
                if     to minor to major
                else  over  major =
                       if   dup minor >
                            if   to minor to major
                            else  2drop
                            then
                       else 2drop
                       then
                then
       repeat
   drop (RegCloseKey) drop
   major minor
 ;

string: guid$

: write$  ( adr cnt fid - ) write-file abort" write error" ;

: WriteGuid  ( fid adr cnt -- ) \ writes only a valid guid to a file
   2dup guid$ place HighestVersion 2dup guid$  count _typelib
    if   rot >r guid$ count r@  write$
        swap s>d (d.) r@ write$
        s" ." r@ write$
        s>d (d.) r@ write$
        crlf$ count r> write$
   else 3drop
   then
 ;

38 constant /guid

: WriteGuids ( - )
   s" guids.txt" r/w create-file abort" Can't create file"
   HKEY_CLASSES_ROOT OpenTypeLibReg -1
       begin  1+ 2dup EnumKey ERROR_SUCCESS =
       while  2 pick lpName lpcbName @ WriteGuid
       repeat
   drop (RegCloseKey) drop
  close-file abort" close error"
  cr cr ." compile ComList.f again and terminate the hanging proces" cr
  7 pause-seconds  Bye
 ;

: .Documentation
   true to NoPeek
     >ascii 2dup cr type cr 0 ?typelib drop
   false to NoPeek
 ;

: GlobalListInterfaces ( type typelib -- )
  dup UCOM ITypeLib GetTypeInfoCount 0 ?do
    2dup tbuf i rot UCOM ITypeLib GetTypeInfoType abort" Unable to get type info"
    tbuf @ = if dup 0 0 rot 0 tbuf rot i swap UCOM ITypeLib GetDocumentation
      abort" Unable to get Documentation!"  tbuf @ zunicount
      .Documentation
    then
  loop   2drop ;


: GlobalDispathes ( type typelib -- )
  dup UCOM ITypeLib GetTypeInfoCount 0 ?do
    2dup tbuf i rot UCOM ITypeLib GetTypeInfoType abort" Unable to get type info"
    tbuf @ = if dup 0 0 rot 0 tbuf rot i swap UCOM ITypeLib GetDocumentation
      abort" Unable to get Documentation!" tbuf @ zunicount
  >ascii dup ?cr type tab
    then
  loop 2drop ;

: ListInterfaces  ( -- ) \ print a list of all available interfaces
  typelibhead begin @ dup while
  dup cell+ TKIND_INTERFACE swap GlobalListInterfaces
  dup cell+ TKIND_DISPATCH swap cr ." Dispathes:" cr GlobalDispathes
 repeat drop ;

: .typelib  ( adr cnt - )
    2dup /guid  /string FindVersion
    2swap drop /guid _typelib drop
        cr ." Interfaces:"  ListInterfaces
     cr cr ." CoClasses:"   CoClasses
     cr cr ." Structures:"  Structures
     free-lasttypelib
 ;

: InterfacesWithProblems  ( adr cnt -- adr cnt flag )
\ Under the v\Vista
       2dup  s" {A020BDC2-1562-11D4-80BB-0050DA1C04B5}1.0" istr=
    >r 2dup  s" {C17E7E12-9C20-4B9C-A225-F79292C58BC9}1.0" istr= r> or
    >r 2dup  s" {E0138278-3E57-44E2-AB64-B0A3B9C56CDE}1.0" istr= r> or
    >r 2dup  s" {E8B06F53-6D01-11D2-AA7D-00C04F990343}1.0" istr= r> or
\ under XP
    >r 2dup  s" {3147B9F7-D11F-11D4-AB83-00B0D02332EB}1.0" istr= r> or
    >r 2dup  s" {27D2CF3C-D5B0-11D2-8094-00104B1F9838}1.0" istr= r> or
    >r 2dup  s" {682C25C5-D7D9-11D2-80C5-00104B1F6CEA}1.0" istr= r> or
    >r 2dup  s" {777C89DE-5C36-11D5-ABAF-00B0D02332EB}1.0" istr= r> or
    >r 2dup  s" {777C8A14-5C36-11D5-ABAF-00B0D02332EB}1.0" istr= r> or
    >r 2dup  s" {91814EB1-B5F0-11D2-80B9-00104B1F6CEA}1.0" istr= r> or
    >r 2dup  s" {DED1EA29-3F89-11D3-BBB9-00105A1F0D68}1.0" istr= r> or
 ;

0 value /temp$

: List  ( - )
    time-reset
    s" guids.txt" r/w open-file
       abort" guids.txt is missing use WriteGuids first and restart Forth."
    s" Interfaces.txt" drop-count file
    .id-user
    cr .time-stamp cr

      begin  temp$ maxcounted 2 pick read-line abort" read error"
      while  temp$ swap dup to /temp$ 2dup cr cr type
             InterfacesWithProblems
                if    cr ." Interfaces can not be analyzed:" cr 2drop
                else  .typelib
                then
      repeat
    cr cr ." End of list." cr .elapsed
     eof
    drop close-file  drop abort \ Abort is for XP
 ;

: .LastGuid  ( - )  temp$ /temp$ cr type cr ;

cr cr

.( First use WRITEGUIDS to extract guids that can be opened.) cr
.( Compile ComList.f again since LoadRegTypeLib can crash/dammage Win32Forth.) cr
.( Then use LIST to extract guids, interfaces and methods to the file: Interfaces.txt.) cr
.( .LastGuid displays the last used guid.) cr
.( Somehow it seems all except 11 of the extracted guids can be handled this way.) cr cr

.( When you get an error and open Interfaces.txt and try to ) cr
.( see the methods of the last interface using the 'Words' command than it will also crash. ) cr
.( No idea how to solve it yet.) cr
.( When it is solved the content of Interfaces.txt could be extended ) cr
.( and put in a treeview for searching and inserting COM interfaces and methods in a source. ) cr
cr

\ Jos
