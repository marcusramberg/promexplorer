import strscans
import strutils
import tables
import re

type
  MetricType* = enum
    Counter = "counter"
    Gauge = "gauge"
    Histogram = "histogram"
    Summary = "summary"
    Untyped = "untyped"

  Metric* = object
    labels*: Table[string, seq[string]]
    metricType*: MetricType
    help*: string
    value*: string
  Metrics* = Table[string, Metric]

converter toType(s: string): MetricType = parseEnum[MetricType](s)

proc parseMetrics*(content: string): Metrics =

  var
    metrics = initTable[string, Metric]()
    lines = content.splitLines()
    metric: string
    metricType: string
    description: string
    value: string
  for line in lines:
    if line.scanf("# TYPE $w $+", metric, metricType):
      if not metrics.hasKey(metric): metrics[metric] = Metric()
      metrics[metric].metricType = toType(metricType)
    elif line.scanf("# HELP $w $+", metric, description):
      if not metrics.hasKey(metric): metrics[metric] = Metric()
      metrics[metric].help = description
    # match prometheus metric with labels
    elif line.scanf("$w $+", metric, value):
      if not metrics.hasKey(metric): metrics[metric] = Metric()
      metrics[metric].value = value
    elif line =~ re"^([a-zA-Z0-9_:]+)\{(.*)\} (.*)$":
      metric = matches[0]
      if not metrics.hasKey(metric): metrics[metric] = Metric()
      metrics[metric].value = matches[2]
      for label in matches[1].split(","):
        if label =~ re"(.*)=(.*)":
          if not metrics[metric].labels.hasKey(matches[0]): metrics[
              metric].labels[matches[0]] = @[]
          metrics[metric].labels[matches[0]].add(matches[1])
    else:
      if line.len > 0:
        echo ""
        echo "Unparsed line: ", line
        echo ""
  return metrics
