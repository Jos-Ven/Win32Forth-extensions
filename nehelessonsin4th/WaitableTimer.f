anew -WaitableTimer.f   \ April 26th, 2013 by Jos v.d.Ven Version


2 cells constant 2cells

\  SetWaitableTimer needs:
\ ( fResume lpArgToCompletionR pfnCompletionR lPeriod *pDueTime hTimer -)

: StartTimer  ( F: 100Nanosec - )  { HndlTimerObject \ *pDueTime -- }
  2cells LocalAlloc: *pDueTime
  fnegate f>d
  swap *pDueTime 2!  false 0 0 0 *pDueTime HndlTimerObject
  call SetWaitableTimer drop
 ;

: CreateTimer ( -  handleTimerObject )
\ Can be closed with CloseHandle function
   0 true 0 call CreateWaitableTimer
 ;

: WaitHndl ( Hndl - )
  INFINITE swap call WaitForSingleObject drop
 ;

\s Use:

0 value HOpenGLTimer
: InitOpenGLTimer   ( - )  CreateTimer to HOpenGLTimer ;
: CloseHOpenGLTimer ( -- ) HOpenGLTimer close-file drop ;

initialization-chain chain-add InitOpenGLTimer
InitOpenGLTimer

unload-chain chain-add CloseHOpenGLTimer

10000000e fconstant fsecond

: testTimer
   1e fsecond f*
   HOpenGLTimer StartTimer
   HOpenGLTimer WaitHndl
   beep
 ;

testTimer abort

\s
