\ Vlc.f
anew VlcTest.f \ 26-6-2024 Last tested with VLC version:3.0.21

0 value vlc-instance    0 value mp    0 value new-ms

create vlcpath.dat$ 260 allot         create start-dir    260 allot

FileOpenDialog DllDialog "Locate and open libvlc.dll"  "Dll Files (libvlc.dll)|libvlc.dll|All Files (*.*)|*.*|"


: set-vlc-dirs
   current-dir$ count start-dir place
   start-dir count vlcpath.dat$ place s" \vlcpath.dat" vlcpath.dat$ +place

   vlcpath.dat$ count file-exist? 0=
     if vlcpath.dat$ count  r/w create-file throw
        s" C:\Program Files (x86)\VideoLAN\VLC" 2 pick write-file throw
        dup flush-file throw close-file drop
     then
 ;

set-vlc-dirs

: locate-vlc-dll ( - )
   GetHandle: cmd Start: DllDialog count
     2dup s" \libvlc.dll" search
          if    nip -  \ vadr-config vlc-dir place
                vlcpath.dat$ count r/w create-file throw dup>r
                write-file throw r@ flush-file throw r> close-file throw
          else  3drop abort" Needs libvlc.dll. File not located. "
          then
;

: read-vlc-dir ( - vlc-dir$ count )
   vlcpath.dat$ count r/w open-file throw
   pad 255 2 pick read-file throw
   swap close-file throw pad swap
 ;


: vlc-dll-missing? ( - flag )
   read-vlc-dir tmp$ place s" \libvlc.dll" tmp$ +place
   tmp$ count file-exist? 0=
 ;


vlc-dll-missing? [IF]

cr cr cr
cr .( Needs VLC media player from: https://www.videolan.org/ )
cr read-vlc-dir type .(  Not found )
cr .( Where is libvlc.dll of VLC ?   Normal location: ~\VideoLAN\VLC ) cr
locate-vlc-dll

[THEN]


read-vlc-dir "chdir

winlibrary libvlc.dll


: vlc-init
   vlc-dll-missing?
     if   locate-vlc-dll
     then
  read-vlc-dir "chdir
  0 0 call libvlc_new dup 0=
  abort" libvlc_new failed." to vlc-instance
  start-dir count "chdir 2drop
 ;

start-dir count "chdir


: vlc-length@ ( mp - ms-length)   call libvlc_media_player_get_length nip ;
: vlc-pause   ( mp - ) dup     if call libvlc_media_player_pause 2drop  else  drop  then ;
: vlc-play    ( mp - ) dup     if call libvlc_media_player_play  2drop  else  drop  then ;
: vlc-release ( mp - ) dup 0<> if call libvlc_media_player_release 2drop 0 then to mp ;
: vlc-stop    ( mp - )            call libvlc_media_player_stop 2drop ;
: vlc-volume@ ( mp - volume )     call libvlc_audio_get_volume nip ;
: vlc-volume! ( volume mp - )     call libvlc_audio_set_volume 3drop ;
: vlc-time@   ( mp - time )       call libvlc_media_player_get_time nip ;
: vlc-time!   ( time mp -- ) 0 -rot dup vlc-pause call libvlc_media_player_set_time 4drop ;
: vlc-free    ( vlc-inst - res )  call libvlc_release nip ;
: NoEscape?   ( - flag ) true key?   if    key 27 =   if  drop false   then   then ;

: vlc-state   ( mp - state )
   dup 0=     \ 0-1 opening 2 buffering 3 plays 4 pause 5 stop 6 ready 7 error 8 not ready
       if    drop 8
       else  call libvlc_media_player_get_state nip
       then ;

: wait-for-vlc ( - )      begin    25 ms mp vlc-state 2 >   until ;

: vlc-start-play ( counted-music-file$ - )
   dup +null 1+ vlc-instance  call libvlc_media_new_path nip nip
   call libvlc_media_player_new_from_media
   swap call libvlc_media_release 2drop
   dup to mp vlc-play  ;

: OnPlaying  ( mp  -  )
   dup>r vlc-time@ dup new-ms >
     if    10 20 gotoxy 1000 / 1000 * 1000 + to new-ms
           r> vlc-time@  dup 1000 <
            if drop 0
            then  s>d ud.
     else  r> 2drop 300 ms
     then  ;

: .playing  ( - state )  begin   mp vlc-state dup 6 < NoEscape? and   while  drop mp OnPlaying   repeat ;

: play-song ( music-file - mp state )
   0 to new-ms  cls 1 1 gotoxy  vlc-start-play wait-for-vlc
   mp vlc-length@ 10 19 gotoxy  ." Takes: " s>d ud. ."  Ms " .playing ;

create music-file  260 allot  s" Rosalita.mp3" music-file place
s" F:\Music\_0\000 Verzamelaars\global underground\T Sasha - Ibiza Global Underground (CD2).mp3"
music-file place

\ vlc-init music-file play-song  cr .s

: mp-volume@ ( - v v )  vadr-config VlcVolume @   dup ;
: mp-volume! ( v v - )  vadr-config VlcVolume ! mp dup if vlc-volume! then ;

: PlayReady? ( - flag )
    mp 0>
      if    mp vlc-state 5 >
      else  true
      then ;

: end-play ( - ) mp dup if dup vlc-stop vlc-release then ;

: GetDurationPlay         ( - seconds ) mp dup if vlc-length@ 1000 / then ;
: GetCurrentPositionPlay  ( - seconds ) mp dup if vlc-time@ 1000 / then ;

: Seconds>SecondsMinutes ( Seconds - SecondsLeft Minutes )  60 /mod ;

defer TimeStats
: PlayStat ( - SecondsDP MinutesdP SecondsCP MinutesCP  )
    GetDurationPlay Seconds>SecondsMinutes   GetCurrentPositionPlay Seconds>SecondsMinutes
 ;
' PlayStat is TimeStats

: CurrentPositionPlay ( - seconds ) GetCurrentPositionPlay ;

: DurationPlay ( - seconds ) GetDurationPlay ;

: nn$      ( n -- addr len )  0 <# # #s #> ;  \ Will be fine for most music

create PfileName$ maxstring    1 cells+ allot
create PlayStat$ 20 allot

: FormatMMSS-PlayStat$  ( m s - )
    nn$ PlayStat$ +place s" :" PlayStat$ +place nn$ PlayStat$ +place
 ;

: MakePlayStat$ ( - addr$ count)
   mp dup
     if  vlc-state 5 <
          if    TimeStats 0 PlayStat$ ! FormatMMSS-PlayStat$
                s" /" PlayStat$ +place FormatMMSS-PlayStat$
          then
     else  drop   s" --/-- " PlayStat$ place
     then
   PlayStat$ count
 ;

: PausePlay  ( - )
   mp vlc-state 4 <
     if mp vlc-pause then ;

: SetPositionInPlay  ( seconds - )  1000 * mp vlc-time! mp vlc-play  ;

\s
