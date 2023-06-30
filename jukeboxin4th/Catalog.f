anew catalog.f  \ February 17th, 2010

needs ExtStruct.f
needs apps\player4\Pl_Toolset.f
needs w_search.f
needs mShellRelClass.f
needs SubDirs2.f


internal
external

\ Define a database, index, RequestIndex
create DatabaseFile$     ," catalog.dat"
create IndexFile$        ," catalog.idx"
create RndIndexFile$     ," rnd.idx"
create RequestIndexFile$ ," request.idx"

string: database$
string: index$
string: RequestIndex$
string: RndIndex$

0 value #Excluded
0 value #playing

true value       _DriveType

 iTasks Catalog_iTask    \ For parallel searches


\ Define the configuration of the database
\ A number of options are not used in this version

:struct ConfigDef \ ConfigDef in PathMediaFiles.dat
                MAX-PATH    Field:      PathMediaFiles
                DWORD                   #free-list
                DWORD                   prev-free-record
                DWORD                   first-free-record
                DWORD                   #MaxRandom
                DWORD                   PositionSlider
                DWORD                   #MaxRndAlbum
                DWORD                   #MaxRndAlbumsReq
                DWORD                   Reserved1
                DWORD                   Reserved2
                DWORD                   Reserved3
                DWORD                   Reserved4
                DWORD                   Reserved5
                DWORD                   Reserved6
                2 CELLS       Field:    SourcePathCatalog
                MAX-PATH 1+   Field:    SearchPathCatalog
                MAX-PATH 1+   Field:    TextBox1$
                MAXCOUNTED    Field:    AddressWebServer$
                MAXCOUNTED    Field:    WiFiName$
                MAXCOUNTED    Field:    WiFiPassword$
                BYTE                    EnableShutdown-
                BYTE                    TellTime-
                BYTE                    pitch
                BYTE                    ttsVolume
                BYTE                    s_Drivetype-
                BYTE                    s_Label-
                BYTE                    s_filesize-
                BYTE                    s_#Random-
                BYTE                    s_FromCollection-
                BYTE                    l_Narrator-
                BYTE                    VoiceRate
                BYTE                    s_Filename-
                BYTE                    s_Artist_Title-
                BYTE                    l_Index-
                BYTE                    l_Drivetype-
                BYTE                    l_Label-
                BYTE                    l_File_size-
                BYTE                    l_#Random-
                BYTE                    l_#Played-
                BYTE                    l_Filename-
                BYTE                    l_Record-
                BYTE                    ExitFailed-
                BYTE                    AutoStart-
                BYTE                    AutoMinimized-
                BYTE                    RequestLevel
                BYTE                    IgnoreRequests
                BYTE                    KeepRequests
                BYTE                    Endless-
                BYTE                    Webserver-
                BYTE                    AccessLevel
                BYTE                    Album-
                BYTE                    JoyStickDisabled-
                BYTE                    NoTooltips-
;struct

sizeof ConfigDef  mkstruct: Config    s" \" Config ConfigDef PathMediaFiles place
create DatFileFile$ ," \PathMediaFiles.dat"
string: DatFile$


: "\+place"  ( file$ - )  s" \"  rot +place ;


: InitFileNames ( - )
   current-dir$  count 2dup database$     place
                       2dup index$        place
                       2dup RequestIndex$ place
                       2dup RndIndex$     place
                            DatFile$      place
                           database$   "\+place"
   DatabaseFile$     count database$     +place
                              index$   "\+place"
   IndexFile$        count    index$     +place
                           RequestIndex$ "\+place"
   RequestIndexFile$ count RequestIndex$   +place
                           RndIndex$   "\+place"
   RndIndexFile$     count RndIndex$    +place
                            DatFile$   "\+place"
   DatFileFile$       count DatFile$     +place
 ;

\ Record discription of the catalog. October 30th, 2005.
\ This model assumes that the filename is the title and
\ that it placed in a directory named after the album
\ The directory the album is is placed in a directory named after artist.

255 constant    /file_name
 32 constant    /MediaLabel
 90 constant    /artist
 80 constant    /album
 85 constant    /Title
  1 constant    /Drivetype

:struct RecordDef \ catalog
                BYTE                    Deleted-
                BYTE                    Excluded-
                BYTE                    Played-
                BYTE                    TimesRequested
                DWORD                   FileSize
                DWORD                   Deleted-thread
                DWORD                   RandomLevel
                DWORD                   #played
                /Drivetype      Field:  DriveType
                /MediaLabel     Field:  MediaLabel
                /artist         Field:  Artist   \ Extracted from the filename
                /Album          Field:  Album    \ Extracted from the filename
                /Title          Field:  Title    \ Extracted from the filename
                /file_name      Field:  File_name
                BYTE                    Cnt_File_name
                BYTE                    Cnt_MediaLabel
                BYTE                    Cnt_Artist
                BYTE                    Cnt_Album
                BYTE                    Cnt_Title
                BYTE                    UserRating
                BYTE                    Request-
                BYTE                    RequestLevelRecord \ Res
                BYTE                    Reserved
                DWORD                   hInTree \ Updated when requests are added.
                DWORD                   reserved_
  ;struct                                       \ NOT reset when requests are deleted!


: in-freelist? ( adr - flag ) s" RecordDef Deleted- c@ " EVALUATE ; IMMEDIATE
: Mark#playingAsPlayed      ( - )
        #playing  -1 >
                if      #playing RecordDef true #playing  RecordDef Played- c!
                then
 ;

: file-exist?   ( adr len -- true-if-file-exist )  file-status nip 0= ;
: file-size>s   ( fileid -- len )       file-size drop d>s  ;
: map-hndl>vadr ( m_hndl - vadr )       >hfileAddress @ ;

map-handle idx-mhndl
map-handle ReqIdx-mhndl
map-handle RndIdx-mhndl
map-handle database-mhndl
map-handle config-mhndl

: map-index         ( - )   index$        count idx-mhndl      open-map-file throw ;
: map-RequestIndex  ( - )   RequestIndex$ count ReqIdx-mhndl   open-map-file throw ;
: map-RndIndex      ( - )   RndIndex$     count RndIdx-mhndl   open-map-file throw ;

: map-database-file ( - )   database$     count database-mhndl open-map-file throw ;
: map-config-file   ( - )   DatFile$      count config-mhndl   open-map-file throw ;
: vadr-config  ( - vadr-config ) s" config-mhndl map-hndl>vadr " EVALUATE ; IMMEDIATE

defer #records-in-database


: create-index-file ( #records - f )
   cells
   index$ create-file-ptrs
   index$ open-file-ptrs
   extend-file
 ;
: mark-as-undeleted ( adr - )
    false 2dup swap RecordDef Deleted- c!
    swap 2dup RecordDef Excluded- c!
    2dup RecordDef RandomLevel !
    2dup RecordDef #played !
         RecordDef Played- c!
  ;

: WarningBox     ( adr len -- flag )
     asciiz z" Warning:"
     [ MB_OKCANCEL MB_ICONWARNING or MB_TASKMODAL or ] literal
     NULL MessageBox
     IDCANCEL <>
  ;

: #RecordsInIndex ( IdxFileName$ - n )
   count r/w open-file drop dup file-size>s cell /
   swap close-file drop
 ;

: #RequestsInFile   ( - n )  RequestIndex$  #RecordsInIndex ;
: #RndRecordsInFile ( - n )  RndIndex$      #RecordsInIndex ;

in-system

: do_part ( n - )
   s" database-mhndl #records-in-database swap do i " EVALUATE ;


: for-all-records-from#        \ compiletime: ( -<word>- ) runtime: ( start - )
          do_part
           ' compile,         ( rec-adr -  )
         postpone loop
 ; immediate

: do_all_part     ( - ) s" database-mhndl #records-in-database  0 do i " EVALUATE ;

:  for-all-records ( - )   \ compiletime: ( -<word>- ) runtime: ( - )
          do_all_part
           ' compile,         ( rec-adr -  )
         postpone loop
 ; immediate

: do_all_part_Requests    ( - ) s" #RequestsInFile  0 do i " EVALUATE ;

:  for-all-Requests ( - )   \ compiletime: ( -<word>- ) runtime: ( - )
          do_all_part_Requests
           ' compile,         ( rec-adr -  )
         postpone loop
 ; immediate


in-application

: map-file-open?        ( map-handle -- f )
        >hfile @ -1 <> ;

: DataBaseFilled? ( - f )
    database$ count r/o open-file drop dup file-size drop d0= not
    swap close-file drop
  ;

defer generate-index-file:Catalog

: CntDelete ( $file - ) count delete-file drop ;

string: search$

\ Define the database catalog that uses the ShellSort as an object


:Object Catalog   <Super ShellSort

:M Start: ( -- )
         sizeof  RecordDef  to record-size
 ;M

:M Set-data-pointers:
   database-mhndl  map-hndl>vadr to records-pointer
   idx-mhndl       map-hndl>vadr to aptrs
 ;M

\ Define a key before using sort-database
:M Sort-database: ( key1..keyx #keys - )
    0 n>aptr  database-mhndl #records-in-database: Self
\      MciDebug?
\        if      cr ." Sort-time:" timer-reset
\        then
     mshell-rel
\     MciDebug?
\        if      .elapsed
\        then
  ;M

:M add-file-ptrs: ( #start #end - )
   dup to #records swap
      do  i records aptrs i cells + !
      loop
;M

: build-file-ptrs ( #records -- ) 0 swap  add-file-ptrs: Self ;

:M Rebuild-index-hdrs:  ( - ) \ database must be mapped
   database-mhndl #records-in-database: Self  build-file-ptrs
 ;M

:M generate-index-file: ( - )
   map-database-file
   database-mhndl #records-in-database: Self create-index-file
   map-index Set-data-pointers: Self
   Rebuild-index-hdrs: Self
 ;M



: free-list-check  ( n - )
   n>record  dup in-freelist?
     if    vadr-config >r  record>r dup  r@ #free-list @ 0=
                if     dup r@ first-free-record ! dup r>record RecordDef Deleted-thread !
                else   r@ prev-free-record @ r>record RecordDef Deleted-thread !
                then
           r@ prev-free-record !  1 r> #free-list +!
     else  drop
     then
 ;

: next-in-freelist ( vadr-config - rel-ptr )
    first-free-record @ r>record RecordDef Deleted-thread @
  ;


:M catalog-exist?:        ( -- f )
        DatFile$ count file-exist?
        database$ count file-exist?     and
        DataBaseFilled? and dup
        if   index$ count file-exist? not
                if   generate-index-file: Self
                then
        then
[defined] MciDebug? [if]
        MciDebug?
        if   cr ." catalog-exist?:" dup .
        then
[then]
      ;M

:M build-free-list:   ( - )
    0 vadr-config  #free-list !
    catalog-exist?: Self
       if  for-all-records free-list-check
       then
 ;M

:M Get-a-record-from-the-free-list:   ( - adr )
    vadr-config dup>r first-free-record  @
    r@ next-in-freelist r@ first-free-record ! r>record
    -1 r> #free-list +!
    dup record-size erase
  ;M

:M Delete-record:   ( n - )
    dup true swap n>record dup>r RecordDef Deleted- c!
    0 r> RecordDef Excluded- c!
    free-list-check
  ;M

:M undelete-all: ( - )
    vadr-config first-free-record @  vadr-config #free-list @ 0
      ?do    r>record dup RecordDef Deleted-thread @ swap mark-as-undeleted
      loop
     drop build-free-list: Self
 ;M


: Delete-record-in-collection ( n - )
    dup n>record RecordDef Excluded- c@ 0=
         if      delete-record: Self
         else    drop
         then
 ;

:M delete-collection:  ( - flag )
     s" Deleting the collection."  WarningBox  dup
        if   for-all-records Delete-record-in-collection
        then
 ;M

\ --------------------------------------------------------------------------
\ search in the catalog
\ --------------------------------------------------------------------------

\ r>record and records-pointer are NOT thread-safe!
0 value *recordspointer
: x>record ( n - a )  [ sizeof RecordDef ] literal * *recordspointer + ;


: search-record ( arg-adr$ count index - arg-adr$ count ) \ Erases also the previous found records
   x>record dup>r RecordDef Deleted- c@
     if     r>drop
     else   r@ RecordDef File_name r@ RecordDef Cnt_File_name c@
            2over 2swap false w-search    \ Much faster than *search
            not r> RecordDef Excluded- c! 2drop
     then
 ;

:M match-record: ( arg-adr$ count index - flag )
   n>record dup>r RecordDef Deleted- c@
     if     r>drop 2drop false
     else   r@ RecordDef File_name r> RecordDef Cnt_File_name c@
            false w-search nip nip
     then
 ;M

: ForTaskRange
    s" GetRange: Catalog_iTask " evaluate  postpone #do
 ; immediate

: search-all-records ( - ) search$ count ForTaskRange  search-record   2drop ;

: GetRangeCatalog ( - #records-in-database 0 )
    database-mhndl >hfileAddress @ to *recordspointer
    database-mhndl #records-in-database  0
 ;

:M GetRangeCatalog: ( - #records-in-database 0 )  GetRangeCatalog ;M


:M MatchArtistChar: ( char index - flag )
    n>record dup>r RecordDef Artist c@ upc =
    r> c@ not and
 ;M


:M MatchArtistNonChar: ( index - flag ) \ true when cjar of the artist is outside A-Z
   n>record  RecordDef dup>r Artist c@ upc dup ascii A < swap ascii Z > or  r> c@ not and
 ;M

:M GetArtist: ( index - Artist$ cnt )
   n>record dup RecordDef Artist swap RecordDef  Cnt_Artist c@
 ;M

:M GetAlbum: ( index - Artist$ cnt )
   n>record dup RecordDef Album swap RecordDef  Cnt_Album c@
 ;M

:M GetTitle: ( index - Artist$ cnt id )
   dup>r n>record dup RecordDef Title swap RecordDef  Cnt_Title c@ r>
 ;M

:M r>record: ( n -- a ) r>record  ;M
:M record>r: ( a -- n ) record>r  ;M

: search-ArtistChar ( char index - charUpc )
   x>record dup>r RecordDef Artist c@ upc over =
   not r> RecordDef Excluded- c!
 ;

0 value char$

: search-all-ArtistChar ( - )  char$   ForTaskRange  search-ArtistChar   drop  ;

: search-ArtistNonChar ( index - )
   x>record dup>r RecordDef Artist c@ upc dup ascii A < swap ascii Z > or
   not r> RecordDef Excluded- c!
 ;

: search-All-ArtistNonChar ( - ) ForTaskRange search-ArtistNonChar ;

:M search-ArtistsChar: ( char - )   \ Search any record with artist starting wih char
   upc to char$ GetRangeCatalog char$ ascii @ =
     if     ['] search-All-ArtistNonChar
     else   ['] search-all-ArtistChar
     then
  Parallel: Catalog_iTask
  ;M

: SetSearch$ ( adr count - )  s" *" search$ place  search$ +place ;

:M "Search-records: ( adr count - )
    SetSearch$ GetRangeCatalog
    ['] search-all-records Parallel: Catalog_iTask
 ;M

: +search-record ( arg-adr$ count index - arg-adr$ count ) \ Extends the found records
   x>record dup>r RecordDef Deleted- c@
     if     r>drop
     else   r@ RecordDef File_name r@ RecordDef Cnt_File_name c@
            2over 2swap false w-search dup 0<>  \ Much faster than *search
             if  not r> RecordDef Excluded- dup c@ 0<>
                 if     c! 2drop
                 else   4drop
                 then
             else   r>drop 3drop
             then
     then
 ;

: +Search-all-records  ( -- )  search$ count  ForTaskRange +search-record   2drop ;

:M "+Search-records: ( adr count - )
    SetSearch$ GetRangeCatalog
    ['] +Search-all-records Parallel: Catalog_iTask  \ For each string in a txt file
 ;M

: -search-record ( arg-adr$ count index - arg-adr$ count ) \ Subtracts the found records
   x>record dup>r RecordDef Deleted- c@
     if     r>drop
     else   r@ RecordDef File_name r@ RecordDef Cnt_File_name c@
            2over 2swap false w-search dup   \ Much faster than *search
             if   r> RecordDef Excluded- dup c@ 0=
                 if     c! 2drop
                 else   4drop
                 then
             else   r>drop 3drop
             then
     then
 ;

: -Search-all-records  ( -- )  search$ count  ForTaskRange -search-record   2drop  ;

:M "-Search-records: ( adr count - )
    SetSearch$ GetRangeCatalog
    ['] -Search-all-records Parallel: Catalog_iTask  \ For each string in a txt file
 ;M

: RemoveFromCollection ( index - ) x>record  true swap RecordDef Excluded- c! -1 +to #excluded ;
: RemoveFromResult     ( n - )     ForTaskRange  RemoveFromCollection  ;

:M Clear-results:      ( -- )  GetRangeCatalog  ['] RemoveFromResult Parallel: Catalog_iTask  ;M

:M ClassInit:    ( -- )        ClassInit: super             ;M

;Object


:Object Requests   <Super ShellSort

:M Start: ( -- )
         sizeof  RecordDef  to record-size
 ;M

:M GetArtist: ( index - Artist$ cnt )
   n>record dup RecordDef Artist swap RecordDef  Cnt_Artist c@
 ;M

:M GetAlbum: ( index - Artist$ cnt )
   n>record dup RecordDef Album swap RecordDef  Cnt_Album c@
 ;M

:M GetTitle: ( index - Artist$ cnt id )
   dup>r n>record dup RecordDef Title swap RecordDef  Cnt_Title c@ r>
 ;M

:M Set-data-pointers:
   database-mhndl  map-hndl>vadr to records-pointer
   ReqIdx-mhndl    map-hndl>vadr to aptrs
 ;M

:M FindRecord#InRequests: ( ID - position flag )
   0 0 rot  #RequestsInFile 0
     do  dup i n>record = if nip nip i swap true swap leave then
     loop
   drop
 ;M

\ Define a key before using sort-database >>>
:M Sort-database: ( key1..keyx #keys - )
    0 n>aptr  #RequestsInFile
      MciDebug?
        if      cr ." Sort-time:" timer-reset
        then
     mshell-rel
     MciDebug?
        if      .elapsed
        then
  ;M

;Object


\ RndIdx-mhndl

:Object RandomRecords   <Super ShellSort

:M Start: ( -- )
         sizeof  RecordDef  to record-size
 ;M

\ Define a key before using sort-database
: Sort-database ( key1..keyx #keys - )
    0 n>aptr   #RndRecordsInFile
      MciDebug?
        if      cr ." Sort-time:" timer-reset
        then
     mshell-rel
     MciDebug?
        if      .elapsed
        then
  ;


:M  Sort-database:
   Sort-database
;M



:M Set-data-pointers:
   database-mhndl  map-hndl>vadr to records-pointer
   RndIdx-mhndl    map-hndl>vadr to aptrs
 ;M

;Object

:Noname #records-in-database: Catalog ;  is #records-in-database

\ Advantage of an inline record:
\ An easy way to create and debug a fixed record
sizeof  RecordDef  mkstruct: InlineRecord
sizeof  RecordDef  mkstruct: RecordPlaying


: map-database  ( - )   map-database-file map-index Set-data-pointers: Catalog ;

: unmap-ReqIdx  ( - )
      ReqIdx-mhndl   dup flush-view-file drop close-map-file drop
 ;

: unmap-RndIdx  ( - )
      RndIdx-mhndl   dup flush-view-file drop close-map-file drop
 ;

: unmap-database  ( - )
    database-mhndl dup flush-view-file drop close-map-file
    idx-mhndl      dup flush-view-file drop close-map-file 2drop
 ;

: unmap-configuration  ( - )
    database-mhndl dup flush-view-file drop close-map-file drop
 ;

: create/open ( name - wHndl )
   count 2dup file-exist?
        if      r/w   open-file         abort" Can't open the file for writing"
        else    r/w create-file         abort" Can't create the file"
        then
 ;

: type-space    ( adr cnt -  )   type space  ;
: type-cr       ( adr cnt -  )   type cr  ;


: generate-index-file ( - )   unmap-database  Generate-index-file: Catalog  ;

\ ==== Part that depends on a record definition

Path: (SearchPathCatalog

: CatalogPath  ( - CatalogPath ) vadr-config SearchPathCatalog count (SearchPathCatalog place (SearchPathCatalog ;

: check-config   ( flag -- ) \ creates one with the right size
    not
        If      Config sizeof ConfigDef
                DatFile$ count r/w create-file abort" Can't create configuration file"
                dup>r write-file abort" Can't save path to media folder"
                r>    FlushCloseFile
                map-config-file
                true vadr-config s_Artist_Title- c!
                10   vadr-config ttsVolume c!
                8    vadr-config pitch c!
                254  vadr-config VoiceRate c!
                s" Style*Artist*Album*Song" vadr-config TextBox1$ place
                GetIpHost$                  vadr-config AddressWebServer$ place
                s" Name WiFi"               vadr-config WiFiName$ place
                s" Password WiFi"           vadr-config WiFiPassword$ place
        then
  ;


: write-record ( wHndl - )    \ Recycle deleted records first.
   InlineRecord [ sizeof RecordDef ] literal
   vadr-config #free-list @ 0>
    if     Get-a-record-from-the-free-list: Catalog swap cmove drop
    else   rot write-file abort" Can't save record"
    then
 ;


false value show-deleted


/artist /album + /Title +  constant  /Record

0 RecordDef File_name   previous /file_name key: FileNameKey
0 RecordDef MediaLabel  previous 255        key: FlexKey
0 RecordDef RandomLevel previous 1 cells    key: RandomKey       RandomKey       bin-sort
0 RecordDef #played     previous 1 cells    key: leastPlayedKey  leastPlayedKey  bin-sort
0 RecordDef Deleted-    previous 1          key: DeletedKey      DeletedKey      byte-sort
0 RecordDef TimesRequested  previous 1      key: TimesRequestedKey TimesRequestedKey  byte-sort
0 RecordDef FileSize    previous 1 cells    key: FileSizeKey     FileSizeKey     bin-sort
0 RecordDef Request-    previous 1 cells 2/ key: RequestKey      RequestKey Descending word-sort
0 RecordDef MediaLabel  previous /MediaLabel /Record + key: LabelKey

: &FlexKeyLen ( - &FlexKeyLen ) FlexKey &key-len ;
: MinFlexKey! ( n - )           min FlexKey !    ;

: by_record  ( - FlexKey )
   /artist /Album + /Title + &FlexKeyLen !
   0 RecordDef Artist FlexKey ! FlexKey
  ;

: RequestKeyFlagged
    vadr-config IgnoreRequests c@ not
      if  RequestKey
      then
 ;

: By_FileName           ( - by )  by[   FileNameKey RequestKeyFlagged    ]by ;
: By_Random             ( - by )  by[   leastPlayedKey Ascending RandomKey   ]by ;
: by_leastPlayed        ( - by )  by[   leastPlayedKey Ascending RequestKeyFlagged ]by ;
: by_FileSize           ( - by )  by[   FileSizeKey    RequestKeyFlagged ]by ;
: by_cand_duplicates    ( - by )  by[   RandomKey Ascending leastPlayedKey Ascending FileSizeKey
                                        FileNameKey ( LabelKey) DeletedKey  ]by ;
: not-deleted? ( rec-adr - flag )   s" RecordDef deleted- c@ 0= " EVALUATE ; IMMEDIATE
: deleted?     ( rec-adr - flag )   s" RecordDef deleted- c@    " EVALUATE ; IMMEDIATE


:inline FileSizeRecord   ( adr - FileSizeRecord )  RecordDef FileSize @ ;

: _list-record ( rec-adr - )
    dup>r not-deleted?
        if      cr r@ .
                r@ RecordDef DriveType  c@ .
                r@ RecordDef MediaLabel r@ RecordDef Cnt_MediaLabel c@ type-space
                r@ RecordDef File_name  r@ RecordDef Cnt_File_name c@   type-space
                cr 3 spaces
                r@ RecordDef Artist r@   RecordDef Cnt_Artist c@   type-space
                r@ RecordDef Album  r@   RecordDef Cnt_Album  c@   type-space
                r@ RecordDef Title  r@   RecordDef Cnt_Title  c@   type-space

                r@ RecordDef #played ?
                r@ RecordDef RandomLevel ?
                r@ RecordDef Played-   c@ .
                r@ RecordDef Excluded- c@ .
                r@ FileSizeRecord 12  U,.R
                r@ RecordDef RequestLevelRecord c@  ."  Req " .
        then
    r>drop
   ;


: _list-record-rnd ( rec-adr - )
    dup>r not-deleted?
        if      cr r@ .
                r@ RecordDef RandomLevel ?
                r@ RecordDef TimesRequested   c@ .
                r@ RecordDef #played ?

                r@ RecordDef Title  r@   RecordDef Cnt_Title  c@   type-space

                r@ RecordDef Played-   c@ .
                r@ RecordDef Excluded- c@ .
        then
    r>drop
   ;

: request? ( n - f )    n>record: catalog  RecordDef Request- c@ 0<> ;

: List-request   ( n - ) n>record: requests _list-record-rnd ;
: List-requests  ( - )   for-all-Requests    List-request cr ;
: list-record    ( n - ) n>record: catalog  _list-record ;
: list-records   ( - )   for-all-records list-record cr ;

: list-database  ( - )   map-database  list-records unmap-database ;

: FullPathSong ( adr - adr cnt ior )
       dup RecordDef File_name swap RecordDef Cnt_File_name c@
       CatalogPath  full-path
 ;

: List-dead-link ( n - )
    n>record: catalog dup FullPathSong
      if    2drop _list-record cr
      else  3drop
      then
;

: List-dead-links ( - )   for-all-records List-dead-link  ;


: Level-request   ( n - ) dup request?
                                if    n>record: catalog  1 swap RecordDef RequestLevelRecord c!
                                else  drop
                        then
 ;

: Level-requests ( - )   for-all-records Level-request ;

: RemoveRequest  ( n - )  0 swap n>record: catalog  RecordDef Request- c! ;
: RemoveAllRequests  ( n - ) for-all-records RemoveRequest ;

: ResetRequest  ( n - )  0 swap n>record: Requests RecordDef Request- c! ;
\ : ResetAllRequests  ( n - ) for-all-Requests RemoveRequest ;

 K_TAB variable separator  separator c!
0 value fid

: +inlineRecord      ( adr cnt -  )  InlineRecord +place ;
: type-separator     ( adr cnt -  )  +inlineRecord  separator 1 +inlineRecord ;
: .csv               ( n - adr cnt ) s>d  (d.)  ;
: fwrite             ( adr cnt - )   fid write-line abort" Can't write to file" ;

: csv-record ( n - )
    InlineRecord off dup >record: catalog
    dup>r not-deleted?
       if  .csv type-separator
           r@ RecordDef DriveType  c@ .csv  type-separator
           r@ RecordDef MediaLabel r@ RecordDef Cnt_MediaLabel c@ type-separator
           r@ RecordDef Artist     r@ RecordDef Cnt_Artist c@ type-separator
           r@ RecordDef Album      r@ RecordDef Cnt_Album  c@ type-separator
           r@ RecordDef Title      r@ RecordDef Cnt_Title  c@ type-separator
           r@ RecordDef #played     @ .csv  type-separator
           r@ FileSizeRecord          .csv  type-separator
           r@ RecordDef File_name  r@ RecordDef Cnt_File_name  c@ type-separator

       \    r@ RecordDef RequestLevelRecord c@ .csv +inlineRecord
           InlineRecord count       fwrite
       else drop
       then
    r>drop
   ;

: csv-catalog  ( - )
   wait-cursor
   s" JukeBoxIn4Th.csv"  r/w create-file abort" Can't create file"  to fid

   InlineRecord off
   s" Id"       type-separator          s" Drivetype"   type-separator
   s" Label"    type-separator          s" Artist"      type-separator
   s" Album "   type-separator          s" Title"       type-separator
   s" #played"  type-separator          s" Size"        type-separator
   s" RelPath" +inlineRecord
   InlineRecord count   fwrite

   for-all-records  csv-record
   fid close-file abort" close error"
   arrow-cursor
 ;

: cmp-Album? { rec1 rec2 } ( rec rec+1 - f )
      rec1 RecordDef Album     rec1 RecordDef Cnt_Album c@
      rec2 RecordDef Album     rec2 RecordDef Cnt_Album c@   compareia 0=
           if   rec1 RecordDef Artist     rec1 RecordDef Cnt_Artist c@
                rec2 RecordDef Artist     rec2 RecordDef Cnt_Artist c@   compareia 0=
           else  false
           then
 ;

0 value prev_rec

: .album ( adr - adr )
   cr dup>r  RecordDef Artist r@ RecordDef Cnt_Artist c@ type
   cr r@ RecordDef Album      r@ RecordDef Cnt_Album  c@ type r>
;

: Album-done? ( n - f )
    dup n>record: catalog  in-freelist?
        if   drop true exit
        then
    prev_rec 0<
          if     to prev_rec false
          else   dup>r n>record: Catalog prev_rec n>record: Catalog cmp-Album? dup
                       if    r>drop
                       else  r> to prev_rec
                       then
          then
 ;

: csv-album ( n - )
   dup Album-done? not
       if    InlineRecord off dup n>record: catalog dup>r not-deleted?
                   if  .csv type-separator
                        r@ RecordDef Artist     r@ RecordDef Cnt_Artist c@ type-separator
                        r@ RecordDef Album      r@ RecordDef Cnt_Album  c@ type-separator
                        InlineRecord count      fwrite
                   else  drop
                   then  r>drop

       else  drop
       then
   ;

: csv-albums  ( - )
   wait-cursor
   -1 to prev_rec
   s" JukeBoxIn4ThAlbums.csv"  r/w create-file abort" Can't create file"  to fid

   InlineRecord off
    s" Id"      type-separator
   s" Artist"   type-separator
   s" Album "   +inlineRecord
   InlineRecord count   fwrite

   for-all-records  csv-album
   fid close-file abort" close error"
   arrow-cursor
 ;

: SetRecordInCollectionToNotPlayed    ( n - )
    n>record: catalog dup RecordDef Excluded- c@ not
        if     0 swap RecordDef Played- c!
        else   drop
        then
 ;

: change-randomlevel  ( level n - )
   n>record: catalog  over random swap RecordDef RandomLevel  ! #Done incr
 ;

: sort_by_filename              ( - )    by_FileName         Sort-database: Catalog ;
: sort_by_leastPlayed           ( - )    by_leastPlayed      Sort-database: Catalog ;
: sort_by_size                  ( - )    by_FileSize         Sort-database: Catalog ;
: sort_by_cand_duplicates       ( - )    by_cand_duplicates  Sort-database: Catalog ;

: SortByFlags ( - )
   vadr-config >r 1
    case
        r@ s_Filename- c@   of sort_by_filename             endof
        r@ s_#Random-  c@   of By_Random Sort-database: Catalog      endof
       \ r@ s_#Played-  c@   of sort_by_leastPlayed          endof
        r@ s_filesize- c@   of sort_by_size                 endof

        sizeof  RecordDef FlexKey !      0 &FlexKeyLen !
        r@ s_Drivetype- c@
                if      [ /Drivetype /MediaLabel +  /Record + ] literal &FlexKeyLen !
                         FlexKey @ 0 RecordDef DriveType MinFlexKey!
                then
        r@ s_Label- c@
                if      [ /MediaLabel /Record + ] literal &FlexKeyLen !
                        FlexKey @ 0 RecordDef MediaLabel MinFlexKey!
                then
        r@ s_Artist_Title- c@
                if      [ /Record ] literal &FlexKeyLen !
                        FlexKey @ 0 RecordDef Artist MinFlexKey!
                then
        FlexKey &key-len @ 0>
                if      by[ FlexKey RequestKeyFlagged ]by Sort-database: Catalog
                then

    endcase
   r>drop
 ;

: sort_by_RandomLevel ( - )
        By_Random Sort-database: Catalog
  ;

: shuffle-catalog ( - )
   database-mhndl 0x7FFFFFFF for-all-records change-randomlevel 2drop
;

: random-shuffle        ( -  )
     shuffle-catalog sort_by_RandomLevel RefreshCatalog
   ;

: incr-#played  ( adr - ) RecordDef #played dup @ 1+ swap ! ;
: mark-played   ( adr - ) -1 swap RecordDef Played- c!      ;

: RequestDone   ( adr - )
    vadr-config KeepRequests c@
       if    drop
       else  0 swap RecordDef Request- c!
       then
 ;


: EnableKeptRequest ( n - )
   n>record: Catalog dup RecordDef Request- c@
     if     0 swap RecordDef Played- c!
     else   drop
     then
 ;

: EnableKeptRequests ( - )   for-all-records  EnableKeptRequest
 ;

internal

0 value /VolumeNameBuffer

: ExtractRecord ( adr count - )
    >r dup r@ + 1- dup r@ ascii \ -scan   \ adr Title
    rot over ascii . -scan             \ count Title
    drop 2 pick 1+ 2dup -  /Title min dup   \ 0< if cr .s  ." file" abort then dup
    struct, InlineRecord RecordDef Cnt_Title    c!
    struct, InlineRecord RecordDef Title swap cmove \ move Title
    drop

    >r 1- dup r> ascii \ -scan  >r 2dup - r@ swap >r 0>
       if     1+ r@ /album min  struct, InlineRecord RecordDef Cnt_Album c!
              struct, InlineRecord RecordDef Album  r@ /album min cmove
       else   struct, InlineRecord RecordDef Cnt_Album  c!
       then                                                \ 4

    r> - 1- dup r>  ascii \ -scan 0>
       if    2dup - swap 1+ over
             /artist min struct, InlineRecord RecordDef Cnt_Artist c!
             struct, InlineRecord RecordDef Artist rot /artist min cmove
       else  0 struct, InlineRecord RecordDef Cnt_Artist  c! drop
       then
    drop   struct, InlineRecord RecordDef File_name  swap r>
    CatalogPath FindRelativeName drop /file_name min >r swap r@ cmove
    r>   struct, InlineRecord RecordDef Cnt_File_name    c!
 ;

0 value DbHndl


: (add-file)    ( addr len file-size - wHndl ) \ add a file to the catalog
   InlineRecord [ sizeof RecordDef ] literal erase
                       struct, InlineRecord RecordDef FileSize         !
                       ExtractRecord
   VolumeNameBuffer    struct, InlineRecord RecordDef MediaLabel
                              /VolumeNameBuffer /MediaLabel min        cmove
   /VolumeNameBuffer   struct, InlineRecord RecordDef Cnt_MediaLabel   c!
   _DriveType          struct, InlineRecord RecordDef DriveType        c!
   DbHndl write-record
 ;

external

sTask FileTask   \ To be used to add files

0 value &FileBlock

\ Map: FileBlock for process-1file:
: >FileSize       ; immediate   ( -- )               \ The 1st cell is the file size
  synonym >name-buf$  cell+ ( adr - name-buf )       \ The 2nd cell contains the full file name
  MAXSTRING cell+ constant /FileEntry                \ Total size of one entry

: >FileEntry ( index - adr )  /FileEntry * &FileBlock + ; \ To get to one entry

: add-file      (  -  ) \ add a file to the catalog ( for whole dir-trees )
    JobEntryID @ >FileEntry >name-buf$ count
    2dup IsValidFileType?
        if   JobEntryID @ >FileEntry >FileSize @ (add-file)
        else 2drop
        then
    #done incr
 ;

: AddFile ( adr cnt - ) \ used for a few selected files
     2dup IsValidFileType?
        if   2dup r/o  open-file  throw dup file-size  throw  d>s
             swap  close-file  throw
             (add-file)
        then
    #done incr
 ;

0 value played_from_catalog
\  -1 value last-selected-rec
0 value #InCollection

: Requests? ( adr - flag ) #RequestsInFile 0> vadr-config IgnoreRequests c@ not and ;
: Requested?  ( adr - flag ) RecordDef Request- c@ ;

: ClearAllFromCollection
   database$ count file-exist?
      if    Clear-results: Catalog
      then
   0 to #excluded
 ;
\ --------------------------------------------------------------------------
\  add a directory tree to the catalog
\ --------------------------------------------------------------------------
internal
create valid-dx-sound-ext ," *.aiff;*.au;*.mid;*.midi;*.mp3;*.snd;*.wav;*.wma"

: select_tree ( - path count file-spec count flag-subdir )
        vadr-config PathMediaFiles dup 0=
        if    drop s" \"
        else  count
        then  valid-dx-sound-ext count true  \ Filtering is not done by the catalog
        ;


: Add.dir->file-size ( -- file-size )
    _win32-find-data @ FILE_ATTRIBUTE_DIRECTORY and
           if   0
           else _win32-find-data 8 cells+ @
           then ;

: start-add-file-task ( adrd adr len -- )       \ handle the found file in a task.
        LockJobEntry[: FileTask GetLockedJobID: FileTask
         >FileEntry dup>r                       \ Using a jobIndex to link it to an entry in the fileblock
        >name-buf$  place                       \ lay in directory  in fileblock
        11 cells+                               \ adrz
        zcount                                  \ adrz slen -- adr len
        r@ >name-buf$ +place                    \ append filename in the file block
        add.dir->file-size r> >FileSize !       \ Save the filesize also in the fileblock
        ['] add-file ]Submit: FileTask
        ;


external

\ 2 records are considered to be duplicate when the
\ relative filename are the same

: duplicates? { rec1 rec2 } ( rec rec+1 - f )
               rec1 RecordDef File_name  rec1 RecordDef Cnt_File_name c@
               rec2 RecordDef File_name  rec2 RecordDef Cnt_File_name c@ compareia 0=
 ;

: DuplicatedToNext? ( n - f ) dup n>record: Catalog swap 1+ n>record: Catalog duplicates? ;

: RemoveDuplicates   ( - )
   sort_by_cand_duplicates
   database-mhndl #records-in-database 1- 0
        ?do   #done incr i n>record: Catalog in-freelist?
                if      leave
                then
              i DuplicatedToNext?
                        if      i Delete-record: Catalog
                        then
        loop

 ;

: CloseReMap  ( wHndl - )
       DbHndl close-file abort" Close error database"
        generate-index-file
 ;

: OpenAppendDatabase ( - wHndl )
    database$  create/open dup file-append throw
 ;

: add_dir_tree  ( -- ) \ add a directory tree to the catalog
  busy? not
     if  true to busy? wait-cursor ClearAllFromCollection
         ['] start-add-file-task is process-1file
         OpenAppendDatabase to DbHndl
         select_tree sdir
         WaitForAll: FileTask
         DbHndl CloseReMap
         RemoveDuplicates
         #RequestsInFile 0>
            if  unmap-ReqIdx
                map-RequestIndex
            then
         shuffle-catalog
         by[ by_record ]by  Sort-database: Catalog
         (RefreshCatalog)
         arrow-cursor
     then
   false to busy?  arrow-cursor
        ;

0 value player-base


string: dialog$

: dialog$_ok?   ( - dialog$ count flag )
                        dialog$ +null dialog$ count dup 1 maxstring between ;

: init-dlg      ( base adr count - dialog$ base )
                       dialog$ place dialog$ swap ;

string: tmp$

: n>tmp$   ( n - )    0 (d.) tmp$ place ;

NewEditDialog RequestLevelDlg "Request level" "Enter the level to use:" "Ok" "Cancel" ""

: SetRequestLevel
   vadr-config RequestLevel c@ n>tmp$ tmp$ count init-dlg  Start: RequestLevelDlg drop
   dialog$ count number?
       if   d>s  vadr-config RequestLevel c!
       else 2drop
       then
 ;


: CatalogPath-does-not-exist ( - flag )
    CatalogPath count nip 0<>
     if   CatalogPath first-path" find-first-file nip 6 0
             do    CatalogPath next-path" find-first-file nip and
             loop
     else true
     then
    dup not vadr-config Endless- c@ and vadr-config Endless- c!
 ;

previous

\s

\ Listtest
start: Catalog
InitFileNames map-database

\s
