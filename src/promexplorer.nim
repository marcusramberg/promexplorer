import httpclient
import parseopt
import strutils
import ./metricsparser
import ./tui


proc getFeed(url: string): Metrics =
  var client = newHttpClient()
  try:
    let res = client.get(url)
    if res.status != "200 OK":
      echo "Error: ", res.status, res.body
      system.quit()
    elif not res.contentType.contains("text/plain"):
      echo "Error: ", "Content type is ", res.contentType, ", not text/plain."
      system.quit()

    return parseMetrics(res.body)

  except CatchableError:
    echo "Error: ", getCurrentExceptionMsg()
    system.quit()
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
        break
      else:
        echo "Unknown option: ", key, ". Run `promexplorer -h` for help."
        quit()
    of cmdArgument:
      echo "Feed to explore: ", key
      initUI(getFeed(key))
      quit()
  echo "promexplorer [-v|--version] | [-h|--help] | exporter_url"
  echo "note: your exporter_url should include /metrics or whatever path your metrics are on."
