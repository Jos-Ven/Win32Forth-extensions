\ Juliamenu.f

menubar Juliamenu
  popup "&File"
     menuitem "&Save to bitmap"            'S'
                save-to-bmpfile Z" ready.wav" sounds ;
     menuitem "Save a slide s&how"         'H'
                save-random-slides Z" ready.wav" sounds ;
     menuitem "Sa&ve parameters"           'V'
                save-to-inifile  ;
     menuitem "&Load parameters"           'L'
                load-ini ;
     menuitem "E&xit"                      'X'
                bye ;

  popup "&View"
     menuitem "&Julia walker"         'C'
                ['] compute to draw-vector .Fractal ;
     menuitem "&Mandelbrot Walker"    'M'
                [']   mandelbrot_walker to draw-vector .Fractal ;
     menuitem "&Random slide show" 'R' random-julia ;

  popup "&Options"
     :MENUITEM   mThreads "Use one thread"
                     ClrDib UseOneThread- not to UseOneThread- MenuChecks  0 to LastKey redraw ;
     :MENUITEM   mContinous "Uninterrupted calculations" Continous- not to Continous- MenuChecks 0 to LastKey  redraw ;

MENUSEPARATOR
     menuitem "P&arameters"             'P'
               parameters ;
     menuitem "Swap &colors"            'A'
               0 to LastKey color_false @ color_true @ color_false ! color_true ! redraw ;
MENUSEPARATOR
     menuitem "Load colors in &backbuffer" 'B'
                load>backbuffer ;
     menuitem "Backbuffer: swap &true"  'T'
               swap_true ;
     menuitem "Backbuffer: swap &false" 'F'
               swap_false ;

  popup "&Help"
     menuitem "A&bout Win32Forth"     'B'
               infoWin32Forth infoWin32Forth-len InformationBox
                ;
     menuitem "Ab&out the program" 'O'
               infojulia$ InformationBox
                ;
     menuitem "&About the fractals"       'J'
               infojulia-functions infojulia-functions-len InformationBox
                ;
     menuitem "About the Fractal &walker"       'W'
               infomandelbrot-functions infomandelbrot-functions-len InformationBox
                ;
     menuitem "Ma&ndelbrot effects"   'N'
               infomandelbrot-effects infomandelbrot-effects-len InformationBox
                ;
     menuitem "Contr&ibutions"        'T'
               info-contrib info-contrib-len InformationBox
                ;
     submenu    "Released from:"
  menuitem "https://sites.google.com/site/win324th/home" s" http://sites.google.com/site/win324th/home" hwnd-julia "Web-Link ;
     endsubmenu
endbar


 Juliamenu SetMenuBar: JuliaWindow

:NoName ( - ) UseOneThread- Check: mThreads
              Continous-    Check: mContinous ; is MenuChecks

\s

