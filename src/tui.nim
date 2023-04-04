import ./illwillWidgets.nim
import ./metricsparser
import ./pager
import algorithm
import illwill
import os
import std/sequtils
import std/strutils
import sugar
import tables

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)


proc fillField(value: string, len: int): string =
  let filled = alignLeft(value, len, ' ')
  return filled[0..len-1]

proc renderMetrics(tb: var(TerminalBuffer), metrics: seq,
    pager: MetricsPager): string =
  var currentMetric: string
  for i in 0..pager.length:
    if i+pager.offset >= metrics.len:
      tb.write(2, i+4, fillField("", 41))
      continue
    var metric = metrics[i+pager.offset]
    tb.write(2, i+4, (if pager.pos == i: fgYellow else: fgWhite),
        metric.fillField(41))
    if pager.pos == i:
      currentMetric = metrics[i+pager.offset]
  return currentMetric

proc renderMetric(tb: var(TerminalBuffer), metricName: string, metric: Metric, width: int) =
  tb.write(47, 1, fgGreen, metricName.fillField(width))
  tb.drawHorizLine(47, terminalWidth()-4, 2, doubleStyle = true)
  if metricName != "":
    tb.write(47, 3, fgWhite, "Last: ", fgCyan, metric.value.fillField(width-6))
    tb.write(47, 4, fgWhite, "Type: ", fgCyan, fillField($metric.metricType, width-6))
    tb.write(47, 5, fgWhite, "Help: ", fgCyan, fillField($metric.help, width-6))
    tb.write(47, 6, fgWhite, "Labels: ")
    var labelPos = 8
    tb.drawHorizLine(47, terminalWidth()-4, 7)
    let labels = toSeq(metric.labels.keys).sorted
    for i in 0..10:
      if len(labels) > i:
        let label = labels[i]
        tb.write(47, labelPos+i, fgWhite, fillField(label&": "&metric.labels[
            label].join(", "), width))
      else:
        tb.write(47, labelPos+i, fillField("", width))

proc drawUI(tb: var(TerminalBuffer), searchBox: TextBox, pager: MetricsPager) =
  tb.setForegroundColor(fgBlack, true)
  tb.drawRect(0, 0, 44, terminalHeight()-2)
  tb.drawRect(45, 0, terminalWidth()-2, terminalHeight()-2)
  tb.drawHorizLine(2, 28, 3, doubleStyle = true)
  tb.write(2, 1, fgWhite, fillField( (
    if searchBox.text != "": "Metrics ("&searchBox.text&")"
  else: "Metrics"), 40))
  tb.write(2, 2, "h/j/k/l - / filter ", fgYellow, "ESC", fgWhite, " to quit")
  tb.write(2, terminalHeight()-2, $pager.page, fgYellow, "/", fgWhite,
      $pager.maxPage)

proc initUI*(results: Metrics) =
  var
    pager = MetricsPager(page: 1)
    currentMetric: string

  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  var keys = toSeq(results.keys).sorted

  var searchBox = newTextBox("", 2, 2, 30, placeholder = "")

  while true:
    var
      key = getKey()
      rightWidth = terminalWidth()-50

    if searchBox.focus:
      if tb.handleKey(searchBox, key): searchBox.focus = false
      key.setKeyAsHandled() # If the key input was handled by the textbox
    var fkeys = keys
    if searchBox.text != "":
      fkeys = collect(newSeq):
        for i, d in keys:
          if d.contains(searchBox.text): d

    pager.count = fKeys.len
    pager.setLength(terminalHeight()-7)

    case key
    of Key.None: discard
    of Key.Escape, Key.Q: exitProc()
    of Key.H:
      if pager.page > 1: pager.page.dec
    of Key.L:
      if pager.page < pager.maxPage: pager.page.inc
    of Key.K:
      if pager.pos > 0: pager.pos.dec
    of Key.J:
      if pager.pos < pager.length: pager.pos.inc
    of Key.Slash:
      searchBox.focus = true
      pager.reset()
    else:
      discard

    # Reset position if we're on the last page and out of bonds
    pager.check_bounds()

    tb.drawUI(searchBox, pager)
    currentMetric = tb.renderMetrics(fkeys, pager)
    if currentMetric != "":
      tb.renderMetric(currentMetric, results[currentMetric], rightWidth)

    discard tb.dispatch(searchBox, getMouse())
    # Only show search while in focus
    if searchBox.focus:
      tb.render(searchBox)

    tb.display()
    sleep(20)
