Anew BmiGraph.f \ The needed code was taken from graphics.f

WinDC CurrentDC

\ : test   159 28 372 240 white FillArea: currentDC  ;  test \s

0e FVALUE win.xleft
0e FVALUE win.xright
0e FVALUE win.ybot
0e FVALUE win.ytop
0e FVALUE win.xdif
0e FVALUE win.ydif

variable SXoffs
variable SXdiff
variable SYoffs
variable SYdiff

                \ Zero is left down
: SET-GWINDOW   \ <xb> <yb> <xt> <yt> --- <>  F: <xb> <yb> <xt> <yt> --- <>
                2OVER  SYoffs ! SXoffs !
                ROT  - SYdiff !                 \ hardware coordinates!
                SWAP - SXdiff !
                FTO win.ytop
                FTO win.xright
                FTO win.ybot
                FTO win.xleft
                win.xright win.xleft F- FTO win.xdif
                win.ytop  win.ybot   F- FTO win.ydif ;

: SCALE         \ F: <x> <y> --- <>  <> --- <x> <y>
                win.ybot  F-  win.ydif F/  SYdiff @ S>F F*  F>S SYoffs @ +
                win.xleft F-  win.xdif F/  SXdiff @ S>F F*  F>S SXoffs @ +
                swap ;

: wtype  ( x y adr n - x y ) 2over 2swap textout: currentDC  ;

\s

