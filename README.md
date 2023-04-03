# promexplorer

A simple tool to explore prometheus exporter feeds
aggregates all the labels into one metric, and gives you a simple tui
to navigate the available metrics

# Installation

Static binaries are provided for mac/linux/windows, get the appropriate one from
the latest release and put it somewhere in your PATH.

## Help

``` sh
❯ ./promexplorer
promexplorer [-v|--version] | [-h|--help] | exporter_url
note: your exporter_url should include /metrics or whatever path your metrics are on.
```
## Usage

``` sh
❯ ./promexplorer http://localhost:9100/metrics
```

![screencast](https://github.com/marcusramberg/promexplorer/blob/main/promexplorer.gif)


## LICENSE

MIT License (See LICENSE for details)

## Copyright 

2022 Marcus Ramberg

