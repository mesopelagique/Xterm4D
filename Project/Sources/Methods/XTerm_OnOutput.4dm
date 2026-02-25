//%attributes = {"invisible":true}
// XTerm_OnOutput — executed in the FORM process via CALL FORM
// Pushes PTY output to the xterm.js Web Area.

#DECLARE($webArea : Text; $output : Text)

WA EXECUTE JAVASCRIPT FUNCTION(*; $webArea; "writeBase64ToTerminal"; *; $output)
