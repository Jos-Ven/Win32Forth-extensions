(( (*
 * LANGUAGE    : ANS Forth
 * PROJECT     : Forth Environments
 * DESCRIPTION : infix parser (for a desk calculator?)
 * CATEGORY    : Example
 * AUTHOR      : Chuck Moore, 1981 Forml Proc. Vol. 2
 * LAST CHANGE : February 17th, 2002 - 18:11, Jos v.d.Ven
 * Changed it for Win32Forth.
 * Made the the floating point mode active.
 * Added: ^ NEG LOG LOG SIN COS TAN ABS 1/ INT SQR DEGREES FRAD
 * Added calculations about intrest in an example.
*)



   (* ****************************************** *)
   (*                                            *)
   (*   O W B R O 'C O N Y   A N G I E L S K I   *)
   (*                                            *)
   (* FC: Chuck Moore, 1981 Forml Proc. Vol. 2   *)
   (*   Title is Polish for "Reverse English"    *)
   (*                                            *)
   (* ****************************************** *)


  ONLY  FORTH ALSO  DEFINITIONS DECIMAL


      REVISION -infix "--- Infix notation      Version 1.03 ---"


DOC Examples
---
(*
  A[ A + B - C * ( D / A ) ]A

 or: : EXPR A[ A + B - C * ( D / A ) ]A ;

 Note that optimizer actions ARE NOT frustated by this
 scheme!

 Very nice: Within A[ .. ]A the search order is ALGEBRAIC, then
 context. After ]A, ALGEBRAIC is automatically switched out.

 The expression becomes unreadable when we are not working with
 VALUE's, CONSTANT's, VARIABLE's or immediate numbers.
*)
ENDDOC ))

  ONLY  FORTH ALSO  DEFINITIONS DECIMAL

' constant alias =:

10 =: maxlevels  \  nestings per expression

CREATE operations
 maxlevels 1+ 2 CELLS * ALLOT \ operations stack, position 0 = ptr

: ?INTERPRET STATE @ IF COMPILE, \ <exec token> --- <?>
                   ELSE EXECUTE
                  ENDIF ;

: 'pair  operations DUP @ + ;    \ <> --- <addr of level:index>

: ?opsp  operations @ DUP
  0< SWAP
  [ maxlevels 2 CELLS * ] LITERAL
  U> OR ABORT" Expression too complex." ;


: >ops  ?opsp      \ <exec token> <level> --- <>
   2 CELLS operations +!
  'pair 2! ;

: ops>  ?opsp
  'pair 2@
  2 CELLS NEGATE operations +!
  DROP ?INTERPRET ;

: LEVEL? 'pair @ ; \ <> --- <level>

: ]A  BEGIN LEVEL?
      WHILE ops>
      REPEAT
     \IN-SYSTEM-OK PREVIOUS ; IMMEDIATE

: INFIX  '         \ <level> INFIX #<n1># #<n2>#
  CREATE SWAP , , IMMEDIATE
  DOES> 2@
     BEGIN  DUP LEVEL? U> 0=
     WHILE  2>R ops> 2R>
     REPEAT
     >ops ;

true value degrees
: frad   ( fs: deg - rad )   fpi f* 180 s>f f/  ;
: sin    ( fs: angle - sin ) degrees    if    frad    then    fsin   ;
: tan    ( fs: angle - tan ) degrees    if    frad    then    ftan   ;
: cos    ( fs: angle - cos ) degrees    if    frad    then    fcos   ;
: 1/     ( fs: x - 1/x )     1e fswap f/ ;

' floor alias int
' fpi   alias pi



 VOCABULARY ALGEBRAIC  ALGEBRAIC DEFINITIONS  ALSO FORTH


WARNING @ temp$ ! WARNING OFF


\    Redefine every operation which must be "infixable" in ALGEBRAIC.

TRUE [IF]


 9 INFIX FNEGATE NEG  9 INFIX FLOG LOG
 9 INFIX FLOG    LOG  9 INFIX SIN SIN
 9 INFIX COS     COS  9 INFIX TAN TAN
 9 INFIX FABS    ABS  9 INFIX 1/ 1/
 9 INFIX FLOOR   INT  9 INFIX FSQRT SQR


 8 INFIX F** ^
 7 INFIX F*  *        7 INFIX F/  /
 6 INFIX F+  +        6 INFIX F-  -
 5 INFIX F>  >        5 INFIX F<  <
 5 INFIX F=  =


[ELSE]

 8 INFIX NEGATE NEG
 7 INFIX * *         7 INFIX /  /
 6 INFIX + +         6 INFIX -  -
 5 INFIX > >         5 INFIX <  <
 5 INFIX = =

[THEN]

temp$ @ WARNING !

: NO-OP ;

: ( ['] NO-OP  1  >ops ; IMMEDIATE


: ) BEGIN 1 LEVEL? <
    WHILE ops>
    REPEAT
    1 LEVEL? = IF 2 CELLS NEGATE operations +!
             ELSE TRUE ABORT" Missing `('"
            ENDIF ; IMMEDIATE

FORTH DEFINITIONS

: A[ 0 operations ! \IN-SYSTEM-OK ALSO \IN-SYSTEM-OK ALGEBRAIC ; IMMEDIATE


B/FLOAT 10 < [if]
cr
cr .( B/FLOAT is only )  B/FLOAT . .( change it to 10 for more accurate results.)
cr .( To change this, you just need to edit the EXTEND.F file.)
cr .( 8 constant B/FLOAT    into    10 constant B/FLOAT )
cr .( Then recompile Win32Forth. Use  Make Win32Forth )
cr
[then]


                   ( * End of Source * )



\s Remove or disable this line for the example




0e fvalue pv         \ Present value
0e fvalue intrest    \ For each perod
0e fvalue n          \ Number of periods on which intrest is added to pv
0e fvalue fv         \ Future value

\ Suppose a PV: $1,000,000, intrest:2,5%,  30 days.

1000000e fto pv
2.5e     fto intrest
30e      fto n

: pmt? A[  pv *  intrest * n /  36000e ]A ;
cr
cr .( Payment for $1,000,000, intrest:2,5%, after 30 days is: ) pmt? f.
cr


\ Let us suppose a PV: $1,000,000,  intrest:2,5%, 24 year.
\ Calculate the future value:
\ Formula:
\ FV=P(1+i)n = 1000000 (1+0.025)24 = 1.808.725,95

24e      fto n
: fv?   A[  pv * ( 1e +  intrest / 100e )  ^ n   ]A ;

cr .( The future value for $1,000,000, intrest:2,5% after 24 years is: )
   FV? fdup f. fto fv


: pv?  A[  fv / ( 1e +  intrest / 100e ) ^ n   ]A  ;

cr    .( The caluculated PV was ) pv? f.
cr cr .( Here is the compiled formula: )
cr
see pv?


