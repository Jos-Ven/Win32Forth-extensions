\ Initial based on Kahn's direct show.
\ Limited to audio only.
\ September 24th, 2011 removed the need for the dshow.tlb file

Anew -DirectShowAudio.f

needs fcom.f
needs struct.f

\ Note: ID3V2tags of mp3 files can disturb the app.

1 constant CLSCTX_INPROC_SERVER

UUID CLSID_FilterGraph {e436ebb3-524f-11ce-9f53-0020af0ba770}
\ UUID CLSID_WMAsfReader {187463A0-5BB7-11D3-ACBE-0080C75E246E}


create eventcode 16 allot

defer ?err
:Noname ( err - )  ?dup  if ( cr ." Error: " ) cr hex u. decimal  then  ; is ?err

sys-warning-off

\ For the **ppvObjects:
IGraphBuilder     ComIFace  pIGraphBuilder->
IMediaEventEx     ComIFace  pIMediaEventEx->
IMediaControl     ComIFace  pIMediaControl->
IMediaSeeking     ComIFace  pIMediaSeeking->
IFileSourceFilter ComIFace  IFileSourceFilter->

sys-warning-on


create UniPfileName$ maxstring 2* 2 cells+ allot
create    PfileName$ maxstring    1 cells+ allot

\ File to play:
: PFileName ( - UniAdr n )
     PfileName$ count 1 max Asc>Uni 2dup UniPfileName$ lplace
     drop free drop UniPfileName$ lcount 2dup + 0 swap ! ;

false value Interfaces?

\ Release can not be in a different word since
\ **ppvObjects are immediate defined and expect an interface or method.

: ReleaseInterfaces ( - )
   Interfaces?
     if   pIMediaControl-> IReleaseRef drop
          pIMediaEventEx-> IReleaseRef drop
          pIGraphBuilder-> IReleaseRef drop
          pIMediaSeeking-> IReleaseRef drop
          false to Interfaces?
     then
 ;

0x10 constant /guid
create *TimeFormatPlay /guid allot
       *TimeFormatPlay /guid erase

: InitDx     ( - )  NULL call CoInitialize   drop ( 1 <> ?err) ;
: StopDx     ( - )       call CoUninitialize     ?err ;
: StopPlay   ( - )  Interfaces?  if pIMediaControl-> Stop     ?err then ;
: EndPlay    ( - )  StopPlay ReleaseInterfaces ;
: PausePlay  ( - )  Interfaces?  if pIMediaControl-> Pause    ?err then ;
: GetStatePlay  ( - state)  Interfaces?  if  -1 sp@ 0 pIMediaControl-> GetState  drop then ;
\ Note: GetStatePlay only returns: 2=playing 1=pause 0=stop

: 100NanoSecond>Seconds ( 100-nanosecond-unitsLow 100-nanosecond-unitsHigh - Seconds )
     d>f 10000000e f/ f>s
 ;

: Seconds>100NanoSecond ( Seconds - 100-nanosecond-unitsLow 100-nanosecond-unitsHigh )
     s>f 10000000e f* f>d
 ;

: Seconds>SecondsMinutes ( Seconds - SecondsLeft Minutes )  60 /mod ;

: GetCurrentPositionPlay ( -  positionLow positionHigh )
     Interfaces?  if   -1 -1 sp@ pIMediaSeeking-> GetCurrentPosition ?err then swap ;

: GetTimeFormatPlay  ( - )
     Interfaces?  if   *TimeFormatPlay pIMediaSeeking-> GetTimeFormat ?err then ;
: GetRatePlay        ( - rateLow rateHigh )
     Interfaces?  if   -1 -1 sp@ pIMediaSeeking-> GetRate ?err then  ;

: MaxDurationPlay    ( DurationLow DurationHigh - DurationLowMax DurationHighMax )
     dup abs 86 >
     if   2drop 0 0 \ Return 0 0 when disturbed
     then
;

: GetDurationPlay    ( - DurationLow DurationHigh )
     Interfaces?
        if   0 0 sp@ pIMediaSeeking-> GetDuration ?err swap MaxDurationPlay
        then
     MaxDurationPlay
 ;

: RunPlay    ( - flag )  Interfaces?
                            if    pIMediaControl-> Run  1 = \ // Run the graph.
                            else  false
                            then  ;

: pIGraphBuilder->queryinterface  (  **ppvObject iid - )
    pIGraphBuilder-> IQueryInterface ?err
 ;


: play  ( adr n - flag ) \ 80040216 = File not found.
   maxstring min 1 max PfileName$ place PfileName$ +null
   pIGraphBuilder-> IGraphBuilder  CLSCTX_INPROC_SERVER 0 CLSID_FilterGraph CoCreateInstance ?err
   pIMediaEventEx-> IMediaEventEx   pIGraphBuilder->queryinterface
   pIMediaControl-> IMediaControl   pIGraphBuilder->queryinterface
   pIMediaSeeking-> IMediaSeeking   pIGraphBuilder->queryinterface
   true to Interfaces?
   null PFileName drop pIGraphBuilder-> RenderFile  ?err  \ 80040256 Nodev
   RunPlay
 ;

\ $80004004  Requested action was canceled. Not ready

0X80040227 CONSTANT  VFW_E_WRONG_STATE \ when the filter graph is not running

: PlayReady? ( - flag )
    Interfaces?
      if    eventcode 0 pIMediaEventEx-> WaitForCompletion VFW_E_WRONG_STATE =
      else  true
      then
    ;

: 100NanoSecond>Time ( 100-nanosecond-unitsLow 100-nanosecond-unitsHigh - Seconds Minutes )
     100NanoSecond>Seconds Seconds>SecondsMinutes
 ;

: DurationPlay  ( - seconds )
    GetDurationPlay 100NanoSecond>Seconds
 ;

: CurrentPositionPlay  ( - seconds )
    GetCurrentPositionPlay 100NanoSecond>Seconds
 ;

defer TimeStats
: PlayStat ( - SecondsDP MinutesdP SecondsCP MinutesCP  )
    GetDurationPlay 100NanoSecond>Time   GetCurrentPositionPlay 100NanoSecond>Time
 ;

' PlayStat is TimeStats

2variable *pCurrent \ High and low will/must be in reversed order
2variable *pStop    \ High and low will/must be in reversed order

: GetPositionsPlay  ( - )
  Interfaces?
    if  *pStop *pCurrent pIMediaSeeking-> GetPositions ?err then
  ;

(( enum AM_SEEKING_SeekingFlags
    {	AM_SEEKING_NoPositioning	= 0,
	AM_SEEKING_AbsolutePositioning	= 0x1,
	AM_SEEKING_RelativePositioning	= 0x2,
	AM_SEEKING_IncrementalPositioning	= 0x3,
	AM_SEEKING_PositioningBitsMask	= 0x3,
	AM_SEEKING_SeekToKeyFrame	= 0x4,
	AM_SEEKING_ReturnTime	= 0x8,
	AM_SEEKING_Segment	= 0x10,
	AM_SEEKING_NoFlush	= 0x20
    } 	AM_SEEKING_SEEKING_FLAGS;
 ))

0x8 constant AM_SEEKING_ReturnTime
0x1 constant AM_SEEKING_AbsolutePositioning
0x4 constant AM_SEEKING_SeekToKeyFrame

: SetPositionsPlay  ( seconds - )
  Interfaces?
    if   >r AM_SEEKING_SeekToKeyFrame       \ Stopfags
         *pStop
         AM_SEEKING_AbsolutePositioning  \ dwCurrentFlags
         r> Seconds>100NanoSecond swap
         *pCurrent 2! *pCurrent
         pIMediaSeeking-> SetPositions ?err
    then
  ;

: nn$      ( n -- addr len )  0 <# # #s #> ;  \ Will be fine for most music

create PlayStat$ 20 allot

: FormatMMSS-PlayStat$  ( m s - )
    nn$ PlayStat$ +place s" :" PlayStat$ +place nn$ PlayStat$ +place
 ;

: MakePlayStat$ ( - addr$ count)
   GetStatePlay 0<> if
   TimeStats 0 PlayStat$ ! FormatMMSS-PlayStat$
   s" /" PlayStat$ +place FormatMMSS-PlayStat$
   then
   PlayStat$ count
 ;


\s
: test ( - ) s" CHIMES.WAV"  play ;

test   .S abort  \s

\s
