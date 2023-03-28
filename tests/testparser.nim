import unittest
import tables

import ../src/promexplorer

test "parseMetrics":
    let f = open("tests/testdata.txt")
    defer: close(f)
    let testdata = f.readAll()

    var metrics: Table[string, promexplorer.Metric] = parseMetrics(testdata)


    let metric = metrics["go_goroutines"]
    assert metric.help == "Number of goroutines that currently exist."
    assert metric.metricType == MetricType.Gauge
    
