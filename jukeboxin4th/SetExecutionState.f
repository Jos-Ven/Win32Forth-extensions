Anew SetExecutionState.f  \ For Windows XP or better


   (( Disable or delete this line for generating a glossary
cr cr .( Generating Glossary )
needs help\HelpDexh.f  DEX SetExecutionState.f
cr cr .( Glossary SetExecutionState.f generated )  cr 2 pause-seconds bye  ))


\ *D doc
\ *! SetExecutionState
\ *T SetExecutionState -- To enable or disable the screen saver or sleep mode.


\ *S Settings:
0x00000040 constant ES_AWAYMODE_REQUIRED
\ *G Enables away mode. This value must be specified with ES_CONTINUOUS.
\ ** Away mode should be used only by media-recording and media-distribution
\ ** applications that must perform critical background processing on desktop
\ ** computers while the computer appears to be sleeping.
\ ** Windows Server 2003 and Windows XP:  ES_AWAYMODE_REQUIRED is not supported.


0x80000000 constant ES_CONTINUOUS
\ *G Informs the system that the state being set should remain in effect until
\ ** the next call that uses ES_CONTINUOUS and one of the other state flags is cleared.

0x00000002 constant ES_DISPLAY_REQUIRED
\ *G Forces the display to be on by resetting the display idle timer.

0x00000001 constant ES_SYSTEM_REQUIRED
\ *G Forces the system to be in the working state by resetting the system idle timer.

0x00000004 constant ES_USER_PRESENT
\ *G This value is not supported. If ES_USER_PRESENT is combined with other esFlags values,
\ ** the call will fail and none of the specified states will be set.
\ ** Windows Server 2003 and Windows XP:  Informs the system that a user is present and resets
\ ** the display and system idle timers. ES_USER_PRESENT must be called with ES_CONTINUOUS.

\ *S Glossary

: SetThreadExecutionState ( execution_state - )
\ *G Set the execution state according using the execution_state.
    call SetThreadExecutionState drop
 ;

: DisableScreenSaver ( - )
\ *G Disables the screen saver. It does not remove an active screen saver.
     ES_CONTINUOUS ES_DISPLAY_REQUIRED or SetThreadExecutionState
 ;

: DisableSleepMode ( - )
\ *G Prevents the sleepmode.
    ES_CONTINUOUS ES_SYSTEM_REQUIRED  or ES_AWAYMODE_REQUIRED or SetThreadExecutionState
 ;

: ClearExecutionState ( - )
\ *G Set the execution_state back to its normal state.
  ES_CONTINUOUS SetThreadExecutionState
 ;

: KeepAwake ( - )
\ *G Prevents the sleepmode and disables the ScreenSaver.
   ES_CONTINUOUS ES_SYSTEM_REQUIRED  or ES_AWAYMODE_REQUIRED or ES_DISPLAY_REQUIRED or SetThreadExecutionState
 ;

\s
