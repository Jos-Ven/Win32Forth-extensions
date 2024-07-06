Anew -MenuBar
: invert-adr        ( adr -- )   dup c@ not swap c! ;
: invert-check      ( check -- ) dup c@ not swap c!   Paint: SplitterWindow ;
: DoEndless         ( -- ) vadr-config Endless-          invert-check ;
: DoAlbum           ( -- ) vadr-config Album-            invert-check ;
: NoJoysticks       ( -- ) vadr-config JoyStickDisabled- invert-check ;
: DoEnableShutdown  ( -- ) vadr-config EnableShutdown-   invert-check ;
: DoNarrator        ( -- ) vadr-config l_Narrator-       invert-check ;

: SwitchWebserver        ( -- )
     vadr-config Webserver- dup invert-check c@
        if    ResumeThreads: WebserverTasks \ IDM_Webserver DoCommand
        \ else  false vadr-config Webserver- c!  \ IDM_DisableWebserver DoCommand
        then
 ;



: SetRateNarrator ( n -- )
   dup 65500 >
     if    65536 swap - negate
     then
   dup vadr-config  VoiceRate c! cpVoice->SetRate
 ;

: StartCoverWindow ( - )
    CoverWindow-
      if    SwitchToProgresWindow: CoverWindow
      else  true to CoverWindow-
            close: ProgresWindow
            SplitterWindow Start: CoverWindow
      then
 ; IDM_DOCOVERWINDOW  SetCommand

: SettingsNarrator     ( -- )
     Start: NarratorWindow
 ;

: .Tooltips
 s"  Move to show an other character " TooltipSw ToolString: TopPane.TrackBar1
 s"  Move to go forwards or backwards " TooltipSw ToolString: TopPane.TrackBarPos
 s"  Move to change \n the volume " TooltipSw ToolString: TopPane.TrackBarVol
 s"  Stop/resume " TooltipSw ToolString: TopPane.Button1
 s"  Search and replace the results " TooltipSw ToolString: TopPane.Button2
 s"  Search previous character " TooltipSw ToolString: TopPane.Button3
 s"  Search next character " TooltipSw ToolString: TopPane.Button4
 s"  Next request " TooltipSw ToolString: TopPane.Button5
 s"  Add to filter \n See the menu File for a new filter  " TooltipSw ToolString: TopPane.Button6
 s"  Remove all results  " TooltipSw ToolString: TopPane.Button7
 s"  Open a filter \n See the menu File for a new filter  " TooltipSw ToolString: TopPane.CmbList1
 s"  Search and add to the results " TooltipSw ToolString: TopPane.Button+
 s"  Search and subtract from the results " TooltipSw ToolString: TopPane.Button-


 s"  Add song or album as a first request " TooltipSw ToolString: Middle.Button1
 s"  Add song or album after the last selected request " TooltipSw ToolString: Middle.Button2
 s"  Add song or album  after the last request " TooltipSw ToolString: Middle.Button3
 s"  Clear all results " TooltipSw ToolString: Middle.Button4

 s"  Remove the selected request and the rest " TooltipSw ToolString: Middle.Button5
 s"  Add random requests " TooltipSw ToolString: Middle.Button6
 s"  Take random request from the search results " TooltipSw ToolString: Middle.Check1

 s"  Move the first position " TooltipSw ToolString: Right.Button1
 s"  Move request up " TooltipSw ToolString: Right.Button2
 s"  Move request down " TooltipSw ToolString: Right.Button3
 s"  Move request to the bottom " TooltipSw ToolString: Right.Button4
 s"  Shuffle requests " TooltipSw ToolString: Right.Button5
 s"  Sort requests " TooltipSw ToolString: Right.Button6
 s"  Show/exlore " TooltipSw ToolString: Right.Button7
 s"  Set the number of requests \n for random additions " TooltipSw ToolString: Right.Button8

 s"  Search for the selected item. \n Old results will be removed " TooltipSw ToolString: FilterWindow.btnSearch
 s"  Search for the selected item and add the found records to the results " TooltipSw ToolString: FilterWindow.btnAdd
 s"  Search for all items and add the found records to the results  " TooltipSw ToolString: FilterWindow.btnAddAll
 s"  Remove the selected item from the results " TooltipSw ToolString: FilterWindow.btnRemove
 s"  Delete the selected item including the duplicates " TooltipSw ToolString: FilterWindow.btnDelete

;

: DoTooltips     ( -- ) vadr-config NoTooltips- invert-check .Tooltips ;

: Set#MaxRandom   ( n -- ) 1 max vadr-config #MaxRandom ! ;

: Enter#OfRequestsToAdd  ( -- )
   SplitterWindow s" Number of requests?"
   vadr-config #MaxRandom @
   ['] Set#MaxRandom ForAskedInteger
 ;



: Set#MaxRndAlbum   ( n -- ) 1 max vadr-config #MaxRndAlbum  ! ;

: Enter#MaxRndAlbum   ( -- )
   SplitterWindow s" Maximal songs in album"
   vadr-config #MaxRndAlbum  @
   ['] Set#MaxRndAlbum ForAskedInteger
 ;



: Set#MaxRndAlbumsReq   ( n -- ) 1 max vadr-config #MaxRndAlbumsReq  ! ;

: Enter#MaxRndAlbumsReq  ( -- )
   SplitterWindow s" Maximal albums"
   vadr-config #MaxRndAlbumsReq  @
   ['] Set#MaxRndAlbumsReq ForAskedInteger
 ;

\ -----------------------------------------------------------------------------
\       Define the Menu bar
\ -----------------------------------------------------------------------------
MENUBAR player4-Menu-bar
    POPUP "&File"
       \ MENUITEM     "&Add missing links of file(s)...\tCtrl+M"                  IDM_ADD_FILES     DoCommand ;
        MENUITEM     "&Import missing links from directory tree...\tCtrl+I"        IDM_IMPORT_FOLDER DoCommand ;
        MENUSEPARATOR
        MENUITEM      "New filter..."                      IDM_Newfilter DoCommand ;
        MENUITEM      "Delete filter..."                   IDM_Deletefilter DoCommand ;
        MENUSEPARATOR
        MENUITEM     "&Export the catalog to JukeBoxIn4Th.csv"   csv-catalog ;
        MENUITEM     "E&xport albums to JukeBoxIn4ThAlbums.csv"  csv-albums ;
        MENUSEPARATOR
        MENUITEM     "&List dead links"                    IDM_ListDeadLinks DoCommand ;
        MENUSEPARATOR
        MENUITEM     "&Remove dead links"                  IDM_RemoveDeadLinks DoCommand ;
        MENUSEPARATOR
        MENUITEM     "&Exit\tAlt+F4"                       IDM_QUIT DoCommand ;

    POPUP "&Play"
        MENUITEM     "&Pause/Resume playing\tCtrl+R"       IDM_START/RESUME  DoCommand ;
        MENUITEM     "&Next request\tCtrl+N"               IDM_NEXT  DoCommand ;
        MENUITEM     "&Announce \tCtrl+Q"                  IDM_DOANNOUNCE DoCommand ;
        MENUSEPARATOR
        MENUITEM     "&Cover window\tCtrl+W"               IDM_DOCOVERWINDOW DoCommand ;

    POPUP "&Webserver"
       :MENUITEM   mWebserver "Enable Webserver"                      SwitchWebserver  ;
        MENUSEPARATOR
        MENUITEM   "Setup &webserver address" SplitterWindow  start: WebserverAddressDialog ;
        MENUITEM   "Setup WiFi &info"         SplitterWindow  start: FormWiFi               ;
        MENUSEPARATOR
        :MENUITEM mRights  "---Access rights clients---" noop ;
       :MENUITEM   mAccessLevel1 "Read only"    Read_only   vadr-config AccessLevel c! MenuChecks ;
       :MENUITEM   mAccessLevel2 "Adjust que"   Adjust_que  vadr-config AccessLevel c! MenuChecks ;
       :MENUITEM   mAccessLevel3 "Full access"  Full_access vadr-config AccessLevel c! MenuChecks ;

    POPUP "&Options"
        MENUITEM     "&Setup search path catalog..."       IDM_SETUPPATH DoCommand ;
        MENUSEPARATOR
        MENUITEM    "&Settings Narrator..."                SettingsNarrator ;
        MENUSEPARATOR
       :MENUITEM   mNarrator "Enable Narrator" DoNarrator ;
        MENUSEPARATOR
        :MENUITEM mRnd  "---Random proporties---" noop ;
       :MENUITEM   mEndless  "Random again before the last request" DoEndless ;
       :MENUITEM   mAlbum  "Take complete albums"             DoAlbum ;
        MENUITEM   "Maximal number of albums"  Enter#MaxRndAlbumsReq ;
        MENUITEM   "Maximal songs in album"  Enter#MaxRndAlbum ;
        MENUITEM   "Maximal number of requests"  Enter#OfRequestsToAdd ;
        MENUSEPARATOR
       :MENUITEM   mNoTooltips  "Disable tooltips"              DoTooltips ;
       :MENUITEM   mJoyStickDisabled "Disable joystick"        NoJoysticks ;
       :MENUITEM   mEnableShutdown "Enable suspend from joystick" DoEnableShutdown ;


    POPUP "&Help"
        MENUITEM     "Info"          GetHandle: SplitterWindow AboutMsg ;
        MENUITEM     "Manual"                      IDM_Manual DoCommand ;
ENDBAR


:Noname ( -- )
         false Enable: mRnd
         false Enable: mRights
         vadr-config l_Narrator-         c@ Check: mNarrator
         vadr-config Webserver-          c@ Check: mWebserver
\        vadr-config AutoMinimized-      c@ Check: mTray
\        vadr-config IgnoreRequests      c@ Check: mHandelReq
         vadr-config Endless-            c@ Check: mEndless
         vadr-config Album-              c@ Check: mAlbum
         vadr-config JoyStickDisabled-   c@ Check: mJoyStickDisabled
         vadr-config EnableShutdown-     c@ Check: mEnableShutdown
         vadr-config AccessLevel c@ Read_only   = Check: mAccessLevel1
         vadr-config AccessLevel c@ Adjust_que  = Check: mAccessLevel2
         vadr-config AccessLevel c@ Full_access = Check: mAccessLevel3
         vadr-config NoTooltips-         c@ Check: mNoTooltips
        ; is MenuChecks    \ enable/disable the menu items ))

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\       Accelerator Table - support
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

AccelTable table

        \ falgs         key-code        command-id
        FALT            VK_F4           IDM_QUIT                ACCELENTRY
        FCONTROL        'I'             IDM_IMPORT_FOLDER       ACCELENTRY
        FCONTROL        'M'             IDM_ADD_FILES           ACCELENTRY
        FCONTROL        'N'             IDM_NEXT                ACCELENTRY
        FCONTROL        'R'             IDM_START/RESUME        ACCELENTRY
        FCONTROL        'Q'             IDM_DOANNOUNCE          ACCELENTRY
        FCONTROL        'W'             IDM_DOCOVERWINDOW       ACCELENTRY


SplitterWindow HandlesThem
