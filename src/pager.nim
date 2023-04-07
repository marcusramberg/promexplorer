import math

type MetricsPager* = object
  page*: int
  pos*: int
  length*: int
  offset*: int
  count*: int

proc absPos*(this: MetricsPager): int = result = this.pos+this.offset

proc maxPage*(this: MetricsPager): int = this.count.ceilDiv this.length

proc maxItem*(this: MetricsPager): int = this.count-this.offset-1

proc check_bounds*(this: var(MetricsPager)) =
  if this.page == this.maxPage and this.absPos >= this.count:
    this.pos = this.maxItem

proc setLength*(this: var(MetricsPager), length: int) =
  this.length = length
  this.offset = (this.page-1)*length

proc reset*(this: var(MetricsPager)) =
  this.page = 1
  this.pos = 0
