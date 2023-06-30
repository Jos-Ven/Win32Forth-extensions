Anew -Declared.f

defer MoveRightButtons
defer MoveMiddleButtons
defer MovePlayButtons
defer MoveTrackbar
defer Paint_TopPane
defer _SearchInCatalog
defer OpenFilterWindow
defer EnableSearchButton

defer MoveProgresWindow
defer Start:Toppane.ProgresWindow
defer DirlistToCmbList
defer UpdateLastSelected

defer DoCmbListMore
defer (RefreshCatalog)


decimal
s" apps\Player4"   "fpath+

false value MciDebug?
false value turnkey?
false value CoverWindow-


defer RefreshCatalog ' noop is RefreshCatalog
\ defer SortCatalog    ' noop is SortCatalog
defer Incollection?  ' noop is Incollection?


\  defer RequestRecord  ' noop is RequestRecord
defer MenuChecks     ' noop is MenuChecks
defer HandleJoystick ' noop is HandleJoystick

load-bitmap _First      "First.bmp"
load-bitmap _up         "Up.bmp"
load-bitmap _scrldn     "down.bmp"
load-bitmap _Last       "Last.bmp"
load-bitmap _Right      "Right.bmp"
load-bitmap _RightUp    "RightUp.bmp"


load-bitmap _RightDown  "RightDown.bmp"
load-bitmap _Left       "Left.bmp"
load-bitmap _LeftBelow  "LeftBelow.bmp"
load-bitmap _Shuffle    "Shuffle.bmp"
load-bitmap _Sort       "Sort.bmp"

0 value upbitmap
0 value downbitmap
0 value lastbitmap
0 value firstbitmap
0 value rightbitmap

0 value RightUpbitmap
0 value RightDownbitmap
0 value Leftbitmap
0 value LeftBelowBitmap
0 value ShuffleBitmap
0 value SortBitmap
0 value Pausing?
0 value CatalogBusy?
variable #Done

3243 constant ScaleVol

0 value Busy?

200 value IDJoystick
AcceleratorTable AccelTable
string: StartupDir
: winxp?  ( - f )  winver winxp = ;


:Inline Set-vFont ( - adr n )
    winxp?
     if         0        Escapement: vFont
                0       Orientation: vFont
                true    Italic: vFont
                0           CharSet: vFont
                3      OutPrecision: vFont
                2     ClipPrecision: vFont
                1           Quality: vFont
                66   PitchAndFamily: vFont
                s" Comic Sans MS"
     else
                0        Escapement: vFont
                0       Orientation: vFont
                true    Italic: vFont
                0           CharSet: vFont
                3      OutPrecision: vFont
                2     ClipPrecision: vFont
                1           Quality: vFont
                2    PitchAndFamily: vFont
                s" Segoe Print"
     then
    SetFacename: vFont
 ;

:Inline Set-Win-font ( -- )
                -13          Height: WinFont
                0             Width: WinFont
                0        Escapement: WinFont
                0       Orientation: WinFont
                400          Weight: WinFont
                0           CharSet: WinFont
                1      OutPrecision: WinFont
                2     ClipPrecision: WinFont
                1           Quality: WinFont
                34   PitchAndFamily: WinFont
                s" MS Sans Serif" SetFacename: WinFont
 ;



\s
