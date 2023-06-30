\ Anew -ListEditor.f
\ *D doc\classes\
\ *! ListEditor
\ *T ListEditor -- To cache list-controls.

\ *S Abstract


\ *P Can be used to cache list-controls etc with only 4 new commands. \n
\ ** The created files can also be edited with notepad. \n
\ ** Note: A line must end with crlf and its size should not exceed 251 characters. \n
\ ** When a user comand has been executed the file is closed. \n


  (( Disable or delete this line for generating a glossary

cr cr .( Generating Glossary )

needs help\HelpDexh.f  DEX ListEditor.f

cr cr .( Glossary ListEditor.f generated. ) cr 2 pause-seconds bye  ))


Internal \ definitions to support the external commands.

251 constant max-line

map-handle mhndl-file

: "DeleteSearch$  ( adr cnt - NewLength deleted ) { \ vadr left deleted }
     mhndl-file >hfileAddress @ to vadr mhndl-file >hfileLength @
     0 to deleted to left
         begin    2dup vadr left true w-search
         while    1 /string >r dup left over vadr - - r> dup +to deleted /string
                  dup 1+ to left >r swap dup 1- to vadr r> cmove
         repeat
     4drop mhndl-file >hfileLength @ deleted - deleted
 ;

: "DeleteFirstSearch$  ( adr cnt - NewLength deleted ) { \ vadr left deleted }
     mhndl-file >hfileAddress @ to vadr mhndl-file >hfileLength @
     0 to deleted  to left
      vadr left true to CaseSensitive? starting-with?
        if    >r left r@ - to deleted  vadr r> cmove
        else  2drop
        then
      mhndl-file >hfileLength @ deleted - deleted
 ;

126 constant alt-wildcard-char \ To avoid conflicts with existing wildcards in search line.

: invalid-line? ( cnt - cnt flag )  dup 0 max-line 1+ between not ;

: FormSearch$  ( Line$ cnt - search$ cnt2 ) \ For all lines except the first one
    invalid-line? abort" Invalid Line size. (Not between 0 and 252)"
    crlf$ count *buffer place
    alt-wildcard-char *buffer 1+ c!
    *buffer +place
    crlf$ count *buffer +place
    *buffer count
 ;

: FormFirstSearch$  ( Line$ cnt - search$ cnt2 ) \ For the first line
    *buffer place
    crlf$ count *buffer +place
    *buffer count
 ;

: CloseMappedFile ( - )  mhndl-file dup flush-view-file drop close-map-file drop ;
: OpenFileMapped  ( FileName cnt - ) mhndl-file open-map-file throw ;

: ResizeFile ( filename cnt NewLength flag- )
   CloseMappedFile
      if     >r r/w open-file abort" Couldn't open the file to write to"
             r> s>d 2 pick resize-file abort" Can't resize the file"
             FlushCloseFile
      else   3drop
      then
 ;

External \ User commands:

\ *S Glossary

: DeleteLine ( filename cnt Line$ cnt - )
\ *G Delete all lines with the content of Line$ cnt from the specified file.
\ ** Is case sensitive!
    2swap 2>r
    2dup  OpenFileMapped
    alt-wildcard-char to wildcard-char
    2dup  2r@  FormSearch$ "DeleteSearch$ ResizeFile
    2dup  OpenFileMapped
    2r>   FormFirstSearch$ "DeleteFirstSearch$ ResizeFile
    ascii * to wildcard-char
 ;

: AddLine  ( filename cnt Line$ cnt - )
\ *G Adds a line and CRLF at the end of the specified file.
    invalid-line? abort" Invalid Line size. (Not between 0 and 252)"
    2swap w/o open-file abort" Can't open the file to add one line"
    dup>r file-append abort" Can't append to file"
    r@ write-line abort" Can't write to file"
    r> FlushCloseFile
 ;


: ForAllLines  ( Filename cnt cfa - ) { cfa \ locHdl line$ }
\ *G Opens a file and passes the adress and length of each line without CRLF
\ ** to the specified CFA.
    max-path LocalAlloc: line$
    r/w open-file abort" Couldn't open the file to process all lines!" to locHdl
          begin   line$ dup MAXCOUNTED locHdl read-line  abort" Read Error"
          while   cfa execute  \ Needed action of the specified CFA: ( line$ cnt - )
          repeat
    locHdl FlushCloseFile 2drop
 ;

: NewFile  ( Filename cnt- ior )
\ *G Creates a new file.
    r/w create-file swap
    FlushCloseFile
 ;

\ DeleteFile Use: delete-file ( Filename cnt- ior )

previous
\ *Z
\s
