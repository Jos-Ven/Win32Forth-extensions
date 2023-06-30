\ $Id: CommandID.f,v 1.4 2006/07/08 19:58:52 jos_ven Exp $
\    File: CommandID.f
\
\  Author: Dirk Busch (dbu)
\   Email: dirkNOSPAM@win32forth.org
\
cr .( Loading Menu Command ID's...)

: NewID ( <name> -- )
        defined
        IF   drop
        ELSE count "header NextId  \in-system-ok  DOCON , ,
        THEN ;

IdCounter constant IDM_FIRST


\ File menu
NewID IDM_ADD_FILES
NewID IDM_IMPORT_FOLDER
NewID IDM_START/RESUME
NewID IDM_QUIT
NewID IDM_Newfilter
NewID IDM_Deletefilter

\ Play menu
NewID IDM_ListDeadLinks
NewID IDM_SETUPPATH
NewID IDM_RemoveDeadLinks
NewID IDM_DOANNOUNCE
NewID IDM_DOCOVERWINDOW


\ Options menu
NewID IDM_AUDIO_ON
NewID IDM_AUDIO_OFF

\ Help menu
NewID IDM_Manual
NewID IDM_ABOUT

\ Other commands
NewID IDM_PAUSE/RESUME
NewID IDM_STOP
NewID IDM_NEXT
NewID ID_CmbList1
NewID ID_CmbListMore

NewID ID_Check1
NewID ID_CmbListFilter


IdCounter constant IDM_LAST

: allot-erase   ( n -- )
                here over allot swap erase ;

Create CommandTable IDM_LAST IDM_FIRST - cells allot-erase

: IsCommand?    ( ID -- f )
                IDM_FIRST IDM_LAST within ;

: >CommandTable ( ID -- addr )
                dup IsCommand?
                if   IDM_FIRST - cells CommandTable +
                else drop abort" error - command ID out of range"
                then ;

: DoCommand     ( ID -- )
                >CommandTable @ ?dup IF execute THEN ;

: SetCommand    ( ID -- )
                last @ name> swap >CommandTable ! ;

\ Access levels for the web interface
1 constant Read_only
2 constant Adjust_que
3 constant Full_access

\s
