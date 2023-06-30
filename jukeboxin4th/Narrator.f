anew -Narrator.f

needs Fcom.f

winver winvista >= [IF]
        5 3 typelib {C866CA3A-32F7-11D2-9602-00C04F8EE628}
 [ELSE]
        5 0 typelib {C866CA3A-32F7-11D2-9602-00C04F8EE628}
 [THEN]

\in-system-ok  ISpVoice ComIFace cpVoice->

1 Value NoSapi?

: cpVoice->SetRate ( n -- )  cpVoice-> SetRate ;

: cVal ( cn - n )
   dup 128 >
     if    256 swap - negate
     then
 ;

: (InitVoice    ( -- )
   cpVoice-> ISpVoice \ Blocks beep
   1 0 SpVoice CoCreateInstance to NoSapi?

 ;

: InitVoice    ( -- )
   (InitVoice
   vadr-config VoiceRate c@ cVal
   cpVoice->SetRate   drop
   100 cpVoice-> SetVolume drop
 ;

string: tts$

: +tts$  ( char - ) sp@ 1 tts$ +place drop ;

: (to-say"   ( - )
    ((")) count bounds
     do i c@  +tts$ loop
   ;

: say"       ( -<string">- )  compile (to-say" ,"  ; immediate

: translate ( c - )
   dup
   case
    ascii . of say" . " endof
    ascii _ of say"   " endof
    ascii ( of say" . " endof
    ascii ) of say" , " endof
    ascii - of say" . " endof
    ascii ! of say" . " endof
    ascii ~ of say" . " endof
    ascii , of say" , " endof
     dup  +tts$
   endcase
   drop
 ;

: CapFirst ( adr len  - )
    0
     ?do   i over + c@ dup ascii a ascii z between
              if     upc over i + c! leave
              else   drop
              then
     loop
    drop
 ;

: Say ( adr len  - )
   NoSapi?
      if     2drop false vadr-config l_Narrator- c!
      else   tts$ maxstring erase
             2dup lower 2dup CapFirst 0
                  ?do   i over + c@ translate
                  loop
             drop tts$ count
             0 0 2swap >Unicode drop cpVoice-> speak drop
             winpause infinite cpVoice-> WaitUntilDone drop
      then
 ;


string: say$

: LeadingNumbersCD? ( adr n - flag )
    1 0
      ?do i over + c@
      loop
 ;

: SkipLeadingNumbersCD  ( adr n - adr' n' )
   2dup 2 min is-number?
     if   over 3 + 1 is-number? not
             if   2 - swap 2 + swap
             then
     then
 ;

0 value h_ev_h_ev_tts_done

: CreateTtsEvent
   z" init_ev_h_ev_tts_done"  make-event-reset   to h_ev_h_ev_tts_done ;

true value SayNext

: s' [char] ' parse state @ if postpone sliteral then ; immediate

: PitchTag ( - adr count )
    s' <pitch absmiddle="' temp$ place
    vadr-config pitch c@ s>d (d.) temp$ +place
    s' "> <emph> ' temp$ +place
    temp$ count
 ;

: ToSay{ ( -- ) PitchTag say$ place ;
: SayIt  ( -- ) s" </emph></pitch>" say$ +place say$ count Say ;
: +say   ( adr$ cnt -- ) say$ +place ;
: }Say   ( adr$ cnt -- ) +say  SayIt ;

string: tts-Artist$
string: tts-Title$

: 24Time  ( - m h )        get-local-time time-buf dup   10 + w@  swap 8 + w@  ;
: (s.")   ( n - str$ cnt ) s>d (D.) ;

: AnnounceTime  ( m h - )
   24Time
    ToSay{   (s.") +say dup 10 <
      if s"  0 "
      else s"  "
      then
   +say   (s.")   }Say
 ;

 true value TellTime30
 0 value h_ev_tellTime

: 30diff ( n - to60|30 )
   dup 30 >=
       if    60
       else  30
       then
   swap -
 ;

: Next30m ( - msTimeOut )
    get-local-time time-buf 10 + w@ 30diff 60 * 1000 *
    time-buf  12 + w@ 30diff 1000 * +

 ;

: Telltime
   TellTime30 not
        if    Next30m 1000 - 1 max ms
              true to TellTime30
        then
 ;

: AnnounceTime30min ( - )
   TellTime30
     if    AnnounceTime  false to TellTime30 ['] Telltime Submit: JukeBoxTasks
     then
 ;

: DoAnnounceTime
     vadr-config TellTime- c@
         case
              1 of AnnounceTime     endof
              2 of AnnounceTime30min endof
         endcase
  ;

: TtsTask    ( - )
    volume@  drop InitVoice
    vadr-config ttsVolume c@  5 * dup volume!
    h_ev_h_ev_tts_done event-reset
    DoAnnounceTime
    SayNext
       if   ToSay{ s" Next" }Say 250 ms
       then

    ToSay{  tts-Artist$ count }Say  150 ms
    ToSay{  tts-Title$  count SkipLeadingNumbersCD }Say

    h_ev_h_ev_tts_done event-set
    655 / dup volume!
    false to SayNext
 ;

: start-tts-task ( -- ) ['] TtsTask  Submit: JukeBoxTasks  ;

: ,UtilArtist$  ( adr cnt - ) \ translates the artist from "tell1,tell2"  to "tell2 tell1"
  2dup ascii , scan dup               \ when a "," is found in the string
    if     dup>r 1 /string over c@ bl =
               if   1 /string
               then
           tts-Artist$ place
           s"  " tts-Artist$ +place r> - tts-Artist$ +place
    else   2drop tts-Artist$ place
    then
 ;


: _Announce ( adr n - )
    dup 0>
       if    ExtractRecord
             struct, InlineRecord RecordDef Artist
             struct, InlineRecord RecordDef Cnt_Artist c@ ,UtilArtist$
             struct, InlineRecord RecordDef Title
             struct, InlineRecord RecordDef Cnt_Title c@ tts-Title$   place
             start-tts-task
       else   2drop
       then
 ;

: Announce ( adr n - )
   dup 0>
       if     true to SayNext _Announce
       else   2drop
       then

;


\s

ISpVoice words   2 3  IMethod SetNotifySink ( *ISpNotifySink -- hres )
  5 4  IMethod SetNotifyWindowMessage ( LONG_PTR UINT_PTR n wireHWND -- hres )
  4 5  IMethod SetNotifyCallbackFunction ( LONG_PTR UINT_PTR **void -- hres )
  4 6  IMethod SetNotifyCallbackInterface ( LONG_PTR UINT_PTR **void -- hres )
  1 7  IMethod SetNotifyWin32Event ( -- hres )
  2 8  IMethod WaitForNotifyEvent ( n -- hres )
  1 9  IMethod GetNotifyEventHandle ( -- ptr )
  5 10  IMethod SetInterest ( d d -- hres )
  4 11  IMethod GetEvents ( *n *SPEVENT n -- hres )
  2 12  IMethod GetInfo ( *SPEVENTSOURCEINFO -- hres )
  3 13  IMethod SetOutput ( n IUnknown -- hres )
  2 14  IMethod GetOutputObjectToken ( **ISpObjectToken -- hres )
  2 15  IMethod GetOutputStream ( **ISpStreamFormat -- hres )
  1 16  IMethod Pause ( -- hres )
  1 17  IMethod Resume ( -- hres )
  2 18  IMethod SetVoice ( *ISpObjectToken -- hres )
  2 19  IMethod GetVoice ( **ISpObjectToken -- hres )
  4 20  IMethod Speak ( *n n lpwstr -- hres )
  4 21  IMethod SpeakStream ( *n n *IStream -- hres )
  3 22  IMethod GetStatus ( *lpwstr *SPVOICESTATUS -- hres )
  4 23  IMethod Skip ( *n n lpwstr -- hres )
  2 24  IMethod SetPriority ( SPVPRIORITY -- hres )
  2 25  IMethod GetPriority ( *SPVPRIORITY -- hres )
  2 26  IMethod SetAlertBoundary ( SPEVENTENUM -- hres )
  2 27  IMethod GetAlertBoundary ( *SPEVENTENUM -- hres )
  2 28  IMethod SetRate ( n -- hres )
  2 29  IMethod GetRate ( *n -- hres )
  2 30  IMethod SetVolume ( h -- hres )
  2 31  IMethod GetVolume ( *h -- hres )
  2 32  IMethod WaitUntilDone ( n -- hres )
  2 33  IMethod SetSyncSpeakTimeout ( n -- hres )
  2 34  IMethod GetSyncSpeakTimeout ( *n -- hres )
  1 35  IMethod SpeakCompleteEvent ( -- ptr )
  5 36  IMethod IsUISupported ( *n n *void lpwstr -- hres )
  6 37  IMethod DisplayUI ( n *void lpwstr lpwstr wireHWND -- hres )
 ok
