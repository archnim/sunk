# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import  threadpool, asyncdispatch, os, sunk

var hasFinished = false

proc longOps() =
  # let's fake long operations with sleep
  sleep 5_000
  hasFinished = true

spawn longOps()

echo "Begin"

once(hasFinished) do(): echo "Finished !"

proc rf() = echo "Really finished !"
rf.doOnce hasFinished

waitFor sleepAsync 7_000