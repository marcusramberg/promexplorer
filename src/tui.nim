import ./metricsparser
import illwill
import os
import std/sequtils
import std/strutils
import algorithm
import tables
import math
import ./illwillWidgets.nim
import sugar

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc fillField(value: string, len: int): string =
  let filled = alignLeft(value, len, ' ')
  return filled[0..len-1]

proc initUI*(results: Metrics) =
  var
    pos = 0
    page = 1
    currentMetric = ""
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  var keys = toSeq(results.keys).sorted

  var textBox = newTextBox("", 2, 2, 30, placeholder = "")

  while true:
    var
      key = getKey()
      pageLength = terminalHeight()-7
      pageOffset = (page-1)*pageLength
      rightWidth = terminalWidth()-50

    # Must be done for every textbox
    if textBox.focus:
      if tb.handleKey(textBox, key):
        page=1
        pos=0
        textBox.focus = false
      key.setKeyAsHandled() # If the key input was handled by the textbox
    var fkeys = keys
    if textBox.text != "":
      fkeys = collect(newSeq):
        for i, d in keys:
          if d.contains(textBox.text): d

    var maxPage = fKeys.len.ceilDiv pageLength

    case key
    of Key.None: discard
    of Key.Escape, Key.Q: exitProc()
    of Key.H:
      if page > 1: page.dec
    of Key.L:
      if page < maxPage: page.inc
    of Key.K:
      if pos > 0: pos.dec
    of Key.J:
      if pos < pageLength: pos.inc
    of Key.Slash:
      textBox.focus = true
    else:
      discard
    # Reset position if we're on the last page and out of bonds
    if page == maxPage and pos+pageOffset >=
        fkeys.len: pos = fkeys.len-pageOffset-1

    tb.setForegroundColor(fgBlack, true)
    tb.drawRect(0, 0, 44, terminalHeight()-2)
    tb.drawRect(45, 0, terminalWidth()-2, terminalHeight()-2)
    tb.drawHorizLine(2, 28, 3, doubleStyle = true)
    tb.write(2, 1, fgWhite, fillField( (
      if textBox.text != "":
      "Metrics ("&textBox.text&")"
    else: "Metrics"), 40))
    tb.write(2, 2, "h/j/k/l - / filter ", fgYellow, "ESC", fgWhite, " to quit")
    tb.write(2, terminalHeight()-2, page.intToStr(), fgYellow, "/", fgWhite,
        maxPage.intToStr())
    for i in 0..pageLength:
      if i+pageOffset >= fkeys.len:
        tb.write(2, i+4, fillField("", 41))
        continue
      var metric = fkeys[i+pageOffset]
      tb.write(2, i+4, (if pos == i: fgYellow else: fgWhite), metric.fillField(41))
      if pos == i:
        currentMetric = fkeys[i+pageOffset]
    let res = results[currentMetric]
    tb.write(47, 1, fgGreen, currentMetric.fillField(rightWidth))
    tb.drawHorizLine(47, terminalWidth()-4, 2, doubleStyle = true)
    tb.write(47, 3, fgWhite, "Last: ", fgCyan, res.value.fillField(rightWidth-6))
    tb.write(47, 4, fgWhite, "Type: ", fgCyan, fillField($res.metricType, rightWidth-6))
    tb.write(47, 5, fgWhite, "Help: ", fgCyan, fillField($res.help, rightWidth-6))
    tb.write(47, 6, fgWhite, "Labels: ")
    var labelPos = 8
    tb.drawHorizLine(47, terminalWidth()-4, 7)
    let labels = toSeq(res.labels.keys).sorted
    for i in 0..10:
      if len(labels) > i:
        let label = labels[i]
        tb.write(47, labelPos+i, fgWhite, fillField(label&": "&res.labels[
            label].join(", "), rightWidth))
      else:
        tb.write(47, labelPos+i, fillField("", rightWidth))

    var ev: Events
    let coords = getMouse()
    ev = tb.dispatch(textBox, coords)
    if textBox.focus:
      tb.render(textBox)

    tb.display()
    sleep(20)

