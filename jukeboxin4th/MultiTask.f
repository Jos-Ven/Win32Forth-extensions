anew MultiTask.f   \ For XP or better. See the demo at the end for it's use.

\ To handle tasks in chains or indexed tasks.
\ 16-7-2011 Added WaitFor and iTasks

needs task.f

0 proc GetCurrentThread
2 proc SetThreadPriority
0 proc GetCurrentThread
2 proc SetThreadPriority

internal

0 value ValuespMainTask  \ Only to be used to see if a word is running in a subtask
: GetValueSpMainTask ( - UpMainTask )  ValuespMainTask ;
: SetValueSpMainTask ( - )             sp0 to ValuespMainTask ;

initialization-chain chain-add SetValueSpMainTask
SetValueSpMainTask

external

\ The main task is task in which the program initial starts
\ That task should not be terminated by ExitTask, otherwise it will hang the program.
: MainTask? ( - f ) GetValueSpMainTask sp0 = ;

previous

: GetTaskParam ( - param ) MainTask?   if    0    else  tcb @ task>parm  @   then ;
: ExitTask     ( - )       MainTask? not   if  GetTaskParam exit-task   then  ;

: #Hardware-threads ( - #Hardware-threads )
    ( sizeof system_info)  36 LOCALALLOC dup
    ( relative dwNumberOfProcessors) 20  + swap
    call GetSystemInfo drop @
    ;

: SetPriority ( Prio - ) GetCurrentThread SetThreadPriority drop ;
: below       ( -- )    THREAD_PRIORITY_BELOW_NORMAL SetPriority ;

: event-set     ( hEvent - )  Call SetEvent   0= abort" Event not set" ;
: event-reset   ( hEvent - )  Call ResetEvent 0= abort" Event not reset" ;

: event-ms-wait    ( hEvent ms- ) \ wait till a number of MS for an event or object while is NOT set
    swap Call WaitForSingleObject drop ;

: event-wait    ( hEvent - )       \ wait while event or object is NOT set
   INFINITE  event-ms-wait ;

\ Note: In W98 it does not matter if bWaitAll is true or false

: event-set?    ( hEvent - true/false )    \ set/not_set
   0  swap  Call WaitForSingleObject 0=  ;

: make-event-set       ( z"name" - hEvent ) \ In Win32
    false              \ init state      ( seems ignored ? )
    true               \ manuel reset ( seems ignored ? )
    0                  \ lpSecurityAttrib
    Call CreateEvent   \ handle event, the event seems allways NOT set
    dup event-set ;

: make-event-reset     ( z"name" - hEvent ) \ In Win32
    false              \ init state      ( seems ignored ? )
    true               \ manuel reset ( seems ignored ? )
    0                  \ lpSecurityAttrib
    Call CreateEvent   \ handle event, the event seems allways NOT set
    dup event-reset ;


\ Commands for tasks in ONE chain called All-tasks
new-chain  All-tasks

0 value taskcount                        \ The number of tasks
0 value taskblocks

: ForAllTasks      { cfa -- } \ execute the cfa for each task
              All-tasks       \ and use each 'task as parameter
                begin   @ ?dup
                while   dup>r           \ make sure stack is clean during
                        cell+ @ cfa execute \ get the task and execute the cfa
                        r>              \ so parameters can be passed through
                repeat  ;               \ the chain if items being performed



: ForAllTasksIds      { cfa -- } \ execute the cfa for each task
              All-tasks          \ and use it's ID as parameter
                begin   @ ?dup
                while   dup>r           \ make sure stack is clean during
                        cell+ perform cfa execute \ get the taskID and execute the cfa
                        r>              \ so parameters can be passed through
                repeat  ;               \ the chain if items being performed


: add-chain     ( chain_address cfa - )
\ *G Add chain item.
\ ** For normal forward chains, no checks.
                >r                      \ chain_addr    | cfa_of_word_to_add
\in-system-ok   noop-chain-add          \ addr          | cfa
                r> swap ! ;

: AllocateTasks ( - )
    taskcount cells malloc to taskblocks \ cells to hold task blocks ptrs
 ;

\ in each running task, when it does not return to initial the main task.

: RunTask ( TaskId - )
    taskblocks swap cells+ @            \ get the task-block
    run-task drop                        \ run the task
 ;

: run-tasks  ( -- )                        \ run all the tasks
    ['] RunTask ForAllTasksIds
 ;

: pause       ( - )                        call SwitchToThread drop ;
: GetTaskId   ( - TaskId )                 taskcount 1 +to taskcount ;
: >IdTask     ( body  - >id )              2 cells+ ;
: >taskblocks ( TaskId - TaskBlockAdress ) taskblocks swap  cells+ ;
: SuspendTask ( TaskId - )                 >taskblocks @ suspend-task drop  ;
: ResumeTask  ( TaskId - )                 >taskblocks @ resume-task drop ;
: CloseTaskHandle  ( TaskId - )            >taskblocks @ task>handle @ CloseHandle drop ;

\ RunCloseTask For tasks that have to rune one time and perhaps at later again.
: RunCloseTask     ( TaskId  - )           dup RunTask CloseTaskHandle ;

: MakeTask:           \ Compiletime: ( cfa <name> -- )
   create  All-tasks last @ name> add-chain
   GetTaskId , ,
   does> >IdTask @  \ Runtime: ( -- TaskId )
 ;

: InitTask    ( 'IdTask - )
    >body >IdTask  dup @ swap cell+ @
    -dup task-block swap >taskblocks ! ;

: InitTasks ( - )   AllocateTasks ['] InitTask ForAllTasks  ;

: Suspend-tasks  ( -- )  \ Suspends all tasks
   ['] SuspendTask ForAllTasksIds
 ;

: Resume-tasks  ( -- )  \ Resume all tasks
   ['] ResumeTask ForAllTasksIds
 ;

\ End of tasks in a chain


winerrmsg on

: #Todo \ RangeFor To construct:     do  i  cfa   loop    \ Runtime: ( limit start - )
   s" do  i " evaluate
   ' compile,  \ compiletime: ( <compile-next-cfa> )  Runtime expects of cfa: ( index -  )
   s" loop " evaluate
   ; immediate

\ : test 10 0 #Todo . ; cr  see test cr test abort


:Class iTasks    <Super Object
\ In this class all tasks are indexed and handeld in one go.
\ Do NOT use commands from the tasks in a chain when using commands from the iTaks
\ ALL tasks should handle their own data. No locking provided.
\ Taskblocks are allocated in the heap.
\ When all tasks are ready that memory is NOT automatic released
\ The number of tasks can also be overwritten when Parallel: is not used.
\ Each task can get its index by using GetTaskParam
\ GetTaskParam can be used to target a value in an array.


    int Taskblocks    \ cells to hold task blocks ptrs
    int #Tasks        \ Number of tasks to use.
    int wait-hndls    \ cells to hold task handles for wait function
    int #wait-hndls   \ Number of used wait-hndl
    int Ranges        \ Allocated ranges.
    int OnlyOneThread \ Forcing to use 1 thread only for testing
    2 cells bytes TotalRange

: >range    ( n - adr )     2 cells  * Ranges + ;
: TaskIndex ( - #Tasks 0 )  #Tasks 1 max 0 ;

:M GetRange: ( n -- High Low )
     #Tasks
        if    >range dup>r  @ r> cell+ @
        else  drop TotalRange 2@
        then
;M

:M GetTaskcount: ( -- #Tasks )     #Tasks ;M
:M PutTaskcount: ( #Tasks -- )     dup to #Tasks to #wait-hndls ;M
:M Putrange:     ( High Low n -- ) >range dup>r  cell+ ! r> ! ;M


: SaveWaitHandle ( n -- )
    taskblocks over cells+ @              \ get the taskhandle
    task>handle @ wait-hndls rot cells+ ! \ save in wait handle
 ;

: CloseTaskHandle  ( n -- )
   taskblocks swap cells+ @
   task>handle @    call CloseHandle drop
 ;

: cr-dup.        ( n - n ) cr dup . ;
: .range         ( n - )   cr-dup. GetRange: Self  swap . .  ;
: .WaitHndl      ( n - )   cr-dup. wait-hndls swap cells+ ? ;
: .TaskHndl      ( n - )   cr-dup. taskblocks swap cells+ @ task>handle ? ;


:M .Ranges:          ( -- )     TaskIndex #Todo .range cr  ;M
:M .TaskHndls:       ( -- )     TaskIndex #Todo .TaskHndl cr ;M
:M .WaitHndls:       ( -- ) #wait-hndls 0 #Todo .WaitHndl cr ;M
:M CloseTaskHandles: ( -- )     TaskIndex #Todo CloseTaskHandle ;M
: SaveWaitHandles    ( -- ) #wait-hndls 0 #Todo SaveWaitHandle  ;


:M SetRanges:  { High low -- }
     High low - #Tasks dup>r  / r> 0
         do      High dup>r over - dup  to High r> swap i Putrange: Self
        loop
    low #Tasks 1- >range cell+ ! drop
 ;M


:M MallocWaitHndls: ( #wait-hndls -- )
     dup to  #wait-hndls
     cells MALLOC to wait-hndls  \ cells to hold task handles for wait function
    ;M

:M MallocTasksArrays: ( -- )
   taskblocks 0=
    if  #Tasks 1 max dup>r cells MALLOC to taskblocks   \ cells to hold task blocks ptrs
        r@ cells 2 * MALLOC to Ranges  \ cells to hold the defined ranges for each task. Map: High low
        r> MallocWaitHndls: Self       \ Allocates handles for wait function
    then
   ;M

:M Make-iTask:   ( 'my-task n -- )  \ Store 'my-task in the taskblock
    dup>r                           \ Index number for my-task
    swap task-block                 \ create the task block
    taskblocks r> cells+ !          \ save 'my-task in the taskblocks area
   ;M

: make-tasks   ( 'my-task -- )     \ create the task blocks
    TaskIndex
      do    dup i Make-iTask: Self
      loop  drop
    ;

: GetTaskblock  ( n - taskblock )  taskblocks swap cells+ @  ;
: RunTask       ( n -- )  GetTaskblock  run-task    drop  ;
: CreateTask    ( n -- )  GetTaskblock  create-task drop  ;

: RunTasks      ( -- )    TaskIndex  #Todo RunTask     ;  \ Run all the tasks
: CreateTasks   ( -- )    TaskIndex  #Todo CreateTask  ;  \ In a suspended state

:M ResumeTask:   ( n -- ) GetTaskblock  resume-task  drop ;M
:M StopTask:     ( n -- ) GetTaskblock  stop-task    drop ;M
:M SuspendTask:  ( n -- ) GetTaskblock  suspend-task drop ;M

:M StopTasks:    ( -- )   TaskIndex  do  i StopTask: Self    loop ;M
:M SuspendTasks: ( -- )   TaskIndex  do  i SuspendTask: Self loop ;M
:M ResumeTasks:  ( -- )   TaskIndex  do  i ResumeTask: Self  loop ;M



: WaitForMultipleObjects { ms wait array count -- res } \ Must deal with messages
        begin QS_ALLINPUT ms wait array count call MsgWaitForMultipleObjects
        dup WAIT_OBJECT_0 count + = while drop winpause repeat ;

:M WaitForAlltasks: { \ taskwaits }
        #wait-hndls to taskwaits
        begin
          taskwaits
        while
          INFINITE false wait-hndls           \ wait for 1 or more tasks to end
          taskwaits  WaitForMultipleObjects   \ wait on handles list
          dup WAIT_FAILED = if getlastwinerr then \ note the error
          WAIT_OBJECT_0 +  >r
          -1 +to taskwaits                    \ 1 fewer task, clean up the list
          wait-hndls taskwaits cells+ @       \ get last handle in list
          wait-hndls r@ cells+ !              \ store in signaled event ptr
          taskblocks taskwaits cells+ @       \ get last block in list
          taskblocks r> cells+ !              \ store in signaled block
        repeat
\        ." All tasks completed" cr
    ;M

:M StartTasks: ( 'my-task -- ) \ Each task gets an index as its parameter
     make-tasks   CreateTasks  SaveWaitHandles  ResumeTasks: Self
     WaitForAlltasks: Self
     CloseTaskHandles: Self
    ;M

:M Max#Tasks:  ( -- #Tasks )  #Hardware-threads 2 max ;M \ 2 max for older cpu's
:M UseOneThreadOnly:  ( -- )  true to OnlyOneThread   ;M

:M SetParallelItems: ( limit IndexLow - )
    Max#Tasks: Self 2 pick min  OnlyOneThread
       if     drop 1     \  Force 1 thread when OnlyOneThread is true
       then   dup to #Tasks to #wait-hndls \ PutTaskcount: Self
    MallocTasksArrays: Self   \ Allocates the tasks, wait-hndls and ranges when not done
    SetRanges: Self
  ;M

:M Parallel: ( limit IndexLow cfa -- )
\ Executes the specified cfa in a number of tasks.
\ The number of tasks depend on the number of hardware threads and
\ the specified range in limit and IndexLow.
\ Parallel: returns when all threads that were started are ready
\ Each task can get it's range by using GetRange:
\ Each range can be passed to a do..loop or #Todo
     -rot SetParallelItems: Self  StartTasks: Self
  ;M

:M Single: ( limit IndexLow cfa -- ) \ For debugging while running in the maintask
   -rot TotalRange 2! execute
  ;M

:M ClassInit:  ( -- )  ClassInit: super 0 to taskblocks  false to OnlyOneThread ;M

:M ReleaseTasksArrays:    ( -- )
     #Tasks
       if  0 to #Tasks
           taskblocks release 0 to taskblocks    \ Release taskblocks
           Ranges     release 0 to Ranges        \ Release Ranges
           wait-hndls release 0 to wait-hndls    \ Release wait-hndls
       then
  ;M

;Class


 (( \ Disable or delete this line to run a demo of tasks in a CHAIN.

: Beeper            ( - )    begin   beep  500 ms  again ;
' Beeper MakeTask: IdTaskBeeper

0 Value Counter1
: IncrementCounter1  ( - )    1 +to Counter1 350 ms ;
: TaskCounter1       ( - )    begin   IncrementCounter1    again ;
' TaskCounter1 MakeTask: IdTaskCounter1

0 Value Counter2
: IncrementCounter2  ( - )    2 +to Counter2 150 ms ;
: TaskCounter2       ( - )    begin   IncrementCounter2    again ;
' TaskCounter2 MakeTask: IDTaskCounter2

: Show-counters ( - )  \ Hit any key to stop showing the counters
    begin  cls Counter1 . ."  " Counter2 . 100 ms
           key?
    until
   cr ." Also try: Suspend-tasks Resume-tasks and Show-counters" cr
 ;

InitTasks run-tasks  Show-counters

\s  ))


 (( \  Disable or delete this line for a demo of indexed tasks in a OBJECT


0e fvalue ft0

: value-ft0
   ms@ 0e fto ft0
       begin  200e ft0 f+ fto ft0
              ms@ over 400 + >
       until drop  ;

TIMER-RESET
value-ft0 ft0 f>s 3 * value #counts    \ To get a runtime for about 8 - 20 seconds

 iTasks myTasks


: my-task ( - )              \ Increments a value at PAD
    Below  0 pad !   #counts 0
      do   1 pad +!
      loop
    ExitTask \ Needed to exit a subtask
       ;

: .Analyse#Counts  ( - )
     cr ." All tasks ended."
     MS@ START-TIME - space .ELAPSED space
     cr ." Total counts: " #counts s>f GetTaskcount: myTasks s>f f* fdup e.
     s>f  1000e  f/
     cr ." counts / second: " f/ g.
 ;

: find-elapsed-times  ( n -- )  \ Setting the number of tasks by hand.
    GetTaskcount: myTasks 1+ 1
        do    cr cr ." Main task is waiting for " i dup . ." task" 1 >
                 if     ." s"
                 then
              i  PutTaskcount: myTasks   \ Set the number of tasks to be used
              ['] my-task TIMER-RESET  StartTasks: myTasks  \ start the tasks
              .Analyse#Counts
       loop
    ;

: .elapsed-results
     cls
     #Hardware-threads 3 + PutTaskcount: myTasks  \ Number of tasks to test. Skip task 0.
     MallocTasksArrays: myTasks
     ." ImpactThreads: Finding the overall speed for" cr  ." parallel running counters using "
     #Hardware-threads . ." hardware threads."
     cr ." Wait till the end of the demo..."
     find-elapsed-times
     ReleaseTasksArrays: myTasks
     cr ." End of demo."
 ;

  .elapsed-results  abort \s ))



  (( \ Disable or delete this line for the Range test.

 iTasks myTask


create results #Hardware-threads 2 max cells allot

: my-range-task  ( - ) { \ index }
   GetTaskParam  to index
   Below   index results index cells+ ! \ Will be overwritten
   GetRange: myTask                     \ Get the range for the do -- loop  for the running task
       do    i results index cells+ !
       loop
   ExitTask   \ Needed to exit a subtask
       ;

\ Just ONE line is needed to distribute data and execute a word in a parallel way
\ using all the hardware threads.

: range-test ( -- ) \ Setting the number of tasks automatically by using the word Parallel:
 \  UseOneThreadOnly: myTask   \ Optional for testing. Note: You can not use the debugger in a task

  170 0  ['] my-Range-task  Parallel: myTask  \ Start a number of tasks using all hardware threads when possible.

\ 170 0  ['] my-Range-task  single: myTask  \ single: instead of Parallel: for debugging

  cr cr ." Task ID's and ranges:"           .Ranges: myTask
        ." Number of used tasks: "          myTask.#Tasks .
  cr    ." Indexes in the array results: "  myTask.#Tasks 1 max 0    do    results i cells+ ?   loop
  ReleaseTasksArrays: myTask                \ Release the allocated task arrays when ready
;

  range-test abort \s ))

\s

