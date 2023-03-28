import strscans
import strutils
import tables
import sets
import re

type 
  MetricType* = enum
    Counter = "counter"
    Gauge = "gauge"
    Histogram = "histogram"
    Summary = "summary",
    Untyped = "untyped"
  Metric* = object
    labels*: OrderedSet[string]
    metricType*: MetricType
    help*: string
    value*: string
  Metrics* = Table[string, Metric]

converter toType(s: string): MetricType = parseEnum[MetricType](s)

proc parseMetrics*(content: string): Metrics =

  var
    metrics = initTable[string, Metric]()
    lines = content.splitLines()
    metric:string
    lastMetric:string
    metricType:string
    description:string
    value:string
  for line in lines:
    if line.scanf("# TYPE $w $+", metric, metricType):
      if not metrics.hasKey(metric):  metrics[metric]=Metric()
      metrics[metric].metricType = toType(metricType)
    elif line.scanf("# HELP $w $+", metric, description):
      if not metrics.hasKey(metric):  metrics[metric]=Metric()
      metrics[metric].help = description 
    # match prometheus metric with labels
    elif line.scanf("$w $+", metric, value):
      if not metrics.hasKey(metric):  metrics[metric]=Metric()
      metrics[metric].value =value
    elif line =~ re"^([a-zA-Z0-9_:]+)\{(.*)\} (.*)$":
      metric = matches[0]
      if not metrics.hasKey(metric):  metrics[metric]=Metric()
      metrics[metric].value=matches[2]
      for label in matches[1].split(","):
        if label =~ re"(.*)=(.*)":
          metrics[metric].labels.incl(matches[0])
    else:
      echo ""
      echo "Unparsed line: ", line
      echo ""
  return metrics
