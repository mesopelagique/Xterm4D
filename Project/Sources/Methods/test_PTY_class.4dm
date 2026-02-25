//%attributes = {}
// Test the PTY wrapper class

var $pty : cs.PTY

// --- 1. Basic usage ---
$pty:=cs.PTY.new("/bin/zsh"; 80; 24; Folder(fk database folder).path)
ASSERT($pty.isOpen; "PTY should be open")

var $text:="echo Hello from PTY class"
$pty.writeLine("/bin/zsh")
var $output : Text
$output:=$pty.read()
ASSERT($output#""; "Should have output")

$pty.close()
ASSERT(Not($pty.isOpen); "PTY should be closed after close()")

// --- 2. Chained writes & status ---
$pty:=cs.PTY.new("/bin/zsh"; 120; 40)

$pty.writeLine("cd /tmp").writeLine("ls").writeLine("pwd")

var $all : Text
$all:=$pty.readAll()

var $status : Object
$status:=$pty.getStatus()
ASSERT($status.running; "Should still be running")
ASSERT($status.pid>0; "Should have a PID")

// --- 3. Resize ---
$pty.resize(200; 50)
$pty.writeLine("tput cols")
$output:=$pty.read()

// --- 4. Close & safe re-close ---
$pty.close()
$pty.close()  // should not crash

ASSERT(Not($pty.getStatus().running); "Should not be running after close")
ASSERT($pty.read()=""; "Read on closed PTY returns empty")

ALERT("All PTY class tests passed")
