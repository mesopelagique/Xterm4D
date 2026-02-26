# Xterm4D

Xterm4D is an experimental personal project that demonstrates how to display terminal output using [Xterm.js](https://xtermjs.org/) embedded inside a 4D Web Area component. It provides a basic proof-of-concept for integrating a web-browser-powered terminal emulator GUI into 4D windowing structures. Under the hood, it uses a pseudoterminal (PTY) session to act as the backend engine.

> **Disclaimer**: This is a personal project intended for testing and experimentation. Use at your own risk. The primary goal is to provide a working terminal block from within 4D to launch and interact with AI CLI tools like Claude, Codex, Gemini, or Copilot.

https://github.com/user-attachments/assets/c45a91bb-4faa-4deb-a477-d9885d8dd8b4

## Web Area Integration with Xterm.js

To help integrate `xterm.js`, the project provides the `cs.xterm.Xterm` class, which serves as a simple controller to bridge the low-level PTY session with the Web Area.

### Basic Usage of `cs.xterm.Xterm`

You simply need a form with a Web Area (for example, named `"MyWebArea"`) and an object to hold the controller logic.

```4d
// On Form Load event:
var $xterm := cs.xterm.Xterm.new("MyWebArea"; "/bin/zsh"; 80; 24; Folder(fk database folder))

// Execute a command
$xterm.writeLine("ls -la")

// Let the Web Area scale layout to fit dimensions
$xterm.fit()
```

Crucially, cleanup MUST be handled when the form closes:

```4d
// On Form Unload event:
$xterm.close()
```

> **Detailed Documentation**: For a complete list of controller actions (like `.interrupt()`, `.setFontSize()`, or `.clearContents()`), please see [Documentation/Classes/XTerm.md](Documentation/Classes/XTerm.md).

### The Lifecycle Interaction Flow between JS and 4D

Because native PTY output carries raw ANSI escape structures, they must be formatted by an emulator to be easily readable. The `cs.xterm.Xterm` class and Xterm.js handle these events automatically. The interaction works as follows:

1. **Background Output Reader (4D `WORKER`)**
   - The `cs.xterm.Xterm` object automatically spawns a background `WORKER` process polling the internal PTY session stream.
   - When new data is returned (including ANSI colorings or cursor shifts), the worker pushes the exact string payloads directly to the active web area frame logic using `CALL FORM` and `WA EXECUTE JAVASCRIPT FUNCTION`.

2. **Frontend (Xterm.js inside the 4D Web Area page)**
   - The embedded Web Area runs an HTML client interface booting `xterm.js`.
   - The interface handles and renders strings visually mimicking genuine shell formatting.
   - When a user interacts by pressing keys or invoking copies, `xterm.js` fires its internal `onData` handler.
   - Associated JavaScript routines accept those payloads and ping specific 4D binding functions (`$4d.SomeClass.onTerminalInput()`).

3. **Writing actions back to running PTY shells**
   - The signaled `cs.xterm.Xterm` binding intercepts the keystroke representation and routes it over the PTY pipe back to the underlying `zsh` or `bash` binary logic processing event loop context.
   - Once executed, the terminal daemon sends the output downstream over step 1, closing the cyclical feedback loop.

*Tip: Because `xterm.js` natively understands ANSI formats and automatically displays standard layout text colorings, you do **not** explicitly require the native ANSI decoder plugin to use Web-Area emulators.*

---

## Native PTY Backend Implementation

Underneath the web interface, Xterm4D uses a low-level object-oriented wrapper (`cs.xterm.PTY`) to interface with the native plugin commands.

### Prerequisites

To use the PTY capabilities in your own 4D project, you will need to install the core native plugin along with any desired decoding tools.

1. **PTY4DPlugin**: The native 4D plugin required to spawn and manage pseudoterminal processes.
   - You can download the plugin from the official repository: [mesopelagique/PTYPlugin4D](https://github.com/mesopelagique/PTYPlugin4D)
   - Install it by placing it inside your local project's `Plugins` folder.

2. **ANSI Decoder (Optional)**: If you want to natively decode and strip or parse ANSI codes entirely inside 4D components instead of `xterm.js` (e.g., styling a native 4D List Box), you should install the [ANSI decoder plugin](https://github.com/mesopelagique/ansi).

### Calling the `cs.xterm.PTY` Wrapper Directly

If you prefer to skip the Web Area interface, you can spawn a terminal process manually:

```4d
// Initialize class: target shell, horizontal columns, vertical rows, initial working directory.
var $pty := cs.xterm.PTY.new("/bin/zsh"; 80; 24; Folder(fk database folder).path)

If ($pty.isOpen)
    // Send a command followed by a trailing newline (\n):
    $pty.writeLine("ls -la")
    
    // Read the process output stream:
    var $output := $pty.readAll(500) // Timeout reading loops dynamically up to 500ms
    
    // Check if the component is continually running
    var $status : cs.PTYStatus := $pty.getStatus()
    
    // Close the PTY session safely once activity has resolved
    $pty.close()
End if
```

> **Detailed Documentation**: For a complete list of underlying properties and methods attached to `cs.xterm.PTY`, refer to [Documentation/Classes/PTY.md](Documentation/Classes/PTY.md).
