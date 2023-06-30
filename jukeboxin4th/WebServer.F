\ HTTP Web Server

s" apps\Internet\WebServer" "fpath+
needs http
needs httpecho
needs httpmime
needs httpfile

s" E:\BackupData\jukeboxin4thWeb\files\" webpath place
\ s" E:\win32forth\doc\" webpath place
\ 250 mb 4u @ 18 kb/s

\ true cr .s .( to Monitor) to monitor


80 httpserver http
http setup-http
http serv-init

\ Run the Server
: www-server
   cr ." www-server running until escape."
        begin http serv-poll 10 ms key?
                if      key k_esc =
                else    false
                then
        until
    cr ." www-server ended"
 ;

www-server

\ Adres in the browser: http://localhost/homejb4th.html
\ Change localhost by you IP-nr. get it from
\ http://checkip.dyndns.org
\ www-server

