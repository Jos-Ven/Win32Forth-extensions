\  Toolset.f by J.v.d.Ven.  ( http://home.planet.nl/~josv )
\  Needed compiler Win32forth version 6.14 or better.
\  Objective: extend Win32forth with my old fashion tools from
\             former and other Forth systems. ( 1802 ELFII + Atari ST )
\             Many definitions are created as a work around for the
\             missing definitions.
\             Perhaps you will hate it. That's ok
\
\

\ Modifications: in this version:
\ Removed a bug from fvalue-to-string-and-count

\ Additions are made at the end.
.( Releasedate: June 15th, 2012 )



s" Win32Forth" environment? not [if]  cr
.( Needs Win32Forth version 6.14 or better.) abort  [then]  drop

INTERNAL WinLibrary WINMM.DLL EXTERNAL PREVIOUS


decimal

anew toolset.f

\ help-file E:\win32api_hlp\WIN32.HLP

8  constant bs                  13 constant carret
10 constant linefeed            10 constant lf
27 constant escape              34 constant quote

: all-warnings-off ( -- )  dpr-warning-off  sys-warning-off warning off ;
: all-warnings-on  ( -- )  dpr-warning-on  sys-warning-on warning on    ;

\ ** all-warnings-off

synonym read         r/o        synonym write   r/w
synonym erase-screen cls        synonym ?ms     ms@
(( synonym d         dir ))     synonym >>>     noop
synonym PRIVATES     noop
\ synonym Private:   noop       synonym Public: noop
synonym DEPRIVE      noop       synonym ;P      ;
synonym ESC          escape     synonym choose  random
synonym s            r@         synonym >s      >r
synonym s>           r>         synonym =:      constant
synonym -s           r>drop     synonym lo      bye

defined  &local nip not [IF]
synonym &local       &of
[THEN]

\ ' \ alias **
\ ' beep alias ** \ 8-5-2009 Disabled, ** became another definition

in-system

in-application

: reversed      ( - )            16777215 1 fgbg! ;
: normal        ( - )            1 -1 fgbg! ;
: .forth        ( - )            ." Forth" ;
: .ok           ( - )            ."  ok" ;
: bin           ( - )            2 base !  ;
: missing       ( - )            abort" missing"  ;
: always        ( flag - true )  drop true  ;
\ : never         ( flag - false ) drop false ;
: .cr           ( n - )           . cr ;
: 0<=           ( - flag )       0 <= ;
: 0>=           ( - flag )       0 >= ;
\in-system-ok : tp            ( - )            .s key escape  =  if abort  then cr ;
\in-system-ok : ftp           ( - )            f.s key escape =  if abort  then cr ;

\ D@ is 'natural 64-bit fetch' and is comparable to 2@ SWAP
: d@            ( - d1_natural_64-bit ) 2@ swap ;

: @+            ( adr -- adr n ) dup cell+ swap @ ;
: 2+            ( n - n+2 )      2 + ;
: 1+!           ( adr - )        1 swap +! ;
: 1-!           ( adr - )       -1 swap +! ;
: 4*            ( n - 4*n )      4 * ;

also hidden

\in-system-ok : (cls   ( - )     c_cls  space 0 0  AT-XY ;

' (cls is cls

previous

\ : -dup  ( n1 n2    - n1 n1 n2 )    >r dup r>  ;
: -over ( n1 n2 n3 - n1 n2 n1 n3 ) >r over r> ;
: -swap ( n1 n2 n3 - n2 n1 n3 )    >r swap r> ;

defer printfile
\in-system-ok : $ftype count "ftype ;
\ ' $ftype is printfile
 ' $fprint is printfile

defer abort/bye
 ' abort is abort/bye
\ ' bye is abort/bye

: Error-StopBox   { adr len \ message$ -- }  ( nfa adr len - )
     MAXSTRING localAlloc: message$
      s" at " message$ place
      0 base @ -rot hex (d.) message$ +place base !
      s" \n" message$ +place
      adr len message$ +place
      message$ +NULL
      MB_OK MB_ICONSTOP  or
      MB_TASKMODAL or
      z" Error:"
      message$ 1+
      NULL call MessageBox drop
 ;

: _bye"   ( flag nfa- )
    swap
       if   cr ((")) count Error-StopBox abort/bye
       else ((")) 2drop
       then
;

: bye"   ( -<string">- )
   last @ name> postpone lit compile,
   compile _bye"  ,"  ; immediate


\ : test  true bye" Some error " ;  test

 -2 constant THROW_ABORTQ

: _XMESSAGE      ( n -- )
                r@ here ! BASE @ >R DECIMAL
                CR ." Error in: "
                POCKET COUNT TYPE SPACE
                DUP THROW_ABORTQ =
                IF      DROP MSG @ COUNT TYPE
                ELSE    ." Error # " .
                THEN
                LOADING?
                IF      BASE @ >R DECIMAL
                        CR ." File: "
                        LOADFILE @ CELL+ COUNT TYPE
                        ."  at line: "
                        LOADLINE ?
                        R> BASE !
                        EDIT-ERROR
                THEN
                R> BASE ! ;

((  ' _XMESSAGE IS MESSAGE
variable at-word
: (ABORT")      ( f -- )
                \ _.rstack
                2r@  at-word ! drop ((")) SWAP
                IF      MSG !
                        THROW_ABORTQ THROW
                THEN    DROP ;

: ABORT"        ( -- )
                COMPILE (ABORT")  ,"  ; IMMEDIATE

: wrong            ( n - 4*n )     1 abort" xxx" ;
: test  wrong noop ;

: test2 test ;
 test2 \ ))

: here!         ( n - )         here ! ;
: here@         ( - n )         here @ ;
: pad!          ( n - )         pad ! ;
: pad@          ( - n )         pad @ ;

: (u.           ( - )           0 (d.) type ;
: u.td          ( n - )         base @ swap decimal (u. base ! ;
: u.th          ( n - )         base @ swap hex (u. base ! ;
: u.tb          ( n - )         base @ swap bin (u. base ! ;
: .dot          ( - )           ." ." ;
: u,.           ( n - )         14 u,.r ;
: ?u,.          ( adr - )       @ u,.   ;
: ?u,.cr        ( adr - )       ?u,. cr ;
synonym dec.    u.td

\ code abs@ ( absolute-adres - n )
\       mov  eax , ebx            \ dst src
\       mov  ebx , [eax]
\    next  c;

in-system

all-warnings-off
: absdump ( from to  - )
   cr  1+ 0
      do   i cells+ dup u.th ." .. "  dup abs@ u.th tab
           i 8 /mod drop 0=
             if   cr   then
      loop
   drop
 ;
all-warnings-on

in-previous

\ 1234 here ! here  10 absdump abort

\ radians = degress x PI / 180 (deg to rad conversion)
\ degress = radians x 180 / PI (rad to deg conversion)

: frad   ( fs: deg - rad )    fpi f* 180 s>f f/  ;

synonym local  to   \ NOTE define the local as value before using local
synonym pi     fpi

0 value is-static?

variable HIDDEN_SET        \ HIDDEN_SET Off
\ variable Private_Used      Private_Used Off
\ variable OLD_CURRENT       0 OLD_CURRENT !


: wnum?         ( - d flag )      bl word uppercase count number? not ;

: tb            ( n - )
   base @  >r  bin  wnum?
   abort" <- Not a binary number" drop state @
\in-system-ok if      [compile] literal
              then    r>  base !
 ; immediate

: th            ( n - )
   base @  >r  hex wnum?
   abort" <- Not a hex number" drop state @
\in-system-ok  if      [compile] literal
               then    r>  base !
 ; immediate

: td            ( n - )
   base @  >r  decimal wnum?
   abort" <- Not a decimal number" drop state @
\in-system-ok  if      [compile] literal
               then    r>  base !
 ; immediate

th A0005 constant K_SHIFT_RIGHT
th A0004 constant K_SHIFT_LEFT
th A0007 constant K_SHIFT_DOWN
th A0006 constant K_SHIFT_UP

: activate-bit ( bit# - n+bit )        1 swap lshift ;

: bit@         ( n bit# - bit )         activate-bit and ;
' bit@ alias bit-active?
: test-bit     ( n bit# - true/false )  bit@ 0<>  ;

: bit!  ( n 1/0 bit# - n-bit! )      \ puts a bit ( 1/0 ) in n
   dup activate-bit rot
       if   rot or nip               \ 1 ( 1 1-bit# - 1-bit )
       else drop over swap bit@ dup
            if   -                   \ 3 ( 0 1-bit# - 0-bit )
            else drop                \ 2 ( 0 0-bit# - 0-bit )
            then
       then
 ;

: #active-bits  ( n - #active-bits )
   0 32 0
     do  over i bit@ 0> swap +
     loop
   nip abs
 ;

\ -1 1 2 bit!  abort \ 1 x
\  tb 11111  0 3  bit!  abort \ 0 1
\  tb 10011  0 2  bit!  abort \ 0 0

: 'of   ( -<name>- )
\in-system-ok     ' [compile] >body postpone literal ; immediate

: SIMPEL_ARRAY
    CREATE  ( n -- )   ALLOT
    DOES>   ( u -- c-addr ) ;

: cell-array
   create 1+ cell * allot   \ compiletime: ( max-cells - )
   does> swap cells+ @ ;    \ runtime:     ( which - value )

: adres-cell-array ( 'cell-array - cell-0 )
   cell+  ;

: array!    ( n  which 'cell-array  - )
    swap 1+ cells+ ! ;

: array+!    ( n which 'cell-array  - )
    swap 1+ cells+ +! ;


: to-cell
   state @                            \ compiletime: ( -<name_cell-array>- )
\in-system-ok if   postpone [']  compile array! \ compiles: 'name_cell-array array!
              else ' array!           \ runtime:  ( n which <name_cell-array> - )
              then  ; immediate

: +to-cell
   state @                             \ compiletime: ( -<name_cell-array>- )
\in-system-ok if   postpone [']  compile array+! \ compiles: 'name_cell-array array!
              else ' array+!           \ runtime:  ( n which <name_cell-array> - )
              then  ; immediate

: least-used ( from n-cells 'cell-array - least )
   here! over dup here@ execute  swap pad ! 3reverse 2dup - 1 >
        if  do
                i here@ execute 2dup <=
                  if   drop
                  else swap drop i pad !
                  then
             loop
        else   2drop
        then   drop pad @
  ;

in-system

: cadump ( from to 'name-cell-array - )
   cr -rot 1+ swap
      do   i dup s>d (d.) type ." .." over execute . tab
           i 8 /mod drop 0=
             if   cr   then
      loop
   drop
 ;

in-previous

: farray
  create 1+  floats allot     \ compiletime: ( max-cells - )
  does> swap floats + f@ ;    \ runtime:     ( which - value )

: farray!     ( f: n - ) ( which 'farray  - )
    swap floats + cell+ f! ;

: farray+!    ( f: n - ) (  which 'farray  - )
    swap floats + cell+  f+! ;

: fto-cell
   state @                         \ compiletime: ( -<name_cell-array>- )
\in-system-ok if   postpone [']  compile farray! \ compiles:    'name_cell-array array!
              else ' farray!       \ runtime: ( f: n - ) (  which <name_cell-array> - )
              then  ; immediate

: +fto-cell
   state @                        \ compiletime: ( -<name_cell-array>- )
\in-system-ok if   postpone ['] compile farray+! \ compiles:    'name_cell-array array!
              else ' farray+!     \ runtime:  ( f: n - ) ( n which <name_cell-array> - )
              then  ; immediate

in-system

: fadump ( from to 'name-cell-array - )
   cr -rot 1+ swap
      do   i dup s>d (d.) type ." .." over execute f. tab
           i 8 /mod drop 0=
             if   cr   then
      loop
   drop
 ;

in-previous

\ 10 farray ftest
\ 1e 1 fto-cell ftest 2e 2 fto-cell ftest
\ 3e 3 fto-cell ftest 10e 10 fto-cell ftest
\ 0 10 ' ftest fadump  abort

defer y/n?

: _y/n?          ( - true | false )  \ y | n
   ."  [y/n] " key upc ascii Y = dup
        if      ." Yes " else ." No "
        then
 ;

' _y/n? is y/n?

defer .any-key

: _.any-key       ( - )
  ." Press any key to continue......." key drop ;

' _.any-key is .any-key

: low-byte      ( n - max-ff ) th ff and ;
: flip          ( n - nflip )
   dup low-byte  8 lshift swap th ff00 and 8 rshift + ;

synonym ><      flip

: C@+           ( c-addr1 -- c-addr2 char )    dup 1+ swap c@  ;

\ : B@            \ <addr> --- <16b>              signed 16-bit fetch
\                C@+ SWAP C@ >< OR
\                DUP $7FFF > IF $FFFF0000 OR
\                         ENDIF ;

\ : B@+           \ <addr> --- <addr'> <16b>      signed 16-bit fetch+
\                C@+ SWAP C@+ ><  ROT OR
\                DUP $7FFF > IF $FFFF0000 OR
\                         ENDIF ;

\ CREATE 16btmp   0 C, 0 C, PRIVATE

\ : B!            \ <16b> <addr> --- <>           16-bit store
\                SWAP 16btmp !
\                16btmp SWAP 2 MOVE ;

\   W@              synonym B!  w!

: []cell        ( no addr - addr+offset )
   swap cell * + ;

: u.2           ( n - )    \ print 9 as 09
   dup 10 <
        if      ascii 0 emit then u.td ;
\ 9 9 u.2 u.2 .s abort

: .clock         ( second minute hour - )
   u.2 ." :" u.2 ." ." u.2  ;

: ms_win32s          ( ms - )
   ms@ +
        begin   ms@ over - 0 >=
        until   drop
 ;

\  ' ms_win32s is ms   \ win32s version

: ms-key? ( ms - true/false )   \  waits ms or for a key
   ms@ +
        begin   ms@ over - 0 >= ekey? dup pad ! or
        until   drop pad @
 ;

\ tp 5000 ms-key? tp abort

: dfact         ( day month year  -  dfact )
   >r r@ 365 * rot  + over 1- 31 * + over 2 <=
     if   nip r@ 1- 4 / +
     else  swap 40 * 230 + 100 / -  r@ 4 /  +
     then
   r@ 100 / 3 * 4 / 1+ -
   r> 2000 >= abs + \ solves the millenium bug
 ;

: systemtime-dmy ( systemtime-date - d m y ) dup >r 6 + w@   r@ 2 + w@ r> w@  ;

: day           (  dfact - day )        \ 0   1   2   3   4   5   6
   dup 7 / 7 * - ;                      \ sat sun mon tue wed thu fri

defer .day

: .(day  ( day - )
        case                            \ Windows
        0 of ." saturday"       endof   \ 6
        1 of ." sunday"         endof   \ 0
        2 of ." monday"         endof   \ 1
        3 of ." tuesday"        endof   \ 2
        4 of ." wednesday"      endof   \ 3
        5 of ." thursday"       endof   \ 4
        6 of ." friday"         endof   \ 5
                abort" a bad day"
        endcase space
 ;

: .dag  ( day - )
        case
        0 of ." zaterdag"       endof
        1 of ." zondag"         endof
        2 of ." maandag"         endof
        3 of ." dinsdag"        endof
        4 of ." woensdag"      endof
        5 of ." donderdag"       endof
        6 of ." vrijdag"         endof
                abort" a bad day"
        endcase space
 ;

' .(day is .day

: .month ( month - )
        case
        1 of ." January"    endof
        2 of ." February"   endof
        3 of ." March"      endof
        4 of ." April"      endof
        5 of ." May"        endof
        6 of ." June"       endof
        7 of ." July"       endof
        8 of ." August"     endof
        9 of ." September"  endof
       10 of ." October"    endof
       11 of ." November"   endof
       12 of ." December"   endof
                abort" a bad month"
        endcase space
 ;

: seconds@  ( - seconds )    ms@ 1000 /   ;

86400 constant seconds/day

: -time  ( dfact-start seconds-start dfact-end seconds-end -  days seconds )
   >r rot - dup 0< abort" Invalid start-time."
   tuck 0=
      if    0
      else  seconds/day
      then
   r> + swap -
 ;

: today         ( - day month year )
  get-local-time time-buf dup 6 + w@ over 2 + w@ rot w@ ;

\ Another .date"

defer .date
80 constant hld-max
: hld-count  ( count - hld count-1 )  hld swap 1- ;

\ : .dd-mm-jjjj   ( day month year - )    rot  u.2 ." -" swap  u.2 ." -" (u. ;
\ : .mm/dd/jjjj   ( day month year - )    swap u.2 ." /" swap  u.2 ." /" (u. ;

: ldate   ( day month year dwFlags - adr count )
    >r 3dup dfact 1- dup 0=
      if drop 6
      then
    time-buf 4 + w! \ day of week
    time-buf     w! \ year
    time-buf 2 + w! \ month
    time-buf 6 + w! \ day
    hld-max hld  0  time-buf
    r> LOCALE_SYSTEM_DEFAULT
    call GetDateFormat dup 0= abort" ldate failed" hld-count
 ;

( DATE_SHORTDATE ) DATE_LONGDATE  value date_format

: .ldate  ( day month year - )   date_format ldate type  ;

: ltime         ( time-buf - adr count )    \ time-buf must be filled
    hld-max hld  0  time-buf
    TIME_FORCE24HOURFORMAT  LOCALE_SYSTEM_DEFAULT
    call GetTimeFormat dup 0= abort" ltime failed" hld-count
 ;

: .ltime        ( - )   get-local-time ltime type ;
: .today        ( - )   today .date ;
: .time-stamp   ( - )
   .today space today dfact day .day .time time-buf 14 + w@ 10 / ." ." u.2 space
 ;

\ ' .dd-mm-jjjj   is .date
\ ' .mm/dd/jjjj is .date

: control-y?    ( - flag )
   key?
        if      key ctrl y =
        else    false
        then
 ;

: kill-line     ( - )           getxy >r cols over - spaces r> gotoxy ;
: up            ( - )           getxy 1- 0 max gotoxy ;
: input         ( - n )         query bl word count number? 2drop ;

\ : testkill 0 1 gotoxy up ." xxxxxxxxxxxxxxxx " 3 0 gotoxy kill-line .s ;
\ testkill  abort

: delete-chars        ( len - )
   0
        ?do  bs emit space bs emit
        loop
 ;

\ August 24th, 2002 - 16:15
: 0term ( $ count - ) + 0 swap c!  ;

: 0terminated ( adr-counted-string - )
   dup c@ 1+ 0term ;

variable passi

: pass+            ( - old-passi ) \ increment passi
   passi @ passi 1+!  ;

: pass-         ( - old-passi ) \ decrement passi
   passi @ -1 passi +!  ;


\ Format string: [count-allocated count-string string 0]  The "0" is not counted

(( : string:        ( compile-time: len - )  ( run-time: - adr-counted-string )
   create th fc over <                       \ max 252 char
   abort" String out off range ! "           \ map:
   here   swap 3 + dup allot swap c!         \ max-char. counted string
   does> 1+ ; )) \ see Primutil.f

: add-to-string ( c string.adr - true/false )
   dup >r 1- c@ r@ c@ 3 + <=
        if      r> 2drop false
        else    r@ c@ 1+ dup r@ c! r@ + c! r> 0terminated true
        then
 ;

: emit$  ( char adr$ - )    add-to-string drop ;

: instring   ( adr-string - )   \ keyboard input for a string.
   dup 1+ over 1 - c@ 1- 1 max accept over c! 0terminated  ;

\ Note: there is a different .string in the hidden dictionary
: .string               ( adr - )       count type ;

: $copy                 ( stringadr-source stringadr-dest - ) \ and makes it 0 terminated
   dup 1- c@ 2 pick c@ 3 + >=
        if      >r  r@ over c@ 1+ cmove r> 0terminated
        else    beep abort" String to copy in too small ! "
        then
 ;

: string"    ( stringadr - ) \ " stream to string "
   quote [compile] word swap 2dup 1- c@ swap c@ dup rot 3 - >
   abort" Input-stream too large"
   1+ over >r cmove r> 0terminated
 ;

: $extract ( adr-counted-string from #chars - adr-string-from #chars ) >r + r> ;

\ April 3rd, 2004
\ string concatenation:  $1 + $2 -> $1+$2 in pad
: $concat ( $1 n $2 n - pad n1+2 )
    temp$ place             \ Save old $2. It might be in pad.
    pad   place             \ Put $1 in place.
    temp$ count pad +place  \ Add old $2.
    pad count
 ;

string: tmp$

\ tmp$ string" 321"
\ s" abc "  s" next " $concat s" test " $concat s" Before " 2swap $concat type abort

\ tmp$ 0 3 $extract type  abort

\ .time-stamp .s abort

: ##d ( #zeros d - )    rot 0 ?do  #  loop  ;


string: $jjjjmmdd

: jjjjmmdd   ( day month year  - adr ) \ July 6th, 2002 - 17:48 stack corrected
    4 swap s>d <# ##d #> $jjjjmmdd  place
    2 swap s>d <# ##d #> $jjjjmmdd +place
    2 swap s>d <# ##d #> $jjjjmmdd +place
    $jjjjmmdd
 ;

synonym flocal fto  \ NOTE define the flocal as fvalue before using flocal

: (+fto    ( n  'cell-array  - )   >body dup f@ f+ f! ;

: fwithin  \ <> --- <bool> \ f: <n> <rlow> <rhigh> --- <>
   2 fpick f> f< 0=  and ;

: 2^x  ( x -- 2^x )  1 swap lshift ; \ sept 2008

: empty_key_buf ( - )                       key? if key drop then  ;

\ : fchoose     100000 * random s>f 100000e f/ ;        ( <n> --- <> F: <> --- <r> )
\ 2024 .s abort

synonym fvalue-to-string    (F.)

: string>float     \ ( adr - f )  FS: ( - n ) \ Note: 0 on FS when f is false
   count >float dup not
         if 0 s>f
         then
 ;

: float-string>number-string \ ( adr - )
   dup c@ 1- swap c!
 ;

: float-number-string \ ( adr - f ) FS: ( - n )
   >r s" e" r@ +place  r@ c@ 1- r@ c! r> string>float
 ;


\ 1.5e2 fvalue aa
\ 10 string: Aa$  Aa$ string" foo"
\ aa Aa$ fvalue-to-string  Aa$ cr dup 10 dump string>float  cr ftp  cr .s cr
\ cr Aa$ 10 dump cr
\ abort

: init-random  ( - )
   today dfact ms@ * random
 ;

: (cr           ( - )
   carret emit lf emit  ;

: (type         ( adr len - )
  dup 0>
     if  bounds
         do     i c@ emit
         loop
     else 2drop
  then
 ;

\ You can't nest fopen or fcreate

0 value fid

: fcreate       ( adr-counted-string - )
   count write create-file abort" Can't create file" to fid ;

: fopen         ( adr-counted-string fmode - )
   swap count rot open-file abort" open file error" to fid ;

: fclose        ( - )
   fid close-file abort" close error" ;

: fread         ( adr len - len )
   fid read-file abort" read error" ;

: drop-count    ( adr len - adr-counted-string )
   drop 1- ;

\ : testrd
\       cr s" test.txt " drop-count read fopen
\       tmp$ 1+ 10  fread . ." red"
\       fclose cr tmp$ 20 dump ;

variable (femit

: femit         ( char - )
   (femit C! 0 (femit 1+ C! (femit 1 fid write-file abort" write error in femit"
 ;

: fwrite        ( adr len - )
   fid write-file abort" write error" ;

 (( Disable or delete this line for the following test.
 : testwr
       cr s" test2.txt" drop-count fcreate
      s" test " tmp$ place tmp$ count fwrite
       tmp$ count fwrite
       th 34 femit th 35 femit
       fclose ;
 testwr cr  testwr
 ftype test2.txt
 abort \ ))

: "!.                   ( pfa - )
  dup >body space ? >name dup c@ 2dup - swap type drop  ."  ! " ;

\in-system-ok : ?!      ( - )    postpone ['] postpone "!. ; immediate

\ variable test

\ : test2   ?! test ;
\ see test2
\ abort

also hidden

\in-system-ok : screen-only  ( - ) ['] c_type  is type ['] c_emit is emit  ['] c_cr is cr ;

: emit-to-file          ( - )
   ['] fwrite is type   ['] femit is emit       ['] (cr is cr ;

previous

: file                  ( adr-counted-string - )
   fcreate  emit-to-file ;

: end-of-file           ( - )
   screen-only fclose ;

synonym eof end-of-file

 (( Disable or delete this line for the following test.
 : temit   \ Not the fastest way
   s" test.txt " drop-count file
   8000 0 do  ascii A emit loop eof ;
   temit .s dir *.txt abort \ ))


create file-time-buf-created 2 cells allot

: get-file-created ( fileid -- system-time )
        >r
        file-time-buf-created 2 cells erase     \ pre-clear buffer
        0                               \ last written time and date not needed
        0                               \ last access time not needed
        file-time-buf-created    \ creation time needed
        r> call GetFileTime drop

        _systemtime              \ where to put results
        file-time-buf            \ file time/date to convert
        call FileTimeToSystemTime drop
        _systemtime ;


: extension> ( str.x..xx -  )  \ deletes .x..xx
   count dup 0= abort" Bad filename" "minus-ext" swap 1- c! ;

0 value bufcnt   0 value buffer

: init-buffer   ( - )    td 2024 DynAlloc to buffer ;

init-buffer  initialization-chain chain-add init-buffer

: bufload               ( file-name - )
   fid >r read fopen buffer ( -1) 2000 fread to bufcnt fclose r> to fid ;

: bufwrite              ( file-name - )
   fid r> buffer bufcnt rot fcreate fwrite fclose r> to fid ;

\ buftest
\ tmp$ string" test.txt"
\ : buftest tmp$ bufload buffer 100 dump ;
\ buftest
\ abort


\ Implements needs.  This works as follows:
\ Not activated.
\ needs foo tools.f
\
\ If foo is not defined, the file tools.f will be loaded, which should
\ define foo.  If foo is already defined, nothing will happen.

\ : needs ( -- ) ( Input Stream: desired-word file-name )
\   >in @ defined nip nip
\   bl [compile] word swap
\        if      drop
\        else    tmp$ $copy tmp$ $fload
\        then
\ ;

\ You don't have to define binary files to save a few variables.
\ Save them in a ASCII file.
\
\ : save-on-disk                ( - )
\    cr s" test.f" drop-count file
\       ." forth needs femit tools.f" cr
\       ." only forth also definitions decimal"  cr
\       ?! passi eof
\ ;
\
\ save-on-disk
\ cr  ftype test.f abort

: count!     ( adr len - )    swap c!  ;

\ : $max-count ( string$-adr - str$ max-allocated )   dup>r 1 - c@ r> 1+ swap ;
: $max-count ( string$-adr - str$ max-possible )   count 255 min ;


: fvalue-to-string-and-count ( n addr$ - addr len )
   >r r@ fvalue-to-string r> count ;

1 value checked
: check!     ( 1/0 bit# - )   checked -rot bit! to checked ;

: OpenProcessToken ( - token )
   here  TOKEN_ADJUST_PRIVILEGES TOKEN_QUERY  or call GetCurrentProcess
   call OpenProcessToken drop here @
 ;

: GetEnvironmentVariable  ( zstr-EnvironmentVariable-name buffer n - adr n )
   swap dup >r  rot  call GetEnvironmentVariable r> swap ;

: SetEnvironmentVariable  ( zstr-EnvironmentVariable-name  buffer n - )
   pad +place pad dup +null 1+  swap
   call SetEnvironmentVariable drop
 ;

: DelEnvironmentVariable  ( zstr-EnvironmentVariable-name  - )
    0 pad ! pad  swap
   call SetEnvironmentVariable drop
 ;

(( Usage:
 z" TEST" s" Hello" setEnvironmentVariable
 z" TEST"   DelEnvironmentVariable
 z" TEST" s" 2Hello" setEnvironmentVariable
 z" TEST" buffer 256 GetEnvironmentVariable cr dump abort ))

: computername$! ( adr - ) \ March 30th, 2002 was GetComputerName
   100 pad ! pad           \ lpszName
   over 1+                  \ lpdwbuffer
   call GetComputerName drop  pad @ swap c! ;

: username$!     ( adr - )  \ March 30th, 2002  was GetUserName
   100 pad! pad  over 1+   call GetUserName  drop
   pad@ 1- swap c!
  ;

: .id-user
  cr ." Username: " here dup UserName$!     .string
  cr ." At      : " here dup computername$! .string ;

cr ' .ldate   is .date
cr today  .ldate space .ltime
.id-user cr

\ April 22nd, 2002 - 22:04 renamed box to _msgbox
: _msgbox    { \ title$ message$ -- } ( adr2 len2 adr1 len1 type  - button )
    MAXSTRING localAlloc: message$
    MAXSTRING localAlloc: title$
    >r
    message$ place message$ +NULL
    title$   place title$   +NULL
    r>
    title$ 1+  message$ 1+
    NULL call MessageBox
 ;

\ changed May 17th, 2003
: infobox   { \ title$ message$ -- }  ( adr2 len2 adr1 len1  - )
    [ MB_OK MB_ICONINFORMATION or MB_TASKMODAL or ] literal _msgbox drop ;

\ changed April 1st, 2002 - 18:49
: qbox    ( adr2 len2 adr1 len1  - button )
    [ MB_YESNOCANCEL MB_ICONQUESTION or MB_TASKMODAL or ] literal _msgbox  ;

\ added April 1st, 2002 - 18:49
: y/n-box  ( adr2 len2 adr1 len1  - button )
    [ MB_YESNO MB_ICONQUESTION or MB_TASKMODAL or ] literal _msgbox  ;

\ s" Test" s" Continue " infobox .s abort

20 cell-array tmp-array
: to-tmp-array  ( ... k - )   \ will also roll the elements on stack when fetched
  0 do i to-cell tmp-array loop  ;

: n_ ( start end -- ...abs )   swap do i tmp-array  loop  ;

\     DWORD  lpAppName,        \ points to section name
\     LPCTSTR lpKeyName,       \ points to key name
\     LPCTSTR lpDefault,       \ points to default string
\     LPTSTR lpReturnedString, \ points to destination buffer
\     DWORD nSize,             \ size of destination buffer
\     LPCTSTR lpFileName       \ points to initialization filename

\ lpReturnedString will contain a counted string with a 0 at the end
:  GetPrivateProfileString  ( lpAppName lpKeyName lpDefault lpReturnedString nSize lpFileName - ncopied )
   1+ 6 to-tmp-array 0 tmp-array  1 tmp-array 2 tmp-array dup >r 1+
   3 6 n_  call GetPrivateProfileString r> c! ;

: WritePrivateProfileString  ( lpAppName lpKeyName lpString lpFileName - flag )
   1+ 4 to-tmp-array  0 4 n_  call WritePrivateProfileString 0=
   abort" Failed to write profile string."
 ;

create profile$ 256 allot

(( \ example:

: inifile ( - adres )
   pad 256 erase current-dir$ count pad place s" \awin.ini" pad +place pad ;

: test_GetPrivateProfileString
  z" MSAPPS2" z" WORDART2" z" Error"  profile$  255 inifile
  GetPrivateProfileString
 ;

: test_WritePrivateProfileString
  z" MSAPPS2"  z" WORDART2"  z" C:\WINNT\MSAPPS\WORDART" inifile
  WritePrivateProfileString
 ;

test_WritePrivateProfileString
test_GetPrivateProfileString profile$ .string \ ))

: s>tmp$      ( n - adr )     s>d (d.) tmp$ place tmp$  dup 0terminated 1+ ;

: f>tmp$      ( f: f - adr )  tmp$ dup fvalue-to-string dup 0terminated 1+ ;

string: bad-ini-file$   bad-ini-file$ maxstring erase
s" --- Bad ini file. ---" bad-ini-file$ place

: get$        ( inifile section key - Inifile profile$ )
   bad-ini-file$  1+
   profile$  255 5 pick GetPrivateProfileString profile$ ;

: profile>$  ( Inifile section key - Inifile section adr )
   over >r get$ r> swap ;

\ March 18th, 2002 - 15:15
\ profile>f changed for better reporting when there is an error

: profile>f   ( Inifile section key - Inifile section ) ( f: - f )
   2dup 2>r get$ float-number-string not
      if     S"  Section: " profile$ place
             2r@ swap 1- count profile$ +place
             S"  Key: " profile$ +place
             1- count profile$ +place
             profile$ count Error-StopBox abort
      then
   2r> drop
 ;

: profile>s   ( Inifile section key - Inifile section n ) profile>f f>s  ;

: +inifile    ( inifile section key - inifile adres )
   3 pick WritePrivateProfileString ;

: f>profile   ( inifile section key - inifile section ) ( f: f - )
   over >r f>tmp$ +inifile r> ;

: s>profile   ( inifile section key n - inifile section )
   2 pick >r s>tmp$ +inifile r> ;

\ May 29th, 2001 - 10:19

also bug

: f.s-debug           ( -- )  \ display the floating point stack
                fdepth
                IF      fdepth  ." {" 1 .r ." } "
                show-fp-depth fdepth umin dup 1- swap 0
                        DO      10 ?cr
                                dup i - fpick g.
                        LOOP
                        drop
                ELSE    ." Empty fp stack "
                THEN ;

also forth

\ : fdebug  ( - ) \ shows the floating point stack while debugging
\     ['] f.s-debug is debug-.s ;

: ndebug  ( - ) \ shows the normal stack while debugging
\in-system-ok     ['] .s-base is debug-.s ;

previous previous


\ August 21st, 2001 - 11:50

: val>$    ( str$ val -  )  s>d (d.)   rot  place  ;
: val>+$   ( str$ val -  )  s>d (d.)   rot +place  ;
: val>$,.  ( str$ val -  )  s>d (ud,.) rot  place  ;
: val>+$,. ( str$ val -  )  s>d (ud,.) rot +place  ;

\ August 27th, 2001 - 14:08

\ For wide strings with a long count
: +unicode    ( adr-dest c - )    swap dup>r @ dup 2+ r@ ! r> cell+ + w!  ;

: c>unicode! ( dest char - dest+2 )   over w! 2 chars + ;

: ansi>unicode  ( caddrSrc u addrDestUnicode -- )
    -rot over + swap
    ?DO i c@ c>unicode! LOOP
    0 swap w! ;

defer pause

\ September 9th, 2001 - 14:38
\ :INLINE was posted in comp.lang.forth by Marcel Hendrix

: NEXT_CHAR ( -- char ) \ NEXT-CHAR was used in float.f
        SOURCE >IN @ <= IF  DROP -1 EXIT  ENDIF
        >IN @ CHARS + C@  ;

: SKIP-LINE ( -- )
        BEGIN  NEXT_CHAR -1 <>
        WHILE  1 >IN +!
        REPEAT ;

\ Embedded linebreaks are allowed. Maximum length is 4096 characters.
\ Not allowed: EXIT LOCALS| DLOCALS| FLOCALS| , DOES> R> DROP etc.
\ It needs a space as the first character on each line

: MULTI-LINE ( quote "ccc<quote>" tmp-buffer -- str len )
        0 LOCALS| ch buff quote |
        buff off
        BEGIN
          NEXT_CHAR TO ch
          ch '\' = IF  SKIP-LINE  -1 TO ch          ENDIF
          ch -1  = IF  BL TO ch REFILL  ELSE  TRUE  ENDIF
        WHILE
          ch quote <>
        WHILE
          ch  buff @+ +  C!  1 buff +!  1 >IN +!
          buff @ 4096 >=
        UNTIL THEN THEN
        buff @+  REFILL DROP ;


: :INLINE ( ccc; -- )
        CREATE  IMMEDIATE
                ';'
                4096 CELL+ CHARS MALLOC DUP>R
                MULTI-LINE  ( addr u tmp-buffer )
                DUP , HERE CELL+ ,
                HERE OVER ALLOT  SWAP MOVE
                R> RELEASE
        DOES>   2@ EVALUATE ;

(( -- Usage:

:INLINE foo
 \ '\' Is allowed when there is a space at the start of the line
 ." string test2 "
 5 6 +
 ;

: test foo foo + . ;

cr see test test \ ))


\ September 20th, 2001 - 12:55


CODE 4>R        ( n1 n2 n3 n4 -- )    \ push a 4 items onto the returnstack
                pop     eax
                sub     ebp, # 16            \ Return Pointer, Forth's subroutine stac
                mov     0 CELLS [ebp], ebx
                mov     1 CELLS [ebp], eax
                pop     eax
                mov     2 CELLS [ebp], eax
                pop     eax
                mov     3 CELLS [ebp], eax
                pop     ebx                 \ tos
                next    c;

CODE 4R>        ( -- n1 n2 n3 n4 )    \ pop a 4 items off the return stack
                push    ebx
                mov     ebx, 0 CELLS [ebp]
                mov     eax, 3 CELLS [ebp]
                push    eax
                mov     eax, 2 CELLS [ebp]
                push    eax
                mov     eax, 1 CELLS [ebp]
                add     ebp, # 16
                push    eax
                next    c;

CODE 4R@        ( -- n1 n2 n3 n4 )    \ get a copy of the top 4 items on the return stack
                push    ebx
                mov     ebx, 0 CELLS [ebp]
                mov     eax, 3 CELLS [ebp]
                push    eax
                mov     eax, 2 CELLS [ebp]
                push    eax
                mov     eax, 1 CELLS [ebp]
                push    eax
                next    c;

\ : t4r    1 2 3 4 4>R 0 4R@ 2r@ 4R> 4drop 4drop 3drop  ;  debug t4r t4r


true value sounds_on/off

: sounds  ( z"sound-file" - )
   sounds_on/off
     if   SND_FILENAME NULL rot  call PlaySound  then drop  ;

\ October 22nd, 2001 - 23:46

also hidden

variable disposition
variable regkey
variable regtype
variable reglen

\ The following 2 definitions allows access to the entire registry.
\ They are copied from registry.f with a few small changes.

\ sadr,slen = the registry section to get the key of
\ return -1 if we could not get the key

: GetRegKey     { sadr slen samDesired \ root-key key$ n -- regkey | -1 }  \ opens the key of a section
                MAXSTRING localAlloc: key$
                sadr slen             key$ place
                                      key$ +NULL
                >r
                disposition          \ we get it, but don't use it
                regkey               \ the return value
                NULL
                samDesired
                REG_OPTION_NON_VOLATILE
                NULL
                0
                key$ 1+
                r> \ root-key
                Call RegCreateKeyEx
                if      -1
                else    regkey @
                then    ;

\ : getregistryentry  ( vadr vlen root-key sadr slen samDesired -- dadr dlen )
\ has been moved to: Winversion.f

previous

(( \ usage
: test_reg$
   s" Directory"  HKEY_CURRENT_USER s" Software\Win32For\Settings" KEY_EXECUTE
   GetRegistryEntry  type cr
\ ( w2k) s" ~MHz"  HKEY_LOCAL_MACHINE s" HARDWARE\DESCRIPTION\System\CentralProcessor\0" KEY_EXECUTE
\ ( w2k) GetRegistryEntry drop ? ." Mhz" cr
   ;
test_reg$ \ ))

\ November 3rd, 2001 - 21:19 added:  u,.  ?u,. ?u,.cr
\ November 3rd, 2001 - 21:35 moved cpuid related words to cpu.f

\ November 21st, 2001 - 12:08 added:
: get-priority  ( - priority_class )
    call GetCurrentProcess  call GetPriorityClass ;

: set-priority  ( priority_class - )    \ May 27th, 2004
    call GetCurrentProcess call SetPriorityClass drop  ;

\ IDLE_PRIORITY_CLASS . 64
\ NORMAL_PRIORITY_CLASS . 32
\ HIGH_PRIORITY_CLASS . 128
\ REALTIME_PRIORITY_CLASS . 256

\ December 17th, 2001 - 13:09
\ Added .ldate
\ Added the security access mask for getregistryentry.

\ January 7th, 2002 - 23:19 from Will Baden's Toolbelt

: third  ( x y z -- x y z x )  2 pick ;
: fourth ( w x y z -- w x y z w )  3 pick ;
: andif  s" dup if drop " evaluate ; immediate
: orif  s" ?dup 0= if " evaluate   ; immediate  \ March 10th, 2002 - 16:34

\ January 10th, 2002 - 22:05
\ added seconds@ seconds/day -time

\ January 14th, 2002 - 12:48
\ Added for access to ini files:
\ s>tmp$  f>tmp$  get$  profile>f  profile>s  +inifile  f>profile  s>profile

: file-exist? (  ( adr len -- true-if-file-exist )
   find-first-file not dup>r
      if    find-close 2drop
      else  drop
      then
   r> ;

\ March 12th, 2002 - 12:19 needed-file aborts when the file is not found.

: needed-file  ( count adr - )
   2dup file-exist? not
       if    temp$ place  s"  is needed." temp$ +place
             s" Missing file" temp$ count infobox true abort" aborted."
       else  2drop
       then
 ;


:inline odd?  ( n - flag )   1 and  ;
: even?          ( n - flag )   odd? not ;

\ October 7th, 2002 - 10:12

: mkdir  ( pSecurityAttributes  z"path" - ior )   call CreateDirectory ;

\ Empty the directory before using rd
: rd     ( z"path" - ior )                        call RemoveDirectory ;

: -string  ( adr1 cnt1 adr2 cnt2 - adr1+cnt2 cnt1-cnt2 )
  dup>r + swap r> - rot drop
 ;

: +pad$ ( adr cnt - ) pad +place ;

: merge$  ( adr2 count2 adr1 count1 - pad count1+2 ) pad place +pad$ pad count ;

: unfold ( adr n ascii1 ascii2 - >adr len flag )
   2over rot scan 2>r scan
     if   1+ 2r>
            if    over - true
            else  drop 0 false
            then
     else  2r> 2drop 1- 0 false
     then
 ;

: fold ( adr n ascii1 ascii2 - pad len )
   >r pad c! tuck pad 1+ swap move pad over 1+ + r> swap c! 2+ pad swap
 ;

: $>profile   ( inifile$ section key counted$+null - inifile section )
   1+ 2 pick >r +inifile r>
 ;

\ June 8th, 2003


create &InfoRect  4 cells allot    ( - &InfoRect )
&InfoRect 4 cells erase
&InfoRect constant window_x
&InfoRect 1 cells+ constant window_y
&InfoRect 2 cells+ constant width
&InfoRect 3 cells+ constant height

: windowposition ( hWnd - ) &InfoRect  swap  Call GetWindowRect ?win-error ;

string: inifile$

\ March 22nd, 2004
defined  cd nip not [IF]
        ' chdir alias  cd
[then]

\ April 5th, 2004

defined  ascii-z nip not [IF]
: ascii-z     ( addr len buff -- buff-z )        \ make an ascii string
       dup>r place r> count over + 0 swap c! ;

[then]

defined  zcount nip not [IF]

: zcount    ( adr -- adr len )    -1 2dup 0 scan nip -  ;

[then]

: context>current ( - )  context @ current ! ;

\ all-warnings-on

\s

