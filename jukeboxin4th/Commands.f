Anew -commands.f

needs CommandID.f

\ Note: A number of options are not used and should be tested before using them.

: DoAnnounce ( - )
   busy? not pfilename$ @ 0<> and
     if  true to busy? false to SayNext PausePlay
         h_ev_h_ev_tts_done event-reset
         pfilename$ count 300 ms _Announce
         WaitForTts
         300 ms mp vlc-play
         false to busy?
     then
 ; IDM_DOANNOUNCE SetCommand


: (RefreshCatalog ( - )
   false SetRedraw: CatalogWindow
   Refresh: CatalogWindow
   Expand: CatalogWindow
   true SetRedraw: CatalogWindow
   paint: CatalogWindow
 ;  ' (RefreshCatalog is (RefreshCatalog)

: SortCatalogByRecord ( - )
   by[ by_record ]by Sort-database: Catalog
   RefreshCatalog
;

: SetUpPath ( - )
   SplitterWindow start: Form_search_path
  ; IDM_SETUPPATH SetCommand


:Inline ExitOnPathError ( - )
    CatalogPath-does-not-exist  if SetUpPath exit then
 ;

: AddFiles      ( -- )
       ExitOnPathError
       AddFilesFromSelector: SplitterWindow
       Build-free-list: Catalog
       SortCatalogByRecord
       RefreshRequests
 ; IDM_ADD_FILES SetCommand

: InfoAt ( adr - $ x y )
   drop 1- GetWindowRect: SplitterWindow 2drop 80 -
 ;

: UpdateWaitWindow ( - )
   false Enable: SplitterWindow
   #done off
      begin   Paint: WaitWindow ( SelectCursor: WaitWindow ) 1000 ms busy? not
      until
   true Enable: SplitterWindow
 ;


: ImportFolder  ( -- )
    ExitOnPathError
    z" Import missing links to the music files\nfrom the underlaying folders at:"
    vadr-config PathMediaFiles dup +null GetHandle: SplitterWindow
    BrowseForFolder
          If  vadr-config PathMediaFiles dup +null count GetLabel
              SplitterWindow  Start: WaitWindow  ['] UpdateWaitWindow submit: RightPane winpause
              wait-cursor add_dir_tree RefreshRequests ExpandFirst2Requests Close: WaitWindow
          then
    ; IDM_IMPORT_FOLDER SetCommand

: ShowDeleted   ( -- )
        true to show-deleted
        Refresh: CatalogWindow
        false to show-deleted
        ;

: catalog-exist? ( - flag  )  catalog-exist?: Catalog ;

: valid-record? ( -- flag )
        catalog-exist?  GetSelectedLparmCatalogWindow -1 <> and ;

\ Buttons in the Jukebox

: DeleteAllRequests ( - )
    RemoveAllRequests unmap-ReqIdx
    RequestIndex$ count delete-file drop
    Refresh: RequestWindow
    Expand:  RequestWindow
 ;

: AskDeleteAllRequests ( - )
  z" Would you like to remove all requests?"
  z" Confirm the following removal:"
  y/n-box  IDYES  =
     if   RemoveAllRequests DeleteAllRequests
     then
;

: _UpdateLastSelected { Lparm \ zArtist$ -- }
    MAXCOUNTED 1+ LocalAlloc: zArtist$
    Lparm dup to last-selected -1 <>
       if   noop
       else pfilename$ count dup 0>
              if ExtractRecord
              else 2drop exit
              then     InlineRecord to Lparm
       then
    ResetContent: Middle.CmbListMore
    SplitterWindow.Width 2/ SetDroppedWidth: Middle.CmbListMore
    FirstLine: Middle.CmbListMore
       Lparm CountedArtist zArtist$ place zArtist$ +null zArtist$ 1+ AddStringTo: Middle.CmbListMore
            zArtist$ count pad place s" *\" pad +place
            Lparm CountedAlbum pad +place pad +null pad 1+ AddStringTo: Middle.CmbListMore
            zArtist$ count pad place s" *\" pad +place
            Lparm CountedTitle pad +place pad +null pad 1+ AddStringTo: Middle.CmbListMore
      0 SetSelection: Middle.CmbListMore

 ; ' _UpdateLastSelected is UpdateLastSelected


: SelectedRequestTolast-selected  ( - )
    GetSelectedItem: RequestWindow dup 0<>
       if  FindAdresRecord: MediaTree dup
           GetLparm: RequestWindow n>record: Requests
       else  drop -1
       then
   UpdateLastSelected
 ;

: Delete#RequestExpand ( n - )
     dup ResetRequest
     dup 1 MoveRequestsUp 1 ShrinkRequestFile RefreshRequests
     ExpandAround  SelectedRequestTolast-selected
 ;

: _DeleteSelectedRequest ( hItem - )
     GetLparm: RequestWindow dup -1 <>
         if  Delete#RequestExpand
         else  drop \ Try selection
         then
    ;


: Delete#Request ( #InRequestFile - )
   dup ResetRequest 1 MoveRequestsUp 1 ShrinkRequestFile
 ;

: DeleteRequest ( hItem - )
     GetLparm: RequestWindow dup -1 <>
         if   Delete#Request
         else drop
         then
 ;

0 value #ToShrink

: DeleteDuplicateRequests ( RelIdCatalog - )
    0 to #ToShrink
   n>record: catalog
   #RequestsInFile 0
     ?do dup i  n>record: Requests =
        if   i  dup ResetRequest 1 MoveRequestsUp 1 +to #ToShrink
        then
    loop
    #ToShrink ShrinkRequestFile
  drop
 ;


: DeleteDeadRequest ( n - 1/0 ) \  0 means one deleted
    dup n>record: Requests  deleted?
        if    1 MoveRequestsUp 1 +to #ToShrink 0
        else  drop 1
        then
   ;

: DeleteDeadRequests 0 { n }  ( -- )
   0 to #ToShrink
   #RequestsInfile 0
      ?do  n DeleteDeadRequest +to n
      loop
   #ToShrink ShrinkRequestFile
   RefreshRequests 0 ExpandAround
 ;


: DeleteSelectedRequest ( - )
   GetSelectedItem: RequestWindow dup
   GetRoot: RequestWindow =
      if     drop AskDeleteAllRequests
      else   dup 0 <>
                if    _DeleteSelectedRequest
                else  drop
                then
      then
 ;

: RedrawRw ( - )
          true SetRedraw: RequestWindow
          Paint: RequestWindow.TreeView
 ;

: RedrawLw ( - )
          true SetRedraw: CatalogWindow
          paint: CatalogWindow
 ;

: NoRedrawLw      ( - )  false SetRedraw: CatalogWindow ;
: NoRedrawRw      ( - )  false SetRedraw: RequestWindow ;

: DeleteSelectedAlbum ( - ) { \ RecAlbumPtr -- }
    Disable: Middle.Button4 Update: Middle.Button4
    OpenChild: RequestWindow
    GetlParmSelectedItem: RequestWindow n>record: Requests to RecAlbumPtr
        begin  GetlParmSelectedItem: RequestWindow n>record: Requests
               CountedAlbum RecAlbumPtr CountedAlbum compare 0=
        while  NoRedrawRw  DeleteSelectedRequest RedrawRw winpause
        repeat
    true Enable: Middle.Button4
 ;

: RequestAlbum?  ( - flag )
    GetlParmSelectedItem: RequestWindow -1 <>
     if    false
     else  GetSelectedItem: RequestWindow  GetChild: RequestWindow
           GetLparm: RequestWindow -1 <>
     then
 ;

: HighPrio ( - )
   THREAD_PRIORITY_ABOVE_NORMAL SetPriority
 ;

: BtDeleteSelectedRequestTask ( - )
   HighPrio NotBusy?
    if   WaitState  RequestAlbum?
             if     DeleteSelectedAlbum
             else   NoRedrawRw DeleteSelectedRequest RedrawRw
             then
         GetlParmSelectedItem: RequestWindow 1- ExpandAround  ReadyState
    then
 ;

: BtDeleteSelectedRequest  ( -- )
  ['] BtDeleteSelectedRequestTask LockExecute: RightPane
 ;

: _DeleteDownFrom ( lparm - )
   #RequestsInFile swap 2dup
     do    I ResetRequest
     loop
   - ShrinkRequestFile RefreshRequests ExpandFirst2Requests
 ;


: DeleteDownFromTask  ( - )
  HighPrio NotBusy?
     if  NoRedrawRw WaitState
         GetSelectedLparmRequestWindow  dup 0 <
            if   drop OpenChild: RequestWindow
                 OpenChild: RequestWindow
                 GetSelectedLparmRequestWindow
            then
          dup 1 <
             if     drop AskDeleteAllRequests
             else   dup 0 <>
                 if   _DeleteDownFrom
                 else  drop
                 then
             then
     ReadyState RedrawRw SelectRootRequests
     then
 ;

: DeleteDownFrom  ( -- )
  ['] DeleteDownFromTask LockExecute: RightPane
 ;

: ExchangeRequestUp { Lparm -- }
   Lparm    n>aptr: Requests
   Lparm 1- dup>r n>aptr: Requests
   2dup @ >r @ swap ! r> swap !
   NoRedrawRw
   RefreshRequests
   r> ExpandAround \ ExpandSelectRequest
   RedrawRw
 ;

: ExchangeRequestDown { Lparm -- }
   Lparm    n>aptr: Requests
   Lparm 1+ dup>r n>aptr: Requests
   2dup @ >r @ swap ! r> swap !
   NoRedrawRw
   RefreshRequests
   r> ExpandAround \ ExpandSelectRequest
   RedrawRw
 ;

: MoveRequestUp  ( - )
   GetSelectedItem: RequestWindow dup 0 <>
     if  GetLparm: RequestWindow dup -1 =
         NoRedrawRw
           if   drop ExpandAlbum   exit
           then
         dup 0>
              if    ExchangeRequestUp
              else  drop
              then
         RedrawRw
     else  drop
     then
 ;

: MoveRequestToTop { Lparm -- }
\  Puts the one at Lparm at the top and moves the rest down to lparm
  Lparm n>aptr:  Requests @
  0  n>aptr:  Requests dup
  1  n>aptr:  Requests
  Lparm cells move !
  0 RefreshRequests ExpandAround
;

: MoveRequestTop  ( - )
         GetSelectedItem: RequestWindow dup 0 <>
            if  GetLparm: RequestWindow dup -1 =
                   if    drop ExpandAlbum
                   else  dup 0>
                          if    MoveRequestToTop
                          else  drop
                          then
                    then
            else  drop
            then
 ;


: BtMoveRequestTop  ( - )
   NotBusy?
     if  WaitState MoveRequestTop     ReadyState
     then
 ;

: GetHndlDuplicate ( - hIntree )
    GetSelectedLparmCatalogWindow n>record: catalog
    RecordDef hIntree @
;

: SelectDuplicate ( - )
    GetHndlDuplicate SelectTreeViewItem: RequestWindow
 ;

-10 value PrevRequest

: ShowFirstSong  ( Lparm - )
    dup 0 <>
     if   GetSelectedItem: CatalogWindow
          dup 0=
              if  drop  GetRoot: CatalogWindow
                  dup TVGN_FIRSTVISIBLE SelectItem: CatalogWindow
                  dup ExpandRecord: CatalogWindow
                      SelectTreeViewItem: CatalogWindow
              then
          ExpandRecord: CatalogWindow drop
          OpenChild: CatalogWindow
          OpenChild: CatalogWindow
          OpenChild: CatalogWindow
          OpenChild: CatalogWindow
     else drop
     then
 ;


: NoRequestSelected?      ( - f )
        GetSelectedLparmCatalogWindow dup -1 =
        if   ShowFirstSong
        else drop false
        then
 ;

: RemoveIfDuplicate ( - )  \ Deletes the candidate duplicate in the request pane
    DuplicateRequest?      \ and keeps the selected record in the request pane
       if   GetSelectedLparmRequestWindow
            GetHndlDuplicate dup GetLparm: RequestWindow swap DeleteRequest
            2dup =
                 if   drop  GetSelectedItem: RequestWindow  GetChild: RequestWindow ExpandItem: RequestWindow
                 else over <
                      if   2 -
                      then
                 Lparm>hIntreeRequest SelectTreeViewItem: RequestWindow
                 then
       then
 ;



: (RequestToFirst ( - )
    NoRedrawRw RemoveIfDuplicate  #RequestsInFile 0>
           if    GetSelectedLparmCatalogWindow MakeRequest 0 MoveRequestsDown
                 GetSelectedLparmCatalogWindow dup to PrevRequest
                 n>aptr: Catalog @ 0 n>aptr: Requests !
                 DownInTree: CatalogWindow
                 FinishRequest
                 ExpandFirst2Requests
           else  RequestRecord
           then
    RedrawRw
 ;

: AlbumSelected? ( - ior )
   GetSongSlectedItem: CatalogWindow dup -1 <>
     if   OpenChild: CatalogWindow
     else  drop 0
     then
 ;




: FindLastSong ( n n1 - nx Hitem )
      Begin   2dup <>
      while   DownInTree: CatalogWindow nip GetSelectedItem: CatalogWindow
      repeat
 ;


: RequestToFirstTask ( - )
  HighPrio NotBusy?
     if  WaitState AlbumSelected? dup 0<>
         if  Disable: Middle.Button1 Update: Middle.Button1
             NoRedrawLw  0 swap FindLastSong
               drop -1 (RequestToFirst UpInTree: CatalogWindow
                   Begin   2dup <>
                   while   (RequestToFirst  UpInTree: CatalogWindow winpause
                           UpInTree: CatalogWindow  nip GetSelectedItem: CatalogWindow
                   repeat  2drop  true Enable: Middle.Button1
         else   drop  GetSelectedLparmCatalogWindow -1 =
                   if    ShowFirstSong
                   else  (RequestToFirst
                   then
         then
       RedrawLw  0 ExpandSelectRequest ReadyState
    then
 ;


: RequestToFirst ( - )
   ['] RequestToFirstTask LockExecute: RightPane
 ;

: (RequestToSecond
         RemoveIfDuplicate NoRedrawRw #RequestsInFile 1 >
           if GetSelectedLparmCatalogWindow MakeRequest GetSelectedLparmRequestWindow 0 max 1+
              dup>r MoveRequestsDown
              GetSelectedLparmCatalogWindow dup to PrevRequest
              n>aptr: Catalog @
              r@ n>aptr: Requests !
              FinishRequest ExpandFirst2Requests
              r> ExpandSelectRequest
              DownInTree: CatalogWindow
           else  RequestRecord
           then

 ;


: RequestToSecondTask ( - )
  HighPrio NotBusy?
     if  WaitState AlbumSelected? dup 0<>
         if Disable: Middle.Button2 Update: Middle.Button2 -1 NoRedrawLw ExpandAlbum
                      Begin   2dup <>
                      while   (RequestToSecond RedrawRw
                              nip GetSelectedItem: CatalogWindow winpause
                      repeat  2drop  true Enable: Middle.Button2
         else drop GetSelectedLparmCatalogWindow -1 =
                  if   ShowFirstSong
                  else (RequestToSecond RedrawRw
           then
        then
    RedrawLw ReadyState
    then
 ;

: RequestToSecond ( - )
   ['] RequestToSecondTask LockExecute: RightPane
 ;


: (RemoveFromResult ( - )
   -1 GetSelectedLparmCatalogWindow
   n>record: catalog  RecordDef Excluded- c!
 ;

: RemoveFromResult ( - )
    NotBusy?
     if  WaitState NoRedrawLw AlbumSelected? dup 0<>
         if -1 \ ExpandAlbum
                      Begin   2dup <>
                      while   (RemoveFromResult nip
                               DownInTree: CatalogWindow GetSelectedItem: CatalogWindow
                      repeat  2drop RefreshCatalog
         else drop GetSelectedLparmCatalogWindow -1 =
                  if   ShowFirstSong
                  else (RemoveFromResult RefreshCatalog
           then
        then
    ReadyState
    then
 ;

: (RequestToLast ( - )    RemoveIfDuplicate   RequestRecord   ;

: RequestToLastTask  ( -- )
  HighPrio NotBusy?
     if  WaitState  AlbumSelected? dup 0<>
          if  Disable: Middle.Button3 Update: Middle.Button3 -1 NoRedrawLw
                      Begin   2dup <>
                      while   NoRedrawRw (RequestToLast nip GetSelectedItem: CatalogWindow
                              ExpandLast: RequestWindow RedrawRw winpause
                      repeat  2drop RedrawLw  true Enable: Middle.Button3
          else  drop GetSelectedLparmCatalogWindow -1 =
                      if    ShowFirstSong
                      else  NoRedrawRw  (RequestToLast RedrawRw
                            ExpandLast: RequestWindow
                      then
          then
     ReadyState
     then
 ;

: RequestToLast  ( -- )
  ['] RequestToLastTask LockExecute: RightPane
 ;

: MoveRequestToBottom { Lparm -- }
\ Moves the one at Lparm to the bottom and
\ moves the ones lower one up
  Lparm n>aptr: Requests @
  Lparm 1+  n>aptr: Requests
  Lparm n>aptr: Requests
  #RequestsInFile Lparm - cells move
  #RequestsInFile  1- ( dup>r) n>aptr: Requests  !
  RefreshRequests
  Lparm ExpandAround
 ;

: MoveRequestBottom ( - )
  NotBusy?
     if  WaitState
         GetSelectedItem: RequestWindow dup 0 <>
         NoRedrawRw
            if  GetLparm: RequestWindow dup -1 =
                   if    drop ExpandAlbum
                   else  dup 1+ #RequestsInFile <
                         if    MoveRequestToBottom
                         else  drop
                         then
                   then
           else  drop
           then
         RedrawRw
    then
    ReadyState
 ;

: MoveRequestDown  ( - )
   GetSelectedItem: RequestWindow dup 0 <>
     if  GetLparm: RequestWindow GetLparm: RequestWindow dup -1 =
           if drop ExpandAlbum exit
           then
         dup 1+ #RequestsInFile <
              if    ExchangeRequestDown
              else  drop
              then
     else  drop
     then
 ;

: Shuffle ( level n - )
   n>record: Requests  over random swap RecordDef RandomLevel  !

 ;

: RShuffle  ( - )
    database-mhndl #records-in-database for-all-Requests Shuffle drop
 ;

: (ShuffleRight ( - )
  #RequestsInFile 0>
     if  WaitState RShuffle
         By_Random Sort-database: Requests
         RefreshRequests ExpandFirst2Requests
         GetRoot: RequestWindow SelectTreeViewItem: RequestWindow
         ReadyState
    then
 ;

: ShuffleRight ( - )
    NotBusy?
       if  NoRedrawRw (ShuffleRight
           ReadyState RedrawRw
       then
;

: Refocus ( - )
    call GetActiveWindow Gethandle: SplitterWindow =
         if   SetFocus: SplitterWindow
         then
 ;

: SetToNotPlayed  ( - )
    for-all-records SetRecordInCollectionToNotPlayed
 ;

: SortRandom ( -- )
    HighPrio NoRedrawRw  vadr-config s_FromCollection- c@
       if   FindRndRecordsIncollection
            #RndRecordsInFile 0=
               if   SetToNotPlayed FindRndRecordsIncollection
                    #RndRecordsInFile 0=
                      if  ReadyState exit
                      then
               then
       else  FindRndRecords
       then
    map-RndIndex Set-data-pointers: RandomRecords
    by[   RandomKey TimesRequestedKey leastPlayedKey Ascending   ]by
    Sort-database: RandomRecords
;

: AddRndPointers
    database-mhndl #RndRecordsInFile vadr-config #MaxRandom @ min 1 max 0
       do    I  AddRndPointer
       loop
 ;


: AddAlbumPointer ( n - )
   dup n>record: Catalog dup IncrTimesRequested
   1 swap RecordDef Request- c!
   n>aptr: Catalog @
   sp@ cell
   RequestIndex$  create/open
   dup>r file-append abort" Can't extend/write request index"
   r@    write-file  abort" Can't write to request index"
   r> FlushCloseFile drop
 ;

: FindAddAlbum { \ ptr   } ( # index - #done )
   n>record: RandomRecords to ptr
   s" *" tmp$ place
   ptr RecordDef Artist ptr RecordDef Cnt_Artist c@ tmp$ +place
   s" *" tmp$ +place
   ptr RecordDef Album ptr RecordDef Cnt_Album c@ tmp$ +place
   GetRangeCatalog: Catalog
      do  tmp$ count i match-record: Catalog
            if   i n>record: catalog  RecordDef Request- dup c@
                 if    drop
                 else  winpause i  AddAlbumPointer true swap c! 1+
                       dup vadr-config #MaxRndAlbum @ >
                          if    leave
                          then
                 then
            then
      loop
 ;

: (AddRndAlbums { \ res }
     -1 dup to res vadr-config #MaxRndAlbumsReq @  0
        do   dup I FindAddAlbum +to res
       loop
    drop res 0max
 ;

: AddRndAlbums
     (AddRndAlbums  0=
        if  shuffle-catalog
            (AddRndAlbums drop
        then
 ;

: ShowAddedRndRequests
         map-RequestIndex Set-data-pointers: Requests
         RefreshRequests
         ExpandFirst2Requests
         SelectRootRequests
         ReadyState \ Refocus
         RedrawRw
 ;

: SortAdddPointers ( - )
         SortRandom  #RndRecordsInFile 0>
          if  vadr-config album- c@
                 if     AddRndAlbums
                 else   AddRndPointers
                 then
          then
        ShowAddedRndRequests
 ;

: (AddRandomRequests  ( - )
    #RndRecordsInFile 2 >
       if    SortAdddPointers
       else  shuffle-catalog
             SortAdddPointers
        then
  ;


: AddRandomRequests ( - )
   NotBusy?
     if   WaitState
          ['] (AddRandomRequests LockExecute: RightPane
          ReadyState \ false to NestingNextRequest?
     then
  ;


: SortRight ( - )
  #RequestsInFile 0> NotBusy? and
     if  NoRedrawRw WaitState
         by[ by_record ]by  Sort-database: Requests
         RefreshRequests ExpandFirst2Requests
         SelectRootRequests
         ReadyState RedrawRw
    then
;

: DisableSearchButton  ( - )
    Disable: TopPane.Button2
    Update: TopPane.Button2
    Disable: TopPane.Button+
    Update: TopPane.Button+
    Disable: TopPane.Button-
    Update: TopPane.Button-
    Disable: TopPane.CmbList1
    Update: TopPane.CmbList1
    Disable: TopPane.Button7
    Update: TopPane.Button7
 ;

: _EnableSearchButton  ( - )
    50 ms  true Enable: TopPane.Button2
    true Enable: TopPane.Button+
    true Enable: TopPane.Button-
    true Enable: TopPane.Button7
    true Enable: TopPane.CmbList1
 ; ' _EnableSearchButton is EnableSearchButton

: (AddSearchResultToPrevResult ( adr n -- )
   dup 0>
      if   "+Search-records: Catalog
      else  2drop
     then
;

:Inline ExitOnBusy ( - )
   CatalogBusy? busy? and if beep exit then true to CatalogBusy? WaitState
 ;

: +SearchToPrevResult ( -- )
    ExitOnBusy
    DisableSearchButton
    GetText: TopPane.TextBox1 (AddSearchResultToPrevResult
    RefreshCatalog
    ReadyState

 ;

: -(SearchToPrevResult ( adr n -- )
   dup 0>
      if   "-Search-records: Catalog
      else  2drop
     then
;

: -SearchToPrevResult ( -- )
    ExitOnBusy
    DisableSearchButton
    GetText: TopPane.TextBox1 -(SearchToPrevResult
    RefreshCatalog
    ReadyState
 ;

: (AddToRequest ( adr n -- )
   vadr-config TextBox1$ dup>r place r> count 2dup SetText: TopPane.TextBox1
   update: TopPane.TextBox1 (AddSearchResultToPrevResult
;

: AddToRequest  ( -- )   \ From search button
    ExitOnBusy  GetTextSelectedItem: FilterWindow  dup 0>
      if    Disable: FilterWindow.btnAdd
            zcount (AddToRequest DownInTree: FilterWindow (RefreshCatalog
            enable: FilterWindow.btnAdd
      else  beep drop
      then
    ReadyState
 ;


: RemoveFromRequest  ( -- )   \ From search button
    ExitOnBusy  GetTextSelectedItem: FilterWindow  dup 0>
      if    Disable: FilterWindow.btnRemove
            zcount -(SearchToPrevResult DownInTree: FilterWindow (RefreshCatalog
            enable: FilterWindow.btnRemove
      else  beep drop
      then
    ReadyState
 ;


: GetSelectedFilter ( - adr cnt ) GetSelectedString: TopPane.CmbList1  ;

: ToResult  ( adr n - )  "+Search-records: Catalog  ;

: AddAll  ( -- )  \ From the add all button
   ExitOnBusy
   wait-cursor Disable: FilterWindow.btnAddAll Update: FilterWindow.btnAddAll
   GetSelectedFilter
   ['] ToResult ForAllLines
   (RefreshCatalog true Enable: FilterWindow.btnAddAll arrow-cursor
   ReadyState
 ;


FileNewDialog  NewFileDialog "NewFilterFile" "Text Files (*.txt)|*.txt|All Files (*.*)|*.*|"
FileOpenDialog DelFileDialog "Deletefilter"  "Text Files (*.txt)|*.txt|All Files (*.*)|*.*|"

: "file-only"   ( a1 n1 -- a2 n2 )
   2dup 2dup pad place  "path-only" nip /string 1 /string
 ;

: FilterExtension ( - adr cnt ) s" .txt" ;

:Noname ( - )
  TopPane Start: ProgresWindow MoveProgresWindow
  IsVisible?: SplitterWindow not
    if    SW_HIDE Show: ProgresWindow
    then
 ; is Start:Toppane.ProgresWindow

: AddToCmbList1 ( adr cnt - )
   temp$ place s" \*.txt" temp$ +place
   temp$ +null temp$ 1+
   DDL_READWRITE  DDL_READONLY or DDL_HIDDEN or DDL_ARCHIVE or  SetDir: TopPane.CmbList1
 ;

: DirlistToCmbList1  ( - )
    CatalogPath-does-not-exist not
     if     Clear: TopPane.CmbList1
            z"  Filters:"  AddStringTo: TopPane.CmbList1
            current-dir$ count AddToCmbList1
            0 0 CB_SETCURSEL GetID: TopPane.CmbList1 SendDlgItemMessage: TopPane drop
      22 SetMinVisible: TopPane.CmbList1 \ force to open 22 lines when there.
      else  Clear: TopPane.CmbList1
     then
 ; ' DirlistToCmbList1 is DirlistToCmbList

: StartPlaceFilterWindow  ( filename cnt - ) { \ xmoved }
    Gethandle: FilterWindow 0=
       If    GetWindowRect: SplitterWindow 3drop InitFilterWindowWidth <
               if     GetWindowRect: SplitterWindow  2>r
                      InitFilterWindowWidth rot - to xmoved
                      InitFilterWindowWidth  35 + swap 2r>
                      >r 2 pick - xmoved + r> 2 pick -  move: SplitterWindow
               then
       Then
    StartFilterWindow
    GetWindowRect: SplitterWindow  DockLeft: FilterWindow
 ;

: NewFilter ( -- )
    GetHandle: SplitterWindow Start: NewFileDialog
    count "minus-ext" "file-only" dup 0=
          if     drop abort" Filter cancelled"
          else   2dup dup cell+ LOCALALLOC dup>r place
                 temp$ place FilterExtension temp$ +place
                 temp$ count 2dup Newfile abort" Filter not created"
                 StartPlaceFilterWindow
                 DirlistToCmbList1
                 r@ +null  r> 1+ SelectString:  TopPane.CmbList1 drop
          then
 ; IDM_Newfilter SetCommand

: DeleteFilter ( -- )
    GetHandle: SplitterWindow Start: DelFileDialog count dup
        if    delete-file DirlistToCmbList1
        else  2drop
        then
 ; IDM_Deletefilter SetCommand

: Clear-results ( -- )
   Clear-results: Catalog
   RefreshCatalog
 ;

create tmpfile$ ," 0.tmp"

: SortFilterFile ( - ) \ Just writing an already small sorted treeview to the file of the filter
   tmpfile$ count  file-exist?
     if  tmpfile$ count delete-file abort" Can't delete an existing old filter"
     then
   GetSelectedString: TopPane.CmbList1 2dup "minus-ext"
   temp$ place s" .tmp" temp$ +place
   temp$ count  r/w create-file abort" Can't create the file" >r
   GetRoot: FilterWindow
     begin  dup GetTextItem: FilterWindow.treeview dup
     while  zcount r@ write-file abort" Can't write to filter"
            crlf$ count r@ write-file abort" Can't write to filter"
           \ NextItem: FilterWindow
            GetNext: FilterWindow.treeview
     repeat
   r> FlushCloseFile  2drop
   2dup tmpfile$ count rename-file abort" Can't rename the old filter"
   temp$ count   2swap rename-file abort" Can't rename the new filter"
   tmpfile$ count      delete-file abort" Can't delete the old filter"
 ;


: AddToFilter ( -- )
   GetText: TopPane.TextBox1 dup 0>
      if     false SetRedraw: SplitterWindow
             false SetRedraw: FilterWindow.treeview
             GetSelectedString: TopPane.CmbList1
             2dup s"  Filters:" compare 0=
             if    4drop s" Make a new filter in the menu File\nor open an existing filter first." MsgBox
             else  2swap AddLine
                   GetSelectedString: TopPane.CmbList1
                   StartPlaceFilterWindow
                   true SetRedraw: FilterWindow.treeview
                   SortFilterFile
             then
             SetFocus: SplitterWindow
             true SetRedraw: SplitterWindow
      else   beep
      then
 ;

: DeleteSearch$ ( -- )
   ExitOnBusy  GetTextSelectedItem: FilterWindow dup 0=
      if   drop beep exit
      then
   disable: FilterWindow.btnDelete
   zcount 2dup 2>r
   GetSelectedString: TopPane.CmbList1 2dup 2>r
   false SetRedraw: FilterWindow.treeview
   DeleteLine
   2r> StartPlaceFilterWindow  \ line cnt file cnt
   true SetRedraw: FilterWindow.treeview
   2r> SetText: TopPane.TextBox1
       update: TopPane.TextBox1
   ReadyState
   enable: FilterWindow.btnDelete
 ;

: _OpenFilterWindow ( - )
   ExitOnBusy
   GetSelectedString: TopPane.CmbList1 StartPlaceFilterWindow
     \  DisableSearchButton  WaitState
   ReadyState
 ;  ' _OpenFilterWindow is OpenFilterWindow

: (SearchInCatalog ( - )
   ExitOnBusy
   DisableSearchButton  WaitState
   GetSearchText: TopPane
   2dup vadr-config TextBox1$ place
   "Search-records: Catalog (RefreshCatalog
   ReadyState
 ;

: SearchInCatalog ( - )
   (SearchInCatalog GetSearchText: TopPane  ascii * scan nip 0>
      if   ExpandAlbum: CatalogWindow
      then
;

: FilterSearch  ( -- )        \ From the search button in the filter window
    GetTextSelectedItem: FilterWindow  dup 0>
       if    disable: FilterWindow.btnSearch
             zcount vadr-config TextBox1$ dup>r place r> count SetText: TopPane.TextBox1
             update: TopPane.TextBox1
             SearchInCatalog   \ "Search-records: Catalog RefreshCatalog
             DownInTree: FilterWindow
             enable: FilterWindow.btnSearch
             ReadyState
       else  beep drop
       then
 ;

: FindMore ( - )
   RemoveSelection:  TopPane.TextBox1
   GetSelectedString: Middle.CmbListMore
   SetText: TopPane.TextBox1
   SelectAll: TopPane.TextBox1
   update: TopPane.TextBox1
     \ SearchInCatalog \ 18-5*-2012: The user decides to add search or subtract
   FirstLine: Middle.CmbListMore
   Disable:  Middle.CmbListMore 2250 ms \ Preventing a fast opening again.
   true Enable: Middle.CmbListMore
 ; ' FindMore is DoCmbListMore

: resume-play ( ms-back - )
    mp dup
      if  dup vlc-time@ rot - 0 max over vlc-time! vlc-play
      then
 ;


: Pause/Resume
   Pausing? dup
      if    10 resume-play
      else  PausePlay
      then
   not to Pausing?
 ; IDM_START/RESUME SetCommand

string: Lastpfilename$

0 value  NestingNextRequest?

: (PlayNextRequest  ( - )
     pfilename$ vlc-start-play  wait-for-vlc
     SetPosBar: TopPane
     vadr-config l_Narrator- c@ \ In W7: The TTS works best when the player is paused
        if 300 ms MP VLC-PAUSE   pfilename$ count  Announce WaitForTts 300 ms   MP VLC-PAUSE
        then
     Refocus
     DurationPlay SetRangePosBar: TopPane
     false to Pausing?
     #RequestsInFile 1 <= vadr-config Endless- c@ and
         if  WaitState (AddRandomRequests \ ['] (AddRandomRequests Execute: RightPane
         then
     ReadyState false to NestingNextRequest?
 ;

: extract-record-playing ( recordAdr - ) RecordPlaying sizeof  RecordDef cmove ;

: PlayNextRequest ( - )
   HighPrio  ExitOnPathError
    #RequestsInFile  0 > not
       if  2drop end-play 0 pfilename$ ! RecordPlaying sizeof RecordDef erase Paint_TopPane exit
       then
          NestingNextRequest? not
            if   true to NestingNextRequest? WaitState
                 0 n>record: Requests  dup>r FullPathSong    drop 2dup file-exist?
                if     NoRedrawRw pfilename$ place
                       pfilename$ count Lastpfilename$ place
                       r@ incr-#played r@ to #playing r@ mark-played
                       r> extract-record-playing
                       paint: CoverWindow  Paint: ProgresWindow
                       end-play vadr-config l_Narrator- c@
                          if    Paint_TopPane
                                paint: CoverWindow
                                h_ev_h_ev_tts_done event-reset
                                s"  " PlayStat$ place Paint: ProgresWindow
                                DeletePlayedRequest RedrawRw
                                Paint_TopPane
                          else  DeletePlayedRequest RedrawRw Paint_TopPane
                          then (PlayNextRequest
                else   r>drop DeletePlayedRequest 2drop ReadyState false to NestingNextRequest?
                then
       then
 ; IDM_NEXT SetCommand



: StartInfoForm ( - )
   pfilename$  c@  0>     \ playing ok ?
   last-selected -1 <> or \ or a song selected
     if  SplitterWindow Start: InfoForm
     then
 ;

: CloseInfoForm ( - ) Close: InfoForm ;


: CloseWebserverAddressDialog ( - ) Close: WebserverAddressDialog ;

: StoreWebserverAddress       ( - )
   GetText: WebserverAddressDialog.TextBox1
   vadr-config AddressWebServer$ place
   CloseWebserverAddressDialog
 ;

: CloseFormWiFi ( - ) Close: FormWiFi ;

: StoreWiFiProporties
   GetText: FormWiFi.TextBox1  vadr-config WiFiName$ place
   GetText: FormWiFi.TextBox2  vadr-config WiFiPassword$ place
   CloseFormWiFi
 ;


: ("ExecuteParmShellParm) { zLpParameters addr cnt hWnd --  errorcode } \ open file using default application
        SW_SHOWNORMAL         \ nShowCmd
        Null                  \ default directory
        ZlpParameters         \ parameters
        addr cnt asciiz       \ file name to execute
        Null                  \ operation to perform
        hWnd                  \ parent
        Call ShellExecute ;

: "find-first-file ( adr count  - flag )
    find-first-file find-close drop nip ;

: FindAnUpperDir true { ior } ( adr count - adr' count' )
   2dup + over  \ - adr count endadres rest
      begin   ascii \ -scan dup
                 if   3 pick over
                      "find-first-file  not
                         if    false to ior
                         then
                 else false to ior
                 then
      ior
      while  swap 1- swap 1-
      repeat
   dup 0>
      if    nip nip
      else  4drop 0 0
      then
 ;


create _quote$ 1 c, ascii " c,
: quote$ ( adr cnt - ) _quote$ count ;

: Explore ( - )
    GetText: InfoForm.TextBox4
    tmp$ place tmp$ +null
    tmp$ count "find-first-file
         if  tmp$ count FindAnUpperDir dup
              if    tmp$ place tmp$ +null
              else  0 tmp$ !
              then
         then
    quote$ pad place tmp$   count pad +place  quote$ pad +place
    pad +null pad 1+
    s" explorer.exe"
    GetHandle: SplitterWindow
    ("ExecuteParmShellParm) drop
    CloseInfoForm
;

: ViewManual ( - )
    quote$ pad place s" JukeboxIn4Th_readme.rtf" pad +place quote$ pad +place
    pad +null pad 1+
    s" wordpad.exe"
    GetHandle: SplitterWindow
    ("ExecuteParmShellParm) drop
 ; IDM_Manual SetCommand

: VolChange ( vol - volscaled change )  ( 650 / ) dup 20 / 1 max ;

: GetVolume/timeOut ( - Volume VolumeChange Volume VolumeChange)
  100 ms mp-volume@ VolChange
  rot VolChange 2swap
;

: DecreaseVolume    ( - ) \ assumes left + right are the same
   mp-volume@ drop ( 650 / ) locals| oldvol |
    begin       SetVolBar: TopPane 100 ms
                oldvol dup 20 /  2 max -  1 max dup to oldvol dup mp-Volume!
                ButtonIn?
     until
 ;

: IncreaseVolume    ( - )
     begin     GetVolume/timeOut 5 max +
               -rot 5 max + swap mp-Volume! SetVolBar: TopPane
               ButtonIn?
     until
 ;

: NextChar ( - )  1 ChangeChar: TopPane ;
: PrevChar ( - ) -1 ChangeChar: TopPane ;

: DoRefreshCatalog  ( - )  Below (RefreshCatalog ;

: start-RefreshCatalog-task ( -- )
    ['] DoRefreshCatalog Submit: JukeBoxTasks ;


:noname ( -- )
        catalog-exist?
        if  start-RefreshCatalog-task
        then
 ; is RefreshCatalog


: ListDeadLinks
    ExitOnPathError
      SplitterWindow  Start: WaitWindow winpause
    WaitState
      ['] UpdateWaitWindow submit: JukeBoxTasks
      ListDeadLinks: MediaTree
      Refresh: CatalogWindow
      ListSelected: MediaTree
      Expand: CatalogWindow
      Close: WaitWindow
    ReadyState
  ; IDM_ListDeadLinks SetCommand

: Remove-dead-link ( n - )
    #Done incr
    PreventWindowsHang
    dup n>record: catalog  FullPathSong
      if    2drop Delete-record: Catalog
      else  3drop
      then
;

: RemoveDeadLinks ( - )
   ExitOnPathError
   SplitterWindow
   WaitState Start: WaitWindow winpause ['] UpdateWaitWindow submit: JukeBoxTasks
     for-all-records Remove-dead-link
   Build-free-list: Catalog
   Refresh: CatalogWindow \ RefreshRequests ExpandFirst2Requests
   DeleteDeadRequests
   Close: WaitWindow
   ReadyState
 ; IDM_RemoveDeadLinks SetCommand


 :Noname
         RightXpos 50 - ThicknessV - 1+
         TopHeight ThicknessH + 49 350 Move: Middle
         Paint: Middle
 ; is MoveMiddleButtons

 :Noname
         RightXpos GetRightWidth: SplitterWindow +
         TopHeight ThicknessH + 50 350 Move: Right
         Paint: Right
 ; is MoveRightButtons

:Noname ( - )
          GetWindowRect: TopPane drop rot drop 202 - swap 2 +
          173 30 Move: ProgresWindow
 ; is MoveProgresWindow

33 constant hTcs \ heightTopControls
64 constant Yo1 \ Y Offset Firstline Buttons
:Noname
        Paint: TopPane.Button5
        Paint: TopPane
        13   TopHeight 40 -  RightXpos 88 -  hTcs MoveTrackbarAlpha: TopPane
        RightXpos 10 -   TopHeight 40 -  GetRightWidth: SplitterWindow  18 +  hTcs   MoveTrackbarPos: TopPane

        Width: SplitterWindow 41 -   0   hTcs   TopHeight 9 -   MoveTrackbarVol: TopPane
        0                TopHeight 40 -  15              hTcs Move: TopPane.Button3
        RightXpos 75 -   TopHeight 40 -  15              hTcs Move: TopPane.Button4


        RightXpos 110 -                TopHeight 64 -  25 winxp?
                                                  if   swap 1+ swap  22
                                                  else    24
                                                  then   Move: TopPane.Button+

        RightXpos 85 -                 TopHeight Yo1 -  25 winxp?
                                                  if   swap 1+ swap  22
                                                  else   24
                                                  then   Move: TopPane.Button-
        Paint: TopPane.Button-

        RightXpos 180 -  TopHeight Yo1 -  winxp?
                                             if     1+ swap 1- swap 71 23
                                             else   70 25
                                             then            Move: TopPane.Button2

        Paint: TopPane.Button2

        124                TopHeight Yo1 -  RightXpos 304 - winxp?
                                                  if   swap 1+ swap  22
                                                  else   24
                                                  then      Move: TopPane.TextBox1

        100                TopHeight  winxp?
                                             if     Yo1 1-
                                             else   Yo1
                                             then  - 24 24 Move: TopPane.Button6

        0                  TopHeight  winxp?
                                             if     Yo1 1-
                                             else   Yo1
                                             then  - 100 24 Move: TopPane.CmbList1

        RightXpos 10 -   TopHeight Yo1 -  50  winxp?
                                                  if   swap 1+ swap  23
                                                  else   24
                                                  then      Move: TopPane.Button1
        RightXpos 40 +   TopHeight Yo1 -  50  winxp?
                                                  if   swap 1+ swap  23
                                                  else   24
                                                  then      Move: TopPane.Button5
        0                TopHeight 24 - winxp?
                                             if     Yo1 1-
                                             else   Yo1
                                             then  - 24 24 Move: TopPane.Button7
        MoveProgresWindow
 ; is MovePlayButtons


0 value LastButton

WinLibrary powrprof.dll

: suspend ( flag  - Err|0) \ True=Hybernate
   false true rot call SetSuspendState 0=
    if    GetLastWinErr
    else  false
    then
 ;

: suspend/resume ( - )
   PausePlay true suspend drop   4 0
    do  250 ms beep 1000 resume-play mp vlc-state 4 <>
          if  leave
          then
    loop
 ;

:Noname       (  - )
   NotBusy?
     if  true to busy?
         vadr-config JoyStickDisabled- c@ not
            if   IDJoystick GetJoystickInfo 2nip nip dup LastButton <>
                   if  dup to LastButton
                        case
                            JOY_BUTTON1   of   IDM_NEXT DoCommand            endof
                            JOY_BUTTON2   of   false to Busy? IDM_DoAnnounce Docommand   endof
                            JOY_BUTTON3   of   DecreaseVolume                endof
                            JOY_BUTTON4   of   IncreaseVolume                endof
                            JOY_BUTTON5   of   Pause/Resume                  endof
                            JOY_BUTTON6   of   vadr-config EnableShutdown- c@
                                                 if  beep suspend/resume
                                              \  if  beep PausePlay true down drop    \ Or Shutdown?
                                                      then                  endof
                            JOY_BUTTON7   of  IDM_DOCOVERWINDOW  Docommand   endof
                        endcase
                   else  drop
                   then
            then
     Pausing? not
       if   PlayReady? #RequestsInFile 0> and  NestingNextRequest? not and
             if  IDM_NEXT DoCommand  \ PlayNextRequest
             then
       then
     false to busy?
     then
 ; is HandleJoystick

: SetFirstPath ( -- )
   vadr-config SearchPathCatalog first-path"
   vadr-config PathMediaFiles place
 ;

: ?MessageBoxExit  ( flag str$ cnt -  )
     2 pick
       if    ?MessageBox 0 CALL ExitProcess
       else  3drop
       then
  ;

: Need-xp-or-better ( -  )
   winver dup 0=
     if drop true s"  Unrecognized OS."  ?MessageBoxExit
     else  winxp <
           s" The JukeBoxIn4Th needs XP or better."  ?MessageBoxExit
     then
 ;

: ManualIsMissing ( flag -  )
   s" The file JukeboxIn4Th_readme.rtf. is missing.\n\nThe program will be terminated."
   ?MessageBoxExit

 ;

: CheckManual ( -  )
   FILE_ATTRIBUTE_READONLY z" JukeboxIn4Th_readme.rtf"
   call SetFileAttributes 0= ManualIsMissing
 ;


: CreateEvents ( - )    CreateTtsEvent  ;

: (StartJukeBoxIn4Th ( - )
   start: Catalog
   set-vlc-dirs
   below
   0 to Pausing?
   0 to busy? 0 pfilename$ !
   CURRENT-DIR$ count  drop 3 StartupDir place
   InitFileNames check/resize-config-file
   map-config-file
   Call InitCommonControls drop
   start: SplitterWindow
   Need-xp-or-better
   vlc-init
   Start: JukeBoxTasks   \ Need max 8 tasks simultaneously.
   Start:  RightPane
   Start:  WebserverTasks
   Start:  Catalog_iTask
   1000 dup Set#Jobs: FileTask              \ Set #jobs
   /FileEntry * malloc to &FileBlock       \ Allocate a string block. One for each used job.
   Start: FileTask

   CatalogPath-does-not-exist
     if      s"  @ " vadr-config PositionSlider place SetUpPath
             begin  CatalogPath-does-not-exist
             while  200 ms winpause
             repeat
          SetFirstPath
     then

   wait-cursor
   SplitterWindow start: Right
   SplitterWindow start: Middle
   addr: TopPane to player-base
   Start:Toppane.ProgresWindow

   DirlistToCmbList1
   MoveRightButtons
   MoveMiddleButtons
   MovePlayButtons
   z" h_ev_tellTime" make-event-reset to h_ev_tellTime
   InitVoice
   player4-menu-bar SetMenuBar: SplitterWindow
   IsVisible?: SplitterWindow 0=
     if SW_HIDE Show: ProgresWindow Update: ProgresWindow
     then
   CreateEvents
\  Starting the database objects
   Start: Requests
   Start: RandomRecords
   CheckManual DisableSearchButton
   catalog-exist?
    if    map-database
          RefreshCatalog
          RefreshRequests
          GetRoot: RequestWindow
          TVGN_CARET SelectItem: RequestWindow
          vadr-config #MaxRndAlbumsReq dup @ 1 max swap !
          vadr-config #MaxRndAlbum dup @ 1 max swap !
          vadr-config #MaxRandom   dup @ 1 max swap !
    else  RequestIndexFile$ CntDelete  \ Initial values
          IndexFile$        CntDelete
          RndIndexFile$     CntDelete
          0   vadr-config #free-list !
          14 vadr-config #MaxRandom !
          20 vadr-config #MaxRndAlbum !
          7 vadr-config #MaxRndAlbumsReq !
          false vadr-config Album- c!
          50 vadr-config VlcVolume !
          true to Pausing?
          ImportFolder false to pausing?
    then
   .Tooltips
   FindFirstJoyStick to IDJoystick drop
   0 120  1 SplitterWindow.hWnd Call SetTimer drop
   0 1000 2 SplitterWindow.hWnd Call SetTimer drop
   ReadyState
   SetVolBar: TopPane
   THREAD_PRIORITY_NORMAL SetPriority
 ;



' SearchInCatalog is _SearchInCatalog \ For TopPane.Button2

' CloseInfoForm           SetFunc: InfoForm.Button1
' Explore                 SetFunc: InfoForm.Button2

' StoreWebserverAddress       SetFunc: WebserverAddressDialog.Button1
' CloseWebserverAddressDialog SetFunc: WebserverAddressDialog.Cancel

' StoreWiFiProporties     SetFunc: FormWiFi.Button1
' CloseFormWiFi           SetFunc: FormWiFi.Button2


' AddToRequest            SetFunc: FilterWindow.btnAdd
' AddAll                  SetFunc: FilterWindow.btnAddAll
' RemoveFromRequest       SetFunc: FilterWindow.btnRemove
' DeleteSearch$           SetFunc: FilterWindow.btnDelete
' FilterSearch            SetFunc: FilterWindow.btnSearch

' Pause/Resume            SetFunc: TopPane.Button1
' PrevChar                SetFunc: TopPane.Button3
' NextChar                SetFunc: TopPane.Button4
' PlayNextRequest         SetFunc: TopPane.Button5
' AddToFilter             SetFunc: TopPane.Button6
' Clear-results           SetFunc: TopPane.Button7
' +SearchToPrevResult     SetFunc: TopPane.Button+
' -SearchToPrevResult     SetFunc: TopPane.Button-


' RequestToFirst          SetFunc: Middle.Button1
' RequestToSecond         SetFunc: Middle.Button2
' RequestToLast           SetFunc: Middle.Button3
' BtDeleteSelectedRequest SetFunc: Middle.Button4
' DeleteDownFrom          SetFunc: Middle.Button5
' AddRandomRequests       SetFunc: Middle.Button6

' StartInfoForm           SetFunc: Right.Button7
' BtMoveRequestTop        SetFunc: Right.Button1
' MoveRequestUp           SetFunc: Right.Button2
' MoveRequestDown         SetFunc: Right.Button3
' MoveRequestBottom       SetFunc: Right.Button4
' ShuffleRight            SetFunc: Right.Button5
' SortRight               SetFunc: Right.Button6
' Enter#OfRequestsToAdd   SetFunc: Right.Button8

' TestTts                 SetFunc: NarratorWindow.Button1
' CloseNarratorWindow     SetFunc: NarratorWindow.Button2

\s
