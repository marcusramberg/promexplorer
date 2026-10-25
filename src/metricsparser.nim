import strscans
import strutils
import tables

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
    elif '{' in line and "} " in line:
      let lb = line.find('{')
      let rb = line.rfind("} ")
      metric = line[0 ..< lb]
      if not metrics.hasKey(metric): metrics[metric] = Metric()
      metrics[metric].value = line[rb+2 .. ^1]
      for label in line[lb+1 ..< rb].split(','):
        let kv = label.split('=', maxsplit = 1)
        if kv.len == 2:
          metrics[metric].labels.mgetOrPut(kv[0], @[]).add(kv[1])
    else:
      if line.len > 0:
        echo ""
        echo "Unparsed line: ", line
        echo ""
  return metrics
