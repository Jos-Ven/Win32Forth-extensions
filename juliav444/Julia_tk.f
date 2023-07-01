[DEFINED] Jullia444  [IF]  100 ms bye [then] \ Preventing duplicate loading.

aNew Jullia444 \ September 4, 2016 by J.M.B.v.d.Ven


string: empty$ empty$ 250 erase

decimal



code compareia    ( adr1 len1 adr2 len2 -- n )
    sub     ebp, # 8
    mov     0 [ebp], edi
    mov     4 [ebp], esi
    pop     eax                     \ eax = adr2
    pop     ecx                     \ ecx = len1
    pop     esi                     \ esi = adr1
    add     esi, edi                \ absolute address
    add     edi, eax                \ edi = adr2 (abs)
    sub     eax, eax                \ default is 0 (strings match)
    cmp     ecx, ebx                \ compare lengths
    je      short @@2
    ja      short @@1
    dec     eax                     \ if len1 < len2, default is -1
    jmp     short @@2
@@1:
    inc     eax                     \ if len1 > len2, default is 1
    mov     ecx, ebx                \ and use shorter length
@@2:
    mov     bl, BYTE [esi]
    mov     bh, BYTE [edi]
    inc     esi
    inc     edi
    cmp     bx, # $2F2F            \ skip chars beteen 0 and 2F ( now lower case )
    jle     short @@7
    or      bx, # $2020            \ May 21st, 2003 or is better then xor
@@7:
    cmp     bh, bl
    loopz   @@2

    je      short @@4               \ if equal, return default
    jnb     short @@3               \ ** jnb for an unsigned test ( was jns )
    mov     eax, # 1                \ if str1 > str2, return 1
    jmp     short @@4
@@3:
    mov     eax, # -1               \ if str1 < str2, return -1
@@4:
    mov     ebx, eax
    mov     edi, 0 [ebp]
    mov     esi, 4 [ebp]
    add     ebp, # 8
    next    c;


 needs fmacro.f  \ An updated version that will be in version 6.15.01
 needs Resources.f
 needs Struct.f
 needs MultiTaskingClass.f
 needs toolset.f
 needs SetExecutionState.f

wtasks ControllerTask

 needs ParallelPlotter.f
 needs ColorExtension.f
 needs juliav443.f
 needs mandelbr.f
 needs export.f
 needs julia_rc.f
 needs JULIAWIN.F
 needs Juliamenu.f

 s" julia.ico" needed-file
 s" ready.wav" needed-file

 s" apps\Setup" "fpath+
 needs com01.f
 needs dtop_lnk.f


: .julia          ( -- )                  \ start the program
    Start: ControllerTask
    Start: FractalTask
    Start: JuliaWindow
    Nomenu    SetMenuBar: JuliaWindow
    hwnd-julia call GetMenu to NOmenu-hmnu
    juliamenu  SetMenuBar: JuliaWindow
    hwnd-julia call GetMenu to julia-hmnu
    redraw
  ;

: create_julia-link_on_desktop  \ Replaces the old link when it exists
   init_dtop_for_link  CURRENT-DIR$  count
   2dup s" \Julia444.exe" $concat  z" Julia" -rot make_link
   2dup s" \JULIA.ICO"    $concat                 set_icon_link
   set_dir_link
   CSIDL_DESKTOPDIRECTORY GetSpecialFolderLocation s" \Julia.lnk" $concat
   save_link
 ;

: start-julia
   decimal
   s" Ready.wav"    needed-file
   s" Version.txt"  needed-file
   s" Howjulia.txt" needed-file
   ['] .julia ['] create_julia-link_on_desktop  link/start
 ;

\ .julia abort \ To make new developments easy


s" none" write-installer  \ Is changed when the link has been made.

 ' start-julia turnkey julia444               \ There may be a virus alert (false positive)
\  NoConsoleBoot ' start-julia SAVE julia444  \ To prevent a false positive, exclude the directory
                                              \ in which the sources are placed in your AV program

winver winnt4 >= [IF]  \ For V6.0.0.0 Common-Controls
  current-dir$ count pad place
  s" \" pad +place
  s" Julia444.exe" pad +place
  pad count "path-file drop AddToFile
               CREATEPROCESS_MANIFEST_RESOURCE_ID RT_MANIFEST s" Julia.exe.manifest" "path-file drop  AddResource
                101 s" julia.ico" "path-file drop AddIcon
                false EndUpdate
        [else]
               s" julia.ico" s" Julia444.exe" Prepend<home>\ AddAppIcon
        [then]

 Require Checksum.f  s" Julia444.exe" (AddCheckSum)

cr cr

 .(  Julia444.exe is created in:)
 cd

 cr .( starting Julia444.exe)
 dos" Julia444.exe" dos$ $exec drop cr
 3 seconds bye
\s
