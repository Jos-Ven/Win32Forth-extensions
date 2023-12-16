\ A high level Forth-tracer for Win32Forth ( ITC/STC)
\ Ported from Gem-Forth by Jos v.d.Ven

\ Still to solve:
\ - floating point numbers
\ - IO redirection when used in the future.

anew -Tracer.f          cr .( Loading Tracer.f )

variable tron?          \ Tracer on/off/abort
variable #traces        \ Number of traces to see or not

defined n>bfa nip not [IF]   \ Assumes the STC version of Win32Forth

: immediate?    ( cfa - flag )  drop true   ; \ Solved by >ct-exec

[THEN]

defined n>bfa nip  [IF]      \ Assumes the ITC version of Win32Forth

: 1+!           ( adr - )       1 swap +! ;
: immediate?    ( cfa - flag )  >name n>bfa c@ 128 and ;
: >ct-exec      ( cfa - )       execute ;

[THEN]

create accepted$ maxstring allot

: accept$         ( -- adr count )          \ Accept a line of input from the user
                accepted$ dup maxstring accept   ;

: input         ( - n flag ) accept$ (number?) nip ;  \ User input for a number

: (tr)
    tron? @
        if   #traces @ 0<
                if   #traces 1+! #traces @ 0<  \ No trace-output when #traces is < 0
                        if   drop exit         \ Drop the CFA indicator
                        then
                else -1 #traces +!
                then
             tab ." \ "  >name count type
\in-system-ok tab ."  - " .s tab  cr
             #traces @ 0=                      \ Ask a new value when #traces = 0
                if   ." T>> " input over and
                        if   #traces !
                        else abort             \ 0 aborts tracing
                        then
                then
        else drop                              \ Drop the CFA indicator
        then ;

: tron   ( - )  cr ." TRON " 1 tron? !   ;     \ Tracer ON

: troff  ( - )
\in-system-ok   cr ." TROFF "  ."  - " .s cr 0 tron? ! ;   \ Tracer OFF

: tracer ( - )                  \ Activates the tracer
  cr .date space .time ." . Used Win32Forth:" .version cr \ To show what was used.
  tron 3 spaces ." TRACING T>> " input over and
    if   cr #traces !
    else abort
    then  ;

create ?; ," ;"

: FindNextWord ( - str ) \ From the sourcefile
   begin        bl word dup count 0=
   while        2drop refill drop
   repeat       drop
 ;

: .Unnest ." ;" ;  \ End of word marker

\in-system-ok : [Compile]Literal ( n - )    [compile] literal  ;

\ Trace compiles the word to be executed, followed by its CFA as a literal and (tr)
\ in the definition after the word trace.
: trace   ( - )
  compile tracer                        \ Activates the tracer in run-time
    begin   FindNextWord dup count  ?; count compare 0<>
    while   find                        \ Word defined?
        if   dup immediate?
                if   dup>r >ct-exec r>  \ execute immediate words on a clean stack
                else dup compile,       \ compile word to execute
                then
        else  count (number?) drop d>s [Compile]Literal  \ Compile numbers
             ['] Literal                \ To compile LITERAL as an indicator for (tr)
        then
        [Compile]Literal                \ Compile CFA as literal as an indicator for (tr)
        compile (tr)                    \ Compile (tr)
    repeat   drop
    compile .Unnest                     \ Compile an extra indication at the end.
    ['] .Unnest [Compile]Literal
    compile (tr)
    ['] ; execute         \ Compiles ; and resumes normal compilation
 ;  immediate

\s \ Test section:
((
: test  trace do  i . loop    ;

\ see test
3 0 test abort  ))

: demo-tracer   ( - )
   cr cr
  ." Enter the number trace points you like to see after the T>>." cr
  ." Negative input skips the number of trace points. 0 aborts."   cr
  trace troff
  ." Put trace in the definition to activate the tracer." cr
  ." Troff sets the tracer off, tron puts it on." cr
  ."  i/o   executed  stack               "       cr
  ."   |        |        |"  cr
  ."  \|/      \|/      \|/" cr
  tron
  3 0
  do    i .
  loop
  cr
  ." End of demo."
 ;

 demo-tracer abort
\s

Enter the number trace points you like to see after the T>>.
Negative input skips the number of trace points. 0 aborts.

17-5-2007 14:55:24. Used Win32Forth:
Version: 6.11.10 Build: 27

TRON    TRACING T>> 99

TROFF  -  empty
Put trace in the definition to activate the tracer.
Troff sets the tracer off, tron puts it on.
 i/o   executed  stack
  |        |        |
 \|/      \|/      \|/

TRON    \ TRON   -  empty
        \ LITERAL        - [1] 3
        \ 0      - [2] 3 0
        \ DO     -  empty
        \ I      - [1] 0
0       \ .      -  empty
        \ DO     -  empty
        \ I      - [1] 1
1       \ .      -  empty
        \ DO     -  empty
        \ I      - [1] 2
2       \ .      -  empty
        \ LOOP   -  empty

        \ CR     -  empty
End of demo.    \ ."     -  empty
;       \ .UNNEST        -  empty

\s
