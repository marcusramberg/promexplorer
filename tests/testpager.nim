import unittest

import ../src/pager

test "testPager":
  var pager = MetricsPager(count: 20, length: 10)
  assert pager.maxPage == 2
  pager.count.inc
  assert pager.maxPage == 3
  pager.page = 2
  pager.setLength(6)
  assert pager.offset == 6
  assert pager.maxPage == 4
