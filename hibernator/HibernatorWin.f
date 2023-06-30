\ HIBERNATOR.FRM
\- textbox needs excontrols.f

Anew HibernatorWin.f \ September 14th, 2005. For Win32Forth version 6.11.04 or better.

needs Resources.f
needs Hibernator.f
needs config.f
needs TextDialog.f
needs HelpAboutHibernate.f

s" Hibernator.dat" ConfigFile$  place
Config$:        Hibernate$
Config$:        TextBox1$
ConfigVariable  UsePid-

create FirstLine$ maxstring allot

: +FirstLine$   ( $ count - )   FirstLine$ +place ;
: +Hibernate$   ( $ count - )   Hibernate$ +place ;
: Data/TimeHib$ ( - )           Hibernate$  Date/Time$!  s" : " +Hibernate$ ;

60000 constant TimeOut \ in MS

:Object Hibernator                <Super DialogWindow

int Phndl

Font WinFont
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color
0 value parent   \ pointer to parent of form

Label LblFirstLine
Label LblHibernate
TextBox TextBox1
Label LblProcWait
PushButton bStartWaiting   \ IDOK
PushButton bAbortWaiting   \ IDCancel
PushButton bHelp        200 constant IdHelp
PushButton bAbout       201 constant IdAbout
GroupBox LblParameter
RadioButton Radio1      51 constant IDR1
RadioButton Radio2      52 constant IDR2

:M ClassInit:   ( -- )
                ClassInit: super
                \ Insert your code here
                ;M

:M DefaultIcon: ( -- hIcon )            \ return the default icon handle for window
        LoadAppIcon ;M

:M WindowStyle:  ( -- style )
                WS_POPUPWINDOW WS_DLGFRAME or
                ;M

\ if this form is a modal form a non-zero parent must be set
:M ParentWindow:  ( -- hwndparent | 0 if no parent )
                parent
                ;M

:M SetParent:  ( hwndparent -- ) \ set owner window
                to parent
                ;M

:M WindowTitle: ( -- ztitle )
                z" Hibernator"
                ;M

:M StartSize:   ( -- width height )
                451 237
                ;M

:M GetPositionParent: ( -- x y wb hb )   \ return upper-left corner
     Parent 0>
        if      pad 16 erase
                pad Parent Call GetWindowRect  ?WinError
                pad 2@ swap pad 8 + 2@ swap
         else   0 0 GetDeskTopSize  \ take the desktop when there is no parent.
         then
      ;M

:M StartPos:    ( -- x y )
                GetPositionParent: Self
                MidPoint
                StartSize: self
                CenterAroundMidpoint
                ;M


:M Close:        ( -- )
                \ Insert your code here
                Close: super
                ;M

:M On_Init:     ( -- )
                0 to Phndl
                EnableConfigFile
                StartPos: Self 2dup
                GetHandle: Self SetParentPos: HelpDialog
                GetHandle: Self SetParentPos: AboutDialog

                s" MS Sans Serif" SetFaceName: WinFont
                8 Width: WinFont
                Create: WinFont

                \ set form color to system color
                COLOR_BTNFACE Call GetSysColor NewColor: FrmColor

                IDR1 SetID: Radio1
                self Start: Radio1
                50 27 277 24 Move: Radio1
                Handle: Winfont SetFont: Radio1
                s" Enter a unique part of a window name." SetText: Radio1

                IDR2 SetID: Radio2
                self Start: Radio2
                50 50 227 16 Move: Radio2
                Handle: Winfont SetFont: Radio2
                s" Enter the PID of a process." SetText: Radio2

                self Start: LblFirstLine
                30 130 407 20 Move: LblFirstLine
                Handle: Winfont SetFont: LblFirstLine
                s" Enter your parameter" SetText: LblFirstLine

                self Start: LblHibernate
                30 155 407 20 Move: LblHibernate
                Handle: Winfont SetFont: LblHibernate
                Hibernate$ count SetText: LblHibernate

                self Start: TextBox1
                30 90 407 23 Move: TextBox1
                Handle: Winfont SetFont: TextBox1
                TextBox1$ count SetText: TextBox1
                SelectAll: TextBox1

                IDOK SetID: BStartWaiting
                self Start: bStartWaiting
                120 187 100 37 Move: bStartWaiting
                Handle: Winfont SetFont: bStartWaiting
                s" Start waiting" SetText: bStartWaiting

                IDCancel SetID: bAbortWaiting
                self Start: bAbortWaiting
                10 187 100 37 Move: bAbortWaiting
                Handle: Winfont SetFont: bAbortWaiting
                s" Abort waiting" SetText: bAbortWaiting

                self Start: LblParameter
                30 10 407 63 Move: LblParameter
                Handle: Winfont SetFont: LblParameter
                s" Used parameter:" SetText: LblParameter

                IdHelp SetID: bHelp
                self Start: bHelp
                230 187 99 37 Move: bHelp
                Handle: Winfont SetFont: bHelp
                s" Help" SetText: bHelp

                IdAbout SetID: bAbout
                self Start: bAbout
                340 187 100 37 Move: bAbout
                Handle: Winfont SetFont: bAbout
                s" About" SetText: bAbout

                UsePid- @ dup not Check: Radio1 Check: Radio2
                ;M

: GetParameters ( - ) ( - TextBox1 count )
        GetText: TextBox1
        2dup TextBox1$ place  \ Safe it in Hibernator.dat
 ;

: UpdateHybernate$ ( - )
       Hibernate$ +null Hibernate$ count  SetText: LblHibernate
       Paint: self
 ;

: EmptyHibernate$  ( - )
        space$ Hibernate$ place UpdateHybernate$
 ;

: StopMonitoring  ( - )
    Phndl
      if  1 hWnd Call KillTimer
          Phndl  call CloseHandle 2drop
          0 to Phndl
      then
 ;

: PromptFirstLine ( - )
    FirstLine$ Date/Time$!
    s" : Waiting for " +FirstLine$
 ;

: GetPidFromWindow ( *name count - Pid )
    dup>r search-window dup 0> r> and 0<>
      if    PromptFirstLine
            temp$ count +FirstLine$ FirstLine$ +null
            lpKernelTime sizeof filetime erase
            lpUserTime   sizeof filetime erase
            WindowThreadID
      else  true abort" Window not found."
      then
 ;

: ConvertToPid  ( adr count - CandPid )
    number? not abort" Bad number for PID" d>s
 ;

: WaitHibernateWin  ( - )
    StopMonitoring      \ Avoid nesting
    GetParameters UsePid- @
        if     2dup ConvertToPid -rot PromptFirstLine +FirstLine$
        else   GetPidFromWindow
        then
    OpenProcess dup 0= Abort" Can't open process to monitor it."  to Phndl
    FirstLine$ count SetText: LblFirstLine
    EmptyHibernate$
    0 TimeOut 1 hWnd Call SetTimer drop
 ;

: HandleButtons ( Action/Button - )
       case
          IDR1        of   false UsePid- !                      endof
          IDR2        of   true  UsePid- !                      endof
          IDOK        of   SetFocus: BStartWaiting
                             TestHibernate WaitHibernateWin not
                                 if   s" to suspend"
                                 else s" to hibernate"
                                 then
                             Hibernate$ place
                             s"  the system." +Hibernate$
                             UpdateHybernate$                   endof
          IDCancel    of   StopMonitoring  SetFocus: bAbortWaiting
                             s" Waiting aborted"
                             FirstLine$ place FirstLine$ +null
                             FirstLine$ count SetText: LblFirstLine
                           EmptyHibernate$                      endof
          IdHelp      of   ShowHelpDialog                       endof
          IdAbout     of   ShowAboutDialog                      endof
       endcase
    Paint: self
 ;

:M WM_COMMAND   ( h m w l -- res )
                over LOWORD ( ID ) self   \ object address on stack
                WMCommand-Func ?dup       \ must not be zero
                if        execute drop HandleButtons
                else      2drop           \ drop ID and object address
                then        0 ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Paint:    ( -- )
                0 0 GetSize: self Addr: FrmColor FillArea: dc
                ;M

: SuspendFailedMsg ( err msg count- )
       Data/TimeHib$ +Hibernate$
       s>d (d.)    +Hibernate$  s" : "  +Hibernate$
       temp$ count +Hibernate$
       UpdateHybernate$
 ;

: SuspendSystem   ( - )
       Data/TimeHib$  s" Starting the suspend state." +Hibernate$
       UpdateHybernate$  false suspend dup
             if      s" Suspending failed." SuspendFailedMsg
             else    drop
             then
 ;

:M WM_TIMER     ( hm wl -- res ) \ handle the WM_TIMER events
      Phndl NoTimeUsedAtAll?
          if    StopMonitoring TestHibernate
                        if      Data/TimeHib$
                                s" Starting the hibernate state." +Hibernate$
                                UpdateHybernate$  true suspend drop 
                                TimeOut 1000 / seconds TestHibernate dup 0=
                                        if    s" Hibernating failed." SuspendFailedMsg
                                              SuspendSystem
                                        else  drop
                                        then
                        else    SuspendSystem
                        then
          then
        2drop  0
        ;M

:M On_Done:    ( -- )
                Delete: WinFont
                \ Insert your code here
                StopMonitoring DisableConfigFile
                On_Done: super
                bye
                ;M

;Object


: StartHibernator start: Hibernator ;

'  StartHibernator turnkey Hibernator
s" Hibernator.ico" s" Hibernator.exe"  AddAppIcon
StartHibernator

\s
