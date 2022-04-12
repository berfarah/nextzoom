# Next Zoom Meeting

Single-purpose binary to join the next zoom meeting. Usage:
```
open `<directory/to/binary>/nextzoom`
```

This is a spiritual fork of [this gist](https://gist.github.com/zmij/c80d6e947bcceaf85ba5c33cf3783d46).

## Build

```
swiftc nextzoom.swift
```

## How I'm using it

### Alfred Workflow

Keyword: join
Run Script:
```
open `<directory/to/binary>/nextzoom`
```
### Stream Deck

Using [streamdeck-osascript](https://github.com/gabrielperales/streamdeck-osascript)
plugin
```
tell application id "com.runningwithcrayons.Alfred" to run trigger "join" in workflow "com.bernardo.me.joinzoom"
```
(make sure to reference your workflow that you create in Alfred)

