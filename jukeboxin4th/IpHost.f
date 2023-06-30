aNew IpHost.f  \ To retrieve the IP adress of your PC
Needs sock.f

code a>r@      ( a1 -- n1 )
                mov     ebx, 0 [ebx]
                next    c;

: zGetHostIP ( z" -- IP ior )
  dup c@ [char] 0 [char] 9 between over and
  if    call inet_addr 0
  else  call gethostbyname DUP
           if  3 CELLS + a>r@ a>r@ a>r@ 0
           else call WSAGetLastError
           then
  then
;

create my-ip-addr-buf maxstring allot

: SocketsStartup ( -- ior ) pad  257 call WSAStartup ;
: my-ip-addr     ( -- IP ) my-ip-addr-buf zGetHostIP drop ;
: #ip            ( du -- 0 ) #s  [char] . hold  2drop 0 ;


: (.ip)  ( ip -- ip$ u )
  0 256 um/mod 0 256 um/mod 0 256 um/mod
        0 <#   \  0      hold
           #ip #ip #ip #s #> ;

: GetIpHost$  ( -- addr u ) SocketsStartup  drop  my-ip-addr (.IP) ;

\ cr  .( IP: ) GetIpHost$ type abort
\s
