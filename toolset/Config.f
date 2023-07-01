anew Config.f           \ June 15th, 2012 for saving data, variables and strings in a file.


   (( Disable or delete this line for generating a glossary
cr cr .( Generating Glossary )
needs help\HelpDexh.f  DEX Config.f
cr cr .( Glossary for Config.f generated )  cr 2 pause-seconds bye  ))


\ *D doc
\ *! Config
\ *T Config -- For saving data, variables and strings in a file.

\ *S Abstract:
\ ** The intention is to save data such as variables and strings to a file
\ ** without much overhead for the programmer. \n
\ ** By default the file name is config.dat and will be placed in the active directory \n
\ ** Since it is done through a memory mapped file, the addressing can be done in the same way as
\ ** if the data is in memory. \n So you can use @ ! place and move etc.
\ ** The minimal steps to handle the system are: \n
\ ** 1) Define ConfigVariables strings and data area's for access in the mapped file before the file is enabled. \n
\ ** 2) Enable the file. Then modify various items. \n
\ ** 3) Disable the File when you are ready. This will flush the data to the file and close the file.



\ *S Glossary

create ConfigFile$   maxstring allot   s" Config.dat" ConfigFile$ place
\ *G Contains the name of the config file.

0 value /ConfigDef
\ *G The size of the config file. New items will increase the size.


map-handle config-mhndl

: file-exist?         ( adr len -- true-if-file-exist )  file-status nip 0= ;
: file-size>s         ( fileid -- len )       file-size drop d>s  ;
: map-hndl>vadr       ( m_hndl - vadr )       >hfileAddress @ ;
: map-config-file     ( - )    ConfigFile$ count config-mhndl  open-map-file throw ;
: vadr-config         ( - vadr-config ) config-mhndl map-hndl>vadr ;

: extend-file ( size hndl - )
    dup>r
    file-size drop d>s +
    s>d r@ resize-file abort" Can't extend file."
    r> close-file  drop
 ;

: CreateConfigFile  ( - )
   /ConfigDef
   ConfigFile$ count r/w create-file abort" Can't create configuration file"
   extend-file
;

: check-config   ( -- ) \ creates a config-file with the right size.
   ConfigFile$ count file-exist?
     if    ConfigFile$ count r/w open-file  abort" Can't open the cofiguration file"
           /ConfigDef over file-size>s   2dup >   \ Extend it when it is needed.
                if    - swap extend-file          \ Keep the extisting data.
                else  2drop close-file throw      \ Do nothing when it is right.
                then
     else  CreateConfigFile
     then
  ;

: AllotConfigDef        ( size - )  /ConfigDef dup , + to /ConfigDef ;
: OffsetInConfigDef     ( adr - )   @ vadr-config + ;

\ A ConfigVariable directly acceses the config file.
\ They only work when the config file is mapped.

: ConfigVariable \ Compiletime: ( -< name >- )  Runtime: ( - AdrInMappedConfigFile )
\ *G Allocates one variable in a configuration file.
  create cell AllotConfigDef   \ Compiletime: ( -< name >- )
  does>  OffsetInConfigDef     \ Runtime: ( - AdrInMappedConfigFile )
 ;

: Config$:   \ Compiletime: ( -< name >- )  Runtime: ( - AdrInMappedConfigFile )
\ *G Allocates one string in a configuration file.
  create maxstring AllotConfigDef
  does>  OffsetInConfigDef
 ;

: DataArea:  \ Compiletime: ( size -< name >- )  Runtime: ( - AdrInMappedConfigFile )
\ *G Allocates a data area in a configuration file.
  create AllotConfigDef
  does>  OffsetInConfigDef
 ;

: EnableConfigFile ( - )
\ *G Enables access to the configuration file.
  check-config  map-config-file ;

: DisableConfigFile   ( - )
\ *G Flush the data to the file and close the file.
  config-mhndl dup flush-view-file drop close-map-file drop
 ;


\ \s Disable this line to see it's use:

\ 1) Define ConfigVariables to access the mapped file before the file is enabled.

ConfigVariable LBs/Inches-
ConfigVariable SingCutoff-
Config$: Somestring$
ConfigVariable ShowObese-
8 DataArea: Test

EnableConfigFile \ 2) Enable the file. Then modify various items.

1 LBs/Inches- !
2 SingCutoff- !

s" A test for a string" Somestring$  place \ Saving a string

3 ShowObese- !
-1 Test !

DisableConfigFile   \ 3) Disable the File when you are ready.

\ ------------------------------------------------

EnableConfigFile   \ To use the config file AGAIN.
cr
cr .( The saved values in the file config.dat are: ) LBs/Inches- ?  SingCutoff- ?  ShowObese- ?
cr .( The content of Somestring$ is: ) Somestring$ count type cr
cr .( Dumping the file Config.dat:) cr
vadr-config /ConfigDef dump

DisableConfigFile   \ When you are ready.
\ *Z
\s
