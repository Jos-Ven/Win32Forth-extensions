Anew HelpAboutHibernate.f

needs TextDialog.f

: HelpText ( - ) \ contains the WindowText
   ResetTextlenght
    7 1l   s" The hibernator will try to put your PC in a hibernate" wtype ( x y adr n - x y )
      +l" state when the process in the textbox becomes one"         wtype
      +l" minute inactive. If the hybernate state is not possible"   wtype
      +l" the suspend mode is tried after 1 minute."                 wtype

     +2l" First test the hibernate and suspend state of your PC"  wtype
      +l" without the use of this program. Be sure that the PC"   wtype
      +l" switches itself off without warning after starting"     wtype
      +l" the hibernate mode."                                    wtype

     +2l" Then choose the desired parameter in the hibornator"    wtype
      +l" program and put the parameter in the textbox."          wtype
      +l" Press the button 'Start waiting'. to start"             wtype

     +2l" The Process Identifier (PID) can be obtained"      wtype
      +l" from the taskmanager. Sometimes you may have"      wtype
      +l" to activate an extra column to see it."            wtype

     +2l" Note: This program is depended on the reliability" wtype
      +l" and configuration of your PC."                     wtype

                Delete:    vFont                  \ Changing the font
                s" MS Sans Serif" SetFaceName: vFont
                black SetTextColor: currentDC
                FW_BOLD   Weight: vFont           \ Make it bold
                8 Width:   vFont
                18 Height: vFont
                Create:    vFont
                Handle:    vFont SetFont: currentDC
                TRANSPARENT SetBkMode: currentDC

     +2l" The use of hibernator is at your own risk."        wtype
      2drop
 ;

:OBJECT HelpDialog              <Super TextDialog
                :M WindowTitle: ( -- ztitle )
                   ['] HelpText IsWindowText
                   z" Hibernator help"
                ;M
;OBJECT

wTextlenght SetTextlenght: HelpDialog


: AboutText
   ResetTextlenght

   10 1l   s" The hibernator might safe you energy costs."          wtype

     +2l" EG: A process needs much time to compute."                wtype
      +l" When it is complete the process becomes idle."            wtype
      +l" The hibernator is able to spot this and will"             wtype
      +l" try to put the PC in the hibernate state after"           wtype
      +l" one minute."                                              wtype

     +2l" Your screen and your data should not be changed"          wtype
      +l" by this action, when you activate the PC again."          wtype

     +2l" If a PC is in the hibernate state it uses no power."      wtype
      +l" When the suspend state is active the use of"              wtype
      +l" power is reduced. You will lose data when you"            wtype
      +l" switch off your PC that is in a suspend state."           wtype

     +2l" It is often possible to switch off your monitor to"       wtype
      +l" safe energy without losing data."                         wtype

    nip 50 swap
      +2l" September 14th, 2005."                    wtype
       +l" The hibernator is written in Win32Forth " wtype
       +l" Version 6.11.04 by J.v.d.Ven."            wtype
    2drop
 ;

:OBJECT AboutDialog     <Super TextDialog
               :M WindowTitle: ( -- ztitle )
                   ['] AboutText IsWindowText
                   z" About the hibernator"
               ;M
;OBJECT

wTextlenght SetTextlenght: AboutDialog


: ShowHelpDialog  (  - )    start: HelpDialog  ;
: ShowAboutDialog (  - )    start: AboutDialog ;

\s Test:

 ShowAboutDialog   ShowHelpDialog

\s
