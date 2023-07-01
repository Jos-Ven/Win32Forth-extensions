anew bmpdot.f  \ May 8th, 2009

\ From the project julia.
\ Structures fora bmp-file and a DIBsection.
\ Changed it a bit for the use with OpenGL.
\ May 17th, 2009 #bytes/pixel changed to a constant

 needs Struct.f

map-handle ahndl

: map-bitmap  ( name count - vadr )
  ahndl open-map-file abort" can't map file."
  ahndl >hfileAddress @  ;

struct{  \ BitmapFileHeader
        WORD   bfType       \ 19778
        LONG   bfSize       \ 3118  2128014
        WORD   bfReserved1  \ 0
        WORD   bfReserved2  \ 0
        DWORD  bfOffsetBits \ 118  54
        OFFSET >BitmapInfoHeader
}struct BitmapFileHeader

struct{ \  BITMAPINFOHEADER
        DWORD      biSize
        LONG       biWidth
        LONG       biHeight
        WORD       biPlanes
        WORD       biBitCount
        DWORD      biCompression
        DWORD      biSizeImage
        LONG       biXPelsPerMeter
        LONG       biYPelsPerMeter
        DWORD      biClrUsed
        DWORD      biClrImportant
 }struct BITMAPINFOHEADER

struct{ \ RGBTRIPLE
        BYTE    rgbtBlue
        BYTE    rgbtGreen
        BYTE    rgbtRed
}struct RGBTRIPLE

sizeof RGBTRIPLE constant #bytes/pixel

struct{ \ Win3DibHeader
    BITMAPFILEHEADER bmfh.BitmapFileHeader
    BITMAPINFOHEADER bmfh.BitmapInfoHeader
    OFFSET           >color-array
}struct Win3DibHeader  \ 54

struct{ \ RGBQUAD
        BYTE    rgbBlue
        BYTE    rgbGreen
        BYTE    rgbRed
        BYTE    rgbReserved
}struct RGBQUAD

\ sizeof RGBQUAD value #bytes/pixel

struct{ \ BITMAPINFO
    BitmapInfoHeader  pbmiBitmapInfoHeader
    offset pbmiColors
    sizeof RGBQUAD 256 * _add-struct
}struct bitmapinfo

sizeof bitmapinfo mkstruct: pbmi

[UNDEFINED] .cr  [IF]
: .cr           ( n - )           . cr ;
[THEN]

: .BitmapFileHeader ( BitmapFileHeader -)
     dup>r cr
            ." bfType______: " bfType       w@ .cr \ 19778
         r@ ." bfSize______: " bfSize       ?   cr \ 589878 h
         r@ ." bfReserved1_: " bfReserved1  w@ .cr \ 0
         r@ ." bfReserved2_: " bfReserved2  w@ .cr \ 0
         r> ." bfOffsetBits: " bfOffsetBits ?   cr \ 54
 ;

: bi-wh@ ( BitmapFileHeader - w h )    dup biWidth @ swap biHeight @  ;

: bytes/pixel?  ( BitmapFileHeader - #bytes/pixel )
     dup biSizeImage @ swap bi-wh@ * /  ;

: .BitmapInfoHeader  ( BitmapFileHeader - )
     dup>r  cr
            ." biSize_________: "     biSize          ?   cr  \ 40
        r@  ." biWidth________: "     biWidth         ?   cr  \ 512       1028
        r@  ." biHeight_______: "     biHeight        ?   cr  \ 384       690
        r@  ." biPlanes_______: "     biPlanes        w@ .cr  \ 1
        r@  ." biBitCount_____: "     biBitCount      w@ .cr  \ 24
        r@  ." biCompression__: "     biCompression   ?   cr  \ 0
        r@  ." biSizeImage____: "     biSizeImage     ?   cr  \ 589824 l
        r@  ." biXPelsPerMeter: "     biXPelsPerMeter ?   cr  \ 4724
        r@  ." biYPelsPerMeter: "     biYPelsPerMeter ?   cr  \ 4724
        r@  ." biClrUsed______: "     biClrUsed       ?   cr  \ 0
        r@  ." biClrImportant_: "     biClrImportant  ?   cr  \ 0
        r>  ." bytes/pixel____: "     bytes/pixel? .cr  \ #bytes/pixel
 ;

   \s Disable or delete this line to use the optional high level test

: gen-Win3DIBfile ( name count width height #bytes/pixel nrgbquad - width height total-file-size vadr  )
   >r drop \ to #bytes/pixel
   2swap 2over swap #bytes/pixel * * r> +
   -rot 2dup r/w create-file abort" Can't create DIBheader" >r
   rot sizeof Win3DibHeader +
   dup s>d r@ resize-file abort" Can't resize DIBheader"
   r> close-file abort" Can't close DIBheader"
   -rot map-bitmap 2dup swap erase
 ;

variable end-adres-bitmap

: fill-24-bits-header  ( w h total-file-size vadr - )
    2dup + end-adres-bitmap !
    2dup dup>r  bfSize !
    54 dup rot  bfOffsetBits !
    - r@ >BitmapInfoHeader biSizeImage !
    19778  r@   bfType w!
    r> >BitmapInfoHeader
      40   over biSize !
      1    over biPlanes w!
      24   over biBitCount w!
      4724 over biXPelsPerMeter !
      4724 over biYPelsPerMeter !
      swap over biHeight !
      biWidth !
 ;

: >bmp  ( x y >BitmapInfoHeader - adr>bmp )
  dup>r biWidth @ * swap - r> biWidth @ + #bytes/pixel *
  end-adres-bitmap @ swap -
 ;

: dot>bmp  ( x y rgb - )  \ bitmap must be mapped  x and y must point in a vallid area
   >r ahndl >hfileAddress @  >BitmapInfoHeader >bmp
   r@ 0x10 rshift over c!    1+ r@ 8 rshift over c!  1+ r> swap c!
 ;

defined set-dot nip [IF]

: dot>bmp? ( - flag )
  ['] dot>bmp ['] set-dot >body @ = ;

[THEN]


in-system

\ Use:
: .test
      s" test.bmp" map-bitmap
      ahndl >hfileAddress @
      cr dup 500 dump
      cr dup .BitmapFileHeader
      cr >BitmapInfoHeader .bitmapinfoheader
  ;

IN-PREVIOUS


: test
  s" testOld.bmp" 400 200 #bytes/pixel 0 gen-Win3DIBfile
  dup>r  fill-24-bits-header
  r@ >color-array r> >BitmapInfoHeader biSizeImage @ 0xff fill  \ make it white
                  \  0 b g r

  150 50 do  50 i  0  dot>bmp  loop
  350 50 do  i 50  0  dot>bmp  loop

  160 40 do  40 i  0  dot>bmp  loop
  360 40 do  i 40  0  dot>bmp  loop

  170 30 do  30 i  0  dot>bmp  loop
  370 30 do  i 30  0  dot>bmp  loop

  180 20 do  20 i  0  dot>bmp  loop
  380 20 do  i 20  0  dot>bmp  loop

  190 10 do  10 i  0  dot>bmp  loop
  390 10 do  i 10  0  dot>bmp  loop

  200 0 do   0  i  0  dot>bmp  loop
  400 0 do   i  0  0  dot>bmp  loop

\ s" test.bmp"  .test
   ahndl close-map-file drop
  ;

   test
   cr chdir
      dir test.bmp
   cr .( View it in paint.)
   cr dos" mspaint.exe test.bmp" dos$ $exec drop
abort \s
