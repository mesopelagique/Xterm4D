// XTerm — all-in-one xterm.js + PTY controller for a 4D Web Area
//
// Uses a background WORKER to read PTY output — no timer polling needed.
// The worker blocks on PTY.read() and instantly pushes output via CALL FORM.
//
// Usage:
//   Form.xterm:=cs.XTerm.new("xterm")   // "xterm" = Web Area object name
//   Form.xterm.close()                   // On Unload
//
// Buttons / actions:
//   Form.xterm.clearContents()
//   Form.xterm.fit()
//   Form.xterm.setFontSize(16)
//   Form.xterm.writeLine("ls -la")
//   Form.xterm.interrupt()               // Ctrl-C
//   etc.

property pty : cs.PTY
property webArea : Text
property _workerName : Text
property _windowRef : Integer
property _signal : Object  // shared object — {running: True/False}

// ═══════════════════════════════════════════════════════════════════
//  Construction / destruction
// ═══════════════════════════════════════════════════════════════════

Class constructor($webArea : Text; $shell : Text; $cols : Integer; $rows : Integer; $workingDirectory : 4D.Folder)
	
	This.webArea:=$webArea
	This._signal:=New shared object("running"; True)
	
	// Create PTY
	This.pty:=cs.PTY.new($shell; $cols; $rows; ($workingDirectory=Null) ? "" : Folder($workingDirectory.platformPath; fk platform path).path)
	
	// Load xterm.html into the Web Area
	var $content : Text
	$content:=Folder(fk resources folder).file("xterm.html").getText()
	WA SET PAGE CONTENT(*; This.webArea; $content; "")
	
	// Bind this object as the $4d context
	WA SET CONTEXT(*; This.webArea; This)
	
	//WA SET PREFERENCE(*; This.webArea; 200; True)
	
	// Remember the window ref so the worker can CALL FORM back
	This._windowRef:=Current form window
	
	// Start a background worker to read PTY output
	This._workerName:="ptyReader_"+String(This.pty.id)
	CALL WORKER(This._workerName; "XTerm_ReadLoop"; This.pty.id; This._windowRef; This.webArea; This._signal)
	
	// ═══════════════════════════════════════════════════════════════════
	//  $4d callbacks  (called FROM JavaScript)
	// ═══════════════════════════════════════════════════════════════════
	
	// ── Called from JS when user types or pastes in xterm ────────────
Function onTerminalInput($data : Text)
	
	If (This.pty.isOpen)
		This.pty.write($data)
	End if 
	
	// ── Called from JS when xterm grid is resized ────────────────────
Function onTerminalResize($cols : Integer; $rows : Integer)
	
	If (This.pty.isOpen)
		This.pty.resize($cols; $rows)
	End if 
	
	// ═══════════════════════════════════════════════════════════════════
	//  Actions  (call from buttons, menus, 4D code…)
	// ═══════════════════════════════════════════════════════════════════
	
	// ── Write raw text to PTY (as if user typed it) ─────────────────
Function write($text : Text) : cs.XTerm
	
	If (This.pty.isOpen)
		This.pty.write($text)
	End if 
	return This
	
	// ── Write text + newline to PTY ─────────────────────────────────
Function writeLine($text : Text) : cs.XTerm
	
	return This.write($text+"\n")
	
	// ── Send Ctrl-C (SIGINT) ────────────────────────────────────────
Function interrupt() : Integer
	
	return This.pty.interrupt()
	
	// ── Clear the xterm screen (scrollback preserved) ───────────────
Function clearContents()
	
	This._jsCall("clearTerminal")
	
	// ── Recalculate terminal fit (after Web Area resize) ────────────
Function fit()
	
	This._jsCall("fitTerminal")
	
	// ── Change font size on the fly ─────────────────────────────────
Function setFontSize($size : Integer)
	
	This._jsCall("setFontSize"; String($size))
	
	// ── Get current grid dimensions → Object {cols, rows} ──────────
Function getSize() : Object
	
	var $json : Text
	This._jsCallReturn("getTerminalSize"; ->$json)
	return JSON Parse($json)
	
	// ── Focus the terminal ──────────────────────────────────────────
Function focus()
	
	This._jsCall("focusTerminal")
	
	// ═══════════════════════════════════════════════════════════════════
	//  Close / cleanup
	// ═══════════════════════════════════════════════════════════════════
	
Function close()
	
	// Signal the worker to stop (shared object — visible across processes)
	Use (This._signal)
		This._signal.running:=False
	End use 
	This._jsCall("dispose")
	This.pty.close()
	
	// ═══════════════════════════════════════════════════════════════════
	//  Private helpers
	// ═══════════════════════════════════════════════════════════════════
	
Function _jsCall($functionName : Text; $arg1 : Text; $arg2 : Text; $arg3 : Text)
	
	Case of 
		: (Count parameters>=4)
			WA EXECUTE JAVASCRIPT FUNCTION(*; This.webArea; $functionName; *; $arg1; $arg2; $arg3)
		: (Count parameters>=3)
			WA EXECUTE JAVASCRIPT FUNCTION(*; This.webArea; $functionName; *; $arg1; $arg2)
		: (Count parameters>=2)
			WA EXECUTE JAVASCRIPT FUNCTION(*; This.webArea; $functionName; *; $arg1)
		Else 
			WA EXECUTE JAVASCRIPT FUNCTION(*; This.webArea; $functionName; *)
	End case 
	
Function _jsCallReturn($functionName : Text; $returnPtr : Pointer)
	
	WA EXECUTE JAVASCRIPT FUNCTION(*; This.webArea; $functionName; $returnPtr->)
	
	