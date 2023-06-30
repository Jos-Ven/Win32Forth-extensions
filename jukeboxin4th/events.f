\ Events.f

\ *D doc\classes\
\ *! Events
\ *T Events -- To support events in windows.

: event-set     ( hEvent - )  Call SetEvent   0= abort" Event not set" ;
: event-reset   ( hEvent - )  Call ResetEvent 0= abort" Event not reset" ;

: event-ms-wait    ( hEvent ms- )
\ *G Wait till a number of MS for an event or object while is NOT set
    swap Call WaitForSingleObject drop ;

: event-wait    ( hEvent - )
\ *G Wait while untill  the event or object is NOT set
   INFINITE  event-ms-wait ;

\ Note: In W98 it does not matter if bWaitAll is true or false

: event-set?    ( hEvent - true/false )
\ *G Inquire if an event is set or not_set
    0  swap  Call WaitForSingleObject 0=  ;

: make-event-set       ( z"name" - hEvent ) \ In Win32
\ *G Make an event and SET it
    false              \ init state      ( seems ignored ? )
    true               \ manuel reset ( seems ignored ? )
    0                  \ lpSecurityAttrib
    Call CreateEvent   \ handle event, the event seems allways NOT set
    dup event-set ;

: make-event-reset     ( z"name" - hEvent ) \ In Win32
\ *G Make an event and RESET it
    false              \ init state      ( seems ignored ? )
    true               \ manuel reset ( seems ignored ? )
    0                  \ lpSecurityAttrib
    Call CreateEvent   \ handle event, the event seems allways NOT set
    dup event-reset ;

\s
