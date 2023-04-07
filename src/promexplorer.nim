import std / [httpclient, parseopt, strutils, uri]
import ./metricsparser
import ./tui


proc getFeed(url: string): Metrics =
  let uri = parseUri(url)
  var contents: string
  try:
    case uri.scheme:
      of "http":
        var client = newHttpClient()
        defer: client.close()
        let res = client.get(url)
        if res.status != "200 OK":
          echo "Error: ", res.status, res.body
          system.quit()
        elif not res.contentType.contains("text/plain"):
          echo "Error: ", "Content type is ", res.contentType, ", not text/plain."
          system.quit()
        contents = res.body
      of "file":
        contents = readFile(uri.path)
      else:
        echo "Error: ", "Unknown scheme: ", uri.scheme
        system.quit()
  except CatchableError:
    echo "Error: ", getCurrentExceptionMsg()
    system.quit()

  return parseMetrics(contents)


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
  echo "promexplorer [-v|--version] | [-h|--help] | [http|file]://exporter_url"
  echo "note: your exporter_url should include /metrics or whatever path your metrics are on."
