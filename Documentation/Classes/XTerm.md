# XTerm Class

The `XTerm` class (`cs.xterm.Xterm`) is an all-in-one controller that bridges the low-level `cs.xterm.PTY` pseudo-terminal sessions with a 4D Web Area running **xterm.js**. 

It handles:
- Spawning the background `PTY` daemon.
- Loading the `xterm.js` HTML/JS interface into the provided Web Area.
- Starting an asynchronous background 4D `WORKER` process that continually reads terminal output without relying on UI blocking or timer polling mechanisms.
- Binding callbacks from the Web Area (like typing and resizing) back to the 4D environment natively.

## Prerequisites

Ensure you have access to the `PTYPlugin4D` native plugin component inside your project before using `cs.xterm.Xterm`.

## Initialization

You create an `XTerm` object by binding it to the object name of a Web Area on your current 4D Form.

```4d
// cs.xterm.Xterm.new($webArea : Text; $shell : Text; $cols : Integer; $rows : Integer; $workingDirectory : 4D.Folder)
var $xterm : cs.xterm.Xterm
$xterm := cs.xterm.Xterm.new("MyWebArea"; "/bin/zsh"; 80; 24; Folder(fk database folder))
```

- **$webArea**: The string object name of your 4D Web Area in the current form.
- **$shell**: The executable shell path (e.g., `/bin/zsh`).
- **$cols**: Terminal column width count.
- **$rows**: Terminal row height count.
- **$workingDirectory**: A `4D.Folder` object defining the initial directory the shell will spawn inside of.

## Essential Binding

To clean up resources natively, always make sure to call `.close()` dynamically when terminating the connection, such as during the generic form unload event:

```4d
If (Form event code = On Unload)
    $xterm.close()
End if
```

## Properties

- `pty` (cs.xterm.PTY): Exposes the foundational `cs.xterm.PTY` process wrapper acting as the data pipe for the Web Area.
- `webArea` (Text): The Object Name bound to the Web Area on the Form.

## Actions & Methods

These methods are standard interfaces for interacting from 4D Code natively:

### `write($text : Text) : cs.xterm.Xterm`
Writes raw string payloads down into the terminal stdin buffer (as if physically typing them inside the console). 

### `writeLine($text : Text) : cs.xterm.Xterm`
Writes a string combined with a trailing `\n` to automatically execute a standalone command line. 

### `interrupt() : Integer`
Simulates sending a `Ctrl+C` interrupt (SIGINT) directly to the attached terminal process group.

### `clearContents()`
Clears the visible viewport text grid on the terminal, while successfully retaining the historical scrollback cache.

### `fit()`
Instructs the front-end xterm viewport to recalculate and automatically scale its column and row layout to naturally fit within the newly resized Web Area frame dimensions. Ideal to trigger manually when the host Web Area grows or shrinks dynamically.

### `setFontSize($size : Integer)`
Modifies the internal font pixel size rendered by the `.js` engine inside the Web Area view canvas.

### `getSize() : Object`
Reads the currently configured grid topology rendered on screen.
**Returns**: `Object {cols: Integer, rows: Integer}`.

### `focus()`
Selects and locks typing focus dynamically onto the terminal cursor canvas frame.

### `close()`
Gracefully sends cross-process shutdown signals to stop the background `WORKER` polling mechanism, clears the GUI layout listeners, and natively triggers the termination of the active `PTY` daemon.
