Anew -FilterWindow.f

\- textbox needs excontrols.f  \ ListBox.f

 Needs TreeView2.f

create TVtext$ maxstring allot

:Class NewTVC <super TreeViewControl

        Font WinFont
   Font TreeViewFont

:M WindowStyle: ( -- style )
                WindowStyle: super
                TVS_DISABLEDRAGDROP or
                TVS_SHOWSELALWAYS   or
                ;M

int hRoot
int hSon
int hPrev

: AddItem       ( sztext hAfter hParent nChildren -- )
                tvins  /tvins  erase
                ( nChildren)      to cChildren
                ( hParent)        to hParent
                ( hAfter)         to hInsertAfter
                                  to pszText
                TVIF_TEXT TVIF_CHILDREN or
                to mask
                tvins 0 TVM_INSERTITEMA hWnd Call SendMessage
                to hPrev
                ;


:M AddTreeView:  (  Z"string -- )
                 TVI_LAST  TVI_ROOT  1  AddItem  hPrev to hRoot
                 TVI_ROOT SortChildren: Self
                ;M

:M Start:       ( Parent -- )
                Start: super
                8 Width: WinFont
                16 Height: WinFont
                s" Courier New" SetFaceName: WinFont
                Create: WinFont
                true Handle: WinFont WM_SETFONT hWnd CALL SendMessage drop \ activate a new font
                ;M

:M GetTextItem:  ( hItem - Text )
                TVIF_TEXT           to mask
                to hItem
                TVtext$             to pszText
                maxstring           to cchTextMax
                tvitem 0 TVM_GETITEMA  hWnd Call SendMessage
                0= if 0 else TVtext$ then winpause
                ;M

:M GetSelItem: \ { \ text$ -- Text }      \ Get text of the selected item. 0 means no selection
                0 TVGN_CARET GetNextItem: Self
                GetTextItem: Self
                ;M
;Class



307 value InitFilterWindowWidth
0 value ObjParent

:Class ttPushButton	<Super PushButton \ for version 6.14

:M ToolString:  ( addr cnt -- )
		binfo place
		binfo count \n->crlf
                ;M

;Class


:Object FilterWindow  <Super Window

ttPushButton btnSearch
ttPushButton btnAdd
ttPushButton btnAddAll
ttPushButton btnRemove
ttPushButton btnDelete
int #items


NewTVC TreeView
int Xpos
int Xinc

int InitWidth


Font WinFont           \ default font
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color



\ Font setting definitions
  Font TreeViewFont


:M ClassInit:   ( -- )
                ClassInit: super
                60 to Xinc
                \ Insert your code here, e.g initialize variables, values etc.
                ;M


:M ExWindowStyle: ( -- style )
        ExWindowStyle: Super
        WS_EX_CLIENTEDGE or ;M


: NewXpos  ( - NewXpos ) Xinc 2 + +to Xpos Xpos ;
: NewBtnPos ( - x y w h ) NewXpos 0 Xinc 24  ;

:M on_size:     ( -- )
                0 25 width dup to InitFilterWindowWidth height 24 -  Move: TreeView
                ;M

:M MinSize:     ( -- width height )  307 10  ;M



\ N.B if this form is a modal form a non-zero parent must be set
:M ParentWindow:  ( -- hwndparent | 0 if no parent )
                hWndParent
                ;M

:M WindowTitle: ( -- ztitle ) z" "  ;M
:M Retitle:             ( adr n -- )  SetTitle: Self ;M

:M StartSize:   ( -- width height ) InitFilterWindowWidth 3  ;M

:M StartPos:    ( -- x y ) CenterWindow: Self     ;M


:M Close:        ( -- )
                0 to #items
                TVGN_ROOT DeleteItem: TreeView
                Close: TreeView
                Close: super
                ;M


:M WM_COMMAND   ( h m w l -- res )
                dup 0=      \ id is from a menu if lparam is zero
                if        over LOWORD CurrentMenu if dup DoMenu: CurrentMenu then
                          CurrentPopup if dup DoMenu: CurrentPopup then drop
                else      over LOWORD ( ID ) self   \ object address on stack
                          WMCommand-Func ?dup    \ must not be zero
                          if        execute
                          then
                then   2drop  0 ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

\ GetWindowRect: Self >r 2 pick - r> 2 pick - move: Self \ zeromove

:M DockLeft: { xParent yParent (w) hbParent -- }
                GetWindowRect: self drop 2 pick  -  dup to (w) ( nW )
                hbParent yParent   -    ( nH )  2>r
                2drop  xParent (w) -    ( nX )
                yParent                 ( nY )
                2r>  Move: self
                ;M

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


:M On_Init:     ( -- )
         \ prevent flicker in window on sizing
          CS_DBLCLKS GCL_STYLE hWnd  Call SetClassLong  drop

                s" MS Sans Serif" SetFaceName: WinFont
                -0 Width: WinFont
                -14 Height: WinFont

                Create: WinFont
                \ set form color to system color
                Color: black NewColor: FrmColor


                self Start: btnSearch
                s" Search" SetText: btnSearch
                Handle: WinFont SetFont: btnSearch

                self Start: btnAdd
                s" Add" SetText: btnAdd
                Handle: WinFont SetFont: btnAdd


                self Start: btnAddAll
                s" Add all" SetText: btnAddAll
                Handle: WinFont SetFont: btnAddAll

                self Start: btnRemove
                s" Remove" SetText: btnRemove
                Handle: WinFont SetFont: btnRemove

                self Start: btnDelete
                s" Delete" SetText: btnDelete
                Handle: WinFont SetFont: btnDelete


                On_Init: super
                1001 SetId: TreeView
                self Start: TreeView
                true UseBigFont SetfontTreeView: Self

               0 to Xpos
               Xpos 0 Xinc 24         Move: btnSearch
               NewBtnPos            Move: btnAdd
               NewBtnPos            Move: btnAddAll
               NewBtnPos            Move: btnRemove
	       NewBtnPos            Move: btnDelete
               ;M

:M DefaultIcon: ( -- hIcon )     IDI_INFORMATION null Call LoadIcon ;M

:M WindowStyle:     ( -- style )
    [ WS_BORDER WS_SYSMENU or  WS_SIZEBOX or WS_CAPTION or ] literal ;M


:M On_Paint:    ( -- )
                 0 0 GetSize: self Addr: FrmColor FillArea: dc
                 ;M

:M On_Done:    ( -- )
                Delete: WinFont
                Delete: TreeViewFont

                \ Insert your code here, e.g delete fonts, any bitmaps etc.
                On_Done: super
                ;M

:M GetRoot: ( - hItem )
                   GetRoot: TreeView
                  \ TVGN_ROOT TVGN_ROOT  GetNextItem: TreeView
                ;M

:M SelectTreeViewItem:  ( hitem - )
    dup 0<>
         if     TVGN_CARET SelectItem: TreeView
         else   drop
         then
 ;M


:M Zadd:       (  z"-string -- )    AddTreeView: Treeview   1 +to #items  ;M
:M GetTextSelectedItem: ( - Text )  GetSelItem: Treeview   ;M
:M GetLastVisible:  ( hItem -- hItem )  TVGN_LASTVISIBLE GetNextItem: Treeview ;M
:M Set#items:  ( n - )    to #items  ;M
:M Get#items:  ( - n )    #items  ;M
:M GetSelectedItem:       ( - hItem )  0 TVGN_CARET GetNextItem: TreeView ;M


:M DownInTree:          ( - )
   GetSelectedItem: Self   TVGN_NEXT  GetNextItem: TreeView
   SelectTreeViewItem: Self
 ;M


;Object

string: Zadd$

: ToFilterWindow  ( adr cnt - ) Zadd$ ascii-z  Zadd: FilterWindow  ;


: StartFilterWindow  ( Filename cnt - )
    2dup ascii : scan not >r drop 2dup file-exist? r> and
    if    false SetRedraw: FilterWindow
          TVGN_ROOT DeleteItem: FilterWindow.TreeView drop
          start: FilterWindow  2dup Retitle: FilterWindow
          0 Set#items: FilterWindow
          ['] ToFilterWindow ForAllLines
          true SetRedraw: FilterWindow
          Paint: FilterWindow.TreeView
    else  2drop
    then
 ;

\s
