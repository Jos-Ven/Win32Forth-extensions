\ $Id: Mediatree.f,v 1.37 2008/09/26 12:00:27 jos_ven Exp $

needs apps\player4\number.f
needs w_search.f
needs mShellRelClass.f
needs catalog.f
needs TreeView2.F \ This version or better will be used in the next version of Win32Forth
needs struct.f

\ 0 value hItem-last-selected
0 value last-selected-request
0 value last-selected \ -1=root or adres selected record
defer GetPositionCatalog
0 value UseBigFont
0 value MaxDif

create valid-dx-sound-ext ," .aiff;.au;.mid;.midi;.mp3;.snd;.wav;.wma"
\ :inline music? ( adr len - f ) valid-dx-sound-ext count (IsValidFileType?) ;
: GetLabel ( path cnt - ) VolumeLabel to /VolumeNameBuffer drop to _DriveType ;
MultiFileOpenDialog GetFilesDialog "Select File" "Music Files (*.aiff,*.au,*.mid,*.midi,*.mp3,*.snd,*.wav,*.wma,)|*.aiff;*.au;*.mid;*.midi;*.mp3;*.snd;*.wav;*.wma;|"


:inline CountedArtist   ( adr - adr count ) dup RecordDef Artist swap Cnt_Artist c@ ;
:inline CountedFilename ( adr - adr count ) dup RecordDef File_name swap Cnt_File_name c@ ;
:inline PathSong        ( adr - adr cnt )   CountedFilename  CatalogPath full-path drop "path-only" ;
:inline CountedAlbum    ( adr - adr count ) dup RecordDef Album  swap Cnt_Album  c@ ;
:inline CountedTitle    ( adr - adr count ) dup RecordDef Title  swap Cnt_Title  c@ ;
:Inline PreventWindowsHang ( index - index) dup 5000 mod 0=  if   winpause  wait-cursor  then ;

:Class MediaTreeControl <super TreeViewControl


sizeof RecordDef bytes InlineRecord

struct{ \ PrevMusic
        DWORD PrevMusicRecord
        DWORD hArtist
        DWORD hAlbum
}struct PrevMember

sizeof  PrevMember bytes &PrevMusic
sizeof  PrevMember bytes &PrevMovie
sizeof  PrevMember bytes &PrevRequest

:M WindowStyle: ( -- style )
               WindowStyle: super
               [  TVS_HASBUTTONS    TVS_HASLINES or TVS_SHOWSELALWAYS or
                  TVS_LINESATROOT or ] literal or
                ;M

:Inline +InlineRecord ( str cnt - )   InlineRecord  +place  s"  " InlineRecord +place ;
:Inline +(l.int) ( n )                (l.int) +InlineRecord ;

: SelectedRecord?  ( n - f )
    n>record: Catalog  dup RecordDef Deleted- c@ not \ show-deleted or
    swap RecordDef Excluded- c@ dup
      if  1 +to #Excluded
      then
     not and
  ;

' SelectedRecord? is Incollection?

: NotIncollection? ( n - f )
    n>record: Catalog  dup RecordDef Deleted- c@ not \ show-deleted and
    swap FullPathSong not nip nip and
  ;

: DeadLinkedRecord? ( n - f )
    PreventWindowsHang
    #Done incr
    n>record: Catalog  dup RecordDef Deleted- c@ not \ show-deleted and
    swap FullPathSong nip nip and
  ;

:inline ResetInlineRecord ( n - n vadr-config )  vadr-config 0 InlineRecord ! ;

: OptionalElements    ( vadr-config rec-addr - vadr-config rec-addr )
          over l_Drivetype- c@
            if   dup RecordDef DriveType c@ DriveType$ +InlineRecord
            then
          over l_Label-     c@
            if   dup RecordDef MediaLabel over Cnt_MediaLabel c@ +InlineRecord
            then
          over l_File_size- c@
             if  dup RecordDef FileSize @ 1000 / 1 max +(l.int)  \ In KB
             then
          over l_#Random-   c@
             if  dup RecordDef RandomLevel @  +(l.int)
             then
          over l_#Played-   c@
             if  dup RecordDef #played @  +(l.int)
             then
 ;

int hPrev


:inline AddItemHierarical  ( sztext hAfter hParent nChildren -- hPrev )
                ( nChildren)      to cChildren
                ( hParent)        to hParent
                ( hAfter)         to hInsertAfter
                                  to pszText
                tvins 0 TVM_INSERTITEMA hWnd Call SendMessage
                dup to hPrev
                ;

int hMusic
int hMusicChar
int hRequests
int OtherArtist?
int PrevRecAdr
int rec-addr
int LastChar

sizeof  RecordDef dup create dummy  allot dummy swap 01 fill

:inline NotPlayable ( - )     -1 to lParam ;

: AddNewChar  ( hMusic hChar - hChar )
   rec-addr RecordDef Artist c@ upc dup  LastChar <>
        if      dup to LastChar 0x100 * 1+ pad !
                drop dup pad 1+ -rot 1 AddItemHierarical
        else    drop nip
        then
 ;

:inline AddAlbum  ( - )
   rec-addr CountedAlbum 1 max PrevRecAdr @ CountedAlbum 1 max compareia 0<> OtherArtist? or
   rec-addr RecordDef Cnt_Artist c@ 0>  and
       if   rec-addr PrevRecAdr !  NotPlayable
            rec-addr RecordDef Album hPrev PrevRecAdr hArtist @
            1 AddItemHierarical PrevRecAdr RecordDef hAlbum !
       then
 ;

:inline AddTitle  ( - hItem )
   rec-addr RecordDef CountedTitle +InlineRecord InlineRecord +null
   InlineRecord 1+ hPrev PrevRecAdr
   rec-addr RecordDef Cnt_Artist c@ 0>
      if     hAlbum @
      else   drop hMusic
      then
   0 AddItemHierarical
 ;


:M Start:       ( Parent -- )
                Start: super
                ;M



:M GetLparm:    ( hItem - lParm )
                to hItem
                TVIF_PARAM
                TVIF_HANDLE or  to mask
                0               to pszText
                0               to cchTextMax
                tvitem 0 TVM_GETITEMA  hWnd  Call SendMessage drop
                lParam
 ;M

:M Rename: ( z$ hitem - )
        tvitem /tvitem erase
         to hitem
        TVIF_TEXT to mask
        to psztext
        SetItem: self
                ;M

:M SetBold: (   hitem - )
        tvitem /tvitem erase
        to hitem
        TVIF_STATE to mask
        TVIS_BOLD dup to stateMask to state
        SetItem: self
                ;M

:M SetNormal: (   hitem - )
        tvins  /tvins  erase
        to hitem
        TVIF_STATE to mask
        TVIS_BOLD to stateMask 0 to state
        SetItem: self
                ;M

:M FindAdresRecord: ( hitem - hItemWithAdres )
        dup GetChild: Self dup 0<>  \ Find the child that contains the record adres
            if  nip dup GetChild: Self dup 0=
                  if   drop
                  else nip
                  then
            else drop
            then
 ;M

;Class


create CatalogName$     ," Results "
String: _Catalog

: Catalog$  ( - adr count )
  _Catalog maxstring erase
  CatalogName$ count _Catalog place
  _Catalog count
 ;

:Class MediaTree <super MediaTreeControl

: root-items  ( - hPrev )
    NotPlayable TVI_LAST  TVI_ROOT 2>r
    Catalog$  drop   2r> 1 AddItemHierarical dup to hMusic

 \   z" Requests"  2r> 1 AddItemHierarical dup to hRequests
    dummy dup &PrevMusic   ! dup &PrevMovie !  dup to LastChar &PrevRequest !
    dup &PrevMovie hArtist ! &PrevMovie hArtist !
((         z" First Artist"  hPrev     hMusic     1  AddItemHierarical to hArtist
           z" Second Music"  hPrev     hArtist    0  AddItemHierarical drop
           z" Third Music"   hPrev     hArtist    0  AddItemHierarical drop  ))
 ;


: OptionalhChar  ( - hChar )   \ hChar catalog
    hMusic    hMusicChar AddNewChar dup to hMusicChar
 ;

:inline AddArtist ( - )
   rec-addr CountedArtist 1 max PrevRecAdr @ CountedArtist 1 max compareia 0<>
   rec-addr RecordDef Cnt_Artist c@ 0>  and
       if   rec-addr PrevRecAdr ! true to OtherArtist? NotPlayable
            rec-addr RecordDef Artist hPrev  hMusic \ ( OR ) OptionalhChar
             1 AddItemHierarical PrevRecAdr hArtist !
       else  false to OtherArtist?
       then
 ;

create path$ z," PATH"

:M ListDeadLinks:
   ['] DeadLinkedRecord? is Incollection?
 ;M

:M ListSelected:
   ['] SelectedRecord?  is Incollection?
 ;M

: AddRecordHierarical { n -- } \ Catalog
   n Incollection?
     if     1 +to #InCollection ResetInlineRecord n n>record: Catalog
            &PrevMusic to PrevRecAdr to rec-addr
            AddArtist AddAlbum
            dup l_Index- c@
                if   n dup +(l.int)
                else n
                then
            to lParam
            drop \ rec-addr OptionalElements 2drop
            AddTitle drop #done incr
      then \ pause
 ;

:M On_SelChanged: ( -- f )
             0 TVGN_CARET GetNextItem: Self dup GetRoot: Self  =
                 if     drop -1
                 else   FindAdresRecord: Self
                        GetLparm: Self n>record: Catalog
                 then
              UpdateLastSelected
              false
                ;M

:M FillTreeView:  ( -- )  \ Results in the Left pane
               \      TVI_ROOT DeleteItem: self \ delete all items from the tree view
                0 to #Excluded
                0 to #InCollection
                tvins  /tvins  erase
                false SetRedraw: self
                TVI_ROOT to hParent
                [ TVIF_TEXT TVIF_CHILDREN or TVIF_PARAM or TVIF_STATE or ] literal to mask
                root-items to hPrev
                0 to hMusicChar 

                for-all-records AddRecordHierarical
        catalog$ drop
        #InCollection (l.int) _catalog +place
        s"  / " _catalog +place
        database-mhndl #records-in-database vadr-config  #free-list @ - 0max
        (l.int) _catalog +place
        _catalog +null
        hMusic Rename: Self
        true SetRedraw: self
 ;M


;Class

\ -----------------------------------------------------------------------------
\ define the child window for the LEFT pane below of the main window
\ in this area the catalog will be shown
\ -----------------------------------------------------------------------------

:Object  CatalogWindow        <Super Child-Window

 MediaTree TreeView

int EnableNotify?
Font TreeViewFont

: SendToTreeView  ( lparm wparm msg -- ) GetHandle: TreeView CALL SendMessage drop ;

:M SetBlackBackGround:  (  - )
               Color: Black     0 TVM_SETBKCOLOR    SendToTreeView
               Color: ltYellow  0 TVM_SETTEXTCOLOR  SendToTreeView
               ;M

:M SetWhiteBackGround:  (  - )
               Color: White     0 TVM_SETBKCOLOR    SendToTreeView
               Color: Black     0 TVM_SETTEXTCOLOR  SendToTreeView
               ;M

:M SetfontTreeView:  (  - )
                UseBigFont
                        if   24 32
                        else  11 18
                        then
                Height: TreeViewFont
                Width:  TreeViewFont
                s" Times New Roman (TrueType)" SetFaceName: TreeViewFont
                Create: TreeViewFont
                true Handle: TreeViewFont WM_SETFONT SendToTreeView
                SetBlackBackGround: Self  \ A black background and a yellow font.
                ;M

:M Start:       ( Parent -- )
                Start: super
                 false to UseBigFont SetfontTreeView: Self
                 0 to MaxDif
                ;M

:M GetRoot: ( - hItem )
                   GetRoot: TreeView
                ;M
\ GetSelectedItem: Self   GetChild: TreeView
:M ExpandRecord: ( hitem - hRecord)
               dup ExpandItem: TreeView
               GetChild: TreeView dup ExpandItem: TreeView
               GetChild: TreeView dup ExpandItem: TreeView
;M

:M Expand: ( - )
                GetRoot: TreeView
                    dup TVE_EXPAND Expand: TreeView
                    dup GetChild: TreeView TVE_EXPAND Expand: TreeView
                        TVGN_FIRSTVISIBLE SelectItem: TreeView
                    Update: TreeView
                ;M

:M WndClassStyle: ( -- style )
         \ CS_DBLCLKS only to prevent flicker in window on sizing.
         CS_DBLCLKS ;M

: AddDropFiles {  hDrop \ drop$ #File wHndl -- res }
        SetForegroundWindow: self
        wait-cursor
        MAXCOUNTED 1+ LocalAlloc: drop$
        0 to #File
        0 0 -1 hDrop  Call DragQueryFile  ?dup
           if  datfile$ count file-exist? check-config
               MAXCOUNTED drop$ 0 hDrop Call DragQueryFile
               drop$ swap GetLabel
               OpenAppendDatabase to DbHndl
                   begin    MAXCOUNTED drop$ #File hDrop Call DragQueryFile dup 0>
                   while    drop$ swap AddFile  1 +to #File
                   repeat
          then
        2drop hDrop Call DragFinish
        wHndl CloseReMap
        RemoveDuplicates
        RefreshCatalog ;

:M WM_DROPFILES ( hDrop lParam -- res )
        drop AddDropFiles  ;M


:M SelectItem:            ( hitem flag - )       SelectItem: TreeView ;M
:M GetLparm:              ( hItem - GetLparm  )  GetLparm: TreeView ;M
:M GetSelectedItem:       ( - hItem )  0 TVGN_CARET GetNextItem: TreeView ;M
:M GetlParmSelectedItem:  ( - lparm )  GetSelectedItem: Self GetLparm: Self ;M
:M GetLastVisible:        ( hItem - hItemLast )  GetLastVisible: TreeView ;M
:M GetPrevious:            ( hItem - hItemPrevious ) GetPrevious: TreeView ;M

:M GetSongSlectedItem:   ( - hitem ) \ To detect Album level
    GetlParmSelectedItem: self -1 =
       if    GetSelectedItem: Self GetChild: TreeView dup GetLparm: Self -1 =
             if drop -1
             then
       else  -1
       then
;M

:M SelectTreeViewItem:  ( hitem - )
    dup 0<>
         if     TVGN_CARET SelectItem: TreeView
         else   drop
         then
 ;M

:M DownInTree:          ( - )
   GetSelectedItem: Self   TVGN_NEXT  GetNextItem: TreeView
     SelectTreeViewItem: Self
 ;M

:M UpInTree:          ( - )
   GetSelectedItem: Self GetPrevious: Self
   SelectTreeViewItem: Self
 ;M

:M OpenChild:        ( - )
   GetSelectedItem: Self   GetChild: TreeView
   SelectTreeViewItem: Self
 ;M

\ :M CloseChild:        ( - )
\   GetSelectedItem: Self    GetParentItem: TreeView
\   Collapse: TreeView
\ ;M

:M On_Init:     ( -- )
        On_Init: super
        self Start: TreeView
        true to EnableNotify?
        ;M

:M On_Size:     ( -- )     AutoSize: TreeView ;M

:M Refresh:     ( -- )  \ Catalog
    \    MciDebug? if cr ." Fill-time: " timer-reset then
        false SetRedraw: TreeView
        GetRoot: TreeView DeleteItem: TreeView
        true to  CatalogBusy?
        wait-cursor
        EnableNotify? false to EnableNotify?
        FillTreeView: TreeView    \ fill,
        to EnableNotify?
        false to  CatalogBusy?
        EnableSearchButton
        arrow-cursor
     \   MciDebug? if .elapsed then
        ;M

:M WM_NOTIFY    ( h m w l -- f )
        dup @ GetHandle: TreeView = EnableNotify? and
        if   Handle_Notify: TreeView
        else false
        then ;M

:M DeleteItem:  ( hItem - )
          DeleteItem: TreeView
;M


:M ExpandAlbum: ( - )
          GetRoot: TreeView  dup TVE_EXPAND Expand: TreeView
          GetChild: TreeView dup TVE_EXPAND Expand: TreeView
          GetChild: TreeView     TVE_EXPAND Expand: TreeView
 ;M

;Object

create RequestsName$     ," Requests "
String: _Requests$

: Requests$  ( - adr count )
  _Requests$ maxstring erase
  RequestsName$ count _Requests$ place
  _Requests$ count
 ;

:Class RequestTree <super MediaTreeControl


: root-items  ( - hPrev )
    NotPlayable TVI_LAST  TVI_ROOT 2>r
  \  z" Music2"     2r@ 1 AddItemHierarical dup to hMusic
    z" Requests"  2r> 1 AddItemHierarical dup to hRequests
    dummy dup &PrevMusic   ! dup &PrevMovie ! dup to LastChar &PrevRequest !
    dup &PrevMovie hArtist ! &PrevMovie hArtist !
((         z" First Artist"  hPrev     hMusic     1  AddItemHierarical to hArtist
           z" Second Music"  hPrev     hArtist    0  AddItemHierarical drop
           z" Third Music"   hPrev     hArtist    0  AddItemHierarical drop  ))
 ;


:inline AddArtist ( - )
   rec-addr CountedArtist 1 max PrevRecAdr @ CountedArtist 1 max compareia 0<>
   rec-addr RecordDef Cnt_Artist c@ 0>  and
       if   rec-addr PrevRecAdr ! true to OtherArtist? NotPlayable
            rec-addr RecordDef Artist hPrev
            hRequests 1 AddItemHierarical PrevRecAdr hArtist !
       else  false to OtherArtist?
       then
 ;

: AddRecordHierarical ( n - ) \ Requests
     >r ResetInlineRecord
     r@ n>record: Requests
     &PrevRequest
     to PrevRecAdr to rec-addr
     AddArtist AddAlbum
     dup l_Index- c@
         if   r> dup +(l.int)
         else r>
         then
     to lParam
     drop \ rec-addr OptionalElements 2drop
     AddTitle
     rec-addr RecordDef hIntree @ 0> \ Skip when already in the tree.
         if    drop   \ So the first one will be shown.
         else  rec-addr RecordDef hIntree !
         then
     \ pause
 ;


: ResetHintree ( n - )
   n>record: Requests true swap RecordDef hIntree !
 ;

:M FillTreeView:  ( -- ) \ Requests
                tvins  /tvins  erase
                false SetRedraw: self
                GetRoot: Self DeleteItem: self \ delete all items from the tree view
                TVI_ROOT to hParent
                [ TVIF_TEXT TVIF_CHILDREN or TVIF_PARAM or TVIF_STATE or ] literal to mask
                root-items to hPrev
                0 to hMusicChar
                RequestIndex$ count file-exist?
                     if   unmap-ReqIdx map-RequestIndex
                          Set-data-pointers: Requests
                          for-all-Requests ResetHintree
                          for-all-Requests AddRecordHierarical
                     then
                 0 TVGN_CARET SelectItem: Self
                 Requests$ drop
                 #RequestsInFile (l.int) _Requests$ +place
                 _Requests$ +null
                 hRequests Rename: Self
                true SetRedraw: self
                ;M

0 value PreviousSelected

:M On_SelChanged: ( -- f )
             0 TVGN_CARET GetNextItem: Self dup GetRoot: Self  =
                 if     to PreviousSelected -1 UpdateLastSelected
                 else   FindAdresRecord: Self GetLparm: Self n>record: Requests dup PreviousSelected <>
                        if  dup to PreviousSelected  UpdateLastSelected
                        else drop
                        then
                 then
            \  UpdateLastSelected
              false
                ;M

;Class



\ -----------------------------------------------------------------------------
\ define the child window for the RIGHT pane below of the main window
\ in this area the catalog will be shown
\ -----------------------------------------------------------------------------
:Object RequestWindow        <Super Child-Window

 RequestTree TreeView

 int EnableNotify?
 Font TreeViewFont

: SendToTreeView  ( lparm wparm msg -- ) GetHandle: TreeView CALL SendMessage drop ;


:M DeleteItem:  ( hItem - )
          DeleteItem: TreeView
;M

:M GetParentItem: (  - hItem )
   GetParentItem: TreeView
                ;M

:M GetChild: ( hItem - hItemChild )  GetChild: TreeView   ;M

:M ExpandItem:   ( hItem - )
                 ExpandItem: TreeView
                ;M

:M SelectItem:  ( hitem flag - )
     SelectItem: TreeView
 ;M

:M SelectTreeViewItem:  ( hitem - )
    dup 0<>
         if     TVGN_CARET SelectItem: TreeView
         else   drop
         then
 ;M

:M ExpandRecord: ( hitem - hRecord)
                dup ExpandItem: TreeView
                GetChild: TreeView dup ExpandItem: TreeView
                GetChild: TreeView dup ExpandItem: TreeView
 ;M

:M Expand: ( - )
                GetRoot: TreeView ExpandRecord: Self
                ;M

:M GetRoot: ( - hItem )
                   GetRoot: TreeView
                ;M
:M GetLastVisible: ( - hItem )  GetLastVisible: TreeView
   ;M

:M ExpandLast: ( - )
                       GetRoot: TreeView dup ExpandItem: TreeView
                GetLastVisible: Self dup ExpandItem: TreeView
                      GetChild: TreeView dup ExpandItem: TreeView
                GetLastVisible: Self SelectTreeViewItem: Self
                ;M

:M SetBlackBackGround:  (  - )
               Color: Black     0 TVM_SETBKCOLOR    SendToTreeView
               Color: ltYellow  0 TVM_SETTEXTCOLOR  SendToTreeView
               ;M

:M SetWhiteBackGround:  (  - )
               Color: White     0 TVM_SETBKCOLOR    SendToTreeView
               Color: Black     0 TVM_SETTEXTCOLOR  SendToTreeView
               ;M

:M SetfontTreeView:  (  - )
                UseBigFont
                        if   24 32
                        else  11 18
                        then
                Height: TreeViewFont
                Width:  TreeViewFont
                s" Times New Roman (TrueType)" SetFaceName: TreeViewFont
                Create: TreeViewFont
                true Handle: TreeViewFont WM_SETFONT SendToTreeView
                SetBlackBackGround: Self  \ A black background and a yellow font.
                ;M

:M Start:       ( Parent -- )
                Start: super
                 false to UseBigFont SetfontTreeView: Self
                 0 to MaxDif
                ;M


:M WndClassStyle: ( -- style )
         \ CS_DBLCLKS only to prevent flicker in window on sizing.
         CS_DBLCLKS ;M

: AddDropFiles {  hDrop \ drop$ #File wHndl -- res }
        SetForegroundWindow: self
        wait-cursor
        MAXCOUNTED 1+ LocalAlloc: drop$
        0 to #File
        0 0 -1 hDrop  Call DragQueryFile  ?dup
           if  datfile$ count file-exist? check-config
               MAXCOUNTED drop$ 0 hDrop Call DragQueryFile
               drop$ swap GetLabel
               OpenAppendDatabase to wHndl
                   begin    MAXCOUNTED drop$ #File hDrop Call DragQueryFile dup 0>
                   while    wHndl drop$ rot AddFile  1 +to #File
                   repeat
          then
        2drop hDrop Call DragFinish
        wHndl CloseReMap
        RemoveDuplicates
        RefreshCatalog ;

:M WM_DROPFILES ( hDrop lParam -- res )
        drop AddDropFiles  ;M

:M GetLparm:            ( hItem - parm )  GetLparm: TreeView ;M

:M GetSelectedItem:     ( - hItem )     0 TVGN_CARET GetNextItem: TreeView ;M

:M OpenChild:        ( - )
   GetSelectedItem: Self   GetChild: TreeView
   SelectTreeViewItem: Self
 ;M

:M On_Init:     ( -- )
        On_Init: super
        self Start: TreeView
        true to EnableNotify?
        ;M

:M On_Size:     ( -- )        AutoSize: TreeView ;M


:M Refresh:     ( -- ) \ Requests
        MciDebug? if cr ." Fill-time: " timer-reset then
\        SW_HIDE Show: TreeView    \ hide,
        wait-cursor
        EnableNotify? false to EnableNotify?
        FillTreeView: TreeView    \ fill,
\        SW_RESTORE Show: TreeView \ and show it
        to EnableNotify?
        arrow-cursor
        MciDebug? if .elapsed then
        ;M

:M WM_NOTIFY    ( h m w l -- f )
        dup @ GetHandle: TreeView = EnableNotify? and
        if   Handle_Notify: TreeView
        else false
        then ;M

 :M SetBold: ( hItem - )
     SetBold: TreeView
   ;M

:M SetNormal:   ( hItem - )
     SetNormal: TreeView
   ;M

:M  GetlParmSelectedItem:  ( - lparm )
      GetSelectedItem: Self GetLparm: Self
 ;M


:M xSetBold:
      GetSelectedItem: Self SetBold: Self

   ;M

:M  xSetNormal:
   GetSelectedItem: Self SetNormal: Self
 ;M


;Object

: AddRequestPointer ( n - )
  n>aptr: catalog @  sp@ cell
  RequestIndex$  create/open
  dup>r file-append abort" Can't extend/write request index"
  r@    write-file abort" Can't write to request index"
  r> FlushCloseFile drop
 ;

: Lparm>hIntreeRequest ( LparmAlbum - hItem )
    0 max n>record: Requests RecordDef hIntree @
 ;

: ExpandSelectRequest  ( LparmAlbum - )
   #RequestsInFile 0 >
     if    Lparm>hIntreeRequest dup
           GetParentItem: RequestWindow dup
           GetParentItem: RequestWindow
           swap
           ExpandItem: RequestWindow
           ExpandItem: RequestWindow
           SelectTreeViewItem: RequestWindow
     else  drop
     then
 ;

: ExpandAlbum ( - )
   OpenChild: RequestWindow
   OpenChild: RequestWindow
   OpenChild: RequestWindow
 ;

: ExpandRequest  ( LparmAlbum - )
   Lparm>hIntreeRequest dup
   GetParentItem: RequestWindow dup
   GetParentItem: RequestWindow
   swap
   ExpandItem: RequestWindow
   ExpandItem: RequestWindow
   drop \
\ SelectTreeViewItem: RequestWindow
 ;

: RefreshRequests ( - ) Refresh: RequestWindow  ;

: GetSelectedLparmCatalogWindow ( - LparmCatalog|Flag ) \ -1 = No album
    GetSelectedItem: CatalogWindow dup 0=
       if      drop true
       else    GetLparm: CatalogWindow
       then
 ;

: GetSelectedLparmRequestWindow ( - LparmRequest|Flag ) \ -1 = No album
   GetSelectedItem: RequestWindow dup 0=
       if      drop true
       else     GetLparm: RequestWindow
       then
 ;

: SelectRootRequests  ( - )
    Getroot: RequestWindow  SelectTreeViewItem: RequestWindow
 ;

: IncrTimesRequested ( addr - )
   RecordDef TimesRequested dup c@ 1+ swap c!
 ;



: MakeRequest  ( Lparm - )
        vadr-config RequestLevel c@ swap
        dup EnableKeptRequest
        dup AddRequestPointer
        n>record: catalog dup>r RecordDef RequestLevelRecord c!
        r@ IncrTimesRequested
        1 r> RecordDef Request- c!
 ;


: FinishRequest
        \ -1 to last-selected-rec
        ReqIdx-mhndl flush-view-file drop RefreshRequests
 ;

: RequestRecord ( -- )
        GetSelectedLparmCatalogWindow MakeRequest FinishRequest
        ExpandLast: RequestWindow
        DownInTree: CatalogWindow
 ;


: ShrinkRequestFile  { n -- }
   n 0>
     if  ReqIdx-mhndl  flush-view-file drop #RequestsInFile unmap-ReqIdx dup 1 >
           if  n - cells s>d RequestIndex$ open-file-ptrs dup>r
               resize-file abort" Can't shrink file."
               r> FlushCloseFile map-RequestIndex
           else  RequestIndex$ count delete-file 2drop
           then
     then
 ;

: MoveAllRequestsUp  ( - )
\ Deletes the first one. The last record is duplicated
  #RequestsInFile 1 >
    if  1  n>aptr:  Requests
        0  n>aptr:  Requests
        #RequestsInFile 1- cells move
  then
 ;

\ Deletes the last one. The first record is duplicated
: MoveRequestsDown  \ ( From - )
  dup>r n>aptr:  Requests
  r@ 1+ n>aptr:  Requests
  #RequestsInFile r> - 1- 0 max cells move
 ;

\ Delete n records at Lparm. The last records are duplicated
: MoveRequestsUp  { Lparm n -- }
   Lparm n + dup>r n>aptr: Requests \ s
   Lparm      n>aptr: Requests      \ d
  #RequestsInFile r> - cells move
 ;


: ExpandFirst2Requests ( - )
   #RequestsInFile 0 >
       if  Getroot: RequestWindow ExpandItem: RequestWindow
           1 ExpandRequest
           0 ExpandRequest
       then
 ;

: ExpandAround  ( Lparm - )
             dup          ExpandSelectRequest
             dup 1- 0 max ExpandSelectRequest
             dup 1+       ExpandSelectRequest
                          ExpandSelectRequest
 ;

: DuplicateRequest? ( - flag )
   GetSelectedLparmCatalogWindow  dup -1 <>
      if    n>record: catalog  RecordDef Request- c@ 0<>
      else  not
      then
 ;

: DeletePlayedRequest (  - )
   #RequestsInFile 0>
   if  GetSelectedLparmRequestWindow
       false 0 n>record: Requests RecordDef Request- c!
       MoveAllRequestsUp 1 ShrinkRequestFile
       RefreshRequests
       Update: RequestWindow.TreeView
       ExpandFirst2Requests
       dup 0>
           if     1- ExpandSelectRequest
           else   drop GetRoot: RequestWindow
                  TVGN_CARET SelectItem: RequestWindow
           then
   then
  ;

: MakeRndIndex { hndlRnd n } ( hndlRnd n - hndlRnd )
    n  n>record: Catalog dup not-deleted? swap RecordDef Request- c@ not and
       if   n  n>aptr: Catalog @ sp@ cell hndlRnd
            write-file abort" Can't write to request index"
            drop
       then
    hndlRnd
 ;

: StartNewIndexFile ( - hndlRnd )
   unmap-RndIdx RndIndex$ count r/w create-file   abort" Can't create the random index file"
 ;

: FindRndRecords ( - )
   StartNewIndexFile
   for-all-records MakeRndIndex
   FlushCloseFile
 ;

: MakeRndIndexFromcollection { hndlRnd n } ( hndlRnd n - hndlRnd )
    n  n>record: Catalog dup not-deleted? over RecordDef Excluded- c@ not and
    swap RecordDef Request- c@ not and
       if   n  n>aptr: Catalog @ sp@ cell hndlRnd
            write-file abort" Can't write to request index"
            drop
       then
    hndlRnd
 ;

: FindRndRecordsIncollection ( - )
   StartNewIndexFile
   for-all-records MakeRndIndexFromcollection
   FlushCloseFile
 ;


: AddRndPointer ( n - )
  dup n>record: RandomRecords dup IncrTimesRequested
  1 swap RecordDef Request- c!
  n>aptr: RandomRecords @
  sp@ cell
  RequestIndex$  create/open
  dup>r file-append abort" Can't extend/write request index"
  r@    write-file  abort" Can't write to request index"
  r> FlushCloseFile drop
 ;

: ButtonIn?         ( - ButtonIn )  IDJoystick GetJoystickInfo  2nip nip 0= ;
: WaitTillDepressed ( - )           begin      ButtonIn?    until   ;

(( : ChangeFont ( Big|small - )
        to UseBigFont   Delete: TreeViewFont       SetfontTreeView: Catalog
        SW_SHOWMAXIMIZED Show:  MainWindow
 ;  ))


\s


