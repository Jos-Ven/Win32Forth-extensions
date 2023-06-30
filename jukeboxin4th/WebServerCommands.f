Anew -WebServerCommands.f

(( Notes:

1) The firewall of windows needs aprooval for access access for the webserver of the JukeBoxIn4Th.
Limit access in the firewall to block access from the internet.

2) When THOMSON SpeedTouch 780 routers are used you need to enable the
the service: HTTP Server (World Wide Web)

3) As soon as the webserver is activated, my virus-scanner reported the program as a thread.
So I made an exception.

4) Change the string WebServer$ when it is not running on the localhost

5) The method POST is not reliable over the internet when various browser are used.
So I use the GET method.  ))

needs w_search.f
needs Struct
needs apps\Player4\number.f

 VOCABULARY Webserver
also Webserver definitions

Needs scoop.f
Needs sockserv.f
Needs HTTPerr.f
Needs http.f
Needs httpecho.f
Needs httpmime.f
Needs httpfile.f

current-dir$ count webpath place  s" \Html\"  webpath +place

: 1+!           ( adr - )       dup @ 1+ swap !  ;
: (u)           ( - adr len )   s>d (d.) ;
: 2n            ( n adr len - ) 0 <# # # #> ;
: +temp         ( adr len - )   temp$ +place ;
: 2n+temp       ( n - )         2n +temp ;

: GetDateTime ( - adr$  )
    time&date (u) +temp 2n+temp 2n+temp
    s" :" +temp 2n+temp 2n+temp s" :" +temp 2n+temp
    time-buf 14 + w@ (u) temp$ +place temp$
 ;

: GetTime$ ( - adr$ cnt ) get-local-time time-buf >time" ;

: WriteRecord ( Record$ count File$ count - )
    2dup file-status 0<> nip
        if      r/w create-file abort" Can't create file"
        else    r/w open-file   abort" Can't open file"
                dup file-append abort" Can't append to file"
        then
    dup>r write-file abort" Can't write to file"
    r> close-file drop
 ;

: LogData ( adr len - )    \ To InputLogging.dat
   s" -" temp$ place GetDateTime
   s" ;" 2dup +temp  FromIp @ iaddr>str +temp  +temp
   s" Gci.log" 2>r count 2r@ WriteRecord
   2r@ WriteRecord
   crlf$ count 2r> WriteRecord
 ;


: ,|     ( -<string|>- )   \ compile a short string| at here max 255 char
    [char] | parse ", 0 c, align ;

: ((p|))       ( -- addr len buff buff )
                [char] | parse new$ dup ;

: ((s|))       ( -<string>- -- add len )    \ for state = not compiling
                ((p|)) >r swap dup>r move 2r> ;
: s|
    state @
      if      compile (s")  ,|
      else    ((s|))
      then ; immediate

: HTML|   ( -<string|>- )
    compile (s")  ,| \ postpone   +Html$
 ;  immediate


\ : testHTML|    HTML| 1234 <"ab">| ;   see testHTML| abort \s


variable _empty$         0 _empty$ !
: Empty$   ( - empty$ )    _empty$ ;

string: GciName$        s" Win32Forth.gci"    GciName$ place

: Replace%hex2 { str$ cnt -- str$ cnt } \ to replace %20 to a space etc.
  str$ dup cnt base @ >r hex
       begin  ascii % scan dup
       while  dup 3 >=
                 if    over  to str$ -2 +to cnt 1 /string over 2 (number?)
                        if   d>s str$ c! 2 /string  1 +to str$ str$ swap dup>r cmove
                             str$ r>
                        else 2drop -1 +to cnt
                        then

                 else  1 /string
                 then
       repeat
   2drop cnt r> base !
 ;

with httpreq
also hidden

: GetRequest ( - req count ) request  with dstr count ;

\IN-SYSTEM-OK  : .request   C_CR  s" **********" C_CR  C_TYPE  GetRequest  C_TYPE   endwith  ;

previous

: GetDataMethod ( - adr len )     0 0  getparam  ;

map-handle html-mhndl

: +dstr   ( adr cnt - )    with dstr reply append endwith ;
\IN-SYSTEM-OK  : .reply  ( adr cnt - )    with dstr reply  count endwith c_type ;
: .HTML   ( # - )          (u) +dstr ;
: crlf$+  ( - )            crlf$ count +dstr ;
: EndCode ( - )            crlf$+ 200 code ! ;

: ?ErrorOpenFileBox ( flag addr len -- )
                asciiz  swap
                if   z" Can not open file:"
                     [ MB_OK MB_ICONSTOP or MB_TASKMODAL or ] literal
                     NULL MessageBox drop
                     bye
                else drop
                then ;

: +file   ( name cnt - )
    2dup html-mhndl open-map-file -rot ?ErrorOpenFileBox
    html-mhndl map-hndl>vadr
    html-mhndl >hfileLength @ +dstr
    html-mhndl close-map-file drop
 ;


2 constant /dial$

0 value PrevArtist$
0 value  cnt

: HomePage$+     ( - ) HomePage$ count +dstr ;
: TopHomePage$+  ( - ) HTML| <a href="| +dstr HomePage$+ HTML| "name="_top">JukeboxIn4Th</a>| +dstr ;
: HomePageLink$+ ( - ) HTML| <a href="| +dstr HomePage$+ HTML| ">JukeboxIn4Th</a>| +dstr ;
: TopLink$+      ( - ) HTML| ===> <a href="#_top" name="_bottom" >Top</a> | +dstr ;
: BottomLink$+   ( - ) HTML| ===> <a href="#_bottom">Bottom</a> | +dstr ;

:inline ListArtist ( index -- )
    GetArtist: Catalog 2dup PrevArtist$ cnt istr= not
       if  1 +to #results 2dup to cnt to PrevArtist$
           HTML| <A href=" | +dstr
           s" A" +dstr  2dup +dstr  HTML| ">| +dstr
           +dstr
            HTML| </A> <BR>| +dstr
       else 2drop
      then
 ;

: send-dial-list-non-char ( - #results )
   0 locals| #results |
   GetRangeCatalog: Catalog
      do  i MatchArtistNonChar: Catalog
            if   i ListArtist
            then
      loop
    #results
 ;

: HtmlBodyFont ( - )
   HTML| <body bgcolor="#FEFFE6"> <p><font size="4" face="Segoe UI" color="#000000"> | +dstr
 ;

: send-dial-list-char ( char - )
   0 locals| #results |
   0 temp$ to PrevArtist$ to cnt  temp$ off
   HTML| <HTML> | +dstr
   HTML|  <head> <style> body {line-height: 24px;} </style> </head> | +dstr
   HtmlBodyFont  BottomLink$+ TopHomePage$+
   HTML| :<p> Hit below an artist or group to see their songs.| +dstr  HTML| <p>| +dstr

   dup ascii @ =
      if    drop send-dial-list-non-char to #results
      else  upc GetRangeCatalog: Catalog
                   do  dup i MatchArtistChar: Catalog
                        if   i ListArtist
                        then
                   loop
            drop
       then
     #results 0=
        if  s" <br> No results found" +dstr
        else s" <br> Number of found artists or groups: " +dstr #results (u) +dstr
        then
     HTML| </p> <p> | +dstr TopLink$+   TopHomePage$+
     HTML| </p> </font>  </body> </HTML> | +dstr
    EndCode
 ;

: GetSearchChar ( adr - char )   2 + c@ ;

0 value #Requests

\  34133C | 2F 40 41 2E 68 74 6D 6C                          |/@A.html|
: doDialSearch ( -- flag )  \ Handles dial-search
    1 +to #Requests
    url over /dial$ s" /@" istr=  \ Act on /@
       if    drop GetSearchChar send-dial-list-char
             true
       else  2drop false
       then
 ;


 doURL doDialSearch http-done

string: InputSearch$

: BodyStart
   HtmlBodyFont BottomLink$+ TopHomePage$+
   HTML| <FORM> <p>Search result for:<BR>| +dstr
   HTML| <INPUT TYPE="TEXT" NAME="SearchString1" value="| +dstr
          InputSearch$ count +dstr  HTML| "><BR>| +dstr
   HTML| <INPUT TYPE="submit" STYLE="color: #000000; background-color: #e5e5e5;" VALUE="New search...">| +dstr
   HTML| </FORM>| +dstr

   HTML| <p> Hit below a song to request it.<br> </font></p> | +dstr
   crlf$+
   HTML| <p> <div style="overflow:visible" class="css-treeview"> | +dstr
   HTML| <ul>| +dstr

 ;

:Inline EndTreeView
  crlf$+
   HTML| </ul> </li> </ul> </ul>  | +dstr
   HTML| <p><font size="4" face="Segoe UI" color="#000000"> | +dstr
   HTML| <br> Number of found records: | +dstr #results (u) +dstr
   HTML| <BR>| +dstr  TopLink$+  HomePageLink$+
   crlf$+
   HTML| <font></p></div> </body> </html> | +dstr
 ;

\ temp$ value prevArtist$
temp$ value prevAlbum$
0 value prevArtisCnt
0 value prevAlbumCnt

0 value IDArtistTV
0 value IDAlbumTV

: SendIDitem ( id - )
   IDArtistTV (u) +dstr s" -" +dstr
   IDAlbumTV  (u) +dstr HTML| " | +dstr
 ;

: SendArtist ( Artist$ cnt - )
    prevArtist$ prevArtisCnt 2over istr= not
     if  IDAlbumTV 0>
           if   HTML| </ul> </li> </ul> </li> | +dstr  1 +to IDArtistTV
           then
         crlf$+
         0 to IDAlbumTV
         HTML| <li><input type="checkbox"  id="item-| +dstr SendIDitem
         HTML| checked="checked" /><label for="item-| +dstr SendIDitem
         HTML| >| +dstr
         2dup +dstr to prevArtisCnt to prevArtist$
         HTML| </label>| +dstr
         crlf$+ HTML| <ul>| +dstr
     else 2drop
     then
 ;

: SendAlbum ( Artist$ cnt - )
    prevAlbum$ prevAlbumCnt 2over istr= not
     if  IDAlbumTV 0>
           if   HTML| </ul> | +dstr
           then
         1 +to IDAlbumTV
         crlf$+
         HTML| <li><input type="checkbox"  id="item-| +dstr SendIDitem
         HTML| checked="checked" /><label for="item-| +dstr SendIDitem
         HTML| >| +dstr
         2dup +dstr to prevAlbumCnt to prevAlbum$
         HTML| </label>| +dstr
         crlf$+ HTML| <ul>| +dstr
     else 2drop
     then
 ;

: (H.N)         ( n1 n2 -- adr cnt )    \ return n1 as a HEX number of n2 digits
                base @ >r hex
                0 <# swap 0 ?do # loop #>
                r> base ! ;

: (h.8)           ( n1 -- adr cnt  ) 8 (h.n) ;


: SendID  ( id - )
    HTML| ~| +dstr  (h.8) +dstr

 ;

: SendTitle ( Artist$ cnt ID - )
   crlf$+
   HTML| <li><a href="| +dstr   SendID  HTML| ">| +dstr
   +dstr
    HTML| </a></li> | +dstr
 ;


: Replace\By|  ( adr cnt - ) \ To avoid disturbences from a link with a "\" in it.
    begin  [char] \ scan dup
    while  [char] | 2 pick c!
    repeat
    2drop
 ;

: Replace|By\  ( adr cnt - )
    begin  [char] | scan dup
    while  [char] \ 2 pick c!
    repeat
    2drop
 ;


: send-tree-for-search$  ( - ) \ The search string to search for needs to be in search$
   0 locals| #results |
   s" treeviewhdr.css3" +file   BodyStart
   0 to #results 0 to IDArtistTV 0 to IDAlbumTV
   0 temp$ ! temp$ dup to prevArtist$  to prevAlbum$ 0 to prevArtisCnt 0 to prevAlbumCnt
   search$ count Replace|By\
   GetRangeCatalog: Catalog
      do     search$ count i match-record: Catalog
                if    1 +to #results
                      i GetArtist: Catalog SendArtist
                      i GetAlbum:  Catalog SendAlbum
                      i GetTitle:  Catalog SendTitle
                      #results 4999 >
                        if  HTML| <BR>Search interrupted.<BR>Too many records.<BR>Redefine your search request.| +dstr
                            leave
                        then
                then
      loop
    EndTreeView
    EndCode
 ;


4 value MinimalLenght$

: ReplaceSpaceBy*  ( adr cnt - ) \ Note a space will be received as a "+"
    begin  [char] + scan dup
    while  [char] * 2 pick c!
    repeat
    2drop
 ;

: Replace*BySpace  ( adr cnt - )
    begin  [char] * scan dup
    while  bl 2 pick c!
    repeat
    2drop
 ;

: send-tree-for-artist ( Artist$ cnt - )
   2dup InputSearch$ place
   s" *\" search$ place
   Replace%hex2 search$  +place  s" \"  search$ +place
   send-tree-for-search$
 ;
: send-tree-for-string ( string$ cnt - )
   2dup InputSearch$ place
   dup MinimalLenght$ >=
   if  InputSearch$ count Replace*BySpace  s" *" search$ place
       Replace%hex2 search$  +place
       send-tree-for-search$
   else 2drop
        HTML| <html><body bgcolor="#FEFFE6"><P>| +dstr
        HTML| Enter at least <strong>4</strong> characters in the textbox for a search.| +dstr
        HTML| <br> Back to the | +dstr  HomePageLink$+ HTML| </body> </HTML>| +dstr EndCode
   then
 ;


: SkipFound$ ( Found$ cnt  TotalData$ cnt - Remain$ cnt flag )
   >r dup>r rot swap - + r> r>
    rot /string
 ;

: FindDataInRequest ( SubmitName$ cnt  SubmitName$+Data$ cnt flag - Data$ cnt flag )
    if   SkipFound$
         2dup bl scan nip -
         2dup ReplaceSpaceBy*
         Replace%hex2 true
    else 2nip false
    then
 ;


: FindInDataLine ( str$ cnt - Data$ cnt flag  )
     request  with dstr count endwith param
     2dup 2>r  true w-search 2r> rot FindDataInRequest
 ;


: SendHeader ( - )
  HTML| <HTML>  <head> <style> body {line-height: 24px;} </style> </head>| +dstr
 ;

1 value DefaultSelected
20 value MaxRank

: <BlueInputType ( - )
  HTML| <INPUT TYPE="submit" STYLE="color: #000000; background-color: #e5e5e5;" | +dstr
 ;

10 value #VolumeSteps

: doFindArtist ( -- flag )  \ Handles dial-search
    1 +to #Requests
    url over /dial$ s" /A" istr=  \ Act on /A
       if    2 /string send-tree-for-artist
             true
       else  2drop false
       then
 ;

 doURL doFindArtist http-done

: AddButtonRank ( n - )
   HTML| <INPUT TYPE=HIDDEN NAME="SetRankFor" VALUE="| +dstr
   dup n>record: requests  record>r: catalog (u) +dstr  HTML| ">| +dstr
   HTML| <INPUT TYPE=SUBMIT value=" | +dstr
   1+ (u) +dstr HTML|  "> | +dstr
 ;

: NewCell-C      ( - ) crlf$+ HTML| <td align="center" width="14%">|+dstr ;
: NewCell-L      ( - ) crlf$+ HTML| <td align="left"   width="14%">|+dstr ;
: NewCell-R      ( - ) crlf$+ HTML| <td align="right"  width="14%">|+dstr ;

: EmptyCell    ( - ) NewCell-C HTML| &nbsp;</td>| +dstr ;


: Send-Display-buttons ( - )
   vadr-config AccessLevel c@ Adjust_que 2dup 2>r >=
    if  HTML| <table border="0"  cellpadding="5" width="100%"><tr>| +dstr
        NewCell-L  HTML| <a href="help.html">Help</a>| +dstr
        NewCell-R 2r@ >
           if  HTML| <FORM ACTION="Win32Forth.gci"><INPUT TYPE="HIDDEN" NAME="Continue" VALUE="Continue">| +dstr
               <BlueInputType  HTML| VALUE=" | +dstr s" || --> " +dstr
               HTML| "></FORM></td>| +dstr
           then
        NewCell-L 2r@ >
           if  HTML| <FORM ACTION="Win32Forth.gci"><INPUT TYPE="HIDDEN" NAME="Next" VALUE="Next">| +dstr
               <BlueInputType  HTML|  VALUE=" Next "> </FORM> </td>| +dstr
        then
        NewCell-L 2r> >
            if  HTML| <FORM ACTION="Win32Forth.gci"><INPUT TYPE="HIDDEN" NAME="Volume" VALUE="Volume">| +dstr
                <BlueInputType  HTML|  VALUE=" Volume "> </FORM></td>| +dstr
            then
        EmptyCell    HTML| </tr> </table>| +dstr
     else   2r> 2drop
     then
 ;

: LinkString  ( adr n - )
  HTML|  <a href="SearchString=| +dstr
  2dup +dstr  dup 4 <
    if s" |++" +dstr
    then
  HTML| " > | +dstr
  +dstr HTML| </a>| +dstr
 ;

: Send-Display ( - )
    HTML| <P><table border="1" cellpadding="1" cellspacing="0" width="42%">| +dstr
    HTML| <tr> <td width="100%">| +dstr

    HTML| <P><table border="0" cellpadding="1" cellspacing="0" width="100%">| +dstr
    HTML| <tr> <td  width="100%"><p align="center">| +dstr
    HTML| <font size="4" face="Segoe UI" color="#000000" align="center">| +dstr
    HTML| Status | +dstr GetTime$ +dstr Pausing?
               if    HTML| . Pause: | +dstr
               else  HTML| . Playing:| +dstr
               then
    HTML| <font size="4" face="Segoe UI" color="#0000ff">| +dstr
    HTML| <BR>Artist: <STRONG>| +dstr
             struct, RecordPlaying RecordDef Artist
             struct, RecordPlaying RecordDef Cnt_Artist c@ LinkString
    HTML| </STRONG><BR>Album: <STRONG>| +dstr
             struct, RecordPlaying RecordDef Album
             struct, RecordPlaying RecordDef Cnt_Album c@ LinkString
    HTML| </STRONG><BR>Song: <STRONG>| +dstr
             struct, RecordPlaying RecordDef Title
             struct, RecordPlaying RecordDef Cnt_Title c@ +dstr
    HTML| </STRONG></td> </tr>| +dstr

    HTML| </table>| +dstr

    Send-Display-buttons
    HTML| </td> </tr></table>| +dstr
 ;

: SkipNonAlfa { adr$ n -- adr1$ n1 }
    adr$ n dup 0
        do    adr$ i + c@ ascii A <
             if   1 /string
             else leave
             then
        loop
    dup 0=
       if 2drop adr$ n
       then
 ;


: SendRefreshingHeader ( - )
  HTML| <HTML>  <head> | +dstr
  HTML| <meta http-equiv="refresh" content="10; url=http://192.168.1.71/?.html" />| +dstr
  HTML| <style> body {line-height: 24px;} </style> </head>| +dstr
 ;

: send-status  ( - )
    SendHeader HtmlBodyFont
    BottomLink$+  HTML| <a href="/?.html" target="_top" >Refresh</a> | +dstr
    TopHomePage$+ Send-Display
    HTML| <p> Additions are at the <a href="#_bottom">bottom</a> of the que: <P>| +dstr
    #RequestsInFile 0>
        if  #RequestsInFile 0
              do  crlf$+
                   HTML| <FORM  ACTION="Win32Forth.gci" STYLE="margin: 0px; padding: 0px;">| +dstr
                   i AddButtonRank
                   i GetTitle:  requests  drop SkipNonAlfa +dstr  HTML|  -- | +dstr
                   i GetArtist: requests LinkString \  <br> +dstr
                   HTML| </FORM>| +dstr
              loop
        else HTML| The que is empty.| +dstr
        then
    HTML|  <p> <a name="_bottom"></a> | +dstr
    TopLink$+
    HTML|  <a href="/?.html" target="_top" name="_bottom" >Refresh</a> | +dstr
    TopHomePage$+
    HTML| </p> </font></p> </body> </html> | +dstr
    EndCode
 ;


: <Option-select ( flag - )
   HTML| <option | +dstr
       if    HTML| SELECTED | +dstr
       then
   HTML| value=| +dstr
 ;

: GetHtmlInputValue ( string$ cnt - d1 flag )
   2dup ascii = scan dup>r 2swap r> - (number?)  \ Find number after the '='
 ;

\ Chrome
\  7FE75B | 31 38 38 36 31 36 30 30  3D 26 52 61 6E 6B 46 6F |18861600=&RankFo|
\  7FE76B | 72 6D 3D 33                                      |rm=3| ok

: send-rank-form ( RelIdInQue$ cnt - )
   vadr-config AccessLevel c@ Read_only >
    if (number?)
        if d>s  SendHeader crlf$+  HtmlBodyFont
           HTML| Remove or move in the | +dstr  TopHomePage$+
           HTML| <BR> of: <STRONG>| +dstr
           dup r>record: catalog dup>r RecordDef Artist r@ RecordDef Cnt_Artist c@ +dstr
           HTML| </STRONG><BR>on album: <STRONG>| +dstr
           r@ RecordDef Album r@ RecordDef Cnt_Album c@ +dstr

           HTML| </STRONG><BR>the song: <STRONG>| +dstr
           r@ RecordDef Title r> RecordDef Cnt_Title c@ +dstr

           HTML| </STRONG><BR>to rank: | +dstr  crlf$+
           HTML| <FORM ACTION="Win32Forth.gci" >| +dstr crlf$+
           HTML| <INPUT TYPE=HIDDEN NAME="NewRank| +dstr  (u) +dstr
           HTML| "> | +dstr  crlf$+
           HTML| <SELECT NAME="RankForm| +dstr  HTML| " SIZE="7">| +dstr
           #RequestsInFile MaxRank min 0
             do  crlf$+ i DefaultSelected =
                    if    HTML| <OPTION SELECTED | +dstr
                    else  HTML| <OPTION | +dstr
                    then
                 HTML| VALUE="| +dstr I (u) +dstr HTML| ">| +dstr  I 1+ (u) +dstr HTML| <br>| +dstr
             loop
           crlf$+
           HTML| </SELECT> <P>| +dstr  crlf$+

           <BlueInputType  HTML| value=" Confirm new rank. "> | +dstr
           HTML| <P> <INPUT TYPE="SUBMIT" NAME="Delete" STYLE="color: #FFFFFF; background-color: #DF013A;" | +dstr
           HTML| value=" Remove from que."> </FORM> | +dstr
           HTML| </font></p>  | +dstr
        else 2drop url +dstr crlf$+ GetDataMethod +dstr  HTML|  Bad rank number.| +dstr
        then
      HTML| </body> </html>| +dstr
      EndCode
    else 2drop send-status
    then
 ;

: send-volume-form  ( $ n  - )
   volume@ drop ScaleVol / 2/ locals| VolumeAtLevel |
         HtmlBodyFont TopHomePage$+
         HTML| <P> Choose a new level for the volume.| +dstr
         HTML| <FORM ACTION="Win32Forth.gci" >| +dstr crlf$+
         HTML| <INPUT TYPE=HIDDEN NAME="NewVolume| +dstr
         HTML| "> | +dstr  crlf$+
         HTML| <SELECT NAME="VolumeValue| +dstr  HTML| " SIZE="7">| +dstr
         #VolumeSteps 1+ 0
             do  crlf$+  i VolumeAtLevel =
                    if    HTML| <OPTION SELECTED | +dstr
                    else  HTML| <OPTION | +dstr
                    then
                 HTML| VALUE="| +dstr I (u) +dstr HTML| ">| +dstr  I  (u) +dstr HTML| <br>| +dstr
             loop
         crlf$+
         HTML| </SELECT>| +dstr  crlf$+
         HTML| <P><INPUT TYPE="SUBMIT" value=" Set new volume level "></FORM> | +dstr
         HTML| </font></p>  | +dstr
         HTML| </body> </html>| +dstr
         EndCode 2drop
 ;

: listSearchString  ( name cnt - )
  2dup Replace\By|
    HTML| <BR>- <a href="SearchString=| +dstr
    2dup +dstr HTML| " > | +dstr  2dup Replace|By\ +dstr HTML| </a>| +dstr

 ;

: "listSearchStrings        { \ locHdl typ$ -<name>- }
     max-path LocalAlloc: typ$ "open
        if HTML| </STRONG><BR>Can't open filter. <STRONG>| +dstr drop exit
        then
     to locHdl
        begin   typ$ dup MAXCOUNTED locHdl read-line
                     if    HTML| </STRONG><BR>Read Error. <STRONG>| +dstr
                     then
                0<>
        while   listSearchString
        repeat
     locHdl close-file 3drop
 ;


: ListFilter ( NameFilter$ cnt - )
   SendHeader HtmlBodyFont  BottomLink$+ TopHomePage$+
    HTML| <P>Choose below a search item to see the involved songs.<BR>| +dstr
    temp$ place s" .txt" temp$ +place temp$ count "listSearchStrings
    HTML| <P>| +dstr TopLink$+  TopHomePage$+
    HTML| </font> </body> </html> | +dstr
 ;

:  .fileName ( adr cnt - )
    HTML| <BR>- | +dstr 4 -
    HTML| <a href=":| +dstr 2dup +dstr HTML| "  > | +dstr +dstr HTML| </a>| +dstr
;

: SendFilters ( - )
   SendHeader HtmlBodyFont  BottomLink$+ TopHomePage$+
    HTML| <P>Hit below a filter to see it's content.<BR>| +dstr
   s" *.txt"
        0 total-file-bytes !                         \ reset total-file-bytes
        0 #files !                                   \ reset # of files in dir
        ['] .fileName  ForAllFileNames

    HTML| <p> | +dstr TopLink$+  TopHomePage$+
    HTML| </font> </body> </html> | +dstr
    EndCode
 ;


: SetVolumeWeb ( string$ cnt - )
    vadr-config AccessLevel c@ Adjust_que >
       if   GetHtmlInputValue
               if    d>s 10 * dup Volume!  SetVolBar: TopPane
               else  2drop s" <html><strong>Invallid volume value </strong>" type
               then
       then
    2drop  send-status
 ;

: DeleteEntryFromQue ( - )
   s" *NewRank*Delete*" GetRequest false w-search
      if   s" NewRank" nip /string  GetHtmlInputValue
             if   d>s r>record: catalog dup FindRecord#InRequests: requests
                  if    Delete#Request  3drop RefreshRequests ExpandFirst2Requests
                  else  4drop s" <html><strong>Song not in que.</strong>" type
                  then
             else   4drop s" <html><strong>Song not in que.</strong>" type
             then
      else  2drop s" <html><strong>Bad Rank</strong>" type
      then
 ;

\ >>> GET /Win32Forth.gci?NewRank72204780=&RankForm=1&Delete=*Remove*from*que.* HTTP/1.1  \ Bad Rank
\ GET /Win32Forth.gci?NewRank63946740=&RankForm=1 HTTP/1.1

: move-to-new-rank ( string$ cnt - ) \ From: send-rank-form
   vadr-config AccessLevel c@ Read_only >
   if  GetHtmlInputValue
       if   d>s r>record: catalog dup GetRangeCatalog: catalog swap >record: catalog between
             if    -rot  s" =&RankForm=" nip /string ( relID stringRank )
                   (number?)
                     if   d>s swap FindRecord#InRequests: requests   \ ( ID - position flag )
                           if  dup n>aptr: Requests @ >r
                               1 MoveRequestsUp dup MoveRequestsDown dup r> swap n>aptr: Requests !
                               RefreshRequests ExpandFirst2Requests ExpandAround
                           else  3drop s" <html><strong>Request not in que.</strong>" type
                           then
                     else  3drop DeleteEntryFromQue
                     then
             else  3drop s" <html><strong>Relative ID out of range</strong>" type
             then
       else  2drop s" <html><strong>Bad relative ID</strong>" type
       then
   else 2drop
   then
   send-status
 ;


: Make$Request ( HexNum$ cnt - )
  2dup base @ >r hex (number?) r> base !
     if   d>s dup DeleteDuplicateRequests MakeRequest 2drop
          FinishRequest
          ExpandLast: RequestWindow
          ExpandLast: RequestWindow
          send-status
     else  +dstr HTML| not a valid number.| +dstr
     then
 ;

: doSendStatus ( -- flag )  \ Status
    1 +to #Requests
    url over /dial$ s" /?" istr=  \ Act on /?
       if    2drop send-status
             true
       else  2drop false
       then
 ;

 doURL doSendStatus http-done

: doSendFilters ( -- flag )  \ Status
    1 +to #Requests
    url over /dial$ s" /!" istr=  \ Act on /!
       if    2drop SendFilters \ send-status
             true
       else  2drop false
       then
 ;

 doURL doSendFilters http-done

: doMakeRequest ( -- flag )  \ Handles dial-search
    1 +to #Requests
    url over /dial$ s" /~" istr=  \ Act on /~
       if    2 /string Make$Request
             true
       else  2drop false
       then
 ;

 doURL doMakeRequest http-done

: HandleData ( url$ cnt - flag )
    s" *SearchString1=" FindInDataLine  if  send-tree-for-string     true exit then  2drop
     s" *SearchString=" FindInDataLine  if  send-tree-for-string     true exit then  2drop
       s" *SetRankFor=" FindInDataLine  if  send-rank-form           true exit then  2drop
           s" *NewRank" FindInDataLine  if  ['] move-to-new-rank LockExecute: RightPane                                                                     true exit then  2drop
              s" *Next" FindInDataLine  if   PlayNextRequest
                                            false to Pausing? send-status  true exit then  2drop
      s" *VolumeValue=" FindInDataLine  if  SetVolumeWeb             true exit then  2drop
           s" *Volume=" FindInDataLine  if  send-volume-form         true exit then  2drop
          s" *Continue" FindInDataLine  if  Pause/Resume send-status true exit then  2drop
                s" */:" FindInDataLine  if  ListFilter               true exit then  2drop
     false
 ;


\ doInputData dump
\ 9FC3194 | 2F 68 6F 6D 65 6A 62 34  74 68 2E 68 74 6D 6C 3F |/homejb4th.html?|
\ 9FC31A4 | 53 65 61 72 63 68 53 74  72 69 6E 67 3D 41 72 74 |SearchString=Art|
\ 9FC31B4 | 69 73 74 2B 41 6C 62 75  6D 2B 53 6F 6E 67       |ist+Album+Song| ok

: doInputData ( -- flag )  \ Handles dial-search
  1 +to #Requests  GetDataMethod s" GET" istr=
      if    HandleData
      else  false
      then
 ;

 doURL doInputData  http-done

previous
endwith

also webserver
\ Setup Server
80 httpserver http

0 value #polls

(( Perhaps used in the future.

create monitor$ maxstring allot

: +monitor$ ( adr len n - )
   -rot  monitor$ +place
   (l.int) monitor$ +place monitor$ +Null
;

: Monitor   ( - )  \ ***
      begin   \ StopServer? not
      while   s" www-server: "    monitor$  place
              s" #polls:"         #polls    +monitor$
              s" , #Requests:"    #Requests +monitor$
             \ s" . Send packets:" #pkt      +monitor$
             \ s" , #bytes:"       #bytes    +monitor$
\              monitor$ retitle-forth
              3000 ms
      repeat
\   z" www-server ended"  retitle-forth
 ;  ))

: SetupPaths    ( -- )
   current-dir$ count
   2dup "fpath+  webpath  place  s" \Html\"  webpath +place
 ;

: server-init   ( -- ) http serv-init ;


: www-server    ( -- )
  begin   vadr-config Webserver- c@ not
            if    SuspendThreads: WebserverTasks
            then
          server-init \ server-init gives a virus alert in AVG.
            begin   vadr-config Webserver- c@
            while   1 +to #polls
                    http  serv-poll  20 ms   \ P3600: +/- 50 polls/sec
            repeat
          http  serv-close
  again
 ;


: InitGci
  SetupPaths http setup-http
  ['] www-server Submit: WebserverTasks
\ ['] noop Submit: WebserverTasks   www-server  \ for debugging in the main task ( No console prompt )
 ;

\s
