import unittest
import tables

import ../src/metricsparser

test "parseMetrics":
    let f = open("tests/testdata.txt")
    defer: close(f)
    let testdata = f.readAll()

    var metrics: Metrics = parseMetrics(testdata)


    let goroutines = metrics["go_goroutines"]
    assert goroutines.help == "Number of goroutines that currently exist."
    assert goroutines.metricType == MetricType.Gauge
    
    let duration = metrics["go_gc_duration_seconds"]
    assert duration.help == "A summary of the pause duration of garbage collection cycles."

    assert duration.metricType == MetricType.Summary
