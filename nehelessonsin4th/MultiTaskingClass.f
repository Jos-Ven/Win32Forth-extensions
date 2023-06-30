anew MultiTaskingClass.f   \ For XP or better. See the demos at the end for its use.

\ *D doc\classes\
\ *! MultiTaskingClass
\ *T MultiTaskingClass -- For clustered tasks in objects.

\ *S Abstract

\ *P CPU's with multiple cores can execute a program faster than cpu's with a single core. \n
\ ** This is done by breaking up a program in smaller pieces and than execute all pieces simultaneously. \n
\ ** In multiTaskingClass.f this idea is supported as follows: \n
\ ** Breaking up is possible at the definition level or at the program level by the 2 classes \biTask\d and \bwTask\d. \n
\ ** Then the pieces are submitted and simultaneously executed in a number of tasks. \n
\ ** Tasks are clustered in an object for easy access.

\ *P Objects defined with \biTask\d can be used as soon as ONE definition should be executed in a parallel way
\ ** and the definition uses a do...loop. \n
\ ** The method \iParallel:\d  divides, distributes and submits for execution the specified cfa over a number of tasks. \n
\ ** A started task can pickup its range for the do...loop part by using the method \iGetTaskRange:\d \n
\ ** The initialization of the objects defined with iTask is automatic. \n
\ ** It is possible to change the number of simultaneous tasks before they run.

\ *P Objects defined with \bwTask\d can be used to execute concurrently one or more different definitions. \n
\ ** These objects must be initialized with the method \iStart:\d \n
\ ** The method \iStart:\d takes the number of simultaneous tasks as a parameter. \n
\ ** It does not start any task. \n
\ ** Use the method \iSubmitTask:\d for starting a definition as a task. \n
\ ** When a new task is submitted and the maximum number of simultaneous tasks is reached the following will happen: \n
\ ** 1) The system will wait till one or more tasks are complete. \n
\ ** 2) Then it will submit the task. \n
\ ** At this moment the system is limited to 63 simultaneous tasks for each taskobject
\ ** that is defined with wTask or iTask.

\ *P Tasks of both classes will get their parameters at the start on the stack
\ ** as soon as the method \iTo&Task:\d is used just before the task is submitted. \n
\ ** MultiTaskingClass.f uses preemptive multitasking system of windows. No need to use pause. \n

\ History:
\ To handle tasks in an object.
\ 16-07-2011 Added WaitFor and iTasks
\ 07-03-2012 Added Putrange: GetTaskRange: SubmitTasks: UseOneThreadOnly:
\                  UseALLThreads: and &Timers for each task in the object iTask
\ 29-05-2012 Moved the task-block out of the dictionary for the taskobjects and
\            added cells+@ cells+! waitobject wTask and a demo for wTask.
\            A wTask allows you to submit one or more words as a task by passing its CFA
\            to the task object.
\            Removed the tasks in a chain. The object wTask does this better and easier.
\            ExitTask is now handled by the objects. Remove ExitTask from your code when it is still there.
\            Added task>cfa and task>&StkParams to the task-block
\            Now maximal 8 parameters can be passed to a task without much overhead. (Can be changed)
\            All in all it means that many definitions are now able to run
\            in a submitted task without having to change the submitted definition.
\            Renamed MultiTask.f to MultiTaskingClass.f
\ 23-9-2012  Added a lock-demo and the classes LockObject and sTask.
\            The methods SubmitTask: and Parallel: are now protected by a lock to prevent a crash when they
\            are used by a re-entry at the same time.



  (( Disable or delete this line for generating a glossary

cr cr .( Generating Glossary )

needs help\HelpDexh.f  DEX MultiTaskingClass.f

cr cr .( Glossary MultiTaskingClass.f generated )  cr 2 pause-seconds bye  ))


winver winxp < [if] cr cr .( MultiTaskingClass.f needs at least Windows XP.) cr abort [then]

needs task.f

\ *S Glossary

code cells+@  ( a1 n1 -- n ) \
\ *G Multiply n1 by the cell size and add the result to address a1
\ ** then fetch the value from that address.
                pop     eax
                lea     ebx, 0 [ebx*4] [eax]
                mov     ebx, 0 [ebx]
                next    c;

code cells+!  ( n a1 n1 -- )
\ *G Multiply n1 by the cell size and add the result to address a1
\ ** then store the value n to that address.
                pop     eax
                lea     ebx, 0 [ebx*4] [eax]
                pop     [ebx]
                pop     ebx
                next    c;

0 proc GetCurrentThread
2 proc SetThreadPriority
0 proc GetCurrentThread
2 proc SetThreadPriority

256 value stacksize

internal

0 value ValuespMainTask  \ Only to be used to see if a word is running in a subtask
: GetValueSpMainTask ( - UpMainTask )  ValuespMainTask ;
: SetValueSpMainTask ( - )             sp0 to ValuespMainTask ;

initialization-chain chain-add SetValueSpMainTask
SetValueSpMainTask

external

: MainTask? ( - flag )
\ *G The main task is the task in which the program initial starts. \n
\ ** MainTask? returns true when it runs in the main task.
    GetValueSpMainTask sp0 = ;

previous

: GetTaskParam ( - IDindex )
\ *G Each task get an index. GetTaskParam returns that index.
\ ** GetTaskParam in a task can be used to target a value in an array.
    MainTask?   if    0    else  tcb @ task>parm  @   then ;

: #Hardware-threads ( - #Hardware-threads )
\ *G  Returns the number of hardware threads found in the CPU.
    ( sizeof system_info)  36 LOCALALLOC dup
    ( relative dwNumberOfProcessors) 20  + swap
    call GetSystemInfo drop @
  ;

: SetPriority ( Prio - )
\ *G Changes the priority of the task.
    GetCurrentThread SetThreadPriority drop ;

: below       ( -- )
\ *G Lowers the the priority of the task in order to keep the main task responsive to the mouse etc.
    THREAD_PRIORITY_BELOW_NORMAL SetPriority ;

winerrmsg on

: #do  \ Compiletime: ( <name> -- )  Runtime: ( limit start - )
\ *G To construct:     do  i  cfa   loop \n
\ ** EG: \n
\ ** : test  10 0   #do . ; \n
\ ** Will be compiled as: \n
\ ** : TEST  10 0    DO  I . LOOP    ; \n
    s" do  i " evaluate
           ' compile,  \   Runtime expects of the compiled cfa: ( index -  )
    s" loop " evaluate
  ; immediate

\ : test 10 0 #do . ; cr  see test cr test abort

: .cr ( n - ) . cr ;


:Class LockObject    <Super Object
\ *G To excute words that are not allowed to run simultaneously by several tasks.
\ ** The Initialization is automatic.

Record: critical_section
    int  LockCount
    int  RecursionCount
    int  OwningThread
    int  LockSemaphore
    int  SpinCount
;Record


:M .Lock:          ( -- )
 cr .time ."  Lock:" cr
    ." IDLockCount: "    LockCount      .cr \ thread ID that owns this critical section.
    ." RecursionCount: " RecursionCount .cr \ the number of times that the owning thread has acquired this critical section
    ." OwningThread: "   OwningThread   .cr \ identifier for the thread that currently holds the critical section
    ." LockSemaphore: "  LockSemaphore  .cr \ handle used to signal the operating system that the critical section is now free
    ." SpinCount: "      SpinCount      .cr \ the spin count for the critical section object. Might be 0, but must be allocated
 ;M

:M TryLock:       ( -- fl )
\ *G Attempts to enter a critical section without blocking. If the call is successful,
\ ** the calling thread takes ownership of the critical section
\ ** increments the lock count and return true. \n
    critical_section  call TryEnterCriticalSection 0<> ;M

:M Lock:          ( -- )
\ *G If another thread owns the lock wait until it's free,
\ ** then if the lock is free claim it for this thread,
\ ** then increment the lock count.
    critical_section call EnterCriticalSection drop 1 ms \ 1 ms is needed for a proper lock.
 ;M                                                      \ Do not use WaitForSingleObject here

:M Unlock:        ( -- )
\ *G Decrement the lock count and free the lock if the resultant count is zero.
   critical_section call LeaveCriticalSection drop
 ;M

:M MakeLock:   ( -- )
\ *G Initialize the criticalSection. Is an automatic operation.
    0 critical_section call InitializeCriticalSectionAndSpinCount drop  \ Needs XP or better
  ;M

:M LockExecute: ( cfa - )
\ *G Locks, executes and unlocks the specified cfa.
\ ** When more than 1 task try to use LockExecute: of the same object
\ ** the next task will be executed after the previous task is ready.
    Lock: Self   execute    UnLock: Self ;M

:M DeleteLock: ( -- )
\ *G deletes the critical section.
   critical_section call DeleteCriticalSection drop
  ;M

:M ClassInit:  ( -- )
\ *G Initializes the object.
    ClassInit: Super
    MakeLock: Self
  ;M

;Class



:Class WaitObject    <Super LockObject
\ *G Handles the waiting of one or more handles.

\ ** Settings in the WaitObject :
\ *L
\ *| Name:        | Use:                                                     |
\ *| &wait-hndls  | -- Cells to hold task the handles for the wait function. |
\ *| #wait-hndls  | -- The Number of used &wait-hndls.                       |
\ *| taskwaits    | -- The number of handles not ready.                      |

    int &wait-hndls     \ cells to hold task handles for wait function.
    int #wait-hndls     \ Number of used &wait-hndls.
    int taskwaits       \ The number of handles not ready

: WaitForMultipleObjects { ms wait array count -- res }
\ *G Waits till one or more handles are ready and deals with messages.

\ ** Parameters:
\ *L
\ *| Name: | Use:                                                                        |
\ *| ms    | -- The time-out interval time in milliseconds to test if a handle is ready. |
\ *| wait  | -- When to return.                                                          |
\ *| array | -- An array of object handles.                                              |
\ *| count | -- The number of object handles in the array.                               |
\ *| res   | -- The event that caused the defintion to return.                           |
    begin   QS_ALLINPUT ms wait array count call MsgWaitForMultipleObjects
            dup WAIT_OBJECT_0 count + =
    while   drop winpause
    repeat
 ;

:M GetTaskwaits: ( - taskwaits )
\ *G Returns the number of handles still waiting.
    taskwaits ;M

:M MallocWaitHndls: ( #wait-hndls -- )
\ *G Allocates the array for the object handles. 63 is the maximum.
    dup MAXIMUM_WAIT_OBJECTS >= abort" Too many wait handles. 63 is the maximum."
    dup to  #wait-hndls
    cells MALLOC to &wait-hndls       \ cells to hold object handles for the wait function
  ;M


;Class


7 cells constant MinimumSizeTaskblock    \ Minimum size of a task block
8 constant /StkParams                    \ The maximum number of parameters to pass to a Task
/StkParams 2 + cells newuser &StkParams  \ To pass parameters to a task.
                                         \ The first cell is resevered for a long count

: Reset&StkParams ( - )
\ *G Sets the long count of &StkParams to 0.
     0 &StkParams ! ;

initialization-chain chain-add Reset&StkParams
Reset&StkParams

\ *P General parameters for all tasks:
\ *L
\ *| Name:      | Use:                                                                 |
\ *| MinimumSizeTaskblock | -- Minimum size of a task block. Default is 7 cells.       |
\ *| /StkParams | -- The maximum number of parameters to pass to a Task. Default is 8. |
\ *| &StkParams | -- An array in the user area to pass parameters to a task.           |

:Class TaskPrimitives    <Super WaitObject
\ *G Contains the general definitions for a task object.

    int #Tasks          \ The maximum number of simultaneously tasks in use in the object.
    int /Taskblock      \ The size of one Task-block.
    int &Taskblocks     \ The taskblock array.
    int OnlyOneThread   \ A flag used to force to use 1 thread only for testing
    int &Timers         \ An array of elapsed &Timers

\ ** Settings in the objects defined with TaskPrimitives:
\ *L
\ *| Name:           | Use: |
\ *| #Tasks          | -- The maximum number of simultaneously tasks in use in the object.      |
\ *| /Taskblock      | -- The size of one Task-block.                                           |
\ *| &Taskblocks     | -- The taskblock array.                                                  |
\ *| OnlyOneThread   | -- A flag used to force to use 1 thread only for testing.                |
\ *| &Timers         | -- An array of elapsed &Timers                                           |

: GetTaskblock     ( IDindex - taskblock )
\ *G Returns the adres of the taskblock array for its index.
    s" /Taskblock  * &Taskblocks + " EVALUATE ; IMMEDIATE

: task>cfa         ( tcb - task>cfa )
\ *G Returns the address of the CFA to be executed from the taskblock.
    5 cells+ ;

: task>&StkParams  ( tcb - task>&StkParams )
\ *G Returns the address of the parameters for a task. The first cell contains its count.
    6 cells+ ; \ pointer to &Task

: ExitTask         ( - )
\ *G To exit a task. \n
\ ** ExitTask releases the except-Buffer and calls ExitThread.
    MainTask? not   if  GetTaskParam exit-task   then  ;

:M To&Task:  ( ... n  --  )
\ *G To pass maximal 8 parameters to a task through &StkParams.
    dup &StkParams  !  &StkParams  dup @ 1+ cells+ swap dup /StkParams >
    abort" Too many parameters for the task. " 0
       do     1 cells- dup>r ! r>
       loop
     drop
  ;M

:M Take&StkParams: { &Adr --  CountTo&Task... }
\ *G Puts the parameters from &StkParams on the stack in the running task.
    &Adr @ 0
       do &Adr i 1+ cells+ @
       loop
    0 &Adr ! \ Reset the count
  ;M

: ExecuteTaskExit  ( -- )
\ *G Will run first in any task.
\ ** ExecuteTaskExit takes the parameters, puts them on the stack, execute the task and exits the task.
    tcb @ dup>r
    task>&StkParams @ dup @ 0>    \ Look for parameters
      if    Take&StkParams: Self  \ Takes the parameters from &StkParams on the stack
      else  drop
      then
    r> task>cfa @ execute    \ execute the cfa
    exittask                 \ exit the task
  ; \ Exit the task when ready

: WhenTasksInRange   ( #Tasks  - #Tasks )
\ *G Continuous when the #Tasks is smaller then MAXIMUM_WAIT_OBJECTS.
    dup MAXIMUM_WAIT_OBJECTS
    >= abort" Too many simultaneously tasks. 63 is the maximum."
 ;

:M GetTaskcount:  ( -- #Tasks )
\ *G Returns the maximum number of simultaneously tasks in use.
    #Tasks ;M

:M Max#Tasks:     ( -- #Tasks )
\ *G When the maximum number of hardware threads is less than 64
\ ** it returns the number of hardware threads. \n
\ ** Else it returns 63. \n
\ ** It returns 2 for older cpu's. Can be overwritten
    #Hardware-threads 2 max  maximum_wait_objects 1- min
  ;M

:M Make-iTask:   ( cfa IDindex -- )
\ *G Makes one task and stores the task ID
\ ** and the cfa in the taskblock
    ['] ExecuteTaskExit over GetTaskblock dup>r !
    r@ task>parm !
    &StkParams r@ task>&StkParams !
    r> task>cfa !
  ;M

: CreateTask    ( IDindex -- )
\ *G Creates the task for windows using its taskblock.
    GetTaskblock  create-task  drop  ;

: SaveWaitHandle ( IDindex -- )
\ *G Save the taskhandle in the wait-handle array.
    dup GetTaskblock task>handle @    \ get the taskhandle
    &wait-hndls rot cells+!           \ save the wait handle
 ;

: TaskIndex          ( - #Tasks 0 )
\ *G Returns 0 and the maximum number of simultaneously tasks in use by the object.
    #Tasks 1 max 0 ;

: SaveWaitHandles    ( -- )
\ *G Save the taskhandles, in use in the object, in the wait-handle array.
    #wait-hndls 0 #do SaveWaitHandle  ;

: CreateTasks        ( -- )
\ *G Creates the tasks, in use in the object, for windows using their taskblock.
     TaskIndex  #do CreateTask  ;  \ In a suspended state

:M SuspendTask:      ( IDindex -- )
\ *G Suspend the task with the specified ID.
    GetTaskblock  suspend-task drop ;M

:M ResumeTask:       ( IDindex -- )
\ *G Resumes the task with the specified ID.
    GetTaskblock  resume-task  drop ;M

:M SuspendTasks:     ( -- )
\ *G Suspend all active tasks in use by the object.
    TaskIndex  do  i SuspendTask: Self loop ;M

:M ResumeTasks:      ( -- )
\ *G Resume all active tasks in use in the object by the object.
    TaskIndex  do  i ResumeTask: Self  loop ;M

:M UseOneThreadOnly: ( -- )
\ *G Overwrite the number of simultaneously tasks in use by the object.
\ ** Use it before submitting a task.
    true to OnlyOneThread  ;M

:M UseALLThreads:    ( -- )
\ *G To overwrite UseOneThreadOnly:. Is default.
    false to OnlyOneThread ;M

:M GetTaskblockSize: ( - Size )
\ *G Returns the taskblock size.
    /Taskblock  ;M


:M #ActiveTasks:  { \ lpExitCode } ( - #ActiveTasks )
\ *G Returns the number active tasks in the object.
    0 &Taskblocks 0<>
        if TaskIndex
             do  i GetTaskblock task>handle @ dup 0<>
                 if 0 swap call WaitForSingleObject WAIT_TIMEOUT =
                    if   1+
                    then
                 else drop
                 then
             loop
        then
  ;M

:M SetTaskblockSize:  ( NewSize - )
\ *G Sets a new size for the task block.
    #ActiveTasks: Self abort" Active tasks detected. Can't resize /StkParamsblock."
    MinimumSizeTaskblock over > abort" The minimal taskblock size is 7 CELLS."
    to /Taskblock
  ;M

: make-tasks   ( cfa -- )
\ *G Makes all the tasks in use by the object and create their taskblocks.
    TaskIndex
      do    dup i Make-iTask: Self
      loop
    drop
   ;

: Init-Tasks ( cfa -- )
\ *G Initializes all the tasks. Start Nothing.
    make-tasks   CreateTasks  SaveWaitHandles ;

:M ClassInit:  ( -- )
\ *G Initializes the object.
    ClassInit: super
    0 to &Taskblocks
    MinimumSizeTaskblock SetTaskblockSize: Self
    false to OnlyOneThread
  ;M

;Class


:Class iTasks    <Super TaskPrimitives
\ *G For a number of tasks that run ONE definition parallel at the same time. \n
\ ** In this class all tasks are indexed and handeld in one go.  \n
\ ** ALL tasks should handle their own data.  \n
\ ** The Task-blocks are allocated in the heap.  \n
\ ** When all tasks are completed the allocated memory is NOT
\ ** released and can be used again. \n
\ ** The number of tasks can also be overwritten when there are notasks active. \n
\ ** Each task can get its index by using GetTaskParam. \n
\ ** GetTaskParam can be used to target a value in an array.

    int &Ranges                \ Pointer to an array of allocated Ranges.
    2 cells bytes TotalRange

\ *P Settings in objects defined with iTasks also include:
\ *L
\ *| Name:      | Use: |
\ *| &Ranges    | --- Pointer to an array of allocated ranges in the object.    |
\ *| TotalRange | --- 2 cells containing the total of all ranges in the object. |

: >range    ( TaskParam - adr )     2 cells  * &Ranges + ;

:M GetRange: ( TaskParam -- High Low )
\ *G Returns the range to be used in a do...loop in one task in use by the object.
    #Tasks 1 >
       if    >range dup>r  @ r> cell+ @
       else  drop TotalRange 2@
       then
  ;M

:M ResetTimer:    ( - )
\ *G Resets a timer in a task by using its IDindex.
    ms@ &Timers GetTaskParam cells+! ;M

:M StopTaskTimer: ( - )
\ *G Stops a timer in a task by using its IDindex.
    ms@ &Timers GetTaskParam cells+ dup>r @  - r> ! ;M

:M Reset&Timers:  ( - )
\ *G Reset all timers of the tasks in use by the object.
    ms@ #Tasks 0   do   dup &Timers i cells+!   loop  drop ;M

:M GetTaskRange:  ( -- High Low )
\ *G Returns the range to be used in a do...loop of the task.
    GetTaskParam GetRange: Self  ;M

:M Putrange:      ( High Low IDindex -- )
\ *G Saves the range of a task.
    >range dup>r  cell+ ! r> ! ;M

:M .&Timers:      ( TaskParam - )
\ *G Show all times. Use in in the main-task when the tasks are completed in the object.
    cr ." &Timers:" #Tasks 1 max 0
        do  &Timers i cells+@ cr i  .
            [ 24 60 * 60 * 1000 * ] literal mod
            1000 /mod
              60 /mod
              60 /mod 2 .#" type ." :"
                      2 .#" type ." :"
                      2 .#" type ." ."
                      3 .#" type
       loop
  ;M

: CloseTaskHandle  ( IDindex -- )
\ *G Close a task handle using the ID of the task.
    GetTaskblock  task>handle dup>r @  call CloseHandle drop 0 r> !
 ;

: ResetTaskHandle  ( IDindex -- )
\ *G Sets a task handle to 0 using the ID of the task.
     GetTaskblock task>handle 0 swap !
 ;

: cr-dup.        ( n - n )
\ *G Show n on a new line in the concole.
    cr dup . ;

: .range         ( IDindex - )
\ *G Show the assigned range of a task using the ID of the task.
     cr-dup. GetRange: Self  swap . .  ;

: .WaitHndl      ( IDindex - )
\ *G Show the waithandle of a task using the ID of the task.
    cr-dup. &wait-hndls swap cells+ ? ;

: .TaskHndl      ( IDindex - )
\ *G Show the task handle of a task using the ID of the task.
    cr-dup. GetTaskblock task>handle ? ;

:M .&Ranges:         ( -- )
\ *G Show all the ranges of the tasks in use by the object.
    TaskIndex #do .range cr  ;M

:M .TaskHndls:       ( -- )
\ *G Show all the taskhandles of the tasks in use by the object.
    TaskIndex #do .TaskHndl cr ;M

:M .WaitHndls:       ( -- )
\ *G Show all the wait handles of the tasks in use by the object.
    #wait-hndls 0 #do .WaitHndl cr ;M

:M CloseTaskHandles: ( -- )
\ *G Close and reset all the taskhandles of the tasks in use by the object.
    TaskIndex #do CloseTaskHandle ;M

:M ResetTaskHandles: ( -- )
\ *G Sets all the taskhandles of the tasks in use by the object to 0.
    TaskIndex #do ResetTaskHandle ;M

:M Set&Ranges:  { High low -- }
\ *G Set all the ranges of the tasks in use by the object.
    High low - #Tasks dup>r  / r> 0
         do      High dup>r over - dup  to High r> swap i Putrange: Self
        loop
    low #Tasks 1- >range cell+ ! drop
  ;M

:M MallocTasksArrays: ( -- )
\ *G Allocates various arrays for the tasks in use by the object. \n
\ ** In an iTask object this is automaticly done.
    &Taskblocks 0=      \ Only executed when not done or when ReleaseTasksArrays: is executed
        if  #Tasks 1 max dup>r /Taskblock  * malloc to &Taskblocks \ Each task gets a taskblock
            r@ cells     MALLOC to &Timers  \ Pointer to the &Timers
            r@ cells 2 * MALLOC to &Ranges  \ Pointer to the defined &Ranges for each task. Map: High low
            r> MallocWaitHndls: Self        \ Allocates handles for wait function
        then
  ;M

:M ReleaseTasksArrays:    ( -- )
\ *G Releases various arrays for the tasks in use by the object.
    #ActiveTasks: Self  abort" Active tasks detected. Can't release memory."
    0 to #Tasks
    &Ranges     release 0 to &Ranges       \ Release &Ranges
    &wait-hndls release 0 to &wait-hndls   \ Release &wait-hndls
    &Taskblocks release 0 to &Taskblocks   \ Release &Taskblocks
  ;M

: RunTask       ( IDindex -- )
\ *G Runs a task using its ID.
    GetTaskblock   run-task drop  ;

: RunTasks      ( -- )
\ *G Runs all tasks in use by the object.
    TaskIndex  #do RunTask     ;

:M StopTask:     ( IDindex -- )
\ *G Stops a task using its ID.
    GetTaskblock  stop-task  drop           ;M

:M StopTasks:    ( -- )
\ *G Stop all tasks in use by the object.
    TaskIndex  do  i StopTask: Self    loop ;M


:M PutTaskcount: ( #Tasks -- )
\ *G Changes the number of simultaneous tasks that can be used by the object. \n
\ ** Can only be done when there are no active tasks.
    &Taskblocks 0<>
       if    ReleaseTasksArrays: Self
       then
    to #Tasks MallocTasksArrays: Self
  ;M


:M WaitForAlltasks: ( - )
\ *G Wait till all tasks in use by the object are completed.
    #wait-hndls  to taskwaits
        begin
          taskwaits
        while
          INFINITE false &wait-hndls          \ wait for 1 or more tasks to end
          taskwaits  WaitForMultipleObjects   \ wait on handles list
          dup WAIT_FAILED = if getlastwinerr then \ note the error
          WAIT_OBJECT_0 +                     \ ( event - IDindex )
          >r -1 +to taskwaits                 \ 1 task fewer to wait for, clean up the list
          &wait-hndls r@ cells+@ call CloseHandle drop   \ close the old taskhandle while the other tasks still run
          &wait-hndls taskwaits cells+@       \ get last handle in list
          &wait-hndls r> cells+!              \ store in signaled event ptr
        repeat
     ResetTaskHandles: Self                   \ Set all taskhandles in the taskblocks to 0
\   cr ." All tasks completed"
  ;M

:M SetParallelItems: ( limit IndexLow - )
\ *G Distributes the ranges for all tasks in use by the object.
    2dup TotalRange 2!
    Max#Tasks: Self 2 pick min  OnlyOneThread
       if     drop 1        \  Force 1 thread when OnlyOneThread is true
       then   PutTaskcount: Self
    MallocTasksArrays: Self \ Allocates the tasks, &wait-hndls and &Ranges when not done
    Set&Ranges: Self
  ;M

:M SubmitTasks: ( cfa -- )
\ *G Submits all tasks in use by the object and returns direct.   \n
\ ** Each task will execute the specified cfa and get its range.  \n
\ ** \bNOTE:\d SetParallelItems: must be executed before SubmitTasks:
    MallocTasksArrays: Self    \ Allocates the tasks, &wait-hndls and &Ranges when not done
    Init-Tasks Reset&Timers: Self ResumeTasks: Self
  ;M

:M StartTasks: ( cfa -- )
\ *G Starts all tasks in use by the object and wait till they are completed. \n
\ ** Each task will execute the specified cfa and get another range. \n
\ ** \bNOTE:\d SetParallelItems: must be executed before StartTasks:
    SubmitTasks: Self         \ Start all threads and return direct.
    WaitForAlltasks: Self     \ THEN WAIT till all the started threads are completed.
  ;M

:M Parallel: ( limit IndexLow cfa -- )
\ *G Executes the specified cfa in a number of tasks. \n
\ ** The number of tasks depend on the number of hardware threads and
\ ** the specified range in limit and IndexLow. \n
\ ** Parallel: returns when all the tasks in the object are completed. \n
\ ** Each task can get its range by using GetTaskRange: \n
\ ** Each range can be passed to a do..loop or #do \n
\ ** The debugger can not be used in a task. \n
\ ** See Single: for debugging.
   Lock: Self           \ To prevent a crash when multiple tasks try to use Parallel a task at the same time
   -rot SetParallelItems: Self StartTasks: Self
   UnLock: Self
  ;M

:M Single: ( limit IndexLow cfa -- )
\ *G Executes the definition of the specified cfa in the main task.
\ ** The executed definition can get its range by using GetTaskRange:
\ ** Made for debugging while running in the maintask.
    MainTask?
       if    MallocTasksArrays: Self
             -rot TotalRange 2! >r
             &StkParams dup @ 0>
                 if   Take&StkParams: Self
                 else drop
                 then
             ms@ &Timers !
             r> execute
       else  s" Single: Must start from the main-task" ErrorBox
       then
  ;M

;Class



:Class wTasks    <Super TaskPrimitives
\ *G To run a number of tasks concurrently that can not be indexed. \n
\ ** Each task may run a different definition. \n
\ ** By default it can run a number of simultaneously tasks that will be limited
\ ** by the number of specified simultaneous tasks with a maximum of 63 in ONE object. \n
\ ** When all the simultaneous tasks are used wTask will wait till ONE task is ready. \n
\ ** Then it will use the free taskblock again and start the new task for the submit command. \n
\ ** Of course you can override the maximum number of tasks that run simultaneously. \n
\ ** by using PutTaskcount:. This must be done when no task runs. \n
\ ** Taskblocks are allocated in the heap. \n
\ ** When all tasks are completed the allocated memory is NOT released
\ ** and can be used again. \n
\ ** ALL tasks should handle their own data. \n
\ ** Each task also get an index before they start. \n
\ ** Use GetTaskParam in the task to get it on the stack. \n
\ ** GetTaskParam can be used to target a value in an array for passing parameters. \n
\ ** Note: Start: must be started \bBEFORE\d a task is submitted.

int Specified#Tasks \ internal use


:M MallocTasksArrays: ( -- )
    &Taskblocks 0=      \ Only executed when not done or when ReleaseTasksArrays: is executed
         if  #Tasks 1 max dup>r /Taskblock * malloc to &Taskblocks \ Each task get a taskblock
             pad to &Timers                 \ No &Timers yet
             r@ MallocWaitHndls: Self       \ Allocates handles for wait function
             r> to Specified#Tasks          \ Remember the #tasks
         then
  ;M

:M ReleaseTasksArrays:    ( -- )
    #ActiveTasks: Self  abort" Active tasks detected. Can't release memory."
    &Taskblocks release 0 to &Taskblocks
    &wait-hndls release 0 to &wait-hndls  \ Release &wait-hndls
  ;M

:M UseALLThreads:    ( - ) false to OnlyOneThread  Specified#Tasks to #Tasks ;M
:M UseOneThreadOnly: ( - ) true to OnlyOneThread 1 to #Tasks ;M

:M PutTaskcount:  ( #Tasks  - )
    WhenTasksInRange ReleaseTasksArrays: Self
    to #Tasks  MallocTasksArrays: Self  0 to #wait-hndls
  ;M

: UseTaskBlockAgain ( cfa IDindex -- )
\ *G Closes the old thread handle and save new cfa in taskblock.
    GetTaskblock dup task>handle @ call CloseHandle drop !
 ;

:M WaitForOnetask: ( cfa - )
\ *G Waits for one or more tasks to be completed.
\ ** Then it will run the specified cfa in a new task and return.
    #wait-hndls  to taskwaits
    INFINITE false &wait-hndls            \ wait for just one of the tasks
    taskwaits  WaitForMultipleObjects     \ wait on handles list
    dup  WAIT_FAILED = if getlastwinerr then \ note the error
    WAIT_OBJECT_0 +                       \ ( event - cfa IDindex )
    dup>r UseTaskBlockAgain r@ CreateTask \ Create a suspended new task in the same free taskblock
    r@ SaveWaitHandle                     \ Save the waithandle in the free position
    r> ResumeTask: Self                   \ Run the new task
  ;M

:M WaitForAlltasks: ( - )                     \ Needed when to check that all submitted are ready
    #wait-hndls to taskwaits
        begin
          taskwaits
        while
          INFINITE false &wait-hndls          \ wait for 1 or more tasks to end
          taskwaits  WaitForMultipleObjects   \ wait on handles list
          dup WAIT_FAILED = if getlastwinerr then \ note the error
          WAIT_OBJECT_0 +                     \ ( event - IDindex )
          >r   -1 +to taskwaits            \ 1 task fewer to wait for, clean up the list
          &wait-hndls taskwaits cells+@       \ get last wait handle in list
          &wait-hndls r> cells+!              \ store in signaled event ptr
        repeat
\   cr ." All tasks completed"
  ;M

:M AddOneTask: ( cfa -- )
\ *G Submits the specified cfa in a new task and returns.
    #wait-hndls   dup>r                      \ ( cfa - cfa IDindex )
    Make-iTask: Self
    r@ CreateTask r@  SaveWaitHandle  r> ResumeTask: Self
    1 +to #wait-hndls
 ;M

:M SubmitTask: ( cfa -- )
\ *G Submits the specified cfa in a new task and return after that task could be submitted.
   Lock: Self                         \ To prevent a crash when multiple tasks try to submit a task at the same time
    #Tasks  #wait-hndls <=            \ When there is no hardware thread free anymore, then
        if    WaitForOnetask: Self    \ wait for one task, create a new thread and use the same free task-block again.
        else  AddOneTask: Self        \ Add a new thread and run.
        then
    unLock: Self
  ;M

:M Execute: ( cfa -- )
\ *G Executes the definition of the specified cfa in the main task.  \n
\ ** The executed definition can get its range by using GetTaskRange:  \n
\ ** Made for debugging while running in the maintask.  \n
    MainTask?
       if  >r &StkParams  dup @ 0>
              if   Take&StkParams: Self
              else drop
              then
           r> execute
       else  s" Execute: Must start from the main-task" ErrorBox
       then
  ;M

:M Start: ( #Tasks -- )     \ Used to initialize the object.
    to #Tasks
    false to OnlyOneThread \ #Tasks is the maximum number of tasks that may run simultaneously.
    0 to &Taskblocks
    0 to taskwaits
    MallocTasksArrays: Self \ Allocates the tasks and &wait-hndls when not done
    0 to #wait-hndls
  ;M


:M SetTaskblockSize:  ( NewSize - )
    SetTaskblockSize:  Super
    ReleaseTasksArrays: Self
    MallocTasksArrays:  Self
    0 to #wait-hndls
  ;M

;Class


:Class sTask    <Super wTasks
\ *G Nearly the same as wTasks
\ ** Differences:
\ ** 1.) It will only use 1 task concurrently.
\ ** 2.) The initialization of the objects defined with sTask is automatic.

:M SubmitTask: ( cfa -- )
   Lock: Self                    \ Prevent multiple tasks running the same cfa at the same time.
   &Taskblocks 0=
     if  1 Start: Super          \ Using ONE task only.
     then
   #Tasks  #wait-hndls  <=       \ When there is no hardware thread free anymore, then
     if    WaitForOnetask: Self  \ wait for one task, create a new thread and use the same free task-block again.
     else  AddOneTask: Self      \ Add a new thread and run.
     then
   UnLock: Self
  ;M

;Class

\ --- Demo and test section ---

 ((   \  Disable or delete this line for a demo of indexed tasks in an OBJECT

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
 ;

: .Analyse#Counts  ( - )
    cr ." All tasks ended."
    MS@ START-TIME - space .ELAPSED space
    cr ." Total counts: " #counts s>f GetTaskcount: myTasks s>f f* fdup e.
    s>f  1000e  f/
    cr ." counts / second: " f/ FE.
 ;

: find-elapsed-time   ( #tasks -- )
    >r cr cr ." Main task is waiting for " r@  . ." task" r@ 1 >
        if     ." s"
        then
    r> PutTaskcount: myTasks    \ Set the number of tasks to be used
    ['] my-task TIMER-RESET  StartTasks: myTasks  \ start the tasks
    .Analyse#Counts
 ;

 #Hardware-threads 2/ 1- value incr-loop

: find-elapsed-times  ( -- )
    1 find-elapsed-time
    Max#Tasks: myTasks dup>r 2/ 2 max find-elapsed-time
    #Hardware-threads 2 >
      if   r@  1- find-elapsed-time
           r@     find-elapsed-time
      then
    r> dup 2/ 1 max + MAXIMUM_WAIT_OBJECTS 1 - min find-elapsed-time
 ;

: .elapsed-results
    cls
    ." ImpactThreads: Finding the overall speed for" cr  ." parallel running counters using "
    #Hardware-threads . ." hardware threads."
    cr ." Wait till the end of the demo..."
    find-elapsed-times
    cr ." End of demo."
 ;

  .elapsed-results  abort \s ))

  (( \ Disable or delete this line for the Range test.

 iTasks myTasks

create results #Hardware-threads 2 max cells allot

: my-range-task  ( index n1 n2 n3 - ) { \ index }
    3drop                                \ Delete n1 n2 n3 passes by To&Task: myTasks
    GetTaskParam dup to index 1+ 10 * ms \ Each task will get an other wait-time.
    Below   index results index cells+!  \ Will be overwritten
    GetTaskRange: myTasks                \ Get the range for the do -- loop  for the running task
       do    i results index cells+!
       loop
    StopTaskTimer: myTasks
  ;

\ Just ONE line is needed to distribute data and execute a word in a parallel way
\ using all the hardware threads.

: range-test ( -- ) \ Setting the number of tasks automatically by using the word Parallel:
\   UseOneThreadOnly: myTasks  \ Optional for testing. Note: You can not use the debugger outside the main-task
    10 20 30 3 To&Task: myTasks                 \ To test that parameters can be passed
    170 0  ['] my-Range-task  Parallel: myTasks \ Start a number of tasks using all hardware threads when possible.
\   170 0  ['] my-Range-task  single: myTasks   \ single: instead of Parallel: for debugging

    cr cr ." Task ID's and &Ranges:"          .&Ranges: myTasks
          ." Number of used tasks: "          myTasks.#Tasks .
    cr    ." Indexes in the array results: "  myTasks.#Tasks 1 max 0
       do    results i cells+ ?
       loop
    .&Timers: myTasks
    ReleaseTasksArrays: myTasks                \ Release the allocated task arrays when ready
  ;

range-test abort \ ))


  (( \ Disable or delete this line for the SubmitTest.
\ Made to test and to prove that the use of more tasks can be faster.

    wTasks myTasks                 \ Make the object myTasks.
Max#Tasks: myTasks Start: myTasks  \ Initialize the object myTasks.
Max#Tasks: myTasks value #counters

\   5 dup PutTaskcount: myTasks to #counters \ An optional test.

#counters floats malloc value counters

 500000 value #loops
 1000 value #Restarts

: TestTask ( n1 n2 n3 - )
    3drop          \ Just to prove that passing parameters from an other task works
    below 0 pad ! #loops 0
      do   1 pad +!
      loop
    pad @ s>f counters  GetTaskParam floats +  f+!
 ;

: clr-counters ( - )
    #counters 0
        do   0e0 counters i floats + f!
        loop ;

: Total-counters  ( - f: Total )
    0e0 #counters  0
        do   counters i floats + f@ f+
        loop
  ;

: PromptTime ( - ) cr ." -- " .time time-buf 14 + w@ ." ."  3 .#" type ."  -- " ;

: .ActiveTasks ( - )
    PromptTime #ActiveTasks: myTasks
    ." The number of tasks that still run is: " . cr
 ;

: SubmitTest ( - )
    cls cr PromptTime ." SubmitTest started for " #loops s>f fe. ." in #loops in TestTask..."
\   UseOneThreadOnly: myTasks          \ Optional choise
\   15 cells SetTaskblockSize: myTasks \ Optional choise
    clr-counters   TIMER-RESET
    #Restarts dup>r 0
       do  10 20 30 3 To&Task: myTasks  \ Pass 3 parameters to the task to be submitted
           ['] TestTask SubmitTask: myTasks
       loop
    .ActiveTasks
    WaitForAlltasks: myTasks \  Needed to make sure that all tasks are ready
    MS@ START-TIME - .ELAPSED  space
    PromptTime ." All tasks are ready."
    ['] beep SubmitTask: myTasks 100 ms
    cr r@ . ." treads were used."

    cr ." Total counted: "
    Total-counters  fdup FE.      s>f 1000e  f/ f/ cr ." counts / second: " FE.
    cr ." The maximal number of simultaneous tasks was: " myTasks.#Tasks r> min .
    .ActiveTasks
 ;

: ExecuteTest ( - )
    cr ." ExecuteTest started for " #loops s>f fe. ." in #loops in TestTask..."
    clr-counters cr  TIMER-RESET
    #Restarts  dup 0
       do    10 20 30 3 To&Task: myTasks
             ['] TestTask Execute: myTasks
       loop
    MS@ START-TIME - .ELAPSED  swap space
    cr . ." restarts used." cr ." Total counted: "
    Total-counters  fdup FE. s>f 1000e  f/ f/ cr ." counts / second: " FE.
    cr ." Using Execute: ( No threads at all )"
 ;

 SubmitTest  ExecuteTest abort \s ))

(( On my iCore7:

-- 18:11:55.612 -- SubmitTest started for 500.000E3 in #loops in TestTask...
-- 18:11:56.246 -- The number of tasks that still run is: 6
Elapsed time: 00:00:00.635
-- 18:11:56.250 -- All tasks are ready.
1000 treads were used.
Total counted: 500.000E6
counts / second: 787.402E6
The maximal number of simultaneous tasks was: 8
-- 18:11:56.354 -- The number of tasks that still run is: 0

ExecuteTest started for 500.000E3 in #loops in TestTask...
Elapsed time: 00:00:02.443
1000 restarts used.
Total counted: 500.000E6
counts / second: 204.666E6
Using Execute: ( No threads at all )  ))



  (( \ Disable or delete this line for the LockTest.

0e fvalue ft0

: value-ft0
    ms@ 0e fto ft0
       begin  200e ft0 f+ fto ft0
              ms@ over 400 + >
       until drop  ;

TIMER-RESET
value-ft0 ft0 f>s  value #counts    \ To get a runtime for about 2 seconds


sTask SeqTask
iTasks ParallelTasks

: ProtectedWord ( - )              \ Increments a value at PAD
  TIMER-RESET
    Below  0 pad !   #counts  0
      do   1 pad +!
      loop
  cr GetTaskParam . .ELAPSED       \ show task ID and the elapsed time
  ;

: Parallel-tasks ( - )             \ Increments a value at PAD parallel in a number of tasks.
   Below  0 pad !   20 0
      do   1 pad +!
      loop  beep                           \ They will be ready at nearly the same time.
   ['] ProtectedWord LockExecute: SeqTask  \ LockExecute: takes care for executing the ProtectedWord
 ;                                         \ one by one and not all simultaneously.
\ Note: When SubmitTask: SeqTask is used in stead of LockExecute: SeqTask
\ the execution will be in a new task using only ONE task at the time.

: TestLock
  cr cr ." ID task with their elapsed time."
  17 0  ['] Parallel-tasks  Parallel: ParallelTasks
 ;


TestLock abort \s ))


\s
\ *Z
