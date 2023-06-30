
needs MultiTaskingClass.f

0 user accu
: IncrementAccu ( - ) 1 accu +! ;

 wTasks myTasks
4 Start: myTasks

 ' IncrementAccu SubmitTask: myTasks
 ' IncrementAccu SubmitTask: myTasks
 ' IncrementAccu SubmitTask: myTasks
 ' IncrementAccu SubmitTask: myTasks

\ Or you could take advantage of a do..loop structure.

iTasks ParallelTask

: AccuTask ( - )
   GetTaskRange: ParallelTask
     do IncrementAccu
     loop  ;

 1000 0  ' AccuTask  Parallel: ParallelTask

\s
