import httpclient
import parseopt
import strscans
import strutils
import tables
import sets

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

converter toType(s: string): MetricType = parseEnum[MetricType](s)

proc parseMetrics*(content: string): Table[string, Metric] =

  var
    metrics = initTable[string, Metric]()
    lines = content.splitLines()
    lastMetric = ""
    metric = ""
    lastType = ""
    lastDescription = ""
    label = ""
    value = ""
  for line in lines:
    if line.scanf("# TYPE $w $+", metric, lastType):
      if metric != lastMetric:
        lastMetric=metric
        metrics[metric]=Metric()
      metrics[lastMetric].metricType = toType(lastType)
    elif line.scanf("# HELP $w $+", metric, lastDescription):
      if metric != lastMetric:
        lastMetric=metric
        metrics[metric]=Metric()
      metrics[metric].help = lastDescription
    elif line.scanf("%w{%w=\"$+\"", metric, label, value):
      if metric != lastMetric:
        lastMetric=metric
        metrics[metric]=Metric()
      metrics[metric].labels.incl(label)
        

    else:
      echo ""
      echo "Unparsed line: ", line
      echo ""
  return metrics

proc getFeed(url: string): Table[string, Metric] =
  var client = newHttpClient()
  try: 
    return parseMetrics(client.getContent(url))
  except:
    echo "Error: ", getCurrentExceptionMsg()
  finally:
    client.close()

when isMainModule:
  for kind, key, value in getOpt():
    case kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if key == "v" or key == "version":
        echo "promexplorer 0.0.1"
        quit()
      elif key == "h" or key == "help":
        echo "promexplorer [-v|--version] [-h|--help] exporter_url"
        quit()
      else: 
        echo "Unknown option: ", key, ". Run `promexplorer -h` for help."
        quit()
    of cmdArgument:
      echo "Feed to explore: ", key
      echo getFeed(key)
