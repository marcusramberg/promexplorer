import ./metricsparser
import illwill
import os
import std/sequtils
import std/strutils
import algorithm
import tables
import math

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc fillField(value:string, len:int):string =
  let filled=alignLeft(value, len, ' ')
  return filled[0..len-1]

proc initUI*(result:Metrics) =
  var 
    pos=0
    page=1
    currentMetric=""
  illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  hideCursor()
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  var keys = toSeq(result.keys)
  keys = keys.sorted()

  while true:
    var 
      pageLength = terminalHeight()-7
      rightWidth = terminalWidth()-55
      maxPage = keys.len.ceilDiv pageLength
      key = getKey()
      pageOffset=(page-1)*pageLength
    tb.setForegroundColor(fgBlack, true)
    tb.drawRect(0, 0, 44, terminalHeight()-2)
    tb.drawRect(45, 0, terminalWidth()-2, terminalHeight()-2)
    tb.drawHorizLine(2, 28, 3, doubleStyle=true)
    tb.write(2, 1, fgWhite, "Metrics")
    tb.write(2, 2, "h/j/k/l  ", fgYellow, "ESC", fgWhite, " to quit")
    tb.write(2,terminalHeight()-2, page.intToStr(), fgYellow, "/", fgWhite, maxPage.intToStr())
    case key
    of Key.None: discard
    of Key.Escape, Key.Q: exitProc()
    of Key.H:
      if page>1: page.dec
    of Key.L:
      if page<maxPage: page.inc
    of Key.K:
      if pos>0: pos.dec
    of Key.J: 
      if pos<pageLength: pos.inc
    else:
      discard
    # Reset position if we're on the last page and out of bonds
    if page==maxPage and pos+pageOffset >= keys.len: pos=keys.len-pageOffset-1
    
    


    for i in 0..pageLength:
      if i+pageOffset >= keys.len: 
        tb.write(2, i+4, fillField("", 40))
        continue
      var metric = keys[i+pageOffset]
      tb.write(2, i+4, (if pos==i: fgYellow else: fgWhite), metric.fillField(40))
      if pos == i:
        currentMetric = keys[i+pageOffset]

    tb.write(46, 1, fgGreen, currentMetric.fillField(rightWidth))
    tb.write(46, 3, fgWhite, "Help: ", fgCyan, fillField($result[currentMetric].help, rightWidth))
    tb.write(46, 4, fgWhite, "Type: ", fgCyan, fillField($result[currentMetric].metricType, rightWidth))
    tb.write(46, 5, fgWhite, "Last: ", fgCyan, result[currentMetric].value.fillField(rightWidth))
    tb.display()
    sleep(20)

