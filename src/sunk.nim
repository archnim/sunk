import asyncdispatch
export asyncdispatch

type

  PStatus = enum
    pending, canceled, running, finished
  PendingOps* = ref object
    status*: PStatus = pending

  CStatus = enum
    running, paused, stopped
  CyclicOps* = ref object
    status*: CStatus = running

proc `$`*(pend: PendingOps): string =
  ## Prints out a pending operation
  "[ Pending Ops Handle: " & $pend.status & " ]"

proc cancel*(pend: PendingOps) =
  ## Cancels a pending operation
  if pend.status == pending:
    pend.status = canceled

proc `$`*(cycle: CyclicOps): string =
  ## Prints out a cyclic operation
  "[ Cyclic Ops Handle: " & $cycle.status & " ]"

proc pause*(cycle: CyclicOps) =
  ## Pauses a cyclic operation
  if cycle.status == running:
    cycle.status = paused

proc resume*(cycle: CyclicOps) =
  ## Resumes a cyclic operation
  if cycle.status == paused:
    cycle.status = running

proc stop*(cycle: CyclicOps) =
  ## Stops a cyclic operation
  if cycle.status != stopped:
    cycle.status = stopped

proc after*(ms: int or float, todo: proc ()): PendingOps =
  ## Executes actions passed as `todo` after `ms` milliseconds
  ## without blocking the main execution flow while waiting.
  ## An equivalent of javascript's setTimeout

  runnableExamples:
    discard after(2_500) do():
      echo "2.5 seconds passed !"

    var pend: PendingOps = after(3_000) do():
      echo "This line will never be executed !"

    # Let's cancel the second pennding process
    # 1.5 seconds before its execution :
    discard after(1_500) do(): cancel pend

  var pend = PendingOps()

  proc p() {.async.} =
    var pend = pend
    await sleepAsync(ms)
    if pend.status == pending:
      pend.status = running
      todo()
      pend.status = finished

  discard p()

  return pend

proc doAfter*(todo: proc (), ms: int or float): PendingOps =
  ## Executes actions passed as `todo` after `ms` milliseconds
  ## without blocking the main execution flow while waiting

  runnableExamples:
    proc todo() = echo "2.5 seconds passed !"
    discard todo.doAfter(2_500)

  var pend = PendingOps()

  proc p() {.async.} =
    var pend = pend
    await sleepAsync(ms)
    if pend.status == pending:
      pend.status = running
      todo()
      pend.status = finished

  discard p()

  return pend

proc every*(ms: int or float, todo: proc ()): CyclicOps =
  ## Executes actions passed as `todo` every `ms` milliseconds
  ## without blocking the main execution flow while waiting.
  ## An equivalent of javascript's setInterval

  runnableExamples:
    var cycle: CyclicOps = every(2_000) do():
      echo "This line will be executed three times !"

    # To stop the background process after 6.5 seconds:
    discard after(6_500) do(): stop cycle

  var cycle = CyclicOps()

  proc p() {.async.} =
    var cycle = cycle
    while true:
      await sleepAsync(ms)
      if cycle.status == stopped: break
      if cycle.status == running:
        todo()

  discard p()

  return cycle

proc doEvery*(todo: proc (), ms: int or float): CyclicOps =
  ## Executes actions passed as `todo` every `ms` milliseconds
  ## without blocking the main execution flow while waiting

  runnableExamples:
    proc todo() = echo "This line will be executed three times !"
    var cycle = todo.doEvery(2_000)

    # To stop the background process after 6.5 seconds:
    discard after(6_500) do(): stop cycle

  var cycle = CyclicOps()

  proc p() {.async.} =
    var cycle = cycle
    while true:
      await sleepAsync(ms)
      if cycle.status == stopped: break
      if cycle.status == running:
        todo()

  discard p()

  return cycle

proc once*(cond: bool, todo: proc ()) =
  ## Checks `cond` in background every 5 milliseconds
  ## and executes actions passed as `todo` once it's true

  runnableExamples:
    import threadpool, os
  
    var hasFinished = false

    proc longOps() =
      # let's fake long operations with sleep
      sleep 5_000
      hasFinished = true

    spawn longOps()
    once(hasFinished) do(): echo "Finished !"

  let p = proc () {.async.} =
    while not cond:
      await sleepAsync(5)
    todo()

  discard p()

proc doOnce*(todo: proc (), cond: bool) =
  ## Checks `cond` in background every 5 milliseconds
  ## and executes actions passed as `todo` once it's true

  runnableExamples:
    import threadpool, os
  
    var hasFinished = false

    proc longOps() =
      # let's fake long operations with sleep
      sleep 5_000
      hasFinished = true
    
    proc notify() = echo "Finished !"

    spawn longOps()
    notify.doOnce(hasFinished)

  let p = proc () {.async.} =
    while not cond:
      await sleepAsync(5)
    todo()

  discard p()

proc then*[T](fut: Future[T], todo: proc(value: T)) =
  runnableExamples:
    import std/[asyncdispatch, httpclient]
    var
      client = newAsyncHttpClient()
      f = client.getContent("https://google.com")
    f.then do(return_value: string): echo return_value

  proc p() {.async.} =
    try:
      todo(await fut)
    except:
      discard
  discard p()

proc then*[T](fut: Future[T], todo: proc()) =
  runnableExamples:
    import std/[asyncdispatch, httpclient]
    var
      client = newAsyncHttpClient()
      f = client.getContent("https://google.com")
    f.then do(): echo "Finished with success !"

  proc p() {.async.} =
    try:
      discard await fut
      todo()
    except:
      discard
  discard p()

proc catch*[T](fut: Future[T], todo: proc(error: ref Exception)) =
  runnableExamples:
    import std/[asyncdispatch, httpclient]
    var
      client = newAsyncHttpClient()
      f = client.getContent("https://google.com")
    f.catch do(what_s_wrong: ref Exception): echo what_s_wrong.msg

  proc p() {.async.} =
    try:
      discard await fut
    except Exception as error:
      todo(error)
  discard p()

proc catch*[T](fut: Future[T], todo: proc()) =
  runnableExamples:
    import std/[asyncdispatch, httpclient]
    var
      client = newAsyncHttpClient()
      f = client.getContent("https://google.com")
    f.catch do(): echo "Failed !"

  proc p() {.async.} =
    try:
      discard await fut
    except Exception as error:
      todo()
  discard p()

proc `finally`*[T](fut: Future[T], todo: proc()) =
  runnableExamples:
    import std/[asyncdispatch, httpclient]
    var
      client = newAsyncHttpClient()
      f = client.getContent("https://google.com")
    f.finally do(): echo "Finished !"

  proc p() {.async.} =
    try:
      discard await fut
    except:
      discard
    todo()
  discard p()