\ JukeboxIn4Th.f   Version 3.10   March 11th, 2014  By Jos v.d.Ven


\ JukeboxIn4Th.f needs Win32Forth version 6.14 and XP or better
\ It runs best in Windows 7 with an iCore7

\ Added/changed in this version:
\ Adapted for the new MultiTaskingClass.f
\ Made it possible to random complete albums

(( From: http://en.wikipedia.org/wiki/ID3
Windows Explorer and Windows Media Player cannot handle id3v2 version 2.4 tags
in any version, up to and including Windows 7/Windows Media Player 12.[3]
Windows can understand id3v2 up to and including version 2.3.

This may result in error 80040218, no combination of filters could
be found to render the file. The JukeboxIn4Th will skip these files.

Possible solution: Remove id3v2 Idtags. ID3Remover can do this for you.
See: http://www.marre.org/id3remover   ))


\ Note: Extra directory levels between Artist and Album returns a wrong artist name.
\ The right format is I:\Mymusic\Style\Artist\Album\Song.wma


[DEFINED] JukeboxIn4Th  [IF]  100 ms bye [then] \ Preventing duplicate loading.

Anew JukeboxIn4Th
fpath+ apps\Internet\WebServer

Needs bitmap.f

\ For _load-bitmap
create &InfoRect  4 cells allot    ( - &InfoRect )
&InfoRect 4 cells erase
&InfoRect constant window_x          \ Position of the bitmap in the cover window
&InfoRect 1 cells+ constant window_y
&InfoRect 2 cells+ constant width    \ For the bitmap in the cover window
&InfoRect 3 cells+ constant height

0 value ogl-hwnd
0 value _limit-bpps

Needs bmpio.f
Needs AcceleratorTables.f
Needs Events.f
Needs MultiTaskingClass.f

wTasks JukeBoxTasks
sTask  RightPane
sTask  WebserverTasks

Needs mShellRelClass.f
Needs ListEditor.f
Needs Declared.f
Needs excontrols.f
Needs TrayWindow.f
Needs Resources.f
Needs TrackBar.f
Needs Volinfo.f
Needs security.f
Needs Number.f
needs fcom.f
Needs InterfacesJB4Th.f
Needs DirectShowAudio.f
Needs SoundVolume.f
Needs SubDirs2.f

also hidden
\ FILE_READ_ATTRIBUTES to sub_dir_access
Needs full-path.f

previous

Needs sock.f
Needs IpHost.f
Needs Catalog.f
Needs Narrator.f
Needs Struct.f
Needs Joystick.f
Needs SetExecutionState.f
Needs Multiopen.f
Needs AskIntWindow.f
Needs Mediatree.f
Needs SearchPath.f
Needs ProgresWindow.f
Needs NarratorWindow.f
Needs CommandID.f
Needs InfoForm.f
Needs FormWebserverAddress.f
Needs FormWiFi.f
Needs FilterWindow.f
Needs Jukebox4Win.f
Needs Middle.f
Needs Right.f
Needs MenuBar.f
Needs Commands.f
Needs WebServerCommands.f

: StartJukeBoxIn4Th ( - )
  (StartJukeBoxIn4Th
  InitGci
 ;

\   StartJukeBoxIn4Th abort                 \s     Stop here for developments
\ ' StartJukeBoxIn4Th turnkey JukeBoxIn4Th  \ For a turnkey. ( Smaller, but might trigger a false positive )

  NoConsoleBoot ' StartJukeBoxIn4Th SAVE JukeBoxIn4Th  \ To prevent a false positive

winver winnt4 >= [IF]  \ For V6.0.0.0 Common-Controls
  current-dir$ count pad place
  s" \" pad +place
  s" JukeBoxIn4Th.exe" pad +place
  pad count "path-file drop AddToFile
               CREATEPROCESS_MANIFEST_RESOURCE_ID RT_MANIFEST s" JukeBoxIn4Th.exe.manifest" "path-file drop  AddResource
                101 s" JukeBoxIn4Th.ico" "path-file drop AddIcon
                false EndUpdate
        [else]
               s" JukeBoxIn4Th.ico" s" JukeBoxIn4Th.exe" Prepend<home>\ AddAppIcon
        [then]

 cr .( Starting JukeBoxIn4Th.exe)
 dos" JukeBoxIn4Th.exe" dos$ $exec drop cr

5 pause-seconds
bye
\s
