![Sunk](sunk-256.png) Sink, Sank, Have Sunk
===========================================
## Few async tools for nim
## `then`, `catch`, `finally`, and more


Documentation: [https://archnim.github.io/sunk-docs](https://archnim.github.io/sunk-docs)

## Installation

```sh
nimble install sunk
```


## Example 1

```nim
import std/[asyncdispatch, httpclient]

var
  client = newAsyncHttpClient()
  f = client.getContent("https://google.com")

f.then do(): echo "Finished with success !"
f.then do(return_value: string): echo return_value

f.catch do(): echo "Failed !"
f.catch do(what_s_wrong: ref Exception): echo what_s_wrong.msg

f.finally do(): echo "Finished !"
```

## Example 2
`After` executes actions passed as `todo` after `ms` milliseconds without blocking the main execution flow while waiting. It's an equivalent of javascript's `setTimeout`

```nim
    discard after(2_500) do():
      echo "2.5 seconds passed !"

    var pend: PendingOps = after(3_000) do():
      echo "This line will never be executed !"

    # Let's cancel the second pennding process
    # 1.5 seconds before its execution :
    discard after(1_500) do(): cancel pend
```

## Example 3
`Every` executes actions passed as `todo` every `ms` milliseconds without blocking the main execution flow while waiting. An equivalent of javascript's `setInterval`

```nim
var cycle: CyclicOps = every(2_000) do():
  echo "This line will be executed three times !"

# To stop the background process after 6.5 seconds:
discard after(6_500) do(): stop cycle
```

## Example 4
`Once` Checks a boolean passed as `cond` in background every 5 milliseconds and executes actions passed as `todo` once it's true

```nim
    import threadpool, os

    var hasFinished = false

    proc longOps() =
      # let's fake long operations with sleep
      sleep 5_000
      hasFinished = true

    spawn longOps()
    once(hasFinished) do(): echo "Finished !"
```