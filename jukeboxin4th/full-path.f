Anew -full-path.f
\s
: full-path     { a1 n1 path \ searchpath$ filename$ current$ -- a2 n2 f1 }
\ *G Find the file \i a1,n1 \d in the path \i path \d and return the full path.
\ ** \i a2,n2 \d . \i f1 \d = false if successful.
                a1 n1 MAX-PATH 1+ LocalAlloc ascii-z to filename$ \ save file name

                MAX_PATH 1+ LocalAlloc: current$
                current$ save-current \ save current dir

                MAX-PATH 1+ LocalAlloc: searchpath$

                path first-path"
                begin dup
                      if    searchpath$ place searchpath$ +null

                            searchpath$ volume-indication?   \ Test for another volume
                            if   searchpath$ char+ $current-dir!  \ 0 fails, then try next
                            else true
                            then

                            if   path-file$ off
                                 0                 \ file component
                                 path-file$        \ found file name buffer
                                 max-path          \ size of buffer
                                 defextz$          \ file extension
                                 filename$         \ file name
                                 searchpath$ char+ \ search path
                                 call SearchPath 0<>
                                 if   path-file$ zcount false   \ path found
                                      current$ restore-current  \ restore current dir
                                      exit                      \ and exit
                                 else true \ try next path...
                                 then
                            else true \ $current-dir! faild. try next path...
                            then
                       else nip
                       then
                while  path next-path"
                repeat

                current$ restore-current \ restore current dir
                a1 n1 true ;  \ return input file and error flag

cr .( FULL-PATH will be updated in the next version of Win32Forth. ) cr

\s
