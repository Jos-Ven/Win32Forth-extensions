\ ===================================================================
\           File: opengllib-1.22.fs
\         Author: Jens Schneider
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 08/06/2010
\    Description: Bump mapping (extensions)
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 22
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson22  also Lesson22 definitions

\ ---[ Variables ]---------------------------------------------------

3 constant NumBumps                  \ number of bump textures to use
3 constant NumInvBumps       \ number of inverse bump textures to use
6 constant NumImages                  \ number of images being loaded

\ Maximum Emboss-Translate. Increase To Get Higher Immersion
0.01e fconstant Max-Emboss

FALSE value emboss                                   \ boolean toggle
TRUE value bumps                                     \ boolean toggle

1 value filter                   \ which filter to use, range: [0..2]

variable glLogo                              \ handle for OpenGL Logo
variable multiLogo             \ handle For Multitexture-Enabled-Logo

fvariable xrot                                           \ x rotation
fvariable yrot                                           \ y rotation
fvariable zrot                                           \ z rotation
fvariable xspeed                                            \ x speed
fvariable yspeed                                            \ y speed
fvariable zdepth                                  \ depth into screen


\ Allot space for additional texture pointers and init the memory
create bump     here NumBumps    cells dup allot 0 fill
create invbump  here NumInvBumps cells dup allot 0 fill
create teximage here NumImages   cells dup allot 0 fill

\ ---[ Array Index Functions ]---------------------------------------
\ Index functions to access the arrays

: bump-ndx     ( n -- *tex[n] ) NumBumps    MOD cells bump + ;
: invbump-ndx  ( n -- *tex[n] ) NumInvBumps MOD cells invbump + ;
: teximage-ndx ( n -- *tex[n] ) cells teximage + ;

\ Returns a pointer to the nth element of an array of floats/sfloats
: farray-ndx  ( *array n -- *array[n] ) floats + ;
: sfarray-ndx ( *array n -- *array[n] ) sfloats + ;

\ ---[ Light Values ]------------------------------------------------
\ The following three arrays are RGBA color shadings.

\ These light tables are passed by address to gl-light-fv, not value,
\ so they must be stored as 32-bit floats, not gforth 64-bit floats.


\ Ambient Light Values \ Jos: Changed it from 0.2 to 0.8 (too dark otherwise)
\ create LightAmbient[]   0.2e SF, 0.2e SF, 0.2e SF, 1e SF,
create LightAmbient[]   0.8e SF, 0.8e SF, 0.8e SF, 1e SF,

\ Diffuse Light Values (white)
create LightDiffuse[]   1e SF, 1e SF, 1e SF, 1e SF,

\ Light Position
create LightPosition[]  0e SF, 0e SF, 2e SF, 1e SF,

\ Grays
create Gray[]           0.5e SF, 0.5e SF, 0.5e SF, 1e SF,


\ Data we'll use to generate our cube
\ These are passed by value, not address, so can stay 64-bits

struct{
  b/float  .tx
  b/float  .ty
  b/float  .x
  b/float  .y
  b/float  .z
}struct vertice%
sizeof vertice% constant /vertice%

create data[]
0e F, 0e F,     -1e F, -1e F,  1e F,                     \ Front Face
1e F, 0e F,      1e F, -1e F,  1e F,
1e F, 1e F,      1e F,  1e F,  1e F,
0e F, 1e F,     -1e F,  1e F,  1e F,

1e F, 0e F,     -1e F, -1e F, -1e F,                      \ Back Face
1e F, 1e F,     -1e F,  1e F, -1e F,
0e F, 1e F,      1e F,  1e F, -1e F,
0e F, 0e F,      1e F, -1e F, -1e F,

0e F, 1e F,     -1e F,  1e F, -1e F,                       \ Top Face
0e F, 0e F,     -1e F,  1e F,  1e F,
1e F, 0e F,      1e F,  1e F,  1e F,
1e F, 1e F,      1e F,  1e F, -1e F,

1e F, 1e F,     -1e F, -1e F, -1e F,                    \ Bottom Face
0e F, 1e F,      1e F, -1e F, -1e F,
0e F, 0e F,      1e F, -1e F,  1e F,
1e F, 0e F,     -1e F, -1e F,  1e F,

1e F, 0e F,      1e F, -1e F, -1e F,                     \ Right Face
1e F, 1e F,      1e F,  1e F, -1e F,
0e F, 1e F,      1e F,  1e F,  1e F,
0e F, 0e F,      1e F, -1e F,  1e F,

0e F, 0e F,     -1e F, -1e F, -1e F,                      \ Left Face
1e F, 0e F,     -1e F, -1e F,  1e F,
1e F, 1e F,     -1e F,  1e F,  1e F,
0e F, 1e F,     -1e F,  1e F, -1e F,

: data-ndx ( n -- data[n] ) /vertice% * data[] + ;

\ Prepare for GL_ARB_multitexture
\ Used To Disable ARB Extensions Entirely
TRUE value ARB_ENABLE

\ Set to TRUE to see your extensions at start-up
TRUE value EXT_INFO

\ Characters For Extension-Strings
10240 constant MAX_EXTENSION_SPACE

\ Maximum Characters In One Extension-String
256 constant MAX_EXTENSION_LENGTH

\ Flag Indicating Whether Multitexturing Is Supported
\ -- this is set in InitGL
FALSE value MultiTextureSupported

\ Use It If It Is Supported?
false value UseMultiTexture

\ Number Of Texel-Pipelines. This Is At Least 1.
variable MaxTexelUnits

\ ---[ Variable Initializations ]------------------------------------

0e xrot F!
0e yrot F!
0e zrot F!
-0.3e xspeed f!
-0.2e yspeed f!
-5e zdepth F!
1 MaxTexelUnits !


\ ---[ Define the OpenGL Extensions ]--------------------------------

VoidGLFunction: glMultiTexCoord2fARB ( t_Glfloat s_Glfloat target -- )
VoidGLFunction: glActiveTextureARB   ( GL_TEXTURE?_ARB -- )

+GLFunctions  \ Search also in the vocabulary GLFunctions for the raw
                                            \ defined OpenGL function

synonym gl-active-texture-ARB  glActiveTextureARB     \ make it known
                                                        \ in lesson22

: gl-multi-tex-coord-2f-ARB   ( target -- ) ( f: s t -- )
    >r 2f' r> glMultiTexCoord2fARB         \ Prepair the raw function
 ;                  \ That means convert floats and reverse the stack

-GLFunctions     \ Remove the vocabulary GLFunctions from context and
                              \ continue with the vocabulary Lesson22

#define GL_COMBINE_EXT                    0x8570
#define GL_COMBINE_RGB_EXT                0x8571


\ ---[ InitMultiTexture ]--------------------------------------------
\ Determines if ARB_multitexture is available

: InitMultiTexture ( -- boolean )
    gl-extensions-supported? ARB_Enable AND if   \ All extensions OK?
    load-gl-extensions                   \ Make the extensions active
\   cr ." The GL_ARB_multitexture extension will be used." cr cr
    GL_MAX_TEXTURE_UNITS_ARB MaxTexelUnits gl-get-integer-v
    TRUE to UseMultiTexture
    TRUE                                               \ return value
  else
    cr ." The GL_ARB_multitexture extension not supported." cr cr
    \ We Can't Use It If It Isn't Supported!
    FALSE to UseMultiTexture
    FALSE                                              \ return value
  then
;


\ ---[ LoadGLTextures ]----------------------------------------------

\ function to load in bitmap as a GL_RGB8 texture
: Generate-Texture { *src -- }
  GL_TEXTURE_2D 0 GL_RGB8
  *src >biWidth  @                           \ width of texture image
  *src >biHeight @                          \ height of texture image
  0 GL_BGR                                \ pixel mapping orientation
  GL_UNSIGNED_BYTE
  *src >color-array                         \ address of texture data
  gl-tex-image-2d                               \ finally generate it
;

\ function to load in bitmap as a GL_RGBA8 texture
: Generate-RGBA8-Texture { *src *data -- }
  GL_TEXTURE_2D 0 GL_RGBA8
  *src >biWidth  @                           \ width of texture image
  *src >biHeight @                          \ height of texture image
  0 GL_RGBA                               \ pixel mapping orientation
  GL_UNSIGNED_BYTE
  *data                                     \ address of texture data
  gl-tex-image-2d                               \ finally generate it
;

: Generate-MipMapped-Texture { *src -- }
  GL_TEXTURE_2D GL_RGB8
  *src >biWidth  @                           \ width of texture image
  *src >biHeight @                          \ height of texture image
  GL_BGR                                  \ pixel mapping orientation
  GL_UNSIGNED_BYTE
  *src >color-array                         \ address of texture data
  glu-build-2d-mipmaps                          \ finally generate it
;

\ ---[ Load-Image ]--------------------------------------------------
\ Attempt to load the texture images into SDL surfaces, saving the
\ result into the teximage[] array; Return TRUE if result from
\ sdl-loadbmp is <> 0; else return FALSE

: Map-Image ( str len ndx mapHndl -- )
  swap >r _map-bitmap r> teximage-ndx ! \ Store the adress _map-bitmap of in the index.
;

(( Jos: Not needed, just change the gl-tex-coord-2f of the logo.
\ ---[ Flip-Image ]--------------------------------------------------
\ Reverses the line ordering of a .BMP image.
\ Requires the handle of the SDL surface to be flipped.

: Flip-Image ( *src -- )
  0 0 0 0 { *src *tdata *timage _b/l _height -- }   \ local variables

  \ Set *tdata to the pixel data in the source surface
  *src sdl-surface-pixels @ to *tdata

  \ Set *timage to the next paragraph boundary above <here>
  \ This does NOT allot memory in the dictionary - it just uses some
  \ of it above <here> as a temporary buffer space.

  here 256 mod 256 swap - here + to *timage

  \ Set the sizes to be used

  *src sdl-surface-pitch sw@ to _b/l          \ bytes/line of surface
  *src sdl-surface-h @ to _height     \ number of rows in the surface

  \ Copy/flip the pixel data to the temp buffer space

  _height 0 do
    *tdata i _b/l * +                                \ source line[i]
    *timage _height i - _b/l * +                     \ dest line[h-i]
    _b/l                                             \ length to move
    cmove
  loop

  *timage *tdata _b/l _height * cmove       \ copy new image over old
;  ))

map-handle hndl0
map-handle hndl1
map-handle hndl2
map-handle hndl3
map-handle hndl4
map-handle hndl5


: Create-Linear-Filtered-Texture { iBind iTexture CFA-ndx -- }
    GL_TEXTURE_2D iBind CFA-ndx execute @ gl-bind-texture
    \ Linear filtering
    LinearFiltering
    \ Generate the texture
    iTexture teximage-ndx @  Generate-Texture
 ;

: Create-Nearest-Filtered-Texture { iBind iTexture CFA-ndx -- }
    GL_TEXTURE_2D iBind CFA-ndx execute @ gl-bind-texture
    \ Nearest filtering
    NearestFiltering
    \ Generate the texture
    iTexture teximage-ndx @  Generate-Texture
 ;

: Create-MipMapped-Texture  { iBind iTexture CFA-ndx -- }
    GL_TEXTURE_2D iBind CFA-ndx execute @ gl-bind-texture
    \ Mipmap filtering
    MipMappedFiltering
    \ Generate the texture
    iTexture teximage-ndx @  Generate-MipMapped-Texture
 ;

: SetAlpha  { *Source *Dest #Pixels -- }  \ Sets the alpha byte of a
    #Pixels  0                         \ RGB image into a RGBA image
    do
      *Source i 3 * + C@                      \ get source red pixel
      *Dest i 4 * 3 + + C!                     \ set dest alpha byte
    loop
 ;

: InclRgbImage  { *Source *Dest #Pixels -- }     \ Copy an RGB image
  #Pixels 0                                       \ to an RGBA image
    do                                  \ and skip the alpha channel
      *Source i 3 * +
      *Dest i 4 * + 3 cmove
    loop
 ;

: LoadGLTextures ( -- status )
   0 0 { *tdata *timage -- }
    \ create variables for storing surface pointers and return flag
    3 MallocTextures    \ MallocTextures allocates only when not done
    NumTextures Texture[] gl-gen-textures       \ create the textures
    \ Attempt to load the texture images by using a mapping
    s" base.bmp"           0 hndl0 Map-Image                \ ndx = 0
    s" bump.bmp"           1 hndl1 Map-Image                \ ndx = 1
    s" opengl_alpha.bmp"   2 hndl2 Map-Image                \ ndx = 2

    s" opengl.bmp"         3 hndl3 Map-Image
    s" multi_on_alpha.bmp" 4 hndl4 Map-Image
    s" multi_on.bmp"       5 hndl5 Map-Image


    \ ---[ Process base.bmp ]---
    0 0 ['] texture-ndx Create-Nearest-Filtered-Texture \ load texture [0]
    1 0 ['] texture-ndx Create-Linear-Filtered-Texture \ load texture [1]
    2 0 ['] texture-ndx Create-MipMapped-Texture       \ load texture [2]

    \ ---[ Process bump.bmp ]---

    \ Scale RGB by 50%
    GL_RED_SCALE   0.5e gl-pixel-transfer-f
    GL_GREEN_SCALE 0.5e gl-pixel-transfer-f
    GL_BLUE_SCALE  0.5e gl-pixel-transfer-f

    \ Specify not to wrap the texture
    GL_TEXTURE_2D GL_TEXTURE_WRAP_S GL_CLAMP gl-tex-parameter-i
    GL_TEXTURE_2D GL_TEXTURE_WRAP_T GL_CLAMP gl-tex-parameter-i

    \ Generate 3 bump textures

    0 1 ['] bump-ndx Create-Nearest-Filtered-Texture \ load texture [0]
    1 1 ['] bump-ndx Create-Linear-Filtered-Texture \ load texture [1]
    2 1 ['] bump-ndx Create-MipMapped-Texture       \ load texture [2]

    \ Invert the Bumpmap
    \ bump.bmp is a 256x256x24b image.
    \ We are subtracting each color element from 255 to invert it.

    1 teximage-ndx @ >R
    R@ >color-array to *tdata
    3 R@ >biWidth  @ * R> >biHeight @ * 0
    do    255 *tdata i + C@ - *tdata i + C!
    loop

    \ ---[ Process inverted bump.bmp ]---

    NumInvBumps invbump gl-gen-textures   \ create 3 invbump textures

    \ Generate 3 invbump textures

    0 1 ['] invbump-ndx Create-Nearest-Filtered-Texture \ load texture [0]
    1 1 ['] invbump-ndx Create-Linear-Filtered-Texture  \ load texture [1]
    2 1 ['] invbump-ndx Create-MipMapped-Texture        \ load texture [2]

    \ ---[ Process opengl_alpha.bmp ]---

    \ Expand the 24bpp image to 32bpp, giving it an Alpha element
    \ Get the adress for the opengl_alpha.bmp surface
( 2)    2 teximage-ndx @ >R
    \ Set *tdata to point to the source image pixel data
    R@ >color-array
    \ Set the alpha element for the RGBA8-texture to the RED pixel
    \ from the opengl_alpha.bmp image
    R@ >biWidth @ R> >biHeight @ * dup
\ allocate *timage
    4 * malloc dup to *timage
    swap SetAlpha ( *Source *Dest #Pixels -- )

    \ Now copy the pixel data from the opengl.bmp image
    \ Get the handle for the opengl.bmp surface
( 3)    3 teximage-ndx @ >R
    \ Set *tdata to the pixel data of the opengl.bmp surface
    R@ >color-array
    \ To the same RGBA destination as opengl_alpha.bmp surface
    *timage
    \ Copy three pixel elements during each loop pass
    R@ >biWidth @ R> >biHeight @ *
     InclRgbImage  ( *Source *Dest #Pixels -- )

    \ ---[ Process opengl.bmp ]---
    1 glLogo gl-gen-textures              \ create the gllogo texture 3 > 1 \ glLogo??
    \ Create linear filtered RGBA8 texture
    GL_TEXTURE_2D glLogo @ gl-bind-texture
    \ Linear filtering
    LinearFiltering
    \ Generate the texture
( 3)    3 teximage-ndx @  *timage Generate-RGBA8-Texture

    \ ---[ Process multi_on_alpha.bmp ]---
    \ Expand the 24bpp image to 32bpp, giving it an Alpha element
    \ Get the handle for the multi_on_alpha.bmp surface
( 4)    4 teximage-ndx @ >R                                  \ texture 4
    \ Set *tdata to point to the source image pixel data
    R@ >color-array    \ Source
    *timage            \ Destination
    \ Set the alpha element for the RGBA8-texture to the RED pixel
    \ from the opengl_alpha.bmp image
    R@ >biWidth @ R> >biHeight @ * \  #Pixels
    SetAlpha  ( *Source *Dest #Pixels -- )

    \ ---[ Process multi_on.bmp ]---
    \ Get the handle for the multi_on.bmp surface
( 5)    5 teximage-ndx @ >R                                \   texture 5
    \ Set *tdata to the pixel data of the opengl.bmp surface
    R@ >color-array \ Source
    *timage            \ Destination
    \ Now copy the 24-bpp data to the 32-bpp data structure
    \ -- Copy three pixel elements during each loop pass
    R@ >biWidth @ R> >biHeight @ *
    InclRgbImage

    1 MultiLogo gl-gen-textures        \ create the MultiLogo
    \ Create linear filtered RGBA8 texture
    GL_TEXTURE_2D MultiLogo @ gl-bind-texture
    \ Linear filtering
    LinearFiltering
    \ Generate the texture
( 5)    5 teximage-ndx @  *timage Generate-RGBA8-Texture

    hndl0 _un-map-bitmap
    hndl1 _un-map-bitmap
    hndl2 _un-map-bitmap
    hndl3 _un-map-bitmap
    hndl4 _un-map-bitmap
    hndl5 _un-map-bitmap
    *timage free drop
;


\ ---[ doCube ]------------------------------------------------------
\ Initializes GL Quads from the data[] array
\ Remember: gforth has separate integer and floating point stacks...

: Set-Quad ( f: x f: y f: z hi lo -- )
  gl-normal-3f
  do
    i data-ndx >R
    R@ .tx F@ R@ .ty F@ gl-tex-coord-2f
    R@ .x F@ R@ .y F@ R> .z F@ gl-vertex-3f
  loop
;

\ function to draw a cube
: DoCube ( -- )
  GL_QUADS gl-begin
     0e  0e  1e    4  0 Set-Quad                         \ Front face
     0e  0e -1e    8  4 Set-Quad                          \ Back face
     0e  1e  0e   12  8 Set-Quad                           \ Top face
     0e -1e  0e   16 12 Set-Quad                        \ Bottom face
     1e  0e  0e   20 16 Set-Quad                         \ Right face
    -1e  0e  0e   24 20 Set-Quad                          \ Left face
  gl-end
;


\ ---[ HandleKeyPress ]----------------------------------------------
:long$ h22$
$| About lesson 22:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| b        toggles bumps
$| e        toggles embossing
$| f        cycles through filters
$| m        toggles multitextured support
$| PgUp     zooms into the screen
$| PgDn     zooms out of the screen
$| Up       increases x rotation speed
$| Dn       decreases x rotation speed
$| Right    increases y rotation speed
$| Left     decreases y rotation speed
$|
$| More about bump mapping at:
$| https://en.wikipedia.org/wiki/Bump_mapping
;long$

: HandleKeyPress ( &event -- )
  case
   \  ESCAPE of TRUE to opengl-exit-flag endof
    ascii W     of start/end-fullscreen endof
    ascii B     of bumps   if   0   else   1   then  to bumps   endof
    ascii E     of emboss  if   0   else   1   then  to emboss  endof
    ascii F     of filter 1+ 3 MOD to filter                    endof
    ascii M     of UseMultiTexture   if   0   else   1   then
                   MultiTextureSupported AND to UseMultiTexture endof
    VK_PGUP     of zdepth F@ 0.02e F- zdepth F!                 endof
    VK_PGDN     of zdepth F@ 0.02e F+ zdepth F!                 endof
    VK_UP       of xspeed F@ 0.01e F- xspeed F!                 endof
    VK_DOWN     of xspeed F@ 0.01e F+ xspeed F!                 endof
    VK_LEFT     of yspeed F@ 0.1e F- yspeed F!                  endof
    VK_RIGHT    of yspeed F@ 0.1e F+ yspeed F!                  endof
    h22$ ShowHelp
  endcase
;


\ ---[ InitLights ]--------------------------------------------------
\ Initialize the lights

: InitLights ( -- )
  GL_LIGHT1 GL_AMBIENT  LightAmbient[]  gl-light-fv
  GL_LIGHT1 GL_DIFFUSE  LightDiffuse[]  gl-light-fv
  GL_LIGHT1 GL_POSITION LightPosition[] gl-light-fv
  GL_LIGHT1 gl-enable
;

\ ---[ Set the viewpoint ]-------------------------------------------

: set-viewpoint ( -- )   \ the call to glViewport is done in Opengl.f
  GL_PROJECTION gl-matrix-mode
  \ Reset the matrix
  gl-load-identity
  \ Set our perspective - the F/ calcs the aspect ratio of w/h
  45e widthViewport  S>F heightViewport  S>F F/ 0.1e 100e glu-perspective
  \ Make sure we are changing the model view and not the projection
  GL_MODELVIEW gl-matrix-mode
;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: InitGL ( -- )
  \ Check on the ARB_multitexture extension availabilty
  InitMultiTexture to MultiTextureSupported
  \ Load in the texture
    LoadGLTextures
    GL_TEXTURE_2D gl-enable                  \ Enable texture mapping
    GL_SMOOTH gl-shade-model                  \ Enable smooth shading
    0e 0e 0e 0.5e gl-clear-color           \ Set the background black
    1e gl-clear-depth                            \ Depth buffer setup
    GL_DEPTH_TEST gl-enable                    \ Enable depth testing
    GL_LEQUAL gl-depth-func                \ type of depth test to do
    GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint    \ perspective
    InitLights                              \ Initialize the lighting
;

\ ---[ VMatMulti ]---------------------------------------------------
\ Calculates v=vM, M Is 4x4 In Column-Major
\ v Is 4dim. Row (i.e. "Transposed")
\ For clarification, the data pointed to by the *m parameter is
\ stored in the 32-bit sfloat format, while the data pointed to by
\ the *v parameter is in gforth-normal 64-bit floating point values.

: VMatMult { *m *v -- }
  *m  0 sfarray-ndx SF@ *v 0 farray-ndx F@ F*
  *m  1 sfarray-ndx SF@ *v 1 farray-ndx F@ F* F+
  *m  2 sfarray-ndx SF@ *v 2 farray-ndx F@ F* F+
  *m  3 sfarray-ndx SF@ *v 3 farray-ndx F@ F* F+    \ leave on fstack

  *m  4 sfarray-ndx SF@ *v 0 farray-ndx F@ F*
  *m  5 sfarray-ndx SF@ *v 1 farray-ndx F@ F* F+
  *m  6 sfarray-ndx SF@ *v 2 farray-ndx F@ F* F+
  *m  7 sfarray-ndx SF@ *v 3 farray-ndx F@ F* F+    \ leave on fstack

  *m  8 sfarray-ndx SF@ *v 0 farray-ndx F@ F*
  *m  9 sfarray-ndx SF@ *v 1 farray-ndx F@ F* F+
  *m 10 sfarray-ndx SF@ *v 2 farray-ndx F@ F* F+
  *m 11 sfarray-ndx SF@ *v 3 farray-ndx F@ F* F+    \ leave on fstack

  *v 2 farray-ndx F!
  *v 1 farray-ndx F!
  *v 0 farray-ndx F!
  *m 15 sfarray-ndx SF@ *v 3 farray-ndx F!    \ homogenous coordinate
;

\ ---[ SetupBumps ]--------------------------------------------------
\ Sets Up The Texture-Offsets. All parameters are pointer to floating
\ point arrays.

\ n : Normal On Surface. Must Be Of Length 1
\ c : Current Vertex On Surface
\ l : Lightposition
\ s : Direction Of s-Texture-Coordinate In Object Space
\ t : Direction Of t-Texture-Coordinate In Object Space
\ s & t must be normalized!

create v[] 0e F, 0e F, 0e F,  \ vertex from current position to light
fvariable lenq                                    \ used to normalize

: SetupBumps { *n *c *l *s *t -- }
  \ Calculate v from current vertex <c> to light pos and normalize
  3 0 do
    *l i farray-ndx F@ *c i farray-ndx F@ F- v[] i farray-ndx F!
  loop

  v[] 0 farray-ndx F@ FDUP F*
  v[] 1 farray-ndx F@ FDUP F* F+
  v[] 2 farray-ndx F@ FDUP F* F+ FSQRT lenq F!

  3 0 do
    v[] i farray-ndx F@ lenq F@ F/ v[] i farray-ndx F!
  loop

  \ Project v such that we get two values on each texture/coord axis

  *s 0 farray-ndx F@ v[] 0 farray-ndx F@ F*
  *s 1 farray-ndx F@ v[] 1 farray-ndx F@ F* F+
  *s 2 farray-ndx F@ v[] 2 farray-ndx F@ F* F+
  Max-Emboss F*
  *c 0 farray-ndx F!

  *t 0 farray-ndx F@ v[] 0 farray-ndx F@ F*
  *t 1 farray-ndx F@ v[] 1 farray-ndx F@ F* F+
  *t 2 farray-ndx F@ v[] 2 farray-ndx F@ F* F+
  Max-Emboss F*
  *c 1 farray-ndx F!
;

\ ---[ DoLogo ]------------------------------------------------------
\ Billboards two logos

: DoLogo ( -- )
  GL_ALWAYS gl-depth-func

  GL_BLEND gl-enable
  GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA  gl-blend-func
  GL_LIGHTING gl-disable
  gl-load-identity

  GL_TEXTURE_2D glLogo @ gl-bind-texture
((  GL_QUADS gl-begin  \ Jos:  Shows the logo upside down
    0e 1e gl-tex-coord-2f 0.23e -0.4e  -1e gl-vertex-3f
    1e 1e gl-tex-coord-2f 0.53e -0.4e  -1e gl-vertex-3f
    1e 0e gl-tex-coord-2f 0.53e -0.25e -1e gl-vertex-3f
    0e 0e gl-tex-coord-2f 0.23e -0.25e -1e gl-vertex-3f
  gl-end ))


  GL_QUADS gl-begin  \  Now it is right
    0e 0e gl-tex-coord-2f 0.23e -0.4e  -1e gl-vertex-3f
    1e 0e gl-tex-coord-2f 0.53e -0.4e  -1e gl-vertex-3f
    1e 1e gl-tex-coord-2f 0.53e -0.25e -1e gl-vertex-3f
    0e 1e gl-tex-coord-2f 0.23e -0.25e -1e gl-vertex-3f
  gl-end



((  UseMultiTexture if \ Jos: Shows the MultiLogo too high
    GL_TEXTURE_2D MultiLogo @ gl-bind-texture
    GL_QUADS gl-begin
      0e 0e gl-tex-coord-2f -0.53e -0.25e -1e gl-vertex-3f
      1e 0e gl-tex-coord-2f -0.33e -0.25e -1e gl-vertex-3f
      1e 1e gl-tex-coord-2f -0.33e -0.15e -1e gl-vertex-3f
      0e 1e gl-tex-coord-2f -0.53e -0.15e -1e gl-vertex-3f
    gl-end ))

  UseMultiTexture if    \ Now it is right
    GL_TEXTURE_2D MultiLogo @ gl-bind-texture
    GL_QUADS gl-begin
      0e 0e gl-tex-coord-2f -0.53e -0.4e -1e gl-vertex-3f
      1e 0e gl-tex-coord-2f -0.33e -0.4e -1e gl-vertex-3f
      1e 1e gl-tex-coord-2f -0.33e -0.25e -1e gl-vertex-3f
      0e 1e gl-tex-coord-2f -0.53e -0.25e -1e gl-vertex-3f
    gl-end
  then
;

\ ---[ DoMesh1TexelUnits ]-------------------------------------------
\ function to do bump-mapping without multitexturing

\ c[] holds the current vertex
\ n[] normalized normal of current surface
\ s[] s-texture coordinate direction, normalized
\ t[] t-texture coordinate direction, normalized
\ l[] hold the lightpos to be transformed into object space
\ Minv[] hold the inverted modelview matrix (16 fp values)

create c[] 0e F, 0e F, 0e F, 1e F,
create n[] 0e F, 0E f, 0e F, 1e F,
create s[] 0e F, 0E f, 0e F, 1e F,
create t[] 0e F, 0E f, 0e F, 1e F,
create l[] 0e F, 0E f, 0e F, 0e F,
create Minv[] 16 sfloats allot          \ 16 element array of sfloats

: SetFaceMesh1 ( r1 r2 r3 r4 f5 r6 r7 r8 r9 hi lo -- )
  t[] 2 farray-ndx F! t[] 1 farray-ndx F! t[] 0 farray-ndx F!
  s[] 2 farray-ndx F! s[] 1 farray-ndx F! s[] 0 farray-ndx F!
  n[] 2 farray-ndx F! n[] 1 farray-ndx F! n[] 0 farray-ndx F!
  do
    i data-ndx .x F@ c[] 0 farray-ndx F!
    i data-ndx .y F@ c[] 1 farray-ndx F!
    i data-ndx .z F@ c[] 2 farray-ndx F!
    n[] c[] l[] s[] t[] SetupBumps
    i data-ndx .tx F@ c[] 0 farray-ndx F@ F+
    i data-ndx .ty F@ c[] 1 farray-ndx F@ F+ gl-tex-coord-2f
    i data-ndx >R R@ .x F@ R@ .y F@ R> .z F@ gl-vertex-3f
  loop
;

\ ---[ DoMesh2TexelUnits ]-------------------------------------------

: DoMesh1TexelUnits ( -- boolean )
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear
  \ Build inverse modelview matrix first.
  \ This substitutes one push/pop with one gl-load-identity.
  \ Simply build it by doing all transformations negated, and in
  \ reverse order.
  gl-load-identity
  yrot F@ FNEGATE 0e 1e 0e gl-rotate-f
  xrot F@ FNEGATE 1e 0e 0e gl-rotate-f
  0e 0e zdepth F@ FNEGATE gl-translate-f
  GL_MODELVIEW_MATRIX Minv[] gl-get-float-v
  gl-load-identity
  0e 0e zdepth F@ gl-translate-f
  xrot F@ 1e 0e 0e gl-rotate-f
  yrot F@ 0e 1e 0e gl-rotate-f

  \ Transform the lightpos into object coordinates

  LightPosition[] 0 farray-ndx F@ l[] 0 farray-ndx F!
  LightPosition[] 1 farray-ndx F@ l[] 1 farray-ndx F!
  LightPosition[] 2 farray-ndx F@ l[] 2 farray-ndx F!
  1e l[] 3 farray-ndx F!                      \ homogenous coordinate
  Minv[] l[] VMatMult

  \ First pass rendering a cube obly out of bump map
  GL_TEXTURE_2D filter bump-ndx @ gl-bind-texture
  GL_BLEND gl-disable
  GL_LIGHTING gl-disable
  DoCube

  \ Second pass rendering a cube with correct emboss bump mapping
  \ but with no colors

  GL_TEXTURE_2D filter invbump-ndx @ gl-bind-texture
  GL_ONE GL_ONE gl-blend-func
  GL_LEQUAL gl-depth-func
  GL_BLEND gl-enable

  GL_QUADS gl-begin
     0e  0e  1e  1e 0e  0e 0e 1e  0e  4  0 SetFaceMesh1  \ Front Face
     0e  0e -1e -1e 0e  0e 0e 1e  0e  8  4 SetFaceMesh1   \ Back Face
     0e  1e  0e  1e 0e  0e 0e 0e -1e 12  8 SetFaceMesh1    \ Top Face
     0e -1e  0e -1e 0e  0e 0e 0e -1e 16 12 SetFaceMesh1 \ Bottom Face
     1e  0e  0e  0e 0e -1e 0e 1e  0e 20 16 SetFaceMesh1  \ Right Face
    -1e  0e  0e  0e 0e  1e 0e 1e  0e 24 20 SetFaceMesh1   \ Left Face
  gl-end

  \ Third pass finishes rendering cube complete with lighting

  emboss FALSE = if
    GL_TEXTURE_ENV GL_TEXTURE_ENV_MODE GL_MODULATE S>F gl-tex-env-f
    GL_TEXTURE_2D filter texture-ndx @ gl-bind-texture
    GL_DST_COLOR GL_SRC_COLOR gl-blend-func
    GL_LIGHTING gl-enable
    DoCube
  then

  xrot F@ xspeed F@ F+
  fdup 360e F> if 360e F- then
  fdup   0e F< if 360e F+ then
  xrot F!
  yrot F@ yspeed F@ F+
  fdup 360e F> if 360e F- then
  fdup   0e F< if 360e F+ then
  yrot F!

  \ Last pass - do the logos
  DoLogo

  TRUE
;

\ ---[ DoMesh2TexelUnits ]-------------------------------------------
\ Same as doMesh1TexelUnits except in 2 passes using 2 texel units

: SetFaceMesh2 ( r1 r2 r3 r4 f5 r6 r7 r8 r9 hi lo -- )
  t[] 2 farray-ndx F! t[] 1 farray-ndx F! t[] 0 farray-ndx F!
  s[] 2 farray-ndx F! s[] 1 farray-ndx F! s[] 0 farray-ndx F!
  n[] 2 farray-ndx F! n[] 1 farray-ndx F! n[] 0 farray-ndx F!
  do
    i data-ndx .x F@ c[] 0 farray-ndx F!
    i data-ndx .y F@ c[] 1 farray-ndx F!
    i data-ndx .z F@ c[] 2 farray-ndx F!
    n[] c[] l[] s[] t[] SetupBumps
    GL_TEXTURE0_ARB i data-ndx dup .tx F@ .ty F@
    gl-multi-tex-coord-2f-ARB
    GL_TEXTURE1_ARB i data-ndx dup .tx F@ c[] 0 farray-ndx F@ F+
    .ty F@ c[] 1 farray-ndx F@ F+ gl-multi-tex-coord-2f-ARB
    i data-ndx >R R@ .x F@ R@ .y F@ R> .z F@ gl-vertex-3f
  loop
;

: DoMesh2TexelUnits ( -- boolean )
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear
  \ Build inverse modelview matrix first.
  \ This substitutes one push/pop with one gl-load-identity.
  \ Simply build it by doing all transformations negated, and in
  \ reverse order.
  gl-load-identity
  yrot F@ FNEGATE 0e 1e 0e gl-rotate-f
  xrot F@ FNEGATE 1e 0e 0e gl-rotate-f
  0e 0e zdepth F@ FNEGATE gl-translate-f
  GL_MODELVIEW_MATRIX Minv[] gl-get-float-v
  gl-load-identity
  0e 0e zdepth F@ gl-translate-f
  xrot F@ 1e 0e 0e gl-rotate-f
  yrot F@ 0e 1e 0e gl-rotate-f

  \ Transform the lightpos into object coordinates

  LightPosition[] 0 farray-ndx F@ l[] 0 farray-ndx F!
  LightPosition[] 1 farray-ndx F@ l[] 1 farray-ndx F!
  LightPosition[] 2 farray-ndx F@ l[] 2 farray-ndx F!
  1e l[] 3 farray-ndx F!                      \ homogenous coordinate
  Minv[] l[] VMatMult

  \ First pass:
  \   No Blending
  \   No Lighting
  \
  \ Set up the texture-combiner 0 to
  \   Use bump-texture
  \   Use not-offset texture-coordinates
  \   Texture-operation GL_REPLACE, resulting in texture being drawn
  \
  \ Set up the texture-combiner 1 to
  \
  \   Offset texture-coordinates
  \   Texture-operation GL_ADD which is the multitexture equivalent
  \   to ONE, ONE- blending.
  \
  \ This will render a cube consisting out of grey-scale erode map.

  \ Texture-Unit #0
  GL_TEXTURE0_ARB gl-active-texture-ARB
  GL_TEXTURE_2D gl-enable
  GL_TEXTURE_2D filter bump-ndx @ gl-bind-texture
  GL_TEXTURE_ENV GL_TEXTURE_ENV_MODE GL_COMBINE_EXT S>F gl-tex-env-f
  GL_TEXTURE_ENV GL_COMBINE_RGB_EXT GL_REPLACE S>F gl-tex-env-f

  \ Texture-Unit #1
  GL_TEXTURE1_ARB gl-active-texture-ARB
  GL_TEXTURE_2D gl-enable
  GL_TEXTURE_2D filter invbump-ndx @ gl-bind-texture
  GL_TEXTURE_ENV GL_TEXTURE_ENV_MODE GL_COMBINE_EXT S>F gl-tex-env-f
  GL_TEXTURE_ENV GL_COMBINE_RGB_EXT GL_ADD S>F gl-tex-env-f

  \ General switches

  GL_BLEND gl-disable
  GL_LIGHTING gl-disable

  GL_QUADS gl-begin
     0e  0e  1e  1e 0e  0e 0e 1e  0e  4  0 SetFaceMesh2  \ Front Face
     0e  0e -1e -1e 0e  0e 0e 1e  0e  8  4 SetFaceMesh2   \ Back Face
     0e  1e  0e  1e 0e  0e 0e 0e -1e 12  8 SetFaceMesh2    \ Top Face
     0e -1e  0e -1e 0e  0e 0e 0e -1e 16 12 SetFaceMesh2 \ Bottom Face
     1e  0e  0e  0e 0e -1e 0e 1e  0e 20 16 SetFaceMesh2  \ Right Face
    -1e  0e  0e  0e 0e  1e 0e 1e  0e 24 20 SetFaceMesh2   \ Left Face
  gl-end

  \ Second Pass
  \
  \ Use the base-texture
  \ Enable Lighting
  \ No offset texturre-coordinates => reset GL_TEXTURE-matrix
  \ Reset texture environment to GL_MODULATE in order to do
  \ OpenGLLighting (doesn?t work otherwise!)
  \
  \ This will render our complete bump-mapped cube.

  GL_TEXTURE1_ARB gl-active-texture-ARB
  GL_TEXTURE_2D gl-disable
  GL_TEXTURE0_ARB gl-active-texture-ARB
  emboss FALSE = if
    GL_TEXTURE_ENV GL_TEXTURE_ENV_MODE GL_MODULATE S>F gl-tex-env-f
    GL_TEXTURE_2D filter texture-ndx @ gl-bind-texture
    GL_DST_COLOR GL_SRC_COLOR gl-blend-func
    GL_BLEND gl-enable
    GL_LIGHTING gl-enable
    DoCube
  then

  \ Last Pass
  \
  \  Update Geometry (esp. rotations)
  \  Do The Logos

  xrot F@ xspeed F@ F+
  fdup 360e F> if 360e F- then
  fdup   0e F< if 360e F+ then
  xrot F!
  yrot F@ yspeed F@ F+
  fdup 360e F> if 360e F- then
  fdup   0e F< if 360e F+ then
  yrot F!

  \ LAST PASS: Do The Logos!
  DoLogo

  TRUE
;

\ ---[ DoMeshNoBumps ]-----------------------------------------------
\ function to draw cube without bump mapping

: DoMeshNoBumps ( -- boolean )
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear
  gl-load-identity
  0e 0e zdepth F@ gl-translate-f

  xrot F@ 1e 0e 0e gl-rotate-f
  yrot F@ 0e 1e 0e gl-rotate-f

  UseMultiTexture if
    GL_TEXTURE1_ARB gl-active-texture-ARB
    GL_TEXTURE_2D gl-disable
    GL_TEXTURE0_ARB gl-active-texture-ARB
  then

  GL_BLEND gl-disable
  GL_TEXTURE_2D filter texture-ndx @ gl-bind-texture
  GL_DST_COLOR GL_SRC_COLOR gl-blend-func
  GL_LIGHTING gl-enable
  DoCube

  xrot F@ xspeed F@ F+
  fdup 360e F> if 360e F- then
  fdup   0e F< if 360e F+ then
  xrot F!
  yrot F@ yspeed F@ F+
  fdup 360e F> if 360e F- then
  fdup   0e F< if 360e F+ then
  yrot F!

  \ LAST PASS: Do The Logos!
  DoLogo

  TRUE
;

\ ---[ ShutDown ]----------------------------------------------------
\ Close down the system gracefully ;-)


: _ExitLesson ( -- )
  true to resizing?
  NumTextures texture[] gl-delete-textures          \ clean up textures
  NumBumps    bump    gl-delete-textures
  NumInvBumps invbump gl-delete-textures
;

: ResetLesson  ( -- )              \ For a clean start in this lesson
    ResetOpenGL                      \ Cleanup from a previous lesson
    InitGL                   \ Enable some features and load textures
    set-viewpoint                                 \ Set the viewpoint
    false to resizing?
 ;


\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- boolean )
  bumps if
    UseMultiTexture MaxTexelUnits @ 1 > AND if
      DoMesh2TexelUnits FALSE = if
        FALSE
        EXIT
      then
    else
      DoMesh1TexelUnits FALSE = if
        FALSE
        EXIT
      then
    then
  else
    DoMeshNoBumps FALSE = if
      FALSE
      EXIT
    then
  then

  sdl-gl-swap-buffers                         \ Draw it to the screen

  xrot F@ 0.3e F+ xrot F!                      \ increment x rotation
  yrot F@ 0.2e F+ yrot F!                      \ increment y rotation
  zrot F@ 0.4e F+ zrot F!                      \ increment z rotation


;

also Forth definitions

: DrawGLLesson22  ( -- )                          \ Handles ONE frame
   LessonChanged?
      if  false to LessonChanged?
          ['] HandleKeyPress is KeyboardAction \ Use the keystrokes for this lesson only
          ['] _ExitLesson is ExitLesson    \ Specify ExitLesson to free allocated memory
          Reset-request-to-stop
      then
   resizing?
     if  ResetLesson
     then
   DrawGLScene           \ Redraw only the changes in the lesson
 ;

 ' DrawGLLesson22 to LastLesson

[Forth]

