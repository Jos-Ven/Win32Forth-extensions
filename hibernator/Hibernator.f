needs struct.f
needs w_search.f

Anew Hibernator.f


struct{ \ _FILETIME { // ft
    DWORD dwLowDateTime
    DWORD dwHighDateTime
}struct filetime

sizeof filetime mkstruct: lpCreationTime  // when the process was created
sizeof filetime mkstruct: lpExitTime      // when the process exited
sizeof filetime mkstruct: lpKernelTime    // time the process has spent in kernel mode
sizeof filetime mkstruct: lpUserTime      // time the process has spent in user mode


: FillProcessTimes  ( Phndl - f )
   >r lpUserTime lpKernelTime lpExitTime lpCreationTime r> call GetProcessTimes
 ;

: NoTimeUsed? ( LowDateTime dwHighDateTime adr-time - f )
   dup>r 2@ 2dup r> 2! d- d0=
 ;

: NoTimeUsedAtAll? ( Phndl - flag )
    >r lpUserTime 2@  lpKernelTime 2@
    r> FillProcessTimes drop
    lpKernelTime NoTimeUsed? -rot
    lpUserTime   NoTimeUsed?  and
 ;

\ A process is considered to be inactive when there is no usertime
\ or kerneltime registered by windows during one minute.

: ProcessWaitInactive { Phndl --  }
   begin  60000 ms Phndl NoTimeUsedAtAll?
   until
 ;

: space$      ( - adr cnt  )   s"  " ;
: GetDate$    ( -- )  get-local-time time-buf >date" ;
: Gettime$    ( -- )  get-local-time time-buf >time" ;
: Date/Time$! ( $ - ) >r GetDate$ r@ place space$ r@ +place Gettime$ r> +place ;

WinLibrary NTDLL.DLL
WinLibrary powrprof.dll

: suspend ( flag  - Err|0) \ True=Hybernate
  false true rot call SetSuspendState 0=
    if    GetLastWinErr
    else  false
    then
 ;

: WindowThreadID ( hwnd -  Pid )
   pad swap call GetWindowThreadProcessId  drop pad @
 ;

: OpenProcess   ( Pid - Phndl|0 )  true PROCESS_ALL_ACCESS call OpenProcess  ;
: TestHibernate ( - flag )         call IsPwrHibernateAllowed  ;

\s

Platform SDK: Power Management


The SetSuspendState function suspends the system by shutting power down.
Depending on the Hibernate parameter, the system either enters a suspend (sleep)
 state or hibernation (S4).


BOOLEAN SetSuspendState(
  BOOL Hibernate,
  BOOL ForceCritical,
  BOOL DisableWakeEvent
);

Parameters
Hibernate
  If this parameter is TRUE, the system hibernates.
  If the parameter is FALSE, the system is suspended.
ForceCritical
  If this parameter is TRUE, the system suspends operation immediately;
  if it is FALSE, the system broadcasts a PBT_APMQUERYSUSPEND event to each application
  to request permission to suspend operation.
DisableWakeEvent
 If this parameter is TRUE, the system disables all wake events.
 If the parameter is FALSE, any system wake events remain enabled.
Return Values
  If the function succeeds, the return value is nonzero.
  If the function fails, the return value is zero.
  To get extended error information, call GetLastError.

Remarks
An application may use SetSuspendState to transition the system from the working
state to the standby (sleep), or optionally, hibernate (S4) state.
This function is similar to the SetSystemPowerState function.

Requirements
Client Requires Windows XP, Windows 2000 Professional, Windows Me, or Windows 98.
Server Requires Windows Server 2003 or Windows 2000 Server.
Header Declared in Powrprof.h.

Library Link to Powrprof.lib.
DLL Requires PowrProf.dll.

==============
IsPwrHibernateAllowed

The IsPwrHibernateAllowed function determines whether the computer supports hibernation.


BOOLEAN IsPwrHibernateAllowed(void);

Parameters
This function has no parameters.
Return Values
If the computer supports hibernation (power state S4) and the file Hiberfil.sys
is present on the system, the function returns TRUE. Otherwise, the function returns FALSE.

Remarks
