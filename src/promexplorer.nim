import httpclient
import parseopt
import ./metricsparser


proc getFeed(url: string): Metrics =
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
